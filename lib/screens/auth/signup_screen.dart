import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localizations.dart';
import '../../core/theme.dart';
import '../../state/auth_session.dart';
import '../../widgets/flowing_title.dart';
import '../../widgets/primary_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.onSwitchToLogin});

  final VoidCallback onSwitchToLogin;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthSession session) async {
    FocusScope.of(context).unfocus();
    await session.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<AuthSession>();

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const FlowingTitle('Sign Up'),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                autocorrect: false,
                decoration: InputDecoration(labelText: l10n.username),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstNameController,
                      decoration: InputDecoration(labelText: l10n.firstName),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
                      decoration: InputDecoration(labelText: l10n.lastName),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              ),
              const SizedBox(height: 8),
              Text(
                l10n.passwordHint,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                label: l10n.signUp,
                busy: session.isBusy,
                onPressed: () => _submit(session),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  session.clearError();
                  widget.onSwitchToLogin();
                },
                child: Text(l10n.haveAccountLogIn),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
