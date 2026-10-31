import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'more_settings_page.dart';
import 'usage_guide_page.dart';
import './models/ble_device.dart';
import './widgets/device_tile.dart';
import './widgets/section_title.dart';
import './widgets/slide_action.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isUnlock = false;
  bool isSetLock = false;
  bool isFindCar = false;
  bool isPowerOn = false;

  String? connectedDeviceId;
  String? connectedDeviceName;
  String? connectingDeviceId;

  bool isConnecting = false;
  bool isScanning = false;

  bool _isHistoryLoaded = false;

  final List<BleDevice> _historyDevices = [];

  final List<BleDevice> _nearbyDevices = [];

  Future<void> _showDeviceDialog() async {
    if (!_isHistoryLoaded) {
      await _loadHistoryDevices();
    }

    if (!mounted) return;

    await _initializeBluetooth();

    if (!mounted) return;

    // Check connected devices before opening the dialog.
    await _loadConnectedDevices();

    if (!mounted) return;

    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> searchDevices() async {
              if (isScanning || isConnecting) return;

              setDialogState(() {
                isScanning = true;
                _nearbyDevices.clear();
              });

              StreamSubscription<List<ScanResult>>? resultsSubscription;
              StreamSubscription<bool>? scanStateSubscription;
              var scanStarted = false;

              try {
                final supported = await FlutterBluePlus.isSupported;

                if (!supported) {
                  throw Exception('Bluetooth is not supported on this device.');
                }

                final adapterState = await FlutterBluePlus.adapterState
                    .firstWhere(
                      (state) => state != BluetoothAdapterState.unknown,
                    )
                    .timeout(const Duration(seconds: 5));

                if (adapterState != BluetoothAdapterState.on) {
                  throw Exception('Bluetooth is not turned on: $adapterState');
                }

                resultsSubscription = FlutterBluePlus.onScanResults.listen(
                  (results) {
                    if (!mounted || !dialogContext.mounted) return;

                    final devices = <String, BleDevice>{};

                    for (final result in results) {
                      final id = result.device.remoteId.str;
                      final advertisedName = result.advertisementData.advName;
                      final platformName = result.device.platformName;

                      final name = advertisedName.isNotEmpty
                          ? advertisedName
                          : platformName;

                      devices[id] = BleDevice(
                        id: id,
                        name: name,
                        rssi: result.rssi,
                        bluetoothDevice: result.device,
                      );
                    }

                    setDialogState(() {
                      _nearbyDevices
                        ..clear()
                        ..addAll(devices.values);

                      _removeDuplicateDevices();

                      // Hide the loading animation as soon as the first result arrives.
                      if (devices.isNotEmpty) {
                        isScanning = false;
                      }
                    });
                  },
                  onError: (Object error) {
                    if (!mounted || !dialogContext.mounted) return;

                    setDialogState(() {
                      isScanning = false;
                    });
                  },
                );

                scanStateSubscription = FlutterBluePlus.isScanning.listen((
                  scanning,
                ) {
                  if (!mounted || !dialogContext.mounted) return;

                  if (scanning) {
                    scanStarted = true;
                    return;
                  }

                  if (scanStarted) {
                    setDialogState(() {
                      isScanning = false;
                    });

                    unawaited(resultsSubscription?.cancel());
                    unawaited(scanStateSubscription?.cancel());
                  }
                });

                await FlutterBluePlus.startScan(
                  timeout: const Duration(seconds: 12),
                );
              } catch (error) {
                await resultsSubscription?.cancel();
                await scanStateSubscription?.cancel();

                if (!mounted || !dialogContext.mounted) return;

                setDialogState(() {
                  isScanning = false;
                });

                await showCupertinoDialog<void>(
                  context: dialogContext,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('蓝牙扫描失败'),
                    content: Text(error.toString()),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              }
            }

            Future<void> connectDevice(BleDevice device) async {
              if (isConnecting || isScanning) return;

              final bleDevice = device.bluetoothDevice;

              if (bleDevice == null) {
                await showCupertinoDialog<void>(
                  context: dialogContext,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('无法连接'),
                    content: const Text('未获取到有效的蓝牙设备，请重新搜索。'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
                return;
              }

              setDialogState(() {
                isConnecting = true;
                connectingDeviceId = device.id;
              });

              try {
                if (FlutterBluePlus.isScanningNow) {
                  await FlutterBluePlus.stopScan();
                }

                await bleDevice.connect(
                  license: License.nonprofit,
                  timeout: const Duration(seconds: 15),
                );

                if (!mounted || !dialogContext.mounted) return;

                final services = await bleDevice.discoverServices();

                if (!mounted || !dialogContext.mounted) return;

                debugPrint('BLE connected: ${bleDevice.remoteId}');
                debugPrint('Discovered ${services.length} BLE services.');

                setState(() {
                  connectedDeviceId = bleDevice.remoteId.str;
                  connectedDeviceName = device.name.isEmpty
                      ? '未知设备'
                      : device.name;

                  _historyDevices.removeWhere((item) => item.id == device.id);

                  for (final item in _historyDevices) {
                    item.isLast = false;
                  }

                  _historyDevices.insert(
                    0,
                    BleDevice(
                      id: bleDevice.remoteId.str,
                      name: device.name,
                      rssi: device.rssi,
                      isHistory: true,
                      isLast: true,
                      isFound: true,
                      bluetoothDevice: bleDevice,
                    ),
                  );
                });

                setDialogState(() {
                  isConnecting = false;
                  connectingDeviceId = null;
                });

                Navigator.of(dialogContext).pop();

                await _saveHistoryDevices();
              } catch (error) {
                debugPrint('BLE connection failed: $error');

                if (!mounted || !dialogContext.mounted) return;

                setDialogState(() {
                  isConnecting = false;
                  connectingDeviceId = null;
                });

                await showCupertinoDialog<void>(
                  context: dialogContext,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('连接失败'),
                    content: Text(
                      '无法连接到 ${device.name.isEmpty ? '未知设备' : device.name}。\n$error',
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              }
            }

            final historyIds = _historyDevices
                .map((device) => device.id)
                .toSet();

            final visibleNearby = _nearbyDevices
                .where((device) => !historyIds.contains(device.id))
                .toList();

            return CupertinoAlertDialog(
              title: const Text(
                '连接蓝牙设备',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      '请选择要连接的摩托车设备',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_historyDevices.isNotEmpty) ...[
                      const SectionTitle(title: '连接过的设备'),
                      const SizedBox(height: 8),
                      ..._historyDevices.map(
                        (device) => DeviceTile(
                          device: device,
                          connected: connectedDeviceId == device.id,
                          connecting: connectingDeviceId == device.id,
                          disabled: isConnecting || isScanning,
                          onTap: () {
                            if (device.isFound) {
                              connectDevice(device);
                            } else {
                              _showUnavailableDeviceActions(
                                dialogContext,
                                device,
                                () => setDialogState(() {}),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SectionTitle(title: '新发现的设备'),
                    const SizedBox(height: 8),
                    if (isScanning)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(),
                            SizedBox(width: 8),
                            Text('正在搜索设备...', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      )
                    else if (visibleNearby.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            '暂未发现新设备',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                      )
                    else
                      ...visibleNearby.map(
                        (device) => DeviceTile(
                          device: device,
                          connected: connectedDeviceId == device.id,
                          connecting: connectingDeviceId == device.id,
                          disabled: isConnecting || isScanning,
                          onTap: () => connectDevice(device),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: isConnecting || isScanning ? null : searchDevices,
                  child: isScanning
                      ? const CupertinoActivityIndicator()
                      : const Text('搜索设备'),
                ),
                CupertinoDialogAction(
                  onPressed: isConnecting
                      ? null
                      : () async {
                          if (FlutterBluePlus.isScanningNow) {
                            await FlutterBluePlus.stopScan();
                          }

                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeDuplicateDevices() {
    final Map<String, BleDevice> nearbyById = {
      for (final device in _nearbyDevices) device.id: device,
    };

    for (final history in _historyDevices) {
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

  Future<void> _initializeBluetooth() async {
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

  Future<void> _showUnavailableDeviceActions(
    BuildContext dialogContext,
    BleDevice device,
    VoidCallback refreshDialog,
  ) async {
    final action = await showCupertinoModalPopup<String>(
      context: dialogContext,
      builder: (context) => CupertinoActionSheet(
        title: Text(device.name.isEmpty ? '未知设备' : device.name),
        message: const Text('该设备当前未被发现，你可以删除这条历史记录。'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop('delete');
            },
            child: const Text('删除设备'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop('cancel');
          },
          child: const Text('取消'),
        ),
      ),
    );

    if (action != 'delete' || !mounted || !dialogContext.mounted) {
      return;
    }

    final confirmed = await showCupertinoDialog<bool>(
      context: dialogContext,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('删除历史设备'),
        content: Text('确定删除「${device.name}」吗？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || !dialogContext.mounted) {
      return;
    }

    setState(() {
      _historyDevices.removeWhere((item) => item.id == device.id);

      if (connectedDeviceId == device.id) {
        connectedDeviceId = null;
        connectedDeviceName = null;
      }
    });

    await _saveHistoryDevices();

    refreshDialog();
  }

  static const String _historyStorageKey = 'ble_device_history';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  void initState() {
    super.initState();
    _loadHistoryDevices();
  }

  Future<void> _loadHistoryDevices() async {
    try {
      final jsonString = await _preferences.getString(_historyStorageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return;
      }

      final List<dynamic> records = jsonDecode(jsonString) as List<dynamic>;

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

      if (!mounted) return;

      setState(() {
        _historyDevices
          ..clear()
          ..addAll(devices);
      });
    } catch (error) {
      debugPrint('Failed to load BLE device history: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isHistoryLoaded = true;
        });
      } else {
        _isHistoryLoaded = true;
      }
    }
  }

  Future<void> _saveHistoryDevices() async {
    try {
      final records = _historyDevices.map((device) {
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

  Future<void> _loadConnectedDevices() async {
    try {
      final devices = FlutterBluePlus.connectedDevices;

      if (!mounted) return;

      setState(() {
        for (final item in _historyDevices) {
          item.isFound = false;
          item.bluetoothDevice = null;
        }

        for (final device in devices) {
          final id = device.remoteId.str;

          final index = _historyDevices.indexWhere((item) => item.id == id);

          if (index < 0) continue;

          final oldDevice = _historyDevices.removeAt(index);

          _historyDevices.insert(
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

        if (devices.isNotEmpty) {
          final device = devices.first;

          connectedDeviceId = device.remoteId.str;

          connectedDeviceName = device.platformName.isNotEmpty
              ? device.platformName
              : _historyDevices
                    .where((item) => item.id == device.remoteId.str)
                    .firstOrNull
                    ?.name;
        } else {
          connectedDeviceId = null;
          connectedDeviceName = null;
        }
      });

      await _saveHistoryDevices();
    } catch (error) {
      debugPrint('Failed to load connected devices: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      navigationBar: const CupertinoNavigationBar(middle: Text('首页')),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          connectedDeviceName ?? '设备型号',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _showDeviceDialog,
                        child: const Text('搜索设备'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.bluetooth,
                        size: 18,
                        color: connectedDeviceId != null
                            ? const Color(0xFF4F9EFF)
                            : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        connectedDeviceId != null ? '蓝牙已连接' : '蓝牙未连接',
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '-- V',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.black,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '电压',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Transform.translate(
                        offset: const Offset(20, -20),
                        child: Image.asset(
                          'assets/common/car.png',
                          width: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildCommand(
                        icon: 'assets/common/unlockImg.png',
                        activeIcon: 'assets/common/activeUnlockImg.png',
                        title: '解防',
                        active: isUnlock,
                        onTap: () {
                          setState(() {
                            isUnlock = !isUnlock;
                          });
                        },
                      ),
                      _buildCommand(
                        icon: 'assets/common/lockImg.png',
                        activeIcon: 'assets/common/activeLockImg.png',
                        title: '设防',
                        active: isSetLock,
                        onTap: () {
                          setState(() {
                            isSetLock = !isSetLock;
                          });
                        },
                      ),
                      _buildCommand(
                        icon: 'assets/common/findCarImg.png',
                        activeIcon: 'assets/common/activeFindCarImg.png',
                        title: '寻车',
                        active: isFindCar,
                        onTap: () {
                          setState(() {
                            isFindCar = !isFindCar;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SlideAction(
                    title: isPowerOn ? '滑动关闭车辆' : '滑动电启动',
                    icon: CupertinoIcons.power,
                    color: isPowerOn
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF4F9EFF),
                    onCompleted: () {
                      setState(() {
                        isPowerOn = !isPowerOn;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildMoreItem(
                    icon: 'assets/common/setImg.png',
                    title: '更多设置',
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        CupertinoPageRoute(
                          builder: (_) => const MoreSettingsPage(),
                        ),
                      );
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: const Color(0xFFF0F0F0),
                  ),
                  _buildMoreItem(
                    icon: 'assets/common/qusetion.png',
                    title: '使用说明',
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        CupertinoPageRoute<void>(
                          builder: (_) => const UsageGuidePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommand({
    required String icon,
    required String activeIcon,
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        onPressed: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              active ? activeIcon : icon,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: active
                    ? const Color(0xFF4F9EFF)
                    : const Color(0xFF333333),
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onPressed: onTap,
      child: Row(
        children: [
          Image.asset(icon, width: 24, height: 24, fit: BoxFit.contain),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: Color(0xFF999999),
          ),
        ],
      ),
    );
  }
}
