import 'package:flutter/cupertino.dart';

//For the page part.
import 'more_settings_page.dart';
import 'usage_guide_page.dart';
//For the ui part.
import './models/ble_device.dart';
import './widgets/device_tile.dart';
import './widgets/section_title.dart';
import './widgets/slide_action.dart';
//For the functionality part.
import 'services/ble_manager.dart';

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

  final List<BleDevice> _nearbyDevices = [];

  final BleManager _bleManager = BleManager();

  List<BleDevice> get _historyDevices => _bleManager.historyDevices;

  bool get _isHistoryLoaded => _bleManager.isHistoryLoaded;

  Future<void> _showDeviceDialog() async {
    if (!_isHistoryLoaded) {
      await _bleManager.loadHistory();
    }

    if (!mounted) return;

    await _bleManager.initializeBluetooth();

    if (!mounted) return;

    // Check connected devices before opening the dialog.
    final connectedDevice = await _bleManager.loadConnectedDevices();

    if (!mounted) return;

    setState(() {
      connectedDeviceId = connectedDevice?.id;
      connectedDeviceName = connectedDevice?.name.isNotEmpty == true
          ? connectedDevice!.name
          : null;
    });

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

              try {
                await _bleManager.startScan(
                  onResults: (devices) {
                    if (!mounted || !dialogContext.mounted) return;

                    setDialogState(() {
                      _nearbyDevices
                        ..clear()
                        ..addAll(devices);

                      _bleManager.updateHistoryFromScan(
                        _nearbyDevices,
                        connectedDeviceId,
                      );
                    });
                  },
                  onScanningChanged: (scanning) {
                    if (!mounted || !dialogContext.mounted) return;

                    setDialogState(() {
                      isScanning = scanning;
                    });
                  },
                );
              } catch (error) {
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

              setDialogState(() {
                isConnecting = true;
                connectingDeviceId = device.id;
              });

              try {
                final services = await _bleManager.connectDevice(device);

                if (!mounted || !dialogContext.mounted) return;

                debugPrint('BLE connected: ${device.id}');
                debugPrint('Discovered $services BLE services.');

                setState(() {
                  connectedDeviceId = device.id;
                  connectedDeviceName = device.name.isEmpty
                      ? '未知设备'
                      : device.name;
                });

                await _bleManager.addToHistory(device);

                if (!mounted || !dialogContext.mounted) return;

                setDialogState(() {
                  isConnecting = false;
                  connectingDeviceId = null;
                });

                Navigator.of(dialogContext).pop();
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
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(),
                            SizedBox(width: 8),
                            Text(
                              '正在搜索设备...',
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (visibleNearby.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            isScanning ? '正在等待发现设备...' : '暂未发现新设备',
                            style: const TextStyle(
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
                          await _bleManager.stopScan();

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

    await _bleManager.removeFromHistory(device.id);

    if (!mounted || !dialogContext.mounted) return;

    setState(() {
      if (connectedDeviceId == device.id) {
        connectedDeviceId = null;
        connectedDeviceName = null;
      }
    });

    refreshDialog();
  }

  @override
  void initState() {
    super.initState();
    _bleManager.loadHistory();
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
