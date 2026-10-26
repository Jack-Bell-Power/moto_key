import 'package:flutter/cupertino.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() =>
      _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  bool remoteControl = false;
  bool openNFC = false;
  bool powerSound = false;
  bool policeSound = false;
  bool headlampSound = false;
  bool rideLampSound = false;
  bool leftRightTurnSound = false;
  bool lockUnlockSound = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('高级设置'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSwitchItem(
                    title: '开启遥控器配对',
                    value: remoteControl,
                    onChanged: (value) {
                      setState(() => remoteControl = value);
                    },
                    isFirst: true,
                  ),
                  _buildSwitchItem(
                    title: '开启NFC卡配对',
                    value: openNFC,
                    onChanged: (value) {
                      setState(() => openNFC = value);
                    },
                  ),
                  _buildSwitchItem(
                    title: '上下电提示音开关',
                    value: powerSound,
                    onChanged: (value) {
                      setState(() => powerSound = value);
                    },
                  ),
                  _buildSwitchItem(
                    title: '报警提示音开关',
                    value: policeSound,
                    onChanged: (value) {
                      setState(() => policeSound = value);
                    },
                  ),
                  _buildSwitchItem(
                    title: '大灯提示音开关',
                    value: headlampSound,
                    onChanged: (value) {
                      setState(() => headlampSound = value);
                    },
                  ),
                  _buildSwitchItem(
                    title: '行车灯提示音开关',
                    value: rideLampSound,
                    onChanged: (value) {
                      setState(() => rideLampSound = value);
                    },
                  ),
                  _buildSwitchItem(
                    title: '左右转提示音开关',
                    value: leftRightTurnSound,
                    onChanged: (value) {
                      setState(() => leftRightTurnSound = value);
                    },
                  ),
                  _buildSwitchItem(
                    title: '上锁、解锁提示音开关',
                    value: lockUnlockSound,
                    onChanged: (value) {
                      setState(() => lockUnlockSound = value);
                    },
                    isLast: true,
                  ),
                ],
              ),
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
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFF0F0F0),
                  width: 1,
                ),
              ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: isFirst ? 16 : 12,
          bottom: isLast ? 16 : 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF333333),
                ),
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
}
