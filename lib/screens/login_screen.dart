import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/logger_utils.dart';
import '../l10n/generated/app_localizations.dart';

/// 登录页面
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0000), // 深黑红色
              Color(0xFF2D0000), // 中黑红色  
              Color(0xFF400000), // 暗红色
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo和标题
                    _buildLogo(),
                    const SizedBox(height: 48),
                    
                    // 登录卡片
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildLoginCard(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // 应用Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icons/app_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // 游戏标题
        const Text(
          'Dice Girls',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Google登录按钮
          _buildGoogleSignInButton(authService),
          const SizedBox(height: 16),
          
          // 分隔线
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  AppLocalizations.of(context)!.or,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Facebook登录按钮
          _buildFacebookSignInButton(authService),
          
          // 错误信息显示
          if (authService.errorMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authService.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton(AuthService authService) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: Colors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(27),
        child: InkWell(
          onTap: authService.isLoading
              ? null
              : () async {
                  LoggerUtils.info('用户点击Google登录');
                  final user = await authService.signInWithGoogle();
                  if (user != null && mounted) {
                    LoggerUtils.info('Google登录成功: ${user.email}');
                    // 不需要手动导航，main.dart中的Consumer会自动处理
                  }
                },
          borderRadius: BorderRadius.circular(27),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: authService.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 12),
                        child: Image.asset(
                          'assets/icons/google_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.loginWithGoogle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3C4043),
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacebookSignInButton(AuthService authService) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: const Color(0xFF1877F2),
        elevation: 1,
        borderRadius: BorderRadius.circular(27),
        child: InkWell(
          onTap: authService.isLoading
              ? null
              : () async {
                  LoggerUtils.info('用户点击Facebook登录');
                  final user = await authService.signInWithFacebook();
                  if (user != null && mounted) {
                    LoggerUtils.info('Facebook登录成功: ${user.email}');
                    // 不需要手动导航，main.dart中的Consumer会自动处理
                  }
                },
          borderRadius: BorderRadius.circular(27),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
            ),
            child: authService.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Image.asset(
                            'assets/icons/facebook_logo.png',
                            fit: BoxFit.contain,
                            // 不设置color，保持原始颜色
                          ),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.loginWithFacebook,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}