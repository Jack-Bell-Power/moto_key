import 'package:flutter/cupertino.dart';

import 'dart:async';

import 'more_settings_page.dart';
import 'usage_guide_page.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  bool isSitBucket = false;

  String? connectedDeviceId;
  String? connectedDeviceName;
  String? connectingDeviceId;

  bool isConnecting = false;
  bool isScanning = false;

  final List<_BleDevice> _historyDevices = [
    _BleDevice(
      id: 'DX02252851',
      name: 'DX02252851',
      rssi: -52,
      isHistory: true,
      isLast: true,
      isFound: false,
    ),
  ];

  final List<_BleDevice> _nearbyDevices = [];

  Future<void> _showDeviceDialog() async {
    await _initializeBluetooth();

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

                    final devices = <String, _BleDevice>{};

                    for (final result in results) {
                      final id = result.device.remoteId.str;
                      final advertisedName = result.advertisementData.advName;
                      final platformName = result.device.platformName;

                      final name = advertisedName.isNotEmpty
                          ? advertisedName
                          : platformName;

                      devices[id] = _BleDevice(
                        id: id,
                        name: name,
                        rssi: result.rssi,
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

            Future<void> connectDevice(_BleDevice device) async {
              if (isConnecting || isScanning) return;

              setDialogState(() {
                isConnecting = true;
                connectingDeviceId = device.id;
              });

              // Simulate a BLE connection.
              await Future<void>.delayed(const Duration(milliseconds: 800));

              if (!mounted || !dialogContext.mounted) return;

              setState(() {
                connectedDeviceId = device.id;
                connectedDeviceName = device.name.isEmpty
                    ? '未知设备'
                    : device.name;

                _historyDevices.removeWhere((item) => item.id == device.id);

                for (final item in _historyDevices) {
                  item.isLast = false;
                }

                _historyDevices.insert(
                  0,
                  _BleDevice(
                    id: device.id,
                    name: device.name,
                    rssi: device.rssi,
                    isHistory: true,
                    isLast: true,
                    isFound: true,
                  ),
                );
              });

              setDialogState(() {
                isConnecting = false;
                connectingDeviceId = null;
              });

              Navigator.of(dialogContext).pop();
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
                      const _SectionTitle(title: '连接过的设备'),
                      const SizedBox(height: 8),
                      ..._historyDevices.map(
                        (device) => _DeviceTile(
                          device: device,
                          connected: connectedDeviceId == device.id,
                          connecting: connectingDeviceId == device.id,
                          disabled: isConnecting || isScanning,
                          onTap: () => connectDevice(device),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const _SectionTitle(title: '新发现的设备'),
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
                        (device) => _DeviceTile(
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
    final Map<String, _BleDevice> nearbyById = {
      for (final device in _nearbyDevices) device.id: device,
    };

    for (final history in _historyDevices) {
      final found = nearbyById[history.id];

      history.isFound = found != null;

      if (found != null) {
        history.rssi = found.rssi;
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

class _BleDevice {
  _BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.isHistory = false,
    this.isLast = false,
    this.isFound = true,
  });

  final String id;
  String name;
  int rssi;
  final bool isHistory;
  bool isLast;
  bool isFound;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.connected,
    required this.connecting,
    required this.disabled,
    required this.onTap,
  });

  final _BleDevice device;
  final bool connected;
  final bool connecting;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool unavailable = device.isHistory && !device.isFound;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      onPressed: disabled ? null : onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              CupertinoIcons.bluetooth,
              size: 21,
              color: Color(0xFF3478F6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name.isEmpty ? '未知设备' : device.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  unavailable
                      ? '未发现'
                      : device.isHistory
                      ? '${device.isLast ? '上次连接' : '历史设备'} · ${device.rssi} dBm'
                      : '蓝牙设备 · ${device.rssi} dBm',
                  style: TextStyle(
                    fontSize: 11,
                    color: unavailable
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (connecting)
            const CupertinoActivityIndicator()
          else if (connected)
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Color(0xFF3478F6),
              size: 22,
            )
          else
            const Icon(
              CupertinoIcons.chevron_right,
              color: Color(0xFF9CA3AF),
              size: 17,
            ),
        ],
      ),
    );
  }
}

class SlideAction extends StatefulWidget {
  const SlideAction({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onCompleted,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onCompleted;

  @override
  State<SlideAction> createState() => _SlideActionState();
}

class _SlideActionState extends State<SlideAction> {
  bool _isOn = false;
  double _dragOffset = 0;

  static const double _height = 48;
  static const double _padding = 4;
  static const double _thumbSize = _height - _padding * 2;

  static const Color _lightBlue = Color(0xFFF0F5FF);
  static const Color _red = Color(0xFFFF3B30);
  static const Color _lightRed = Color(0xFFFFEDEC);

  void _onDragUpdate(DragUpdateDetails details, double maxOffset) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx)
          .clamp(0.0, maxOffset)
          .toDouble();
    });
  }

  void _onDragEnd(double maxOffset) {
    final bool oldState = _isOn;
    final double progress = maxOffset <= 0 ? 0 : _dragOffset / maxOffset;

    setState(() {
      if (progress >= 0.75) {
        _isOn = true;
      } else if (progress <= 0.25) {
        _isOn = false;
      }

      _dragOffset = _isOn ? maxOffset : 0;
    });

    if (oldState != _isOn) {
      widget.onCompleted();
    }
  }

  @override
  void didUpdateWidget(covariant SlideAction oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool newIsOn = widget.title.contains('关闭车辆');

    if (newIsOn != _isOn) {
      _isOn = newIsOn;
      _dragOffset = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxOffset =
            (constraints.maxWidth - _thumbSize - _padding * 2)
                .clamp(0.0, double.infinity)
                .toDouble();

        final double dragOffset = _dragOffset.clamp(0.0, maxOffset).toDouble();

        final Color activeColor = _isOn ? _red : widget.color;
        final Color trackColor = _isOn ? _lightRed : _lightBlue;

        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                  ),
                ),
              ),
              Positioned(
                left: _padding + dragOffset,
                top: _padding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onDragUpdate(details, maxOffset),
                  onHorizontalDragEnd: (_) => _onDragEnd(maxOffset),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      color: CupertinoColors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
