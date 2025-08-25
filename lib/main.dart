import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/admob_service.dart';
import 'services/npc_config_service.dart';
import 'services/dialogue_service.dart';
import 'services/language_service.dart';
import 'services/storage/local_storage_service.dart';
import 'services/game_progress_service.dart';
import 'services/temp_state_service.dart';
import 'utils/logger_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger
  LoggerUtils.init(debugMode: true);
  
  // Initialize Storage Services
  try {
    // LocalStorage doesn't need init anymore
    LoggerUtils.info('存储服务初始化成功');
  } catch (e) {
    LoggerUtils.error('存储服务初始化失败: $e');
  }
  
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
  
  // Initialize NPC Config
  try {
    await NPCConfigService().initialize();
    LoggerUtils.info('NPC配置加载成功');
  } catch (e) {
    LoggerUtils.error('NPC配置加载失败: $e');
  }
  
  // Initialize Dialogue Service
  try {
    await DialogueService().initialize();
    LoggerUtils.info('对话服务初始化成功');
  } catch (e) {
    LoggerUtils.error('对话服务初始化失败: $e');
  }
  
  // Game Progress Service will be initialized after user login
  // to ensure we have a valid user ID for database operations
  LoggerUtils.info('游戏进度服务将在用户登录后初始化');
  
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
    return ScreenUtilInit(
      // 设计稿的宽高，这里使用iPhone 14的尺寸作为设计基准
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(create: (_) => UserService()),
            ChangeNotifierProvider(create: (_) => LanguageService()..initialize()),
          ],
          child: Consumer<LanguageService>(
            builder: (context, languageService, _) {
              return MaterialApp(
                title: 'Dice Girls',
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    brightness: Brightness.dark,
                  ),
                ),
                locale: languageService.currentLocale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  Locale('zh', 'TW'),
                  Locale('es'),
                  Locale('pt'),
                  Locale('id'),
                ],
                home: Consumer<AuthService>(
          builder: (context, auth, _) {
            // 如果已经登录，直接进入主页
            if (auth.user != null) {
              return const HomeScreen();
            }
            // 如果正在加载（自动登录中），显示加载界面
            if (auth.isLoading) {
              return Scaffold(
                backgroundColor: const Color(0xFF3D0000), // 暗红色背景
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF000000),  // 纯黑色
                        Color(0xFF3D0000),  // 暗红色
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 游戏Logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.casino,
                            size: 70,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 30),
                        // 游戏标题
                        const Text(
                          'Dice Girls',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // 加载指示器
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            // 否则显示登录界面
            return const LoginScreen();
          },
                ),
                debugShowCheckedModeBanner: false,
              );
            },
          ),
        );
      },
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