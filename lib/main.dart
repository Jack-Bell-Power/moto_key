import 'package:flutter/cupertino.dart';
import 'package:moto_key/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const MotoKey());
}

class MotoKey extends StatelessWidget {
  const MotoKey({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: [
            BottomNavigationBarItem(
              icon: Image.asset('assets/tab/index.png', width: 24, height: 24),
              activeIcon: Image.asset(
                'assets/tab/selectIndex.png',
                width: 24,
                height: 24,
              ),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Image.asset('assets/tab/me.png', width: 24, height: 24),
              activeIcon: Image.asset(
                'assets/tab/selectMe.png',
                width: 24,
                height: 24,
              ),
              label: '我的',
            ),
          ],
        ),
        tabBuilder: _buildTab,
      ),
    );
  }

  static Widget _buildTab(BuildContext context, int index) {
    return CupertinoTabView(
      builder: (context) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(index == 0 ? '首页' : '我的'),
          ),
          child: Center(child: Text(index == 0 ? '首页内容' : '我的内容')),
        );
      },
    );
  }
}
