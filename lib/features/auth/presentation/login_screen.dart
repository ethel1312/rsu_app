import 'package:flutter/material.dart';

import '../../conductor/presentation/schedules_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SchedulesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  const SizedBox(height: 52),
                  const _RsuBrand(),
                  const SizedBox(height: 34),
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenido',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ingresa tus datos para continuar',
                              style: TextStyle(color: Colors.blueGrey[600]),
                            ),
                            const SizedBox(height: 24),
                            const _FieldLabel('Usuario'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _userController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'Ingresa tu usuario',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Ingresa tu usuario'
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel('Contraseña'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _hidePassword,
                              onFieldSubmitted: (_) => _signIn(),
                              decoration: InputDecoration(
                                hintText: 'Ingresa tu contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _hidePassword
                                      ? 'Mostrar contraseña'
                                      : 'Ocultar contraseña',
                                  onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword,
                                  ),
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Ingresa tu contraseña'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: _signIn,
                                child: const Text('Ingresar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 54,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sistema de Gestión de Residuos Sólidos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blueGrey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RsuBrand extends StatelessWidget {
  const _RsuBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: const Color(0xFF0B63CE),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330B63CE),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.recycling, color: Colors.white, size: 52),
        ),
        const SizedBox(height: 14),
        Text(
          'RSU',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF0B63CE),
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        Text(
          'Aplicación para conductores',
          style: TextStyle(color: Colors.blueGrey[600]),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
  );
}
