import 'package:flutter/cupertino.dart';

import 'modify_password_page.dart';

class MoreSettingsPage extends StatefulWidget {
  const MoreSettingsPage({super.key});

  @override
  State<MoreSettingsPage> createState() => _MoreSettingsPageState();
}

class _MoreSettingsPageState extends State<MoreSettingsPage> {
  // The following options are currently using sample data and can be replaced with the actual device settings later.
  final List<String> levelArr = ["0", "1", "2", "3", "4", "5", "6", "7", "8"];
  final List<String> nearUnlockArr = ['只解锁', '解锁并上电', '仅解锁，需要振动上电'];
  final List<String> feelRangeArr = ["远", "中", "近"];
  final List<String> batteryList = ['铅酸电池', '锂电池'];
  final List<String> voltageList = ['48V', '60V', '72V'];

  int levelIndex = 1;
  int nearUnlockIndex = 0;
  int feelRangeIndex = 1;
  int batteryIndex = 0;
  int voltageIndex = 0;

  bool autoLock = false;
  bool bleFeelOnOff = false;
  bool feelVolume = false;

  Future<void> _selectOption({
    required String title,
    required List<String> options,
    required ValueChanged<int> onSelected,
  }) async {
    final result = await showCupertinoModalPopup<int>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          for (int i = 0; i < options.length; i++)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(i),
              child: Text(options[i]),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        onSelected(result);
      });
    }
  }

  void _openModifyPassword() {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute<void>(builder: (_) => const ModifyPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      navigationBar: const CupertinoNavigationBar(middle: Text('更多设置')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // General Settings
            _buildCard([
              _buildPickerItem(
                title: '防盗灵敏度选择',
                value: levelArr[levelIndex],
                first: true,
                onTap: () => _selectOption(
                  title: '防盗灵敏度选择',
                  options: levelArr,
                  onSelected: (index) => levelIndex = index,
                ),
              ),
              _buildDivider(),
              _buildSwitchItem(
                title: '自动锁车',
                value: autoLock,
                onChanged: (value) {
                  setState(() => autoLock = value);
                },
              ),
              _buildDivider(),
              _buildSwitchItem(
                title: '蓝牙感应开关',
                value: bleFeelOnOff,
                onChanged: (value) {
                  setState(() => bleFeelOnOff = value);
                },
              ),
              _buildDivider(),
              _buildPickerItem(
                title: '靠近感应模式选择',
                value: nearUnlockArr[nearUnlockIndex],
                onTap: () => _selectOption(
                  title: '靠近感应模式选择',
                  options: nearUnlockArr,
                  onSelected: (index) => nearUnlockIndex = index,
                ),
              ),
              _buildDivider(),
              _buildSwitchItem(
                title: '感应提示音开关',
                value: feelVolume,
                onChanged: (value) {
                  setState(() => feelVolume = value);
                },
              ),
              _buildDivider(),
              _buildPickerItem(
                title: '感应距离',
                value: feelRangeArr[feelRangeIndex],
                onTap: () => _selectOption(
                  title: '感应距离',
                  options: feelRangeArr,
                  onSelected: (index) => feelRangeIndex = index,
                ),
                last: true,
              ),
            ]),

            const SizedBox(height: 16),

            // Battery Type and Voltage
            _buildCard([
              _buildPickerItem(
                title: '电池类型',
                value: batteryList[batteryIndex],
                first: true,
                onTap: () => _selectOption(
                  title: '电池类型',
                  options: batteryList,
                  onSelected: (index) => batteryIndex = index,
                ),
              ),
              _buildDivider(),
              _buildPickerItem(
                title: '电压',
                value: voltageList[voltageIndex],
                last: true,
                onTap: () => _selectOption(
                  title: '电压',
                  options: voltageList,
                  onSelected: (index) => voltageIndex = index,
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // Change password
            _buildCard([
              _buildPickerItem(
                title: '修改密码',
                value: '',
                first: true,
                last: true,
                onTap: _openModifyPassword,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildPickerItem({
    required String title,
    required String value,
    required VoidCallback onTap,
    bool first = false,
    bool last = false,
  }) {
    return SizedBox(
      height: 56,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        onPressed: onTap,
        child: Row(
          children: [
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
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
              ),
            ),
            CupertinoSwitch(
              value: value,
              activeTrackColor: const Color(0xFF0084FF),
              onChanged: onChanged,
            ),
          ],
        ),
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
