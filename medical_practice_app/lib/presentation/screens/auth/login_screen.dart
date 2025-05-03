import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/loading_animation.dart';
import '../../state/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  bool _isCodeLogin = false;
  String _accountType = 'doctor'; // default to doctor login
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppConstants.longAnimationDuration),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleLoginMode() {
    setState(() {
      _isCodeLogin = !_isCodeLogin;
      _errorMessage = null;
    });
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success;

      if (_isCodeLogin) {
        // Login with code
        success = await authProvider.loginWithCode(
          _passwordController.text,
          _accountType,
        );
      } else {
        // Login with email and password (Azure AD)
        success = await authProvider.login();
      }

      if (!success && mounted) {
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials and try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final bool isLargeScreen = size.width > 800;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          // Background Design
          Positioned(
            top: -size.height * 0.2,
            right: -size.width * 0.2,
            child: Container(
              height: size.height * 0.6,
              width: size.width * 0.6,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(300),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.2,
            left: -size.width * 0.2,
            child: Container(
              height: size.height * 0.6,
              width: size.width * 0.6,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(300),
              ),
            ),
          ),

          // Main Content
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 1000 : 450,
              ),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: isLargeScreen
                    ? _buildLargeScreenLayout(theme)
                    : _buildSmallScreenLayout(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeScreenLayout(ThemeData theme) {
    return Row(
      children: [
        // Left Side - Image or Logo
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo or app icon
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Modern healthcare management at your fingertips',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right Side - Login Form
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: _buildLoginForm(theme),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo or app icon
          Image.asset(
            'assets/images/logo.png',
            height: 80,
          ),
          const SizedBox(height: 24),
          Text(
            AppConstants.appName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildLoginForm(theme),
        ],
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isCodeLogin ? 'Login with Code' : 'Welcome Back',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isCodeLogin
                  ? 'Enter your access code to continue'
                  : 'Please sign in to your account',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Error message if login fails
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (_isCodeLogin) ...[
              // Account Type Selection
              Text(
                'Account Type',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    _buildAccountTypeOption(
                      theme,
                      'Pharmacy',
                      'pharmacy',
                      Icons.medical_services_outlined,
                    ),
                    _buildAccountTypeOption(
                      theme,
                      'Laboratory',
                      'laboratory',
                      Icons.science_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Access Code Field
              CustomTextField(
                label: 'Access Code',
                placeholder: 'Enter your access code',
                controller: _passwordController,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                isRequired: true,
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                onSubmitted: (_) => _login(),
              ),
            ] else ...[
              // Regular login fields - handled by Azure AD
              Text(
                'You will be redirected to sign in with your organization account.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Login Button
            CustomButton(
              label: _isCodeLogin ? 'Login with Code' : 'Sign In',
              icon: _isCodeLogin ? Icons.login : Icons.account_circle,
              onPressed: _login,
              isLoading: _isLoading,
              isFullWidth: true,
              height: 50,
              showAnimation: true,
            ),

            const SizedBox(height: 24),

            // Toggle between login modes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isCodeLogin
                      ? 'Are you a doctor? '
                      : 'Are you a pharmacy or lab? ',
                  style: theme.textTheme.bodyMedium,
                ),
                GestureDetector(
                  onTap: _toggleLoginMode,
                  child: Text(
                    _isCodeLogin ? 'Sign in here' : 'Use access code',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Forgot Password
            if (!_isCodeLogin)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.forgotPassword);
                  },
                  child: Text(
                    'Forgot Password?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeOption(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    final isSelected = _accountType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _accountType = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onBackground.withOpacity(0.6),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onBackground,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
