import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_notifier.dart';
import '../auth/password_rules.dart';
import '../core/api_exceptions.dart';
import '../data/catalog_cache.dart';
import '../repositories/salon_api.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.preview});

  final String? preview;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _again = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _busy = false;
  var _showErrors = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.preview == 'weak') {
      _name.text = 'Новый клиент';
      _email.text = 'new.client@example.com';
      _password.text = 'короткий';
      _again.text = 'короткий';
      _showErrors = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _showErrors = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthNotifier>().register(_name.text, _email.text, _password.text);
      if (!mounted) {
        return;
      }
      await context.read<SalonApi>().warm(context.read<CatalogCache>());
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final check = PasswordCheck(_password.text);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Text('Регистрация', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Новая учётная запись получает роль читателя. Пароль на этой странице не хешируется: его проверяет и сохраняет сервер.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_error != null) Text(_error!),
              Form(
                key: _formKey,
                autovalidateMode: _showErrors ? AutovalidateMode.always : AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Имя', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Введите имя' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Почта', border: OutlineInputBorder()),
                      validator: (value) => (value == null || !value.contains('@')) ? 'Укажите почту' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        border: const OutlineInputBorder(),
                        errorText: _showErrors ? check.message : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    _rule('Не короче 8 символов', check.longEnough),
                    _rule('Есть цифра', check.hasDigit),
                    _rule('Есть специальный символ', check.hasSpecial),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _again,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Пароль ещё раз', border: OutlineInputBorder()),
                      validator: (value) => value == _password.text ? null : 'Пароли не совпадают',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Регистрация…' : 'Создать учётную запись'),
              ),
              TextButton(onPressed: () => context.go('/login'), child: const Text('Уже есть вход')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rule(String text, bool ok) {
    final color = _password.text.isEmpty
        ? Colors.black54
        : (ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(ok && _password.text.isNotEmpty ? Icons.check : Icons.close, size: 18, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
