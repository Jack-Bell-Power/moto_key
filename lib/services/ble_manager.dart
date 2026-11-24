import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/ble_device.dart';
import '../models/ble_connection_status.dart';

class BleManager {
  static const String _historyStorageKey = 'ble_device_history';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  final List<BleDevice> historyDevices = [];

  final Map<String, BluetoothDevice> _devicesById = {};
  final Map<String, BleDevice> _scanResultsById = {};

  bool isHistoryLoaded = false;

  Future<void>? _historyLoadFuture;

  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _scanStateSubscription;

  bool _scanStarted = false;

  static const String _serviceUuid = '0000FEE5-0000-1000-8000-00805F9B34FB';

  static const String _writeCharacteristicUuid =
      '0000FEB5-0000-1000-8000-00805F9B34FB';

  static const String _notifyCharacteristicUuid =
      '0000FEB6-0000-1000-8000-00805F9B34FB';

  BluetoothDevice? _connectedDevice;

  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  StreamSubscription<List<int>>? _notifySubscription;

  final StreamController<BluetoothConnectionState> _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();

  final StreamController<List<int>> _receivedDataController =
      StreamController<List<int>>.broadcast();

  final StreamController<BleConnectionStatus> _statusController =
      StreamController<BleConnectionStatus>.broadcast();

  BleConnectionStatus _connectionStatus = BleConnectionStatus.disconnected;

  /// Listen to BLE connection status.
  Stream<BleConnectionStatus> get connectionStatusStream =>
      _statusController.stream;

  /// Get the current BLE connection status.
  BleConnectionStatus get connectionStatus => _connectionStatus;

  /// Update the BLE connection status.
  void _updateConnectionStatus(BleConnectionStatus status) {
    _connectionStatus = status;

    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// Listen to received BLE data.
  Stream<List<int>> get receivedDataStream => _receivedDataController.stream;

  /// Get the currently selected device.
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Check whether the selected device is connected.
  bool get isConnected => _connectedDevice?.isConnected ?? false;

  /// Get the current device ID.
  String? get connectedDeviceId => _connectedDevice?.remoteId.str;

  /// Check whether the communication characteristics are ready.
  bool get isCommunicationReady =>
      isConnected &&
      _writeCharacteristic != null &&
      _notifyCharacteristic != null;

  static const List<Duration> _reconnectIntervals = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 5),
    Duration(seconds: 8),
  ];

  static const int _maxReconnectAttempts = 12;

  Timer? _reconnectTimer;

  bool _autoReconnectEnabled = false;
  bool _isConnecting = false;
  bool _hasConnectedSuccessfully = false;
  bool _isDisposed = false;

  int _reconnectAttempts = 0;

  int _connectionGeneration = 0;

  /// Initialize the Bluetooth adapter.
  Future<void> initializeBluetooth() async {
    try {
      final supported = await FlutterBluePlus.isSupported;

      if (!supported) {
        debugPrint('BLE is not supported.');
        return;
      }

      await FlutterBluePlus.adapterState
          .firstWhere((state) => state != BluetoothAdapterState.unknown)
          .timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint('BLE initialization failed: $error');
    }
  }

  /// Load previously connected devices from local storage.
  Future<void> loadHistory() {
    return _historyLoadFuture ??= _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final jsonString = await _preferences.getString(_historyStorageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return;
      }

      final records = jsonDecode(jsonString) as List<dynamic>;

      final devices = records.map((record) {
        final item = Map<String, dynamic>.from(record as Map);

        return BleDevice(
          id: item['id'] as String,
          name: item['name'] as String? ?? '',
          rssi: item['rssi'] as int? ?? 0,
          isHistory: true,
          isLast: item['isLast'] as bool? ?? false,
          isFound: false,
        );
      }).toList();

      historyDevices
        ..clear()
        ..addAll(devices);
    } catch (error) {
      debugPrint('Failed to load BLE device history: $error');
    } finally {
      isHistoryLoaded = true;
    }
  }

  /// Save the device history to local storage.
  Future<void> saveHistory() async {
    try {
      final records = historyDevices.map((device) {
        return <String, dynamic>{
          'id': device.id,
          'name': device.name,
          'rssi': device.rssi,
          'isLast': device.isLast,
        };
      }).toList();

      await _preferences.setString(_historyStorageKey, jsonEncode(records));
    } catch (error) {
      debugPrint('Failed to save BLE device history: $error');
    }
  }

  /// Start scanning for nearby BLE devices.
  Future<void> startScan({
    required ValueChanged<List<BleDevice>> onResults,
    required ValueChanged<bool> onScanningChanged,
  }) async {
    final supported = await FlutterBluePlus.isSupported;

    if (!supported) {
      throw Exception('Bluetooth is not supported on this device.');
    }

    final adapterState = await FlutterBluePlus.adapterState
        .firstWhere((state) => state != BluetoothAdapterState.unknown)
        .timeout(const Duration(seconds: 5));

    if (adapterState != BluetoothAdapterState.on) {
      throw Exception('Bluetooth is not turned on: $adapterState');
    }

    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    await _cancelScanSubscriptions();

    _scanResultsById.clear();
    _scanStarted = false;

    // Notify the UI immediately.
    onScanningChanged(true);

    _scanResultsSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        for (final result in results) {
          final id = result.device.remoteId.str;

          final advertisedName = result.advertisementData.advName;
          final platformName = result.device.platformName;

          final previous = _scanResultsById[id];

          final name = advertisedName.isNotEmpty
              ? advertisedName
              : platformName.isNotEmpty
              ? platformName
              : previous?.name ?? '';

          // Only accept connectable devices with names containing DX.
          if (!name.toUpperCase().contains('DX') ||
              !result.advertisementData.connectable) {
            continue;
          }
          _devicesById[id] = result.device;
          // Update existing devices or insert newly discovered devices.
          _scanResultsById[id] = BleDevice(
            id: id,
            name: name,
            rssi: result.rssi,
            isHistory: false,
            isLast: false,
            isFound: true,
          );
        }

        // Always return the complete list discovered so far.
        onResults(
          List<BleDevice>.unmodifiable(_scanResultsById.values.toList()),
        );
      },
      onError: (Object error) {
        debugPrint('BLE scan results error: $error');
      },
    );

    _scanStateSubscription = FlutterBluePlus.isScanning.listen(
      (scanning) {
        if (scanning) {
          _scanStarted = true;
          return;
        }

        if (_scanStarted) {
          _scanStarted = false;
          onScanningChanged(false);
        }
      },
      onError: (Object error) {
        debugPrint('BLE scan state error: $error');
      },
    );

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(_serviceUuid)],
        timeout: const Duration(seconds: 12),
      );
    } catch (error) {
      _scanStarted = false;
      onScanningChanged(false);

      await _cancelScanSubscriptions();

      rethrow;
    }
  }

  /// Stop the current BLE scan.
  Future<void> stopScan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    _scanStarted = false;

    await _cancelScanSubscriptions();
  }

  /// Cancel BLE scan subscriptions.
  Future<void> _cancelScanSubscriptions() async {
    await _scanResultsSubscription?.cancel();
    await _scanStateSubscription?.cancel();

    _scanResultsSubscription = null;
    _scanStateSubscription = null;
  }

  /// Connect to a BLE device and initialize communication.
  Future<int> connectDevice(BleDevice device) async {
    if (_isDisposed) {
      throw StateError('BLE manager has been disposed.');
    }

    if (_isConnecting) {
      throw StateError('A BLE connection is already in progress.');
    }

    final bluetoothDevice = _devicesById[device.id];

    if (bluetoothDevice == null) {
      throw StateError('The Bluetooth device is unavailable.');
    }

    // Invalidate previous connection tasks.
    _connectionGeneration++;
    final generation = _connectionGeneration;

    // Lock immediately to prevent concurrent connection attempts.
    _isConnecting = true;

    // Disable automatic reconnection for the previous device.
    _autoReconnectEnabled = false;
    _hasConnectedSuccessfully = false;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _reconnectAttempts = 0;

    bool connectionStarted = false;

    // Check whether this connection task is still valid.
    void checkConnectionTask() {
      if (_isDisposed ||
          generation != _connectionGeneration ||
          !_autoReconnectEnabled ||
          !identical(_connectedDevice, bluetoothDevice)) {
        throw StateError('BLE connection attempt was cancelled.');
      }
    }

    try {
      await stopScan();

      if (_isDisposed || generation != _connectionGeneration) {
        throw StateError('BLE connection attempt was cancelled.');
      }

      final previousDevice = _connectedDevice;

      if (previousDevice != null &&
          previousDevice.remoteId != bluetoothDevice.remoteId &&
          previousDevice.isConnected) {
        await previousDevice.disconnect();
      }

      if (_isDisposed || generation != _connectionGeneration) {
        throw StateError('BLE connection attempt was cancelled.');
      }

      // Clean up previous connection listeners.
      await _notifySubscription?.cancel();
      await _connectionStateSubscription?.cancel();

      _notifySubscription = null;
      _connectionStateSubscription = null;

      _writeCharacteristic = null;
      _notifyCharacteristic = null;

      _connectedDevice = bluetoothDevice;
      connectionStarted = true;

      _autoReconnectEnabled = true;

      // Listen for connection state changes.
      _connectionStateSubscription = bluetoothDevice.connectionState.listen(
        _handleConnectionState,
        onError: (Object error) {
          debugPrint('BLE connection state error: $error');
        },
      );

      // Establish the BLE connection.
      await bluetoothDevice.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
      );

      checkConnectionTask();

      // Discover services.
      final services = await bluetoothDevice.discoverServices();

      checkConnectionTask();

      BluetoothService? targetService;

      for (final service in services) {
        debugPrint('BLE service UUID: ${service.uuid.str}');

        if (_matchesUuid(service.uuid.str, _serviceUuid)) {
          targetService = service;
          break;
        }
      }

      if (targetService == null) {
        throw StateError('Required BLE service FEE5 was not found.');
      }

      // Find the write and notify characteristics.
      for (final characteristic in targetService.characteristics) {
        final uuid = characteristic.uuid.str;

        debugPrint(
          'BLE characteristic UUID: $uuid, '
          'properties: ${characteristic.properties}',
        );

        if (_matchesUuid(uuid, _writeCharacteristicUuid) &&
            characteristic.properties.write) {
          _writeCharacteristic = characteristic;
        }

        if (_matchesUuid(uuid, _notifyCharacteristicUuid) &&
            (characteristic.properties.notify ||
                characteristic.properties.indicate)) {
          _notifyCharacteristic = characteristic;
        }
      }

      if (_writeCharacteristic == null) {
        throw StateError('Write characteristic FEB5 was not found.');
      }

      if (_notifyCharacteristic == null) {
        throw StateError('Notify characteristic FEB6 was not found.');
      }

      // Subscribe before enabling notifications.
      _notifySubscription = _notifyCharacteristic!.onValueReceived.listen(
        (value) {
          if (!_receivedDataController.isClosed) {
            _receivedDataController.add(List<int>.unmodifiable(value));
          }
        },
        onError: (Object error) {
          debugPrint('BLE notification error: $error');
        },
      );

      // Enable notifications.
      await _notifyCharacteristic!.setNotifyValue(true);

      checkConnectionTask();

      _hasConnectedSuccessfully = true;
      _reconnectAttempts = 0;

      _updateConnectionStatus(BleConnectionStatus.connected);

      debugPrint('BLE communication initialized.');

      return services.length;
    } catch (error) {
      if (generation == _connectionGeneration) {
        _autoReconnectEnabled = false;
        _hasConnectedSuccessfully = false;

        _updateConnectionStatus(BleConnectionStatus.disconnected);
      }

      debugPrint('BLE connection initialization failed: $error');

      if (connectionStarted) {
        await _notifySubscription?.cancel();
        await _connectionStateSubscription?.cancel();

        _notifySubscription = null;
        _connectionStateSubscription = null;

        _writeCharacteristic = null;
        _notifyCharacteristic = null;

        if (identical(_connectedDevice, bluetoothDevice)) {
          _connectedDevice = null;
        }

        if (bluetoothDevice.isConnected) {
          try {
            await bluetoothDevice.disconnect();
          } catch (disconnectError) {
            debugPrint('BLE cleanup failed: $disconnectError');
          }
        }
      }

      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  /// Add or update a connected device in history.
  Future<void> addToHistory(BleDevice device) async {
    historyDevices.removeWhere((item) => item.id == device.id);

    for (final item in historyDevices) {
      item.isLast = false;
    }

    historyDevices.insert(
      0,
      BleDevice(
        id: device.id,
        name: device.name,
        rssi: device.rssi,
        isHistory: true,
        isLast: true,
        isFound: true,
      ),
    );

    await saveHistory();
  }

  /// Remove a device from history.
  Future<void> removeFromHistory(String deviceId) async {
    historyDevices.removeWhere((item) => item.id == deviceId);

    await saveHistory();
  }

  /// Update history devices using the latest scan results.
  void updateHistoryFromScan(
    List<BleDevice> nearbyDevices,
    String? connectedDeviceId,
  ) {
    final Map<String, BleDevice> nearbyById = {
      for (final device in nearbyDevices) device.id: device,
    };

    for (final history in historyDevices) {
      final found = nearbyById[history.id];

      history.isFound = found != null || history.id == connectedDeviceId;

      if (found != null) {
        history.rssi = found.rssi;

        if (found.name.isNotEmpty) {
          history.name = found.name;
        }
      }
    }
  }

  /// Handle BLE connection state changes.
  void _handleConnectionState(BluetoothConnectionState state) {
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }

    if (state == BluetoothConnectionState.disconnected) {
      _notifySubscription?.cancel();
      _notifySubscription = null;

      _writeCharacteristic = null;
      _notifyCharacteristic = null;

      if (_autoReconnectEnabled && _hasConnectedSuccessfully && !_isDisposed) {
        // Keep the reconnecting status during automatic reconnection.
        _updateConnectionStatus(BleConnectionStatus.reconnecting);

        if (!_isConnecting) {
          _scheduleReconnect();
        }
      } else {
        _updateConnectionStatus(BleConnectionStatus.disconnected);
      }
    }
  }

  /// Disconnect the currently selected device.
  Future<void> disconnectDevice() async {
    // Invalidate any ongoing connection tasks.
    _connectionGeneration++;

    _autoReconnectEnabled = false;
    _hasConnectedSuccessfully = false;

    _updateConnectionStatus(BleConnectionStatus.disconnected);
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final device = _connectedDevice;

    if (device == null) {
      return;
    }

    try {
      await device.disconnect();
    } finally {
      await _notifySubscription?.cancel();
      await _connectionStateSubscription?.cancel();

      _notifySubscription = null;
      _connectionStateSubscription = null;

      _writeCharacteristic = null;
      _notifyCharacteristic = null;
      _connectedDevice = null;

      _reconnectAttempts = 0;
    }
  }

  /// Write data to the vehicle.
  Future<void> writeData(List<int> data) async {
    final characteristic = _writeCharacteristic;

    if (!isCommunicationReady || characteristic == null) {
      throw StateError('BLE communication is not ready.');
    }

    await characteristic.write(data);
  }

  /// Release BLE resources.
  Future<void> dispose() async {
    _connectionGeneration++;

    _isDisposed = true;
    _autoReconnectEnabled = false;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await stopScan();

    await _notifySubscription?.cancel();
    await _connectionStateSubscription?.cancel();

    final device = _connectedDevice;

    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _connectedDevice = null;

    if (device != null && device.isConnected) {
      try {
        await device.disconnect();
      } catch (error) {
        debugPrint('BLE dispose disconnect failed: $error');
      }
    }

    await _connectionStateController.close();
    await _receivedDataController.close();
    await _statusController.close();
  }

  /// Check whether a UUID contains the expected 16-bit UUID.
  bool _matchesUuid(String actual, String expected) {
    final shortUuid = expected
        .replaceAll('-', '')
        .substring(4, 8)
        .toUpperCase();

    return actual.toUpperCase().contains(shortUuid);
  }

  /// Schedule the next reconnection attempt.
  void _scheduleReconnect() {
    if (_isDisposed ||
        !_autoReconnectEnabled ||
        !_hasConnectedSuccessfully ||
        _connectedDevice == null ||
        _isConnecting ||
        _reconnectTimer != null) {
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _autoReconnectEnabled = false;

      _updateConnectionStatus(BleConnectionStatus.disconnected);

      return;
    }

    final index = _reconnectAttempts < _reconnectIntervals.length
        ? _reconnectAttempts
        : _reconnectIntervals.length - 1;

    final delay = _reconnectIntervals[index];

    _reconnectAttempts++;

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _attemptReconnect();
    });
  }

  /// Attempt to reconnect to the previously connected device.
  Future<void> _attemptReconnect() async {
    final device = _connectedDevice;
    final generation = _connectionGeneration;

    if (_isDisposed ||
        !_autoReconnectEnabled ||
        !_hasConnectedSuccessfully ||
        device == null ||
        _isConnecting) {
      return;
    }

    _isConnecting = true;

    _updateConnectionStatus(BleConnectionStatus.reconnecting);

    try {
      final adapterState = await FlutterBluePlus.adapterState
          .firstWhere((state) => state != BluetoothAdapterState.unknown)
          .timeout(const Duration(seconds: 5));

      // Check whether this reconnection task is still valid.
      if (_isDisposed ||
          generation != _connectionGeneration ||
          !_autoReconnectEnabled ||
          !identical(_connectedDevice, device)) {
        return;
      }

      if (adapterState != BluetoothAdapterState.on) {
        throw StateError('Bluetooth is not turned on.');
      }

      await _initializeConnection(device);

      // Check again after connection initialization.
      if (_isDisposed ||
          generation != _connectionGeneration ||
          !_autoReconnectEnabled ||
          !identical(_connectedDevice, device)) {
        if (device.isConnected) {
          await device.disconnect();
        }
        return;
      }

      _reconnectAttempts = 0;

      _updateConnectionStatus(BleConnectionStatus.connected);
    } catch (_) {
      final isCurrentTask =
          !_isDisposed &&
          generation == _connectionGeneration &&
          _autoReconnectEnabled &&
          identical(_connectedDevice, device);

      if (isCurrentTask) {
        await _notifySubscription?.cancel();
        _notifySubscription = null;

        _writeCharacteristic = null;
        _notifyCharacteristic = null;

        if (device.isConnected) {
          try {
            await device.disconnect();
          } catch (_) {
            // Ignore disconnect errors during reconnection.
          }
        }
      }
    } finally {
      _isConnecting = false;
    }

    if (!_isDisposed &&
        generation == _connectionGeneration &&
        _autoReconnectEnabled &&
        identical(_connectedDevice, device) &&
        !device.isConnected) {
      _scheduleReconnect();
    }
  }

  /// Connect to a device and initialize its BLE communication.
  Future<int> _initializeConnection(BluetoothDevice device) async {
    _writeCharacteristic = null;
    _notifyCharacteristic = null;

    await device.connect(
      license: License.nonprofit,
      timeout: const Duration(seconds: 15),
    );

    final services = await device.discoverServices();

    BluetoothService? targetService;

    for (final service in services) {
      if (_matchesUuid(service.uuid.str, _serviceUuid)) {
        targetService = service;
        break;
      }
    }

    if (targetService == null) {
      throw StateError('Required BLE service FEE5 was not found.');
    }

    for (final characteristic in targetService.characteristics) {
      final uuid = characteristic.uuid.str;

      if (_matchesUuid(uuid, _writeCharacteristicUuid) &&
          characteristic.properties.write) {
        _writeCharacteristic = characteristic;
      }

      if (_matchesUuid(uuid, _notifyCharacteristicUuid) &&
          (characteristic.properties.notify ||
              characteristic.properties.indicate)) {
        _notifyCharacteristic = characteristic;
      }
    }

    if (_writeCharacteristic == null) {
      throw StateError('Write characteristic FEB5 was not found.');
    }

    if (_notifyCharacteristic == null) {
      throw StateError('Notify characteristic FEB6 was not found.');
    }

    await _notifySubscription?.cancel();

    _notifySubscription = _notifyCharacteristic!.onValueReceived.listen((
      value,
    ) {
      if (!_receivedDataController.isClosed) {
        _receivedDataController.add(List<int>.unmodifiable(value));
      }
    });

    await _notifyCharacteristic!.setNotifyValue(true);

    return services.length;
  }
}
