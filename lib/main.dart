import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/admob_service.dart';
import 'utils/logger_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger
  LoggerUtils.init(debugMode: true);
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    LoggerUtils.info('Firebase初始化成功');
  } catch (e) {
    LoggerUtils.error('Firebase初始化失败: $e');
  }
  
  // Initialize AdMob
  try {
    await AdMobService.initialize();
    LoggerUtils.info('AdMob初始化成功');
  } catch (e) {
    LoggerUtils.error('AdMob初始化失败: $e');
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserService()),
      ],
      child: MaterialApp(
        title: '表情博弈',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const AuthGuard(child: HomeScreen()),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// 认证守卫 - 确保用户已登录
class AuthGuard extends StatelessWidget {
  final Widget child;
  
  const AuthGuard({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // 监听认证状态
        if (authService.isLoggedIn || authService.user?.isAnonymous == true) {
          // 已登录或游客模式，初始化用户服务
          final userService = Provider.of<UserService>(context, listen: false);
          userService.initialize(authService.user);
          return child;
        } else {
          // 未登录，返回登录页
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}