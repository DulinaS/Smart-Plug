import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_controller.dart';
import '../../../data/repositories/auth_repo.dart';

class ConfirmSignupScreen extends ConsumerStatefulWidget {
  const ConfirmSignupScreen({super.key, this.prefilledEmail});

  final String? prefilledEmail;

  @override
  ConsumerState<ConfirmSignupScreen> createState() =>
      _ConfirmSignupScreenState();
}

class _ConfirmSignupScreenState extends ConsumerState<ConfirmSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _obscureCode = false; // usually not needed for codes, but kept as option
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
      _emailCtrl.text = widget.prefilledEmail!;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(authControllerProvider.notifier).clearError();
      }

      // If a confirm action just finished successfully, go to login
      if (prev?.isLoading == true &&
          next.isLoading == false &&
          next.error == null &&
          next.requiresEmailVerification == false &&
          next.pendingEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully! You can now log in.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Signup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 8),
                const Icon(Icons.mark_email_read, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  'Enter the code we sent to your email',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email is required';
                    final emailRx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRx.hasMatch(v.trim()))
                      return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 6-digit verification code
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  obscureText: _obscureCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Confirmation Code',
                    hintText: '123456',
                    prefixIcon: const Icon(Icons.security),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCode ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCode = !_obscureCode),
                    ),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Code is required';
                    if (value.length != 6) return 'Code must be 6 digits';
                    if (!RegExp(r'^\d{6}$').hasMatch(value))
                      return 'Digits only';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                      authState.isLoading ? 'Verifying...' : 'Confirm',
                    ),
                    onPressed: authState.isLoading ? null : _onConfirm,
                  ),
                ),
                const SizedBox(height: 8),

                // Resend
                TextButton(
                  onPressed: _isResending ? null : _onResend,
                  child: _isResending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Didn't receive code? Resend"),
                ),

                const SizedBox(height: 12),
                Text(
                  'Tip: Check your spam folder if you don’t see the email.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();

    ref.read(authControllerProvider.notifier).confirmEmail(email, code);
  }

  Future<void> _onResend() async {
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email first to resend the code'),
        ),
      );
      return;
    }

    setState(() => _isResending = true);
    try {
      // Reuse signup to trigger resend (as currently implemented in EmailVerificationScreen)
      await ref
          .read(authRepositoryProvider)
          .signUp(_emailCtrl.text.trim(), '', 'User');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }
}
