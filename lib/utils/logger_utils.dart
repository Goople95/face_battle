import 'package:logger/logger.dart';

/// 全局日志管理器
class LoggerUtils {
  static final LoggerUtils _instance = LoggerUtils._internal();
  factory LoggerUtils() => _instance;
  LoggerUtils._internal();
  
  static late Logger _logger;
  static bool _initialized = false;
  
  /// 初始化日志系统
  static void init({bool debugMode = true}) {
    if (_initialized) return;
    
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0, // 不显示调用栈
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: debugMode ? Level.trace : Level.info,
      filter: debugMode ? DevelopmentFilter() : ProductionFilter(),
    );
    
    _initialized = true;
  }
  
  /// 获取日志实例
  static Logger get logger {
    if (!_initialized) {
      init();
    }
    return _logger;
  }
}

/// AI服务专用日志器
class AILogger {
  static final _logger = LoggerUtils.logger;
  
  /// 记录API调用开始
  static void apiCallStart(String service, String method) {
    _logger.i('🌐 [$service] 开始调用: $method');
  }
  
  /// 记录API调用成功
  static void apiCallSuccess(String service, String method, {String? result}) {
    _logger.d('✅ [$service] 调用成功: $method${result != null ? ' - $result' : ''}');
  }
  
  /// 记录API调用失败
  static void apiCallError(String service, String method, dynamic error) {
    _logger.e('❌ [$service] 调用失败: $method', error: error);
  }
  
  /// 记录Prompt内容
  static void logPrompt(String prompt) {
    _logger.t('📝 Prompt内容:\n$prompt');
  }
  
  /// 记录API响应
  static void logResponse(String response) {
    _logger.t('📨 API响应:\n$response');
  }
  
  /// 记录解析结果
  static void logParsing(String stage, dynamic data) {
    _logger.d('🔍 解析[$stage]: $data');
  }
  
  /// 记录游戏决策
  static void logDecision(String decision, Map<String, dynamic> details) {
    _logger.i('🎯 决策: $decision', error: details);
  }
  
  /// 记录模式切换
  static void logModeSwitch(String from, String to) {
    _logger.w('🔄 模式切换: $from -> $to');
  }
}

/// 游戏日志器
class GameLogger {
  static final _logger = LoggerUtils.logger;
  
  /// 记录游戏状态
  static void logGameState(String state, {Map<String, dynamic>? details}) {
    _logger.d('🎮 游戏状态: $state${details != null ? ' - $details' : ''}');
  }
  
  /// 记录玩家动作
  static void logPlayerAction(String action, {dynamic data}) {
    _logger.i('👤 玩家动作: $action${data != null ? ' - $data' : ''}');
  }
  
  /// 记录AI动作
  static void logAIAction(String action, {dynamic data}) {
    _logger.i('🤖 AI动作: $action${data != null ? ' - $data' : ''}');
  }
  
  /// 记录游戏结果
  static void logGameResult(String winner, Map<String, dynamic> stats) {
    _logger.w('🏆 游戏结果: $winner 获胜', error: stats);
  }
}