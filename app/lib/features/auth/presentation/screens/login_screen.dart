import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../../core/routing/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Basic validation
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = AuthProvider.of(context);
      if (authProvider?.signIn != null) {
        await authProvider!.signIn!(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (mounted && authProvider.user != null) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.farms, (route) => false);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context);

    return Scaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 400,
            child: Card(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Farm Disease Detection').h2().textCenter(),
                  const Gap(8),
                  const Text('Sign in to your account').muted().textCenter(),
                  const Gap(32),
                  if (_errorMessage != null) ...[
                    Alert(
                      destructive: true,
                      leading: const Icon(RadixIcons.exclamationTriangle),
                      title: const Text('Error'),
                      content: Text(_errorMessage!),
                    ),
                    const Gap(24),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    placeholder: const Text('Email'),
                  ),
                  const Gap(16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    placeholder: const Text('Password'),
                  ),
                  const Gap(24),
                  PrimaryButton(
                    onPressed: _isLoading || authProvider?.isLoading == true
                        ? null
                        : _handleLogin,
                    child: _isLoading || authProvider?.isLoading == true
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(size: 20),
                              ),
                              const Gap(8),
                              const Text('Signing in...'),
                            ],
                          )
                        : const Text('Sign In'),
                  ),
                  const Gap(16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.register);
                    },
                    child: const Text("Don't have an account? Sign up"),
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
