import 'package:flutter/material.dart';
import '../../../core/animations/fade_animation.dart';
import '../../../core/animations/button_animation.dart';
import '../../../core/animations/loading_animation.dart';
import '../../themes/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isForgotPassword = false;
  bool _isLoginViaCode = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate login delay
    await Future.delayed(const Duration(seconds: 2));

    // Navigate to home page
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
    
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _toggleForgotPassword() {
    _animationController.reverse().then((_) {
      setState(() {
        _isForgotPassword = true;
        _isLoginViaCode = false;
      });
      _animationController.forward();
    });
  }

  void _toggleLoginViaCode() {
    _animationController.reverse().then((_) {
      setState(() {
        _isLoginViaCode = true;
        _isForgotPassword = false;
      });
      _animationController.forward();
    });
  }

  void _goBackToLogin() {
    _animationController.reverse().then((_) {
      setState(() {
        _isForgotPassword = false;
        _isLoginViaCode = false;
      });
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildLogo(),
            ),
            Expanded(
              flex: 1,
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: _isForgotPassword
                        ? _buildForgotPasswordForm()
                        : _isLoginViaCode
                            ? _buildLoginViaCodeForm()
                            : _buildLoginForm(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      color: Colors.white,
      child: Center(
        child: FadeAnimation(
          delay: 0.3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Replace with your actual logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services,
                  size: 70,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Medical Practice\nManagement',
                style: AppTheme.headingStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Simplify your practice, focus on your patients',
                style: TextStyle(
                  color: AppTheme.textLightColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FadeAnimation(
            delay: 0.4,
            child: Text(
              'Login',
              style: AppTheme.headingStyle,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          FadeAnimation(
            delay: 0.5,
            child: TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeAnimation(
            delay: 0.6,
            child: TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ),
          const SizedBox(height: 30),
          FadeAnimation(
            delay: 0.7,
            child: _isLoading
                ? const Center(child: LoadingAnimation())
                : AnimatedButton(
                    onPressed: _login,
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          FadeAnimation(
            delay: 0.8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _toggleForgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _toggleLoginViaCode,
                  child: const Text(
                    'Login via Code',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeAnimation(
            delay: 0.3,
            child: Row(
              children: [
                IconButton(
                  onPressed: _goBackToLogin,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Forgot Password',
                  style: AppTheme.headingStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const FadeAnimation(
            delay: 0.4,
            child: Text(
              'Enter your email address to reset your password',
              style: TextStyle(
                color: AppTheme.textLightColor,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 30),
          FadeAnimation(
            delay: 0.5,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ),
          const SizedBox(height: 30),
          FadeAnimation(
            delay: 0.6,
            child: AnimatedButton(
              onPressed: () {
                // Implement password reset functionality
              },
              child: const Text(
                'Reset Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginViaCodeForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeAnimation(
            delay: 0.3,
            child: Row(
              children: [
                IconButton(
                  onPressed: _goBackToLogin,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Login via Code',
                  style: AppTheme.headingStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const FadeAnimation(
            delay: 0.4,
            child: Text(
              'Enter the access code provided by the doctor',
              style: TextStyle(
                color: AppTheme.textLightColor,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 30),
          FadeAnimation(
            delay: 0.5,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Access Code',
                prefixIcon: Icon(Icons.code),
              ),
            ),
          ),
          const SizedBox(height: 30),
          FadeAnimation(
            delay: 0.6,
            child: AnimatedButton(
              onPressed: () {
                // Implement login via code functionality
              },
              child: const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}