import 'package:flutter/material.dart';
import '../../auth/presentation/auth_widgets.dart';

class LaunchSplash extends StatefulWidget {
  final VoidCallback onFinished;
  const LaunchSplash({super.key, required this.onFinished});
  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this);
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      controller.duration = Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 50 : 1400);
      controller.forward().whenComplete(() {
        if (mounted) widget.onFinished();
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: authPaper,
      body: ReferenceBackground(
          child: Center(
              child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    final value =
                        Curves.easeOutCubic.transform(controller.value);
                    return Opacity(
                        opacity: value,
                        child: Transform.scale(
                            scale: .82 + .18 * value, child: child));
                  },
                  child: const BrandLogo(height: 175)))));
}

class WelcomePage extends StatelessWidget {
  final VoidCallback onContinue;
  const WelcomePage({super.key, required this.onContinue});
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: authPaper,
      body: ReferenceBackground(
          ribbons: false,
          child: SafeArea(
              child: Center(
                  child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
                builder: (context, bounds) => SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                        onPressed: onContinue,
                                        child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('Passer',
                                                  style: TextStyle(
                                                      color: authInk)),
                                              Icon(Icons.chevron_right_rounded,
                                                  color: authPurple)
                                            ]))),
                                const Entrance(child: BrandLogo(height: 100)),
                                const SizedBox(height: 18),
                                const Entrance(
                                    start: .1,
                                    child: Text(
                                        'Votre passerelle\nvers l’enseignement',
                                        style: TextStyle(
                                            fontSize: 29,
                                            height: 1.08,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -1.1,
                                            color: authInk))),
                                Entrance(
                                    start: .15,
                                    child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: CustomPaint(
                                            painter: _GoldUnderline(),
                                            child: const Padding(
                                                padding:
                                                    EdgeInsets.only(bottom: 9),
                                                child: Text('supérieur',
                                                    style: TextStyle(
                                                        fontSize: 35,
                                                        height: 1.1,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Color(
                                                            0xff9d20ff))))))),
                                const SizedBox(height: 12),
                                const Entrance(
                                    start: .2,
                                    child: Text(
                                        'Analysez votre profil, découvrez les meilleures formations, les universités et les opportunités de bourses, en quelques clics.',
                                        style: TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            color: Color(0xff423b72)))),
                                Entrance(
                                    start: .25,
                                    child: Image.asset(
                                        'assets/images/welcome_reference.png',
                                        height: (bounds.maxHeight * .37)
                                            .clamp(220.0, 340.0),
                                        fit: BoxFit.contain,
                                        semanticLabel:
                                            'Une étudiante découvre les formations, bourses et recommandations Orientia')),
                                const SizedBox(height: 4),
                                const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _Dot(active: true),
                                      _Dot(),
                                      _Dot(),
                                    ]),
                                const SizedBox(height: 20),
                                Entrance(
                                    start: .3,
                                    child: AuthActionButton(
                                        label: 'Commencer',
                                        onPressed: onContinue)),
                              ])),
                    )),
          )))));
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({this.active = false});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0xff9c1cff) : const Color(0xffd7d1f4)));
}

class _GoldUnderline extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .42, size.height - 4)
      ..cubicTo(size.width * .64, size.height + 6, size.width * .74,
          size.height - 7, size.width, size.height - 9)
      ..cubicTo(size.width * .79, size.height - 15, size.width * .67,
          size.height + 1, size.width * .42, size.height - 4);
    canvas.drawPath(path, Paint()..color = const Color(0xffffba00));
  }

  @override
  bool shouldRepaint(covariant _GoldUnderline oldDelegate) => false;
}
