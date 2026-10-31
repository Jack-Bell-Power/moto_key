
import 'package:flutter/cupertino.dart';

class SlideAction extends StatefulWidget {
  const SlideAction({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onCompleted,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onCompleted;

  @override
  State<SlideAction> createState() => _SlideActionState();
}

class _SlideActionState extends State<SlideAction> {
  bool _isOn = false;
  double _dragOffset = 0;

  static const double _height = 48;
  static const double _padding = 4;
  static const double _thumbSize = _height - _padding * 2;

  static const Color _red = Color(0xFFFF3B30);
  static const Color _lightBlue = Color(0xFFF0F5FF);
  static const Color _lightRed = Color(0xFFFFEDEC);

  void _onDragUpdate(DragUpdateDetails details, double maxOffset) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx)
          .clamp(0.0, maxOffset)
          .toDouble();
    });
  }

  void _onDragEnd(double maxOffset) {
    final bool oldState = _isOn;
    final double progress = maxOffset <= 0 ? 0 : _dragOffset / maxOffset;

    setState(() {
      if (progress >= 0.75) {
        _isOn = true;
      } else if (progress <= 0.25) {
        _isOn = false;
      }

      _dragOffset = _isOn ? maxOffset : 0;
    });

    if (oldState != _isOn) {
      widget.onCompleted();
    }
  }

  @override
  void didUpdateWidget(covariant SlideAction oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool newIsOn = widget.title.contains('关闭车辆');

    if (newIsOn != _isOn) {
      _isOn = newIsOn;
      _dragOffset = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxOffset =
            (constraints.maxWidth - _thumbSize - _padding * 2)
                .clamp(0.0, double.infinity)
                .toDouble();

        final double dragOffset =
            _dragOffset.clamp(0.0, maxOffset).toDouble();

        final Color activeColor = _isOn ? _red : widget.color;
        final Color trackColor = _isOn ? _lightRed : _lightBlue;

        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                  ),
                ),
              ),
              Positioned(
                left: _padding + dragOffset,
                top: _padding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onDragUpdate(details, maxOffset),
                  onHorizontalDragEnd: (_) => _onDragEnd(maxOffset),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      color: CupertinoColors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
