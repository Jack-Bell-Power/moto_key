import 'package:flutter/cupertino.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            // Top device info card
            Container(
              padding: const EdgeInsets.all(20),
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
                        onPressed: () {
                          // Later add search device feature
                        },
                        child: const Text('搜索设备'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Bluetooth connection status
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

                      // Temporarily using a car icon as a placeholder
                      Transform.translate(
                        offset: const Offset(20, -15),
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
          ],
        ),
      ),
    );
  }
}
