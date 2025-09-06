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
import 'services/npc_raw_config_service.dart';
import 'services/dialogue_service.dart';
import 'services/language_service.dart';
import 'services/storage/local_storage_service.dart';
import 'services/game_progress_service.dart';
import 'services/temp_state_service.dart';
import 'utils/logger_utils.dart';
import 'services/share_tracking_service.dart';
import 'services/purchase_service.dart';
import 'services/analytics_service.dart';
import 'services/rules_service.dart';
import 'services/cloud_npc_service.dart';
import 'services/resource_version_manager.dart';
import 'widgets/app_lifecycle_observer.dart';

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
  
  
  // AdMob异步初始化（不阻塞启动）
  // 节省约2.1秒的启动时间
  AdMobService.initialize().then((_) {
    LoggerUtils.info('AdMob初始化成功（异步）');
  }).catchError((e) {
    LoggerUtils.error('AdMob初始化失败（异步）: $e');
  });
  
  // 初始化NPC配置（必须在启动时加载，因为HomeScreen立即需要）
  try {
    await NPCConfigService().initialize();
    LoggerUtils.info('NPC配置加载成功');
    
    // 初始化NPC原始配置服務（用於皮膚系統）
    await NPCRawConfigService.instance.initialize();
    LoggerUtils.info('NPC原始配置服務初始化成功');
    
    // 智能清理NPC缓存（异步执行，不阻塞启动）
    CloudNPCService.smartCleanCache().then((_) {
      LoggerUtils.info('NPC缓存清理检查完成');
    }).catchError((e) {
      LoggerUtils.debug('NPC缓存清理失败: $e');
    });
  } catch (e) {
    LoggerUtils.error('NPC配置加载失败: $e');
  }
  
  // 初始化资源版本管理器（设备级别，不需要用户ID）
  try {
    await ResourceVersionManager.instance.load();
    LoggerUtils.info('资源版本管理器初始化成功（设备级别）');
  } catch (e) {
    LoggerUtils.error('资源版本管理器初始化失败: $e');
  }
  
  // Initialize Dialogue Service
  try {
    await DialogueService().initialize();
    LoggerUtils.info('对话服务初始化成功');
  } catch (e) {
    LoggerUtils.error('对话服务初始化失败: $e');
  }
  
  // Initialize share tracking (不使用Firebase Dynamic Links)
  try {
    await ShareTrackingService.trackInstallSource();
    LoggerUtils.info('分享追踪服务初始化成功');
  } catch (e) {
    LoggerUtils.error('分享追踪服务初始化失败: $e');
  }
  
  // Initialize In-App Purchase
  try {
    await PurchaseService().initialize();
    LoggerUtils.info('内购服务初始化成功');
  } catch (e) {
    LoggerUtils.error('内购服务初始化失败: $e');
  }
  
  // Initialize NPC Skin Service (after Purchase Service)
  // 皮膚服務在用戶登錄後初始化，因為需要LocalStorage的用戶ID
  
  // Initialize Analytics
  try {
    await AnalyticsService().initialize();
    LoggerUtils.info('Analytics服务初始化成功');
  } catch (e) {
    LoggerUtils.error('Analytics服务初始化失败: $e');
  }
  
  // 异步初始化规则服务（不阻塞启动）
  // 规则在实际使用时会检查是否已加载完成
  RulesService().initialize().then((_) {
    LoggerUtils.info('规则服务初始化成功（异步）');
  }).catchError((e) {
    LoggerUtils.error('规则服务初始化失败: $e');
  });
  
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 在第一帧渲染后保存原始的文字显示设置
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final mediaQuery = MediaQuery.of(context);
        final originalTextScaleFactor = mediaQuery.textScaleFactor;
        final originalBoldText = mediaQuery.boldText;
        
        // 保存原始值（只保存文字相关设置）
        await LocalStorageService.instance.saveOriginalTextScaleFactor(originalTextScaleFactor);
        await LocalStorageService.instance.saveOriginalBoldText(originalBoldText);
        
        LoggerUtils.info('保存原始文字显示设置:');
        LoggerUtils.info('  - textScaleFactor: $originalTextScaleFactor');
        LoggerUtils.info('  - boldText: $originalBoldText');
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // 设计稿的宽高，统一使用 Pixel 7 的尺寸作为设计基准
      designSize: const Size(412, 915),
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
              return AppLifecycleObserver(
                child: MaterialApp(
                  title: 'Dice Girls',
                  builder: (context, child) {
                    final mediaQueryData = MediaQuery.of(context);
                    
                    // 只强制调整文字相关的MediaQuery参数
                    // Android系统不允许app修改display ratio，只能修改文字设置
                    return MediaQuery(
                      data: mediaQueryData.copyWith(
                        textScaleFactor: 1.0,  // 强制标准字体大小
                        boldText: false,  // 强制禁用系统粗体文字设置
                      ),
                      child: child!,
                    );
                  },
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
                  Locale('zh'), // 支持所有中文变体，都使用繁体中文
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
                ),
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