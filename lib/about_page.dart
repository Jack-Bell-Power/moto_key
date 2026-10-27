import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Color _backgroundColor = Color(0xFFF5F6F8);
  static const Color _primaryColor = Color(0xFF3478F6);
  static const Color _titleColor = Color(0xFF172337);
  static const Color _subtitleColor = Color(0xFF8190A8);

  static const String _githubUrl =
      'https://github.com/Jack-Bell-Power/moto_key';

  Future<void> _openGithub(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _githubUrl));

    if (!context.mounted) return;

    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('GitHub 开源仓库'),
          content: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              '仓库地址已复制，可以在浏览器中打开：\n\n'
              'github.com/Jack-Bell-Power/moto_key',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('完成'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('关于'),
        backgroundColor: _backgroundColor,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE3E8F0), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            // Developer Info
            _buildDeveloperCard(),

            const SizedBox(height: 28),

            // open-source project
            _buildProjectCard(context),

            const SizedBox(height: 32),

            // Bottom Note
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.heart_fill,
                    size: 12,
                    color: _primaryColor,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Open Source',
                    style: TextStyle(fontSize: 13, color: _subtitleColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Developer Card
  Widget _buildDeveloperCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/about/avatar.JPG',
              width: 76,
              height: 76,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '开发者',
                  style: TextStyle(fontSize: 14, color: _subtitleColor),
                ),
                SizedBox(height: 5),
                Text(
                  'Jack Bell',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '独立开发者 · 开源项目爱好者',
                  style: TextStyle(fontSize: 13, color: _subtitleColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Open Source Project Card
  Widget _buildProjectCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '开源项目',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _subtitleColor,
            ),
          ),

          const SizedBox(height: 22),

          // Project Overview
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/about/app_icon.png',
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moto Key',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '面向电动车的控制应用',
                      style: TextStyle(fontSize: 14, color: _subtitleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Container(height: 0.5, color: const Color(0xFFE5EAF1)),

          // GitHub repo entry
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 18),
            onPressed: () => _openGithub(context),
            child: const Row(
              children: [
                Icon(CupertinoIcons.link, size: 30, color: Color(0xFF24292F)),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GitHub 开源仓库',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _titleColor,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'github.com/Jack-Bell-Power/moto_key',
                        style: TextStyle(fontSize: 12, color: _subtitleColor),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: _subtitleColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
