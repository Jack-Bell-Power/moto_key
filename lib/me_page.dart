import 'package:flutter/cupertino.dart';

import 'advanced_settings_page.dart';
import 'about_page.dart';
import 'donate_page.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  // After connecting via Bluetooth later, replace it with the actual device name and version number
  final String deviceName = '未知';
  final String version = '最新版';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      navigationBar: const CupertinoNavigationBar(middle: Text('我的')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Electric vehicle name and version info
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildInfoItem(
                    icon: 'assets/common/myCar.png',
                    title: '电动车名称',
                    value: deviceName,
                    showArrow: false,
                  ),
                  _buildDivider(),
                  _buildInfoItem(
                    icon: 'assets/common/deviceInfo.png',
                    title: '版本信息',
                    value: version,
                    showArrow: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Advanced Settings
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildInfoItem(
                icon: 'assets/common/myLocation.png',
                title: '高级设置',
                value: '',
                showArrow: true,
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute(
                      builder: (context) => const AdvancedSettingsPage(),
                    ),
                  );
                },
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildInfoItem(
                icon: 'assets/common/donate.png',
                title: '捐赠',
                value: '',
                showArrow: true,
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const DonatePage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildInfoItem(
                icon: 'assets/common/about.png',
                title: '关于',
                value: '',
                showArrow: true,
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute<void>(builder: (_) => const AboutPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required String icon,
    required String title,
    required String value,
    required bool showArrow,
    VoidCallback? onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      onPressed: onTap,
      child: Row(
        children: [
          Image.asset(icon, width: 22, height: 22, fit: BoxFit.contain),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          if (showArrow) ...[
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: Color(0xFF999999),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFF0F0F0),
    );
  }
}
