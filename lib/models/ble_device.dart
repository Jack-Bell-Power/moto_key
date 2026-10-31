class BleDevice {
  BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.isHistory = false,
    this.isLast = false,
    this.isFound = true,
  });

  final String id;
  String name;
  int rssi;
  final bool isHistory;
  bool isLast;
  bool isFound;
}
