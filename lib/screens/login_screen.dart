import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_notifier.dart';
import '../core/api_exceptions.dart';
import '../data/catalog_cache.dart';
import '../repositories/salon_api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.preview, this.reason});

  final String? preview;
  final String? reason;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _busy = false;
  var _showErrors = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final authMessage = context.read<AuthNotifier>().message;
    if (authMessage != null) {
      _error = authMessage;
    }
    if (widget.reason == 'idle') {
      _error = 'Сессия завершена из-за неактивности.';
    } else if (widget.reason == 'limit') {
      _error = 'Время сессии истекло. Войдите снова.';
    }
    if (widget.preview == 'bad') {
      _email.text = 'reader@salon.local';
      _password.text = 'неверный';
      _loadBadLogin();
    }
  }

  Future<void> _loadBadLogin() async {
    try {
      await context.read<AuthNotifier>().login(_email.text, _password.text);
    } on ApiException catch (error) {
      _error = error.message;
    }
    if (mounted) {
      setState(() => _showErrors = true);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
      final auth = context.read<AuthNotifier>();
      await auth.login(_email.text, _password.text);
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
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.directions_car, size: 64),
              const SizedBox(height: 12),
              Text('Вход в автосалон', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!),
                    ),
                  ),
                ),
              Form(
                key: _formKey,
                autovalidateMode: _showErrors ? AutovalidateMode.always : AutovalidateMode.disabled,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Почта', border: OutlineInputBorder()),
                      validator: (value) => (value == null || !value.contains('@')) ? 'Укажите почту' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.isEmpty) ? 'Введите пароль' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Вход…' : 'Войти'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('Нет учётной записи? Регистрация'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
