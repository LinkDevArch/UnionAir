import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'motion.dart';

const blue = Color(0xFF0064D9);
const navy = Color(0xFF172B45);
const muted = Color(0xFF5C6D82);
const canvasColor = Color(0xFFF4F7FB);
const fieldColor = Color(0xFFEDF3FA);
const borderColor = Color(0xFFE7EDF5);
const paleBlue = Color(0xFFE3EFFF);
const danger = Color(0xFFDE3445);
const _symbolFont = ['DejaVu UI Symbols'];

ThemeData unionAirTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: blue)
      .copyWith(primary: blue, error: danger),
  scaffoldBackgroundColor: canvasColor,
  fontFamily: 'Poppins',
  textTheme: ThemeData.light().textTheme.apply(
    fontFamily: 'Poppins',
    fontFamilyFallback: _symbolFont,
    bodyColor: navy,
    displayColor: navy,
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: blue.withValues(alpha: .08),
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      ...const PageTransitionsTheme().builders,
      TargetPlatform.android: const UnionAirPageTransition(),
      TargetPlatform.fuchsia: const UnionAirPageTransition(),
      TargetPlatform.linux: const UnionAirPageTransition(),
      TargetPlatform.macOS: const UnionAirPageTransition(),
      TargetPlatform.windows: const UnionAirPageTransition(),
    },
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(22)),
    ),
  ),
  datePickerTheme: const DatePickerThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    headerBackgroundColor: paleBlue,
    headerForegroundColor: navy,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(22)),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    modalBackgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    dragHandleColor: Color(0xFFB5C6DB),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: fieldColor,
  ),
);

class Copy extends StatelessWidget {
  const Copy(
    this.text, {
    super.key,
    this.size = 14,
    this.weight = FontWeight.w500,
    this.color = navy,
    this.align,
    this.maxLines,
    this.height = 1.4,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final TextAlign? align;
  final int? maxLines;
  final double height;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    maxLines: maxLines,
    style: TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    ),
  );
}

class ArtIcon extends StatelessWidget {
  const ArtIcon(this.name, {super.key, this.size = 21, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/$name.svg',
    width: size,
    height: size,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
    excludeFromSemantics: true,
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.white = false, this.large = false});

  final bool white;
  final bool large;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ArtIcon(white ? 'logo-white' : 'logo-blue', size: large ? 61 : 51),
        SizedBox(width: large ? 16 : 9),
        Flexible(
          child: Copy(
            'UnionAir',
            size: large ? 32 : 30,
            color: white ? Colors.white : blue,
            weight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, this.back = true, this.action});

  final bool back;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 72,
    child: Row(
      children: [
        SizedBox(
          width: 42,
          child: back
              ? IconButton(
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back, size: 19),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
        ),
        const Expanded(child: Brand()),
        SizedBox(width: 42, child: action),
      ],
    ),
  );
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.children,
    this.footer,
    this.header = const PageHeader(),
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 24),
  });

  final List<Widget> children;
  final Widget? header;
  final Widget? footer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final visibleHeader = keyboardOpen ? null : header;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (visibleHeader != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  padding.left,
                  padding.top,
                  padding.right,
                  16,
                ),
                child: visibleHeader,
              ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: padding.copyWith(
                  top: visibleHeader == null ? padding.top : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...children,
                    if (footer == null)
                      SizedBox(height: MediaQuery.paddingOf(context).bottom),
                  ],
                ),
              ),
            ),
            if (footer case final widget?)
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: widget,
              ),
          ],
        ),
      ),
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.color = Colors.white,
    this.outline = borderColor,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color outline;
  final bool shadow;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: motionDuration(context, motionQuick),
    curve: motionEase,
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: outline),
      boxShadow: shadow
          ? const [
              BoxShadow(
                color: Color(0x0E172B45),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ]
          : null,
    ),
    child: child,
  );
}

class ActionButton extends StatelessWidget {
  const ActionButton(
    this.label,
    this.onPressed, {
    super.key,
    this.outline = false,
    this.color = blue,
    this.height = 46,
    this.radius = 12,
    this.fontSize = 15,
    this.weight = FontWeight.w600,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outline;
  final Color color;
  final double height;
  final double radius;
  final double fontSize;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final textStyle = TextStyle(
      fontFamily: 'Poppins',
      fontFamilyFallback: _symbolFont,
      fontSize: fontSize,
      fontWeight: weight,
    );
    return SizedBox(
      width: double.infinity,
      child: PressFeedback(
        builder: (states) => outline
            ? OutlinedButton(
                onPressed: onPressed,
                statesController: states,
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  backgroundColor: Colors.white,
                  minimumSize: Size(0, height),
                  shape: shape,
                  side: BorderSide(
                    color: onPressed == null ? borderColor : color,
                  ),
                  textStyle: textStyle,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                ),
                child: Text(label, textAlign: TextAlign.center),
              )
            : FilledButton(
                onPressed: onPressed,
                statesController: states,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFDEE7F1),
                  disabledForegroundColor: muted,
                  minimumSize: Size(0, height),
                  shape: shape,
                  textStyle: textStyle,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                ),
                child: Text(label, textAlign: TextAlign.center),
              ),
      ),
    );
  }
}

class Segments extends StatelessWidget {
  const Segments({
    super.key,
    required this.labels,
    required this.index,
    required this.onChange,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final position = labels.length == 1
        ? 0.0
        : -1 + 2 * index / (labels.length - 1);
    final duration = motionDuration(context, motionStandard);
    return Material(
      color: fieldColor,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: duration,
              curve: motionEase,
              alignment: AlignmentDirectional(position, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: blue,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: Row(
              children: [
                for (final (i, label) in labels.indexed)
                  Expanded(
                    child: Semantics(
                      selected: i == index,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => onChange(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 3,
                          ),
                          child: Copy(
                            label,
                            size: 12,
                            color: i == index ? Colors.white : muted,
                            align: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile(
    this.label,
    this.value, {
    super.key,
    required this.icon,
    this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final String icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Material(
    color: fieldColor,
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          children: [
            ArtIcon(icon, color: navy, size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Copy(label, size: 10, color: muted),
                  Copy(value, size: 13),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(
    this.text, {
    super.key,
    this.color = blue,
    this.background = paleBlue,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Copy(
      text,
      size: 10,
      weight: FontWeight.w600,
      color: color,
      align: TextAlign.center,
    ),
  );
}

class Heading extends StatelessWidget {
  const Heading(this.title, {super.key, this.subtitle, this.size = 23});

  final String title;
  final String? subtitle;
  final double size;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Copy(title, size: size, weight: FontWeight.w600),
      ),
      if (subtitle case final text?) ...[
        const SizedBox(height: 5),
        Copy(text, size: 13, color: muted, weight: FontWeight.w400),
      ],
    ],
  );
}

class LabelValue extends StatelessWidget {
  const LabelValue(this.label, this.value, {super.key, this.accent = false});

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Copy(
          label,
          size: accent ? 17 : 13,
          color: accent ? blue : muted,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Copy(
          value,
          size: accent ? 21 : 13,
          color: accent ? blue : navy,
          weight: FontWeight.w600,
          align: TextAlign.end,
        ),
      ),
    ],
  );
}

String money(int amount) {
  final digits = amount.toString();
  return '\$${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
}

String dateLabel(DateTime date, {bool weekday = false, bool year = false}) {
  const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final prefix = weekday ? '${weekdays[date.weekday - 1]}, ' : '';
  final suffix = year ? ' ${date.year}' : '';
  return '$prefix${date.day} ${months[date.month - 1]}$suffix';
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> askConfirmation(
  BuildContext context,
  String title,
  String message,
  String action, {
  String cancelLabel = 'Volver',
}) async {
  return await showDialog<bool>(
        context: context,
        animationStyle: AnimationStyle(
          duration: motionDuration(context, motionStandard),
          reverseDuration: motionDuration(context, motionQuick),
          curve: motionEase,
        ),
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
}
