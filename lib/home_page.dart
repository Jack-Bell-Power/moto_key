import 'package:flutter/cupertino.dart';

import 'more_settings_page.dart';
import 'usage_guide_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // The highlighted state of the four function buttons
  bool isUnlock = false;
  bool isSetLock = false;
  bool isFindCar = false;

  // Electric start status
  bool isPowerOn = false;

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
            // Device Info Card
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device model and search button
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '设备型号',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        child: const Text('搜索设备'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Bluetooth status
                  const Row(
                    children: [
                      Icon(
                        CupertinoIcons.bluetooth,
                        size: 18,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '蓝牙未连接',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Voltage and vehicle pictures
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

            // Vehicle Function Control Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Four function buttons
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

                  // Electric start / Turn off the vehicle
                  SlideAction(
                    title: isPowerOn ? '滑动关闭车辆' : '滑动电启动',
                    icon: CupertinoIcons.power,
                    color: isPowerOn
                        ? const Color(0xFF4F9EFF)
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

            // More settings and instructions
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

  // General function button: switch between normal and highlighted images based on status
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
                fontSize: 14,
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
  double _progress = 0;
  bool _dragging = false;

  void _onDragUpdate(DragUpdateDetails details, double maxDistance) {
    setState(() {
      _dragging = true;
      _progress = (_progress + details.delta.dx / maxDistance).clamp(0.0, 1.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_progress >= 0.9) {
      widget.onCompleted();
    }

    setState(() {
      _progress = 0;
      _dragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double height = 50;
        const double padding = 4;
        const double thumbSize = height - padding * 2;

        final double maxDistance =
            constraints.maxWidth - thumbSize - padding * 2;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              Center(
                child: Opacity(
                  opacity: 1 - _progress * 0.7,
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: padding + _progress * maxDistance,
                top: padding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    _onDragUpdate(details, maxDistance);
                  },
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.22),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
