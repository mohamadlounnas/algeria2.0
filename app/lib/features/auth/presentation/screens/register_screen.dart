import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../../core/routing/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Basic validation
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = AuthProvider.of(context);
      if (authProvider?.signUp != null) {
        await authProvider!.signUp!(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
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
                  const Text('Create Account').h2().textCenter(),
                  const Gap(8),
                  const Text('Sign up to get started').muted().textCenter(),
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
                    controller: _nameController,
                    placeholder: const Text('Full Name'),
                  ),
                  const Gap(16),
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
                  const Gap(16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    placeholder: const Text('Confirm Password'),
                  ),
                  const Gap(24),
                  PrimaryButton(
                    onPressed: _isLoading || authProvider?.isLoading == true
                        ? null
                        : _handleRegister,
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
                              const Text('Creating account...'),
                            ],
                          )
                        : const Text('Sign Up'),
                  ),
                  const Gap(16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.login);
                    },
                    child: const Text('Already have an account? Sign in'),
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
