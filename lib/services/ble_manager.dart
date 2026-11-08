import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/ble_device.dart';

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

  /// Listen to connection state changes.
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

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

  /// Refresh history entries using devices currently connected by the system.
  Future<BleDevice?> loadConnectedDevices() async {
    try {
      final devices = FlutterBluePlus.connectedDevices;

      for (final item in historyDevices) {
        item.isFound = false;
      }

      BleDevice? firstConnected;

      for (final device in devices) {
        final id = device.remoteId.str;
        final index = historyDevices.indexWhere((item) => item.id == id);

        _devicesById[id] = device;

        final oldDevice = index >= 0 ? historyDevices[index] : null;

        final connectedDevice = BleDevice(
          id: id,
          name: device.platformName.isNotEmpty
              ? device.platformName
              : oldDevice?.name ?? '',
          rssi: oldDevice?.rssi ?? 0,
          isHistory: true,
          isLast: true,
          isFound: true,
        );

        firstConnected ??= connectedDevice;

        historyDevices.removeWhere((item) => item.id == id);

        for (final item in historyDevices) {
          item.isLast = false;
        }

        historyDevices.insert(0, connectedDevice);
      }

      await saveHistory();

      return firstConnected;
    } catch (error) {
      debugPrint('Failed to load connected devices: $error');
      return null;
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
    final bluetoothDevice = _devicesById[device.id];

    if (bluetoothDevice == null) {
      throw StateError('The Bluetooth device is unavailable.');
    }

    await stopScan();

    final previousDevice = _connectedDevice;

    if (previousDevice != null &&
        previousDevice.remoteId != bluetoothDevice.remoteId &&
        previousDevice.isConnected) {
      await previousDevice.disconnect();
    }

    // Clean up previous connection listeners.
    await _notifySubscription?.cancel();
    await _connectionStateSubscription?.cancel();

    _writeCharacteristic = null;
    _notifyCharacteristic = null;

    _connectedDevice = bluetoothDevice;

    // Listen for connection state changes.
    _connectionStateSubscription = bluetoothDevice.connectionState.listen(
      _handleConnectionState,
      onError: (Object error) {
        debugPrint('BLE connection state error: $error');
      },
    );

    try {
      // Establish the BLE connection.
      await bluetoothDevice.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
      );

      // Discover services.
      final services = await bluetoothDevice.discoverServices();

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
          _receivedDataController.add(List<int>.unmodifiable(value));
        },
        onError: (Object error) {
          debugPrint('BLE notification error: $error');
        },
      );

      // Enable notifications.
      await _notifyCharacteristic!.setNotifyValue(true);

      debugPrint('BLE communication initialized.');

      return services.length;
    } catch (error) {
      debugPrint('BLE connection initialization failed: $error');

      await _notifySubscription?.cancel();
      _notifySubscription = null;

      _writeCharacteristic = null;
      _notifyCharacteristic = null;

      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;

      _connectedDevice = null;

      if (bluetoothDevice.isConnected) {
        try {
          await bluetoothDevice.disconnect();
        } catch (disconnectError) {
          debugPrint('BLE cleanup failed: $disconnectError');
        }
      }

      rethrow;
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
    debugPrint('BLE connection state: $state');

    _connectionStateController.add(state);

    if (state == BluetoothConnectionState.disconnected) {
      _notifySubscription?.cancel();
      _notifySubscription = null;

      _writeCharacteristic = null;
      _notifyCharacteristic = null;

      _connectedDevice = null;

      debugPrint('BLE device disconnected.');
    }
  }

  /// Disconnect the currently selected device.
  Future<void> disconnectDevice() async {
    final device = _connectedDevice;

    if (device == null) {
      return;
    }

    try {
      await device.disconnect();
    } catch (error) {
      debugPrint('BLE disconnect failed: $error');
      rethrow;
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
  }

  /// Check whether a UUID contains the expected 16-bit UUID.
  bool _matchesUuid(String actual, String expected) {
    final shortUuid = expected
        .replaceAll('-', '')
        .substring(4, 8)
        .toUpperCase();

    return actual.toUpperCase().contains(shortUuid);
  }
}
