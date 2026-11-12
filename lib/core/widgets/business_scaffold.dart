import 'package:flutter/material.dart';

/// Visual surface for signed-in journeys. Entry screens keep their own theme.
class BusinessScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body, bottomNavigationBar, floatingActionButton;
  final bool? resizeToAvoidBottomInset;
  const BusinessScaffold(
      {super.key,
      this.appBar,
      this.body,
      this.bottomNavigationBar,
      this.floatingActionButton,
      this.resizeToAvoidBottomInset});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    const ink = Color(0xFF20143C);
    const purple = Color(0xFF7138CE);
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE9E2F2)));
    final theme = base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFFAF8FD),
      colorScheme: base.colorScheme.copyWith(
          primary: purple,
          surface: Colors.white,
          onSurface: ink,
          secondary: const Color(0xFF9562DD)),
      appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: const Color(0xFFFAF8FD),
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
              color: ink, fontSize: 22, fontWeight: FontWeight.w800)),
      cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: shape,
          margin: const EdgeInsets.symmetric(vertical: 7)),
      listTileTheme: const ListTileThemeData(
          iconColor: purple,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          titleTextStyle:
              TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w700),
          subtitleTextStyle:
              TextStyle(color: Color(0xFF746A83), fontSize: 14, height: 1.5)),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE1D8EE))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE1D8EE))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: purple, width: 2))),
      navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
          height: 76,
          indicatorColor: const Color(0xFFEDE3FC),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: ink))),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 50),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              foregroundColor: purple,
              minimumSize: const Size(48, 48),
              side: const BorderSide(color: Color(0xFFD8C8EE)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)))),
      expansionTileTheme: const ExpansionTileThemeData(
          shape: Border(), collapsedShape: Border(), iconColor: purple),
    );
    return Theme(
        data: theme,
        child: Scaffold(
            appBar: appBar,
            body: body,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingActionButton,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset));
  }
}
