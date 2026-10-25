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
			theme: CupertinoThemeData(
        brightness: Brightness.light,
      ),
      home: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house_fill),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person_fill),
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
          child: Center(
            child: Text(index == 0 ? '首页内容' : '我的内容'),
          ),
        );
      },
    );
  }
}
