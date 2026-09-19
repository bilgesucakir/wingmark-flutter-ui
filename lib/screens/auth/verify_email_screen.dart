import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_localizations.dart';
import '../../core/theme.dart';
import '../../state/auth_session.dart';
import '../../widgets/flowing_title.dart';

/// Shown right after registration, and after a login attempt is rejected
/// with 403 (backend blocks login until the account's email is verified).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _sending = false;
  bool _sent = false;

  Future<void> _resend(AuthSession session) async {
    setState(() => _sending = true);
    await session.resendVerification();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<AuthSession>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_outlined,
                    size: 56, color: AppTheme.accent),
                const SizedBox(height: 16),
                FlowingTitle(l10n.verifyEmailTitle, size: 30),
                const SizedBox(height: 12),
                Text(
                  l10n.verifyEmailBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                if (session.pendingVerificationEmail != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    session.pendingVerificationEmail!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 28),
                OutlinedButton(
                  onPressed: _sending ? null : () => _resend(session),
                  child: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.resendVerification),
                ),
                if (_sent) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.verificationResent,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => session.backToLogin(),
                  child: Text(l10n.logIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
