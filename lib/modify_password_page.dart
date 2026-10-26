import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class ModifyPasswordPage extends StatefulWidget {
  const ModifyPasswordPage({super.key});

  @override
  State<ModifyPasswordPage> createState() => _ModifyPasswordPageState();
}

class _ModifyPasswordPageState extends State<ModifyPasswordPage> {
  bool _showPassword = false;

  final TextEditingController _passwordController = TextEditingController();

  void _savePassword() {
    final password = _passwordController.text;

    if (!RegExp(r'^\d{6}$').hasMatch(password)) {
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('提示'),
          content: const Text('请输入6位纯数字密码'),
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

    // TODO: 后续在这里调用蓝牙接口，保存新密码。

    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: const Text('密码格式正确，后续可连接设备保存'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      navigationBar: const CupertinoNavigationBar(middle: Text('修改密码')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CupertinoTextField(
                controller: _passwordController,
                placeholder: '请输入6位纯数字密码',
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: !_showPassword,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(),
                clearButtonMode: OverlayVisibilityMode.editing,
                suffix: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                  child: Icon(
                    _showPassword
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    size: 20,
                    color: const Color(0xFF999999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onPressed: _savePassword,
                child: const Text(
                  '保存修改',
                  style: TextStyle(fontSize: 16, color: CupertinoColors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
