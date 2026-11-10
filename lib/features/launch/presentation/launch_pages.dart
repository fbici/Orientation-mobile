import 'dart:async';
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

class WelcomePage extends StatefulWidget {
  final VoidCallback onContinue;
  const WelcomePage({super.key, required this.onContinue});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with WidgetsBindingObserver {
  final pages = PageController();
  Timer? timer;
  int index = 0;
  bool paused = false, foreground = true;
  bool get reduced =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    restartTimer();
  }

  void restartTimer() {
    timer?.cancel();
    if (!mounted || paused || !foreground || reduced) return;
    timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted && pages.hasClients) goTo((index + 1) % 3);
    });
  }

  void goTo(int value) {
    if (reduced) {
      pages.jumpToPage(value);
    } else {
      pages.animateToPage(value,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeInOutCubic);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    restartTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    pages.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  static const slides = [
    (
      'Votre passerelle\nvers l’enseignement',
      'supérieur',
      'Analysez votre profil, découvrez les meilleures formations, les universités et les opportunités de bourses, en quelques clics.',
      'welcome_reference.png',
      'Une étudiante découvre les formations, bourses et recommandations Orientia'
    ),
    (
      'Un parcours qui\nvous ressemble,',
      'vraiment',
      'Explorez les universités et les formations. Renseignez votre profil pour comprendre vos possibilités et préparer un choix éclairé.',
      'welcome_orientation.png',
      'Un étudiant explore les universités et construit son parcours'
    ),
    (
      'Des opportunités\npour aller',
      'plus loin',
      'Découvrez les bourses et leurs conditions, préparez votre dossier et ouvrez vos horizons, au Bénin et dans le monde.',
      'welcome_scholarships.png',
      'Une étudiante prépare son dossier et découvre des bourses'
    ),
  ];
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
                builder: (context, bounds) => Padding(
                    padding: const EdgeInsets.fromLTRB(26, 4, 26, 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  onPressed: widget.onContinue,
                                  child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Passer',
                                            style: TextStyle(color: authInk)),
                                        Icon(Icons.chevron_right_rounded,
                                            color: authPurple)
                                      ]))),
                          Entrance(
                              child: BrandLogo(
                                  height: bounds.maxHeight < 600 ? 65 : 95)),
                          const SizedBox(height: 16),
                          Expanded(
                              child: NotificationListener<ScrollNotification>(
                            onNotification: (notice) {
                              if (notice is ScrollEndNotification) {
                                restartTimer();
                              }
                              return false;
                            },
                            child: PageView.builder(
                                key: const ValueKey('welcome-pages'),
                                controller: pages,
                                itemCount: 3,
                                onPageChanged: (value) {
                                  setState(() => index = value);
                                  restartTimer();
                                },
                                itemBuilder: (context, page) {
                                  final slide = slides[page];
                                  return SingleChildScrollView(
                                      key: ValueKey('welcome-slide-$page'),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Entrance(
                                                key: ValueKey('headline-$page'),
                                                child: Text(slide.$1,
                                                    style: const TextStyle(
                                                        fontSize: 29,
                                                        height: 1.08,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: -1.1,
                                                        color: authInk))),
                                            Entrance(
                                                start: .1,
                                                child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: CustomPaint(
                                                        painter:
                                                            _GoldUnderline(),
                                                        child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    bottom: 9),
                                                            child: Text(
                                                                slide.$2,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        35,
                                                                    height: 1.1,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800,
                                                                    color: Color(
                                                                        0xff9d20ff))))))),
                                            const SizedBox(height: 12),
                                            Entrance(
                                                start: .15,
                                                child: Text(slide.$3,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        height: 1.4,
                                                        color: Color(
                                                            0xff423b72)))),
                                            Entrance(
                                                start: .2,
                                                child: Image.asset(
                                                    'assets/images/${slide.$4}',
                                                    height: (bounds.maxHeight *
                                                            .37)
                                                        .clamp(220.0, 340.0),
                                                    fit: BoxFit.contain,
                                                    semanticLabel: slide.$5)),
                                          ]));
                                }),
                          )),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 40),
                                for (int dot = 0; dot < 3; dot++)
                                  Semantics(
                                      selected: index == dot,
                                      button: true,
                                      label: 'Présentation ${dot + 1} sur 3',
                                      child: InkResponse(
                                          key: ValueKey('welcome-dot-$dot'),
                                          onTap: () => goTo(dot),
                                          radius: 22,
                                          child: Padding(
                                              padding: const EdgeInsets.all(9),
                                              child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 180),
                                                  width: index == dot ? 12 : 10,
                                                  height:
                                                      index == dot ? 12 : 10,
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: index == dot
                                                          ? const Color(
                                                              0xff9c1cff)
                                                          : const Color(
                                                              0xffd7d1f4)))))),
                                IconButton(
                                    key: const ValueKey('welcome-pause'),
                                    tooltip: paused
                                        ? 'Reprendre le défilement'
                                        : 'Mettre le défilement en pause',
                                    onPressed: reduced
                                        ? null
                                        : () {
                                            setState(() => paused = !paused);
                                            restartTimer();
                                          },
                                    icon: Icon(
                                        paused
                                            ? Icons.play_arrow_rounded
                                            : Icons.pause_rounded,
                                        color: authPurple,
                                        size: 19)),
                              ]),
                          const SizedBox(height: 8),
                          Entrance(
                              start: .25,
                              child: AuthActionButton(
                                  label: 'Commencer',
                                  onPressed: widget.onContinue)),
                        ]))),
          )))));
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
