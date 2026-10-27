import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_recipe_app/providers/auth_provider.dart';
import 'package:smart_recipe_app/services/api_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isRegister = false;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String _extractErrorMessage(Object? err) {
    if (err == null) return 'Bilinmeyen hata.';
    // DioException içindeki ApiException'ı çıkar
    if (err is ApiException) return err.message;
    // DioException'ın .error alanını kontrol et
    try {
      final dynamic dioErr = err;
      final inner = dioErr.error;
      if (inner is ApiException) return inner.message;
      if (inner != null) {
        final innerStr = inner.toString();
        if (!innerStr.contains('Instance of') && !innerStr.contains('minified') && innerStr.isNotEmpty) {
          return innerStr;
        }
      }
    } catch (_) {}
    final str = err.toString();
    if (str.contains('Instance of') || str.contains('minified') || str.isEmpty) {
      return 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.';
    }
    return str;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authNotifierProvider.notifier);
    if (_isRegister) {
      await notifier.register(_emailCtrl.text.trim(), _passwordCtrl.text, _nameCtrl.text.trim());
    } else {
      await notifier.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    }
    if (ref.read(authNotifierProvider).hasValue && !ref.read(authNotifierProvider).hasError) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      final wasLoading = previous?.isLoading ?? false;
      if (next.hasError && wasLoading) {
        final err = next.error;
        String msg = _extractErrorMessage(err);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.restaurant_menu, size: 72, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    'Akıllı Tarif',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700, color: Colors.green.shade800),
                  ),
                  const SizedBox(height: 32),
                  if (_isRegister) ...[
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v?.length ?? 0) < 2 ? 'En az 2 karakter girin' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) => (v?.contains('@') ?? false) ? null : 'Geçerli e-posta girin',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v?.length ?? 0) < 6 ? 'En az 6 karakter' : null,
                  ),
                  if (!_isRegister) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Şifremi Unuttum'),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isRegister ? 'Kayıt Ol' : 'Giriş Yap'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isRegister ? 'Hesabınız var mı?' : 'Hesabınız yok mu?'),
                      TextButton(
                        onPressed: () => setState(() => _isRegister = !_isRegister),
                        child: Text(_isRegister ? 'Giriş Yapın' : 'Kayıt Olun'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
