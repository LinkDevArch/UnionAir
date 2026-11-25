import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

const motionQuick = Duration(milliseconds: 130);
const motionStandard = Duration(milliseconds: 240);
const motionEase = Curves.easeOutCubic;

bool reducesMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    MediaQuery.reduceMotionOf(context);

Duration motionDuration(BuildContext context, Duration duration) =>
    reducesMotion(context) ? Duration.zero : duration;

class UnionAirPageTransition extends PageTransitionsBuilder {
  const UnionAirPageTransition();

  @override
  Duration get transitionDuration => motionStandard;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reducesMotion(context)) return child;
    final eased = animation.drive(CurveTween(curve: motionEase));
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: eased.drive(
          Tween(begin: const Offset(0, .024), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}

class PressFeedback extends StatefulWidget {
  const PressFeedback({super.key, required this.builder});

  final Widget Function(WidgetStatesController states) builder;

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  final _states = WidgetStatesController();
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(_updatePress);
  }

  void _updatePress() {
    final pressed = _states.value.contains(WidgetState.pressed);
    if (pressed == _pressed) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updatePress();
      });
      return;
    }
    setState(() => _pressed = pressed);
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: _pressed && !reducesMotion(context) ? .975 : 1,
    duration: motionDuration(context, motionQuick),
    curve: motionEase,
    child: widget.builder(_states),
  );
}
