import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollAwareBottomNavigation extends StatefulWidget {
  const ScrollAwareBottomNavigation({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ScrollAwareBottomNavigation> createState() =>
      _ScrollAwareBottomNavigationState();
}

class _ScrollAwareBottomNavigationState
    extends State<ScrollAwareBottomNavigation> {
  static const double _directionThreshold = 8.0;

  ScrollController? _controller;
  double _directionDistance = 0;
  bool _visible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final controller = PrimaryScrollController.maybeOf(context);

    if (identical(controller, _controller)) {
      return;
    }

    _controller?.removeListener(_handleScroll);
    _controller = controller;
    _controller?.addListener(_handleScroll);
  }

  void _handleScroll() {
    final controller = _controller;

    if (controller == null || !controller.hasClients) {
      return;
    }

    final position = controller.position;

    if (position.pixels <= position.minScrollExtent) {
      _directionDistance = 0;

      if (!_visible && mounted) {
        setState(() {
          _visible = true;
        });
      }

      return;
    }

    final direction = position.userScrollDirection;

    if (direction == ScrollDirection.reverse) {
      _directionDistance += 1;

      if (_visible && _directionDistance >= _directionThreshold) {
        _directionDistance = 0;

        if (mounted) {
          setState(() {
            _visible = false;
          });
        }
      }

      return;
    }

    if (direction == ScrollDirection.forward) {
      _directionDistance += 1;

      if (!_visible && _directionDistance >= _directionThreshold) {
        _directionDistance = 0;

        if (mounted) {
          setState(() {
            _visible = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 225),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 225),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
