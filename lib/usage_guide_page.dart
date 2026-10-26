import 'package:flutter/cupertino.dart';

class UsageGuidePage extends StatelessWidget {
  const UsageGuidePage({super.key});

  static const Color _backgroundColor = Color(0xFFF5F6F8);
  static const Color _primaryColor = Color(0xFF1677FF);
  static const Color _textColor = Color(0xFF333333);
  static const Color _secondaryColor = Color(0xFF666666);
  static const Color _dividerColor = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('使用说明'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 01 配对密码
            _buildCard(
              children: [
                _buildSectionTitle('01', '配对密码'),
                const SizedBox(height: 20),
                const Text(
                  'Q：连接配对密码（代码）是什么？',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '初始密码为：',
                  style: TextStyle(
                    fontSize: 14,
                    color: _secondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '123456',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: _primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '为了车辆安全，连接成功后，请进入【更多设置】修改连接密码。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: _secondaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDivider(),
                const SizedBox(height: 12),
                const Text(
                  '忘记密码时，同时按一下遥控器的【闪电键 + 上锁键】，即可恢复密码。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: _secondaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 02 蓝牙连接问题
            _buildCard(
              children: [
                _buildSectionTitle('02', '蓝牙连接问题'),
                const SizedBox(height: 20),
                const Text(
                  'Q：蓝牙连不上怎么办？',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 20),
                _buildStep(
                  number: '1',
                  title: '开启手机蓝牙和定位',
                  description: '确认手机系统中的蓝牙和定位功能均已开启。',
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 42),
                  child: _buildDivider(),
                ),
                _buildStep(
                  number: '2',
                  title: '取消旧配对并重新连接',
                  description:
                      '在手机系统蓝牙设置中忽略或取消原有配对，再返回小程序重新搜索连接。',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 03 电压与电池类型
            _buildCard(
              children: [
                _buildSectionTitle('03', '电压与电池类型'),
                const SizedBox(height: 20),
                const Text(
                  'Q：如何设置电压？',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '请向卖车商家确认电动车的电压和电池类型，然后进入【更多设置】选择正确的电压和电池类型。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.8,
                    color: _secondaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '温馨提示',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '正确设置后，首页才能正常展示电压，并可根据电压大致估算车辆剩余电量。',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: _secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String number, String title) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE5F1FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F1FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: _secondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: _dividerColor,
    );
  }
}
