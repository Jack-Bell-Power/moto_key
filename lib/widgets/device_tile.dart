
import 'package:flutter/cupertino.dart';

import '../models/ble_device.dart';

class DeviceTile extends StatelessWidget {
  const DeviceTile({
    super.key,
    required this.device,
    required this.connected,
    required this.connecting,
    required this.disabled,
    required this.onTap,
  });

  final BleDevice device;
  final bool connected;
  final bool connecting;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool unavailable = device.isHistory && !device.isFound;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      onPressed: disabled ? null : onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              CupertinoIcons.bluetooth,
              size: 21,
              color: Color(0xFF3478F6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name.isEmpty ? '未知设备' : device.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  unavailable
                      ? '未发现'
                      : connected
                          ? '已连接 · ${device.rssi} dBm'
                          : device.isHistory
                              ? '${device.isLast ? '上次连接' : '历史设备'} · ${device.rssi} dBm'
                              : '蓝牙设备 · ${device.rssi} dBm',
                  style: TextStyle(
                    fontSize: 11,
                    color: unavailable
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (connecting)
            const CupertinoActivityIndicator()
          else if (connected)
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Color(0xFF3478F6),
              size: 22,
            )
          else
            const Icon(
              CupertinoIcons.chevron_right,
              color: Color(0xFF9CA3AF),
              size: 17,
            ),
        ],
      ),
    );
  }
}
