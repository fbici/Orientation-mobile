import 'package:flutter/material.dart';
import '../../../core/network/api_failure.dart';

const authInk = Color(0xff100c50);
const authPurple = Color(0xff6900e8);
const authPaper = Color(0xfff9f7ff);

class BrandLogo extends StatelessWidget {
  final double height;
  const BrandLogo({super.key, this.height = 105});
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/orientia_transparent.png',
          height: height, fit: BoxFit.contain, semanticLabel: 'Logo Orientia');
}

class Entrance extends StatelessWidget {
  final Widget child;
  final double start;
  const Entrance({super.key, required this.child, this.start = 0});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final progress = ((value - start) / (1 - start)).clamp(0.0, 1.0);
        return Opacity(
            opacity: progress,
            child: Transform.translate(
                offset: Offset(0, 18 * (1 - progress)), child: child));
      },
      child: child);
}

class ReferenceBackground extends StatelessWidget {
  final Widget child;
  final bool ribbons;
  const ReferenceBackground(
      {super.key, required this.child, this.ribbons = true});
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
            Color(0xfffcfbff),
            Color(0xfff4f1ff),
            Color(0xfffefeff)
          ])),
      child: Stack(children: [
        if (ribbons)
          Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _Ribbons()))),
        child,
      ]));
}

class _Ribbons extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final top = Path()
      ..moveTo(size.width * .70, 0)
      ..cubicTo(size.width * .73, size.height * .10, size.width * .95,
          size.height * .09, size.width, size.height * .20)
      ..lineTo(size.width, 0)
      ..close();
    final bottom = Path()
      ..moveTo(0, size.height * .90)
      ..cubicTo(size.width * .16, size.height * .88, size.width * .32,
          size.height * .98, size.width * .64, size.height)
      ..lineTo(0, size.height)
      ..close();
    final paint = Paint()
      ..shader = const LinearGradient(colors: [
        Color(0xffeee8ff),
        Color(0xffc6a8ff),
        Color(0xff9a45f2),
        Color(0xfff7f2ff)
      ], stops: [
        0,
        .36,
        .57,
        1
      ]).createShader(Offset.zero & size);
    canvas.drawPath(top, paint);
    canvas.drawPath(bottom, paint);
    final edge = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(
        Path()
          ..moveTo(size.width * .70, 0)
          ..cubicTo(size.width * .73, size.height * .10, size.width * .95,
              size.height * .09, size.width, size.height * .20),
        edge);
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height * .90)
          ..cubicTo(size.width * .16, size.height * .88, size.width * .32,
              size.height * .98, size.width * .64, size.height),
        edge);
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height * .935)
          ..cubicTo(size.width * .13, size.height * .90, size.width * .25,
              size.height * .95, size.width * .43, size.height * .98),
        edge);
  }

  @override
  bool shouldRepaint(covariant _Ribbons oldDelegate) => false;
}

class AuthShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;
  const AuthShell(
      {super.key,
      required this.title,
      this.subtitle,
      required this.children,
      this.onBack});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: authPaper,
        body: ReferenceBackground(
            child: SafeArea(
                child: LayoutBuilder(
                    builder: (context, bounds) => SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(26, 20, 26, 34),
                          child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: (bounds.maxHeight - 54)
                                      .clamp(0, double.infinity)),
                              child: Center(
                                  child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 420),
                                child: Theme(
                                    data: Theme.of(context).copyWith(
                                        colorScheme: Theme.of(context)
                                            .colorScheme
                                            .copyWith(primary: authPurple),
                                        textTheme: Theme.of(context)
                                            .textTheme
                                            .apply(
                                                bodyColor: authInk,
                                                displayColor: authInk),
                                        inputDecorationTheme:
                                            InputDecorationTheme(
                                          filled: true,
                                          fillColor: Colors.white
                                              .withValues(alpha: .65),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 16),
                                          hintStyle: const TextStyle(
                                              color: Color(0xff46406f),
                                              fontSize: 15),
                                          labelStyle: const TextStyle(
                                              color: Color(0xff46406f),
                                              fontSize: 14),
                                          prefixIconColor: authPurple,
                                          suffixIconColor: authInk,
                                          errorMaxLines: 3,
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(17),
                                              borderSide: const BorderSide(
                                                  color: Color(0xffd4c4ff))),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(17),
                                              borderSide: const BorderSide(
                                                  color: Color(0xffd4c4ff))),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(17),
                                              borderSide: const BorderSide(
                                                  color: authPurple,
                                                  width: 1.5)),
                                        )),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Entrance(
                                              child: SizedBox(
                                                  height: 105,
                                                  child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        const BrandLogo(),
                                                        if (onBack != null)
                                                          Align(
                                                              alignment:
                                                                  Alignment
                                                                      .topLeft,
                                                              child: IconButton.filledTonal(
                                                                  onPressed:
                                                                      onBack,
                                                                  tooltip:
                                                                      'Retour à la connexion',
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .chevron_left_rounded),
                                                                  style: IconButton.styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      foregroundColor:
                                                                          authPurple))),
                                                      ]))),
                                          const SizedBox(height: 18),
                                          Entrance(
                                              start: .1,
                                              child: Text(title,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 30,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: -1.1,
                                                      color: authInk))),
                                          if (subtitle != null) ...[
                                            const SizedBox(height: 8),
                                            Entrance(
                                                start: .15,
                                                child: Text(subtitle!,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        height: 1.35,
                                                        color:
                                                            Color(0xff38316b))))
                                          ],
                                          const SizedBox(height: 28),
                                          ...children.map((child) => Entrance(
                                              start: .2, child: child)),
                                        ])),
                              ))),
                        )))),
      );
}

class AuthField extends StatelessWidget {
  final Widget child;
  const AuthField({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(17), boxShadow: [
        BoxShadow(
            color: authPurple.withValues(alpha: .10),
            blurRadius: 10,
            offset: const Offset(0, 5)),
      ]),
      child: child);
}

class AuthActionButton extends StatefulWidget {
  final String label, pendingLabel;
  final bool busy;
  final VoidCallback? onPressed;
  final IconData? leading;
  const AuthActionButton(
      {super.key,
      required this.label,
      this.pendingLabel = 'Traitement en cours…',
      this.busy = false,
      this.onPressed,
      this.leading});
  @override
  State<AuthActionButton> createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => AnimatedScale(
      scale: pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xffd13bff),
                    Color(0xff6900cc),
                    Color(0xff39008a),
                    Color(0xff9900ed)
                  ],
                  stops: [
                    0,
                    .28,
                    .68,
                    1
                  ]),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: authPurple.withValues(alpha: .32),
                    blurRadius: 15,
                    offset: const Offset(0, 5)),
                const BoxShadow(
                    color: Color(0x33dd80ff), blurRadius: 2, spreadRadius: 2)
              ]),
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onHighlightChanged: (value) =>
                      setState(() => pressed = value),
                  onTap: widget.busy ? null : widget.onPressed,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 40),
                        child: Row(children: [
                          if (widget.leading != null) ...[
                            Icon(widget.leading, color: Colors.white, size: 24),
                            const SizedBox(width: 10)
                          ],
                          Expanded(
                              child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: Text(
                                      widget.busy
                                          ? widget.pendingLabel
                                          : widget.label,
                                      key: ValueKey(widget.busy),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: -.5)))),
                          const SizedBox(width: 8),
                          Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: .6)),
                                  gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: .35),
                                        Colors.white.withValues(alpha: .05)
                                      ])),
                              child: widget.busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.double_arrow_rounded,
                                      color: Colors.white, size: 29)),
                        ])),
                  )))));
}

class GoogleAuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool busy;
  const GoogleAuthButton({super.key, this.onPressed, this.busy = false});
  @override
  Widget build(BuildContext context) => AuthField(
      child: OutlinedButton(
          style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .7),
              foregroundColor: authInk,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              side: const BorderSide(color: Color(0xffded0ff)),
              shape: const StadiumBorder()),
          onPressed: busy ? null : onPressed,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (busy)
              const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: authPurple))
            else
              Image.asset('assets/images/google-g.png',
                  height: 26, width: 26, semanticLabel: 'Google'),
            const SizedBox(width: 16),
            const Flexible(
                child: Text('Continuer avec Google',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
          ])));
}

class AuthError extends StatelessWidget {
  final Object error;
  const AuthError(this.error, {super.key});
  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: true,
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xffffeeee),
              borderRadius: BorderRadius.circular(12)),
          child: Text(ApiFailure.from(error).message,
              style: const TextStyle(color: Color(0xffa82035)))));
}

String? emailValidator(String? v) =>
    v != null && RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
        ? null
        : 'Adresse email valide requise.';
