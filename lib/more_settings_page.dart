import 'package:flutter/cupertino.dart';

class MoreSettingsPage extends StatefulWidget {
  const MoreSettingsPage({super.key});

  @override
  State<MoreSettingsPage> createState() => _MoreSettingsPageState();
}

class _MoreSettingsPageState extends State<MoreSettingsPage> {
  // 以下选项暂时使用示例数据，后续可替换为设备实际配置。
  final List<String> levelArr = ['低', '中', '高'];
  final List<String> nearUnlockArr = ['关闭', '靠近解锁', '离开上锁'];
  final List<String> feelRangeArr = ['近', '中', '远'];
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
    // TODO: 替换成实际的修改密码页面。
    // 例如：Navigator.of(context).push(
    //   CupertinoPageRoute(
    //     builder: (_) => const ModifyPasswordPage(),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('更多设置'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 常规设置
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

            // 电池类型与电压
            _buildCard([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '电池类型',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 20,
                      runSpacing: 12,
                      children: List.generate(
                        batteryList.length,
                        (index) => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() => batteryIndex = index);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                batteryIndex == index
                                    ? CupertinoIcons
                                        .largecircle_fill_circle
                                    : CupertinoIcons.circle,
                                size: 20,
                                color: batteryIndex == index
                                    ? const Color(0xFF0084FF)
                                    : const Color(0xFF999999),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                batteryList[index],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDivider(),
                    _buildPickerItem(
                      title: '电压',
                      value: voltageList[voltageIndex],
                      onTap: () => _selectOption(
                        title: '电压',
                        options: voltageList,
                        onSelected: (index) => voltageIndex = index,
                      ),
                      last: true,
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 16),

            const SizedBox(height: 16),

            // 修改密码
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
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildPickerItem({
    required String title,
    required String value,
    required VoidCallback onTap,
    bool first = false,
    bool last = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: first ? 16 : 12,
        bottom: last ? 16 : 12,
      ),
      onPressed: onTap,
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
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: Color(0xFF999999),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
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
