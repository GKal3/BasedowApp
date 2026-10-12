import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/form_error_box.dart';
import 'auth_controller.dart';
import 'auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nome = TextEditingController();
  final _cognome = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _nome.dispose();
    _cognome.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nome = _nome.text.trim();
    final cognome = _cognome.text.trim();
    final email = _email.text.trim();
    final pwd = _password.text;
    if (nome.isEmpty || cognome.isEmpty || email.isEmpty || pwd.length < 6) {
      setState(() => _error = 'Compila tutti i campi correttamente.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await ref.read(authProvider.notifier).signUp(
          nome: nome,
          cognome: cognome,
          email: email,
          password: pwd,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Crea un account',
      subtitle:
          'Registrati per iniziare a registrare pazienti e valutazioni cliniche.',
      children: [
        FormErrorBox(message: _error),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: 'Nome',
                controller: _nome,
                hint: 'Mario',
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextField(
                label: 'Cognome',
                controller: _cognome,
                hint: 'Rossi',
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
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
          hint: 'Almeno 6 caratteri',
          obscureText: true,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 6),
        PrimaryButton(label: 'Registrati', onPressed: _submit, loading: _loading),
        const SizedBox(height: 14),
        Center(
          child: AuthSwitchLine(
            prefix: 'Hai già un account?',
            action: 'Accedi',
            onTap: () => context.pushReplacement(AppRoutes.login),
          ),
        ),
      ],
    );
  }
}
