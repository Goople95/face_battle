// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '骰子吹牛';

  @override
  String get gameNameChinese => '骰子吹牛';

  @override
  String get loginTitle => '欢迎';

  @override
  String get loginWithGoogle => '使用 Google 账号登录';

  @override
  String get loginWithFacebook => '使用 Facebook 账号登录';

  @override
  String get skipLogin => '跳过';

  @override
  String get or => '或';

  @override
  String get selectOpponent => '选择对手';

  @override
  String get vipOpponents => 'VIP对手';

  @override
  String get gameInstructions => '游戏说明';

  @override
  String get instructionsContent => '每位玩家秘密掷5个骰子。轮流叫注骰子总数。如果你认为对方在说谎就质疑！';

  @override
  String get playerStats => '玩家统计';

  @override
  String get wins => '胜利';

  @override
  String get losses => '失败';

  @override
  String get winRate => '胜率';

  @override
  String get level => '等级';

  @override
  String intimacyLevel(Object level) {
    return '亲密度 Lv.$level';
  }

  @override
  String drinkCapacity(Object current, Object max) {
    return '$current/$max 杯';
  }

  @override
  String soberTimeRemaining(Object time) {
    return '$time后清醒';
  }

  @override
  String aboutMinutes(Object minutes) {
    return '约$minutes分钟';
  }

  @override
  String get startGame => '开始游戏';

  @override
  String get continueGame => '继续';

  @override
  String get newGame => '新游戏';

  @override
  String get exitGame => '退出游戏';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get soundEffects => '音效';

  @override
  String get music => '音乐';

  @override
  String get on => '开';

  @override
  String get off => '关';

  @override
  String get logout => '退出登录';

  @override
  String get confirmLogout => '确定要退出登录吗？';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get loading => '加载中...';

  @override
  String get error => '错误';

  @override
  String get networkError => '网络连接失败';

  @override
  String get unknownError => '发生未知错误';

  @override
  String get yourTurn => '你的回合';

  @override
  String opponentTurn(Object name) {
    return '$name的回合';
  }

  @override
  String get bid => '叫注';

  @override
  String get challenge => '质疑';

  @override
  String currentBid(Object dice, Object quantity) {
    return '当前叫注：$quantity × $dice';
  }

  @override
  String get selectBid => '选择你的叫注';

  @override
  String get quantity => '数量';

  @override
  String get diceValue => '骰子点数';

  @override
  String get youWin => '你赢了！';

  @override
  String get youLose => '你输了！';

  @override
  String get drink => '喝酒！';

  @override
  String get cheers => '干杯！';

  @override
  String get drunkWarning => '你醉得不能继续了！';

  @override
  String get soberUp => '等待清醒或观看广告';

  @override
  String get watchAd => '观看广告';

  @override
  String waitTime(Object minutes) {
    return '等待$minutes分钟';
  }

  @override
  String get unlockVIP => '解锁VIP';

  @override
  String get vipBenefits => 'VIP特权';

  @override
  String get noAds => '无广告';

  @override
  String get exclusiveContent => '独家角色';

  @override
  String get bonusRewards => '额外奖励';

  @override
  String price(Object amount) {
    return '价格：$amount';
  }

  @override
  String get purchase => '购买';

  @override
  String get restorePurchases => '恢复购买';

  @override
  String get share => '分享';

  @override
  String get shareMessage => '我刚在骰子吹牛中获胜！你能打败我吗？';

  @override
  String get rateApp => '评价应用';

  @override
  String get feedback => '反馈';

  @override
  String version(Object version) {
    return '版本 $version';
  }

  @override
  String get allDiceValues => '所有骰子';

  @override
  String get onesLoseWildcard => '1不再是万能牌！';

  @override
  String get wildcardActive => '1可以当作任何数字';

  @override
  String get tutorialTitle => '教程';

  @override
  String get skipTutorial => '跳过';

  @override
  String get next => '下一步';

  @override
  String get previous => '上一步';

  @override
  String get done => '完成';

  @override
  String get connectionLost => '连接丢失';

  @override
  String get reconnecting => '重新连接中...';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get loginFailed => '登录失败';

  @override
  String get guestMode => '游客模式';

  @override
  String get createAccount => '创建账号';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get rememberMe => '记住我';

  @override
  String get termsOfService => '服务条款';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String agreeToTerms(Object privacy, Object terms) {
    return '继续即表示您同意我们的$terms和$privacy';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => '骰子吹牛';

  @override
  String get gameNameChinese => '骰子吹牛';

  @override
  String get loginTitle => '歡迎';

  @override
  String get loginWithGoogle => '使用 Google 帳號登入';

  @override
  String get loginWithFacebook => '使用 Facebook 帳號登入';

  @override
  String get skipLogin => '跳過';

  @override
  String get or => '或';

  @override
  String get selectOpponent => '選擇對手';

  @override
  String get vipOpponents => 'VIP對手';

  @override
  String get gameInstructions => '遊戲說明';

  @override
  String get instructionsContent => '每位玩家秘密擲5個骰子。輪流叫注骰子總數。如果你認為對方在說謊就質疑！';

  @override
  String get playerStats => '玩家統計';

  @override
  String get wins => '勝利';

  @override
  String get losses => '失敗';

  @override
  String get winRate => '勝率';

  @override
  String get level => '等級';

  @override
  String intimacyLevel(Object level) {
    return '親密度 Lv.$level';
  }

  @override
  String drinkCapacity(Object current, Object max) {
    return '$current/$max 杯';
  }

  @override
  String soberTimeRemaining(Object time) {
    return '$time後清醒';
  }

  @override
  String aboutMinutes(Object minutes) {
    return '約$minutes分鐘';
  }

  @override
  String get startGame => '開始遊戲';

  @override
  String get continueGame => '繼續';

  @override
  String get newGame => '新遊戲';

  @override
  String get exitGame => '退出遊戲';

  @override
  String get settings => '設置';

  @override
  String get language => '語言';

  @override
  String get soundEffects => '音效';

  @override
  String get music => '音樂';

  @override
  String get on => '開';

  @override
  String get off => '關';

  @override
  String get logout => '登出';

  @override
  String get confirmLogout => '確定要登出嗎？';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確認';

  @override
  String get loading => '載入中...';

  @override
  String get error => '錯誤';

  @override
  String get networkError => '網路連線失敗';

  @override
  String get unknownError => '發生未知錯誤';

  @override
  String get yourTurn => '你的回合';

  @override
  String opponentTurn(Object name) {
    return '$name的回合';
  }

  @override
  String get bid => '叫注';

  @override
  String get challenge => '質疑';

  @override
  String currentBid(Object dice, Object quantity) {
    return '當前叫注：$quantity × $dice';
  }

  @override
  String get selectBid => '選擇你的叫注';

  @override
  String get quantity => '數量';

  @override
  String get diceValue => '骰子點數';

  @override
  String get youWin => '你贏了！';

  @override
  String get youLose => '你輸了！';

  @override
  String get drink => '喝酒！';

  @override
  String get cheers => '乾杯！';

  @override
  String get drunkWarning => '你醉得不能繼續了！';

  @override
  String get soberUp => '等待清醒或觀看廣告';

  @override
  String get watchAd => '觀看廣告';

  @override
  String waitTime(Object minutes) {
    return '等待$minutes分鐘';
  }

  @override
  String get unlockVIP => '解鎖VIP';

  @override
  String get vipBenefits => 'VIP特權';

  @override
  String get noAds => '無廣告';

  @override
  String get exclusiveContent => '獨家角色';

  @override
  String get bonusRewards => '額外獎勵';

  @override
  String price(Object amount) {
    return '價格：$amount';
  }

  @override
  String get purchase => '購買';

  @override
  String get restorePurchases => '恢復購買';

  @override
  String get share => '分享';

  @override
  String get shareMessage => '我剛在骰子吹牛中獲勝！你能打敗我嗎？';

  @override
  String get rateApp => '評價應用';

  @override
  String get feedback => '反饋';

  @override
  String version(Object version) {
    return '版本 $version';
  }

  @override
  String get allDiceValues => '所有骰子';

  @override
  String get onesLoseWildcard => '1不再是萬能牌！';

  @override
  String get wildcardActive => '1可以當作任何數字';

  @override
  String get tutorialTitle => '教程';

  @override
  String get skipTutorial => '跳過';

  @override
  String get next => '下一步';

  @override
  String get previous => '上一步';

  @override
  String get done => '完成';

  @override
  String get connectionLost => '連線丟失';

  @override
  String get reconnecting => '重新連線中...';

  @override
  String get loginSuccess => '登入成功';

  @override
  String get loginFailed => '登入失敗';

  @override
  String get guestMode => '訪客模式';

  @override
  String get createAccount => '創建帳號';

  @override
  String get forgotPassword => '忘記密碼？';

  @override
  String get rememberMe => '記住我';

  @override
  String get termsOfService => '服務條款';

  @override
  String get privacyPolicy => '隱私政策';

  @override
  String agreeToTerms(Object privacy, Object terms) {
    return '繼續即表示您同意我們的$terms和$privacy';
  }
}
