import 'package:flutter/cupertino.dart';

class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  static const Color _backgroundColor = Color(0xFFF5F6F8);
  static const Color _primaryColor = Color(0xFF3478F6);
  static const Color _titleColor = Color(0xFF172337);
  static const Color _subtitleColor = Color(0xFF8190A8);
  static const Color _wechatColor = Color(0xFF2DBE60);
  static const Color _alipayColor = Color(0xFF2589F5);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('捐赠'),
        backgroundColor: _backgroundColor,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE3E8F0), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            _buildWelcome(),

            const SizedBox(height: 28),

            _buildDonationCard(context),

            const SizedBox(height: 20),

            _buildSupportCard(),

            const SizedBox(height: 32),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // Top Thanks Area
  Widget _buildWelcome() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F0FF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            CupertinoIcons.heart_fill,
            size: 56,
            color: _primaryColor,
          ),
        ),

        const SizedBox(height: 22),

        const Text(
          '感谢你的支持',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _titleColor,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          '如果你觉得 Moto Key 对你有帮助，\n'
          '欢迎通过捐赠支持我继续改进和维护这个项目！',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.8, color: _subtitleColor),
        ),
      ],
    );
  }

  // Donation Methods Card
  Widget _buildDonationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _buildPaymentItem(
            context: context, // 新增
            title: '微信支付',
            subtitle: '使用微信扫一扫，向我捐赠',
            color: _wechatColor,
            backgroundColor: const Color(0xFFEAF8EF),
            icon: CupertinoIcons.chat_bubble_2_fill,
            imagePath: 'assets/donate/wechat_pay.JPG',
          ),

          Container(height: 0.5, color: const Color(0xFFE5EAF1)),

          _buildPaymentItem(
            context: context, // 新增
            title: '支付宝支付',
            subtitle: '使用支付宝扫一扫，向我捐赠',
            color: _alipayColor,
            backgroundColor: const Color(0xFFEAF3FF),
            icon: CupertinoIcons.money_yen_circle_fill,
            imagePath: 'assets/donate/alipay.JPG',
          ),
        ],
      ),
    );
  }

  // Single payment method
  Widget _buildPaymentItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
    required IconData icon,
    required String imagePath,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, size: 34, color: CupertinoColors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: _subtitleColor),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    title == '微信支付' ? '微信扫码捐赠' : '支付宝扫码捐赠',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Click to view full image
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () => _showPaymentImage(
              context: context,
              title: title,
              imagePath: imagePath,
            ),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.qrcode, size: 29, color: color),
                  const SizedBox(height: 4),
                  Text('查看收款码', style: TextStyle(fontSize: 10, color: color)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Support Info Card
  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFDCE9FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.heart,
              color: _primaryColor,
              size: 32,
            ),
          ),

          const SizedBox(width: 16),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '你的支持很重要',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _titleColor,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  '每一份支持都会帮助我更好地维护和更新项目，'
                  '让 Moto Key 变得更好！非常感谢！',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.8,
                    color: _subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom trim
  Widget _buildFooter() {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              child: SizedBox(
                height: 1.5,
                child: ColoredBox(color: Color(0xFFD5E0F0)),
              ),
            ),
            SizedBox(width: 14),
            Icon(CupertinoIcons.heart_fill, size: 22, color: _primaryColor),
            SizedBox(width: 14),
            SizedBox(
              width: 48,
              child: SizedBox(
                height: 1.5,
                child: ColoredBox(color: Color(0xFFD5E0F0)),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Text(
          '感谢有你 · 一路同行',
          style: TextStyle(fontSize: 14, color: _subtitleColor),
        ),
      ],
    );
  }

  void _showPaymentImage({
    required BuildContext context,
    required String title,
    required String imagePath,
  }) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Image.asset(
              imagePath,
              width: 240,
              height: 300,
              fit: BoxFit.contain,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('完成'),
            ),
          ],
        );
      },
    );
  }
}
