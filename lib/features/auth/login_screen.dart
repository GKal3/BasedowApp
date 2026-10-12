import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/form_error_box.dart';
import 'auth_controller.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await ref
        .read(authProvider.notifier)
        .signIn(_email.text, _password.text);
    if (!mounted) return;
    // Se il login riesce, il router reindirizza da solo alla dashboard.
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Bentornato/a',
      subtitle:
          'Accedi per gestire i tuoi pazienti e le valutazioni di orbitopatia basedowiana.',
      children: [
        FormErrorBox(message: _error),
        AppTextField(
          label: 'Email',
          controller: _email,
          hint: 'nome@ospedale.it',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        AppTextField(
          label: 'Password',
          controller: _password,
          hint: '••••••••',
          obscureText: true,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 6),
        PrimaryButton(label: 'Accedi', onPressed: _submit, loading: _loading),
        const SizedBox(height: 14),
        Center(
          child: AuthSwitchLine(
            prefix: 'Non hai un account?',
            action: 'Registrati',
            onTap: () => context.pushReplacement(AppRoutes.register),
          ),
        ),
      ],
    );
  }
}
