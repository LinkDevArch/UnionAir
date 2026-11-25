import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../data/session_service.dart';
import '../../domain/travel.dart';
import '../design.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.session, required this.onSignIn});

  final SessionService session;
  final VoidCallback onSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (widget.session.signIn(_email.text, _password.text)) {
      widget.onSignIn();
    } else {
      setState(() => _error = 'El correo o la contraseña no coinciden.');
    }
  }

  Future<void> _accountDialog({required bool register}) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _AccountDialog(
        session: widget.session,
        register: register,
        initialEmail: _email.text,
      ),
    );
    if (!mounted || result == null) return;
    if (register) {
      _email.text = result;
      _password.clear();
      setState(() => _error = null);
    }
    showMessage(
      context,
      register
          ? 'Cuenta de demostración creada. Ya puedes ingresar.'
          : 'Para la cuenta de demostración usa la contraseña UnionAir2026.',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F5F5),
    body: LayoutBuilder(
      builder: (context, constraints) {
        if (usesDesktopLayout(context)) return _desktopLogin();
        final scale = (constraints.maxWidth / 440).clamp(.72, 1.1);
        final designHeight = math.max(constraints.maxHeight, 890 * scale);
        final topInset = MediaQuery.viewPaddingOf(context).top;
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: designHeight),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/login-background.webp',
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: math.max(topInset, 34 * scale),
                    bottom: 64 * scale,
                  ),
                  child: Column(
                    children: [
                      const Brand(white: true, large: true),
                      SizedBox(
                        height: math.max(
                          160 * scale,
                          designHeight * .406 - 95 * scale,
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32 * scale),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: _loginForm(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _desktopLogin() => ColoredBox(
    color: canvasColor,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250, maxHeight: 820),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 11,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/login-background.webp',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          excludeFromSemantics: true,
                        ),
                        const Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: EdgeInsets.all(34),
                            child: Brand(
                              white: true,
                              large: true,
                              alignment: MainAxisAlignment.start,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 9,
                    child: ColoredBox(
                      color: Colors.white,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 22,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _loginForm(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _loginForm() => Form(
    key: _form,
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Copy(
            'Inicia sesión',
            align: TextAlign.center,
            size: 24,
            color: Colors.black,
          ),
          const SizedBox(height: 10),
          const Copy(
            'Accede y encuentra\ntu próximo vuelo',
            align: TextAlign.center,
            size: 16,
            color: Colors.black,
            weight: FontWeight.w300,
            height: 1.1,
          ),
          const SizedBox(height: 30),
          _field(
            label: 'Correo electrónico',
            hint: 'nombre@correo.com',
            controller: _email,
            keyboard: TextInputType.emailAddress,
            autofill: AutofillHints.email,
            validate: (value) => Passenger.validEmail(value)
                ? null
                : 'Ingresa un correo válido.',
          ),
          const SizedBox(height: 7),
          _field(
            label: 'Contraseña',
            hint: 'Ingresa tu contraseña',
            controller: _password,
            secret: true,
            autofill: AutofillHints.password,
            validate: (value) =>
                value.isNotEmpty ? null : 'Ingresa tu contraseña.',
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _accountDialog(register: false),
              child: const Copy(
                '¿Olvidaste tu contraseña?',
                size: 13,
                color: Color(0xFF0057BA),
              ),
            ),
          ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                liveRegion: true,
                child: Copy(error, size: 12, color: danger),
              ),
            ),
          const SizedBox(height: 5),
          ActionButton(
            'Ingresar',
            _submit,
            height: 60,
            radius: 33,
            fontSize: 20,
            color: const Color(0xFF0075F2),
            weight: FontWeight.w400,
          ),
          const SizedBox(height: 13),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Copy(
                '¿No tienes cuenta?',
                size: 13,
                color: Color(0xFF292E36),
              ),
              TextButton(
                onPressed: () => _accountDialog(register: true),
                child: const Copy(
                  'Regístrate',
                  size: 13,
                  color: Color(0xFF0057BA),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _field({
    required String label,
    required String hint,
    required String autofill,
    required TextEditingController controller,
    required String? Function(String) validate,
    TextInputType? keyboard,
    bool secret = false,
  }) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(33)),
      borderSide: BorderSide.none,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 3),
          child: Copy(
            label,
            size: 14,
            weight: FontWeight.w400,
            color: const Color(0xFF292E36),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: secret && !_showPassword,
          autofillHints: [autofill],
          textInputAction: secret ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: secret ? (_) => _submit() : null,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          validator: (value) => validate(value?.trim() ?? ''),
          style: const TextStyle(fontSize: 15, color: navy),
          decoration: InputDecoration(
            hintText: hint,
            fillColor: usesDesktopLayout(context) ? fieldColor : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 15,
            ),
            border: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: blue),
            ),
            suffixIcon: !secret
                ? null
                : IconButton(
                    tooltip: _showPassword
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
                    icon: _showPassword
                        ? const Icon(Icons.visibility_outlined, size: 21)
                        : const ArtIcon('eye-off', size: 23),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
          ),
        ),
      ],
    );
  }
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({
    required this.session,
    required this.register,
    required this.initialEmail,
  });
  final SessionService session;
  final bool register;
  final String initialEmail;

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (widget.register) widget.session.register(_email.text, _password.text);
    Navigator.pop(context, _email.text.trim());
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.register ? 'Regístrate' : 'Recuperar contraseña'),
    content: Form(
      key: _form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value ?? '';
                if (!Passenger.validEmail(email)) {
                  return 'Ingresa un correo válido.';
                }
                if (widget.register && widget.session.hasAccount(email)) {
                  return 'Este correo ya está registrado.';
                }
                if (!widget.register &&
                    email.trim().toLowerCase() != 'demo@unionair.com') {
                  return 'La ayuda está disponible para la cuenta de demostración.';
                }
                return null;
              },
            ),
            if (widget.register) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (value) => (value?.length ?? 0) < 8
                    ? 'Usa al menos 8 caracteres.'
                    : null,
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Volver'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.register ? 'Crear cuenta' : 'Ver ayuda'),
      ),
    ],
  );
}
