import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_session.dart';
import '../root/root_tab_view.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'verify_email_screen.dart';

/// Root of the app, mirroring Swift's AuthGateView: shows the main tab view
/// once authenticated, otherwise the Log In / Sign Up flow (or the
/// verify-email screen if the backend just rejected a login as unverified).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    context.read<AuthSession>().bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    switch (session.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          ),
        );
      case AuthStatus.authenticated:
        return const RootTabView();
      case AuthStatus.needsVerification:
        return const VerifyEmailScreen();
      case AuthStatus.unauthenticated:
        return const _AuthFlow();
    }
  }
}

class _AuthFlow extends StatefulWidget {
  const _AuthFlow();

  @override
  State<_AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<_AuthFlow> {
  bool showSignUp = false;

  @override
  Widget build(BuildContext context) {
    return showSignUp
        ? SignUpScreen(onSwitchToLogin: () => setState(() => showSignUp = false))
        : LoginScreen(onSwitchToSignUp: () => setState(() => showSignUp = true));
  }
}
