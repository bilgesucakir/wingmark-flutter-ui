import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localizations.dart';
import '../../core/theme.dart';
import '../../state/auth_session.dart';
import '../../widgets/flowing_title.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSwitchToSignUp});

  final VoidCallback onSwitchToSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthSession session) async {
    FocusScope.of(context).unfocus();
    await session.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<AuthSession>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flutter_dash, size: 56, color: AppTheme.accent),
                const SizedBox(height: 8),
                const FlowingTitle('wingmark', size: 40),
                const SizedBox(height: 8),
                Text(
                  l10n.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l10n.email),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.password),
                  onSubmitted: (_) => _submit(session),
                ),
                if (session.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    session.errorMessage!,
                    style: const TextStyle(color: Color(0xFFE58C8C)),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: l10n.logIn,
                  busy: session.isBusy,
                  onPressed: () => _submit(session),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    session.clearError();
                    widget.onSwitchToSignUp();
                  },
                  child: Text(l10n.noAccountSignUp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
