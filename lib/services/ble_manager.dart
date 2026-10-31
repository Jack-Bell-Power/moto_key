import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/ble_device.dart';

class BleManager {
  static const String _historyStorageKey = 'ble_device_history';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  final List<BleDevice> historyDevices = [];

  bool isHistoryLoaded = false;

  Future<void>? _historyLoadFuture;

  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _scanStateSubscription;

  bool _scanStarted = false;

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
  Future<BluetoothDevice?> loadConnectedDevices() async {
    try {
      final devices = FlutterBluePlus.connectedDevices;

      for (final item in historyDevices) {
        item.isFound = false;
        item.bluetoothDevice = null;
      }

      for (final device in devices) {
        final id = device.remoteId.str;
        final index = historyDevices.indexWhere((item) => item.id == id);

        if (index < 0) continue;

        final oldDevice = historyDevices.removeAt(index);

        for (final item in historyDevices) {
          item.isLast = false;
        }

        historyDevices.insert(
          0,
          BleDevice(
            id: id,
            name: device.platformName.isNotEmpty
                ? device.platformName
                : oldDevice.name,
            rssi: oldDevice.rssi,
            isHistory: true,
            isLast: true,
            isFound: true,
            bluetoothDevice: device,
          ),
        );
      }

      await saveHistory();

      return devices.isNotEmpty ? devices.first : null;
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

    await _cancelScanSubscriptions();

    _scanStarted = false;

    _scanResultsSubscription = FlutterBluePlus.onScanResults.listen((results) {
      final devices = <String, BleDevice>{};

      for (final result in results) {
        final id = result.device.remoteId.str;
        final advertisedName = result.advertisementData.advName;
        final platformName = result.device.platformName;

        devices[id] = BleDevice(
          id: id,
          name: advertisedName.isNotEmpty ? advertisedName : platformName,
          rssi: result.rssi,
          bluetoothDevice: result.device,
        );
      }

      onResults(devices.values.toList());
    });

    _scanStateSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      if (scanning) {
        _scanStarted = true;
        return;
      }

      if (_scanStarted) {
        onScanningChanged(false);
        _cancelScanSubscriptions();
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
  }

  /// Stop the current BLE scan.
  Future<void> stopScan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    await _cancelScanSubscriptions();
  }

  /// Cancel BLE scan subscriptions.
  Future<void> _cancelScanSubscriptions() async {
    await _scanResultsSubscription?.cancel();
    await _scanStateSubscription?.cancel();

    _scanResultsSubscription = null;
    _scanStateSubscription = null;
  }

  /// Connect to a BLE device and discover its services.
  Future<List<BluetoothService>> connectDevice(BleDevice device) async {
    final bluetoothDevice = device.bluetoothDevice;

    if (bluetoothDevice == null) {
      throw StateError('The Bluetooth device is unavailable.');
    }

    await stopScan();

    await bluetoothDevice.connect(
      license: License.nonprofit,
      timeout: const Duration(seconds: 15),
    );

    return bluetoothDevice.discoverServices();
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
        bluetoothDevice: device.bluetoothDevice,
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
        history.bluetoothDevice = found.bluetoothDevice;

        if (found.name.isNotEmpty) {
          history.name = found.name;
        }
      }
    }
  }
}
