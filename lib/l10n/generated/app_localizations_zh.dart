// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '骰色天香';

  @override
  String get gameNameChinese => '骰色天香';

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
  String get instructionsContent =>
      '每位玩家秘密擲5個骰子。輪流叫注骰子總數。如果你認為對方在說謊就質疑！\n\n• 1為萬能點數，可以當作任何數字\n• 一旦有人叫過1，該回合1就不再是萬能點數';

  @override
  String get playerStats => '玩家統計';

  @override
  String get wins => '勝利';

  @override
  String get losses => '失敗';

  @override
  String get winRate => '勝率';

  @override
  String get totalWins => '勝場';

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
  String aiWins(Object name) {
    return '$name贏了！';
  }

  @override
  String get drink => '喝酒！';

  @override
  String get cheers => '乾杯！';

  @override
  String get drunkWarning => '你醉得不能繼續了！';

  @override
  String get drunkWarningTitle => '🥴 醉酒警告！';

  @override
  String drinksConsumedMessage(int count) {
    return '你已經喝了$count杯酒';
  }

  @override
  String soberPotionRemaining(int count) {
    return '剩餘 $count 瓶';
  }

  @override
  String drunkDescription(String name) {
    return '$name醉意朦朧地看著你';
  }

  @override
  String get soberOptions => '醒酒選項';

  @override
  String get drunkStatusDeadDrunk => '爛醉如泥';

  @override
  String get drunkStatusDizzy => '醉意朦朧';

  @override
  String get drunkStatusObvious => '明顯醉意';

  @override
  String get drunkStatusTipsy => '微醺狀態';

  @override
  String get drunkStatusSlightly => '略有酒意';

  @override
  String get drunkStatusOneDrink => '小酌一杯';

  @override
  String get drunkStatusSober => '清醒狀態';

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
  String get unlockVIPCharacter => '解鎖VIP角色';

  @override
  String get chooseUnlockMethod => '選擇以下方式解鎖此VIP角色';

  @override
  String get freePlayOneHour => '免費遊玩1小時';

  @override
  String get permanentUnlock => '永久解鎖';

  @override
  String gemsRequired(Object required, Object current) {
    return '$required寶石（你有$current寶石）';
  }

  @override
  String get laterDecide => '稍後再說';

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
  String get shareSubject => '骰色天香 - 完美勝利！';

  @override
  String shareTemplate1(String name, int drinks, int minutes) {
    return '🎉 我在骰色天香把$name灌醉了！喝了整整$drinks杯，獨處了$minutes分鐘～ #骰色天香 #完美勝利';
  }

  @override
  String shareTemplate2(String name, int drinks, int minutes) {
    return '🏆 戰績播報：$name已倒！$drinks杯下肚，親密度+$minutes！誰敢來挑戰？ #骰色天香';
  }

  @override
  String shareTemplate3(String name, int drinks, int minutes) {
    return '😎 輕鬆拿下$name！$drinks杯酒就不行了，我們還聊了$minutes分鐘的小秘密～ #骰色天香';
  }

  @override
  String shareTemplate4(String name, int drinks, int minutes) {
    return '🍺 今晚的MVP是我！$name醉倒在第$drinks杯，接下來的$minutes分鐘...你懂的😏 #骰色天香';
  }

  @override
  String get shareCardDrunk => '已醉倒';

  @override
  String get shareCardIntimacy => '親密度';

  @override
  String shareCardPrivateTime(int minutes) {
    return '獨處了 $minutes 分鐘';
  }

  @override
  String shareCardDrinkCount(int count) {
    return '$count 杯醉倒';
  }

  @override
  String get shareCardGameName => '骰色天香';

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

  @override
  String get playerDataAnalysis => '你的統計';

  @override
  String get vsRecord => '戰鬥記錄';

  @override
  String get gameStyle => '遊戲風格';

  @override
  String get bluffingTendency => '詐唱率';

  @override
  String get aggressiveness => '進攻性';

  @override
  String get challengeRate => '質疑率';

  @override
  String get styleNovice => '新手';

  @override
  String get styleBluffMaster => '詐唱大師';

  @override
  String get styleBluffer => '詐唱高手';

  @override
  String get styleHonest => '誠實玩家';

  @override
  String get styleAggressive => '激進派';

  @override
  String get styleOffensive => '進攻型';

  @override
  String get styleConservative => '保守派';

  @override
  String get styleChallenger => '挑戰者';

  @override
  String get styleCautious => '謹慎型';

  @override
  String get styleBalanced => '均衡型';

  @override
  String totalGames(Object count) {
    return '$count局';
  }

  @override
  String get win => '勝';

  @override
  String get lose => '負';

  @override
  String get debugTool => '除錯工具';

  @override
  String get noVIPCharacters => '無VIP角色';

  @override
  String minutes(Object count) {
    return '$count分鐘';
  }

  @override
  String get sober => '醒酒';

  @override
  String get useSoberPotion => '使用醒酒藥';

  @override
  String get close => '關閉';

  @override
  String aiIsDrunk(Object name) {
    return '$name喝醉了';
  }

  @override
  String get aiDrunkMessage => '她太醉了不能玩\n幫她醒酒吧';

  @override
  String get watchAdToSober => '看廣告';

  @override
  String languageSwitched(Object language) {
    return '語言已切換';
  }

  @override
  String get instructionsDetail => '詳細說明';

  @override
  String get yourDice => '你的骰子';

  @override
  String get playerDiceLabel => '你的骰子';

  @override
  String aiDiceLabel(Object name) {
    return '$name的骰子';
  }

  @override
  String bidCall(Object quantity, Object value) {
    return '叫牌';
  }

  @override
  String challengeSuccessRateDisplay(Object rate) {
    return '成功率: $rate%';
  }

  @override
  String get bidMustBeHigher => '叫牌必須更大';

  @override
  String get roundEnd => '回合結束';

  @override
  String roundNumber(int number) {
    return '第 $number 回合';
  }

  @override
  String nextBidHint(int quantity, int value) {
    return '下次叫牌：數量 > $quantity 或點數 > $value';
  }

  @override
  String get backToHome => '返回首頁';

  @override
  String get playAgain => '再玩一次';

  @override
  String get shareResult => '分享結果';

  @override
  String aiThinking(Object name) {
    return '$name正在思考...';
  }

  @override
  String get bidHistory => '叫牌歷史';

  @override
  String get completeBidHistory => '完整叫牌記錄';

  @override
  String get totalGamesCount => '總局數';

  @override
  String get watchAdSuccess => '✨ 廣告看完，完全醒酒！';

  @override
  String get usedSoberPotion => '使用醒酒藥水，清醒了2杯！';

  @override
  String aiSoberSuccess(Object name) {
    return '✨ $name醒酒了！';
  }

  @override
  String get drunkStatus => '你太醉了不能繼續！\n你需要醒醒酒';

  @override
  String get soberTip => '💡 小貼士：每10分鐘自然恢復1杯酒';

  @override
  String get watchAdToSoberTitle => '看廣告醒酒';

  @override
  String get returnToHome => '回家，自然醒酒';

  @override
  String get youRolled => '你擲出';

  @override
  String aiRolled(Object name) {
    return '$name擲出';
  }

  @override
  String get myDice => '我的骰子';

  @override
  String get challenging => '正在質疑';

  @override
  String get gameTips => '遊戲提示';

  @override
  String userIdPrefix(Object id) {
    return 'ID：';
  }

  @override
  String get vipLabel => 'VIP';

  @override
  String tempUnlockTime(Object minutes) {
    return '$minutes分鐘';
  }

  @override
  String privateTime(Object minutes) {
    return '私人時間：$minutes分鐘';
  }

  @override
  String get victory => '勝利';

  @override
  String intimacyLevelShort(Object level) {
    return 'Lv.$level';
  }

  @override
  String get watchAdUnlock => '觀看廣告';

  @override
  String drunkAndWon(Object name) {
    return '$name醉倒了，你贏了！';
  }

  @override
  String get copiedToClipboard => '已複製到剪貼板';

  @override
  String pleaseWaitThinking(Object name) {
    return '$name思考中...';
  }

  @override
  String get pleaseBid => '輪到你叫牌';

  @override
  String get showDice => '開骰子！';

  @override
  String get challengeOpponent => '質疑對手叫牌';

  @override
  String challengePlayerBid(Object quantity, Object value) {
    return '質疑玩家叫牌：$quantity個$value';
  }

  @override
  String get playerShowDice => '玩家開骰子！';

  @override
  String aiShowDice(Object name) {
    return '$name開骰子！';
  }

  @override
  String get adLoadFailed => '廣告加載失敗';

  @override
  String get adLoadFailedTryLater => '廣告加載失敗，請稍後再試';

  @override
  String get adWatchedSober => '✨ 廣告觀看完成，完全清醒了！';

  @override
  String aiSoberedUp(Object name) {
    return '✨ $name醒酒了，繼續對戰！';
  }

  @override
  String get minimumBidTwo => '起叫最少2個';

  @override
  String languageChanged(Object language) {
    return '語言已切換為$language';
  }

  @override
  String tempUnlocked(Object name) {
    return '✨ 已臨時解鎖$name，有效期1小時';
  }

  @override
  String permanentUnlocked(Object name) {
    return '🎉 成功永久解鎖$name';
  }

  @override
  String get screenshotSaved => '截圖已保存！';

  @override
  String get challengeProbability => '質疑概率計算';

  @override
  String get challengeWillSucceed => '質疑必定成功';

  @override
  String get challengeWillFail => '質疑必定失敗';

  @override
  String get challengeSuccessRate => '質疑成功率';

  @override
  String aiDecisionProcess(Object name) {
    return '$name決策過程';
  }

  @override
  String challengePlayerBidAction(Object quantity, Object value) {
    return '質疑玩家叫牌：$quantity個$value';
  }

  @override
  String get challengeOpponentAction => '質疑對手叫牌';

  @override
  String openingBidAction(Object quantity, Object value) {
    return '開局叫牌：$quantity個$value';
  }

  @override
  String respondToBidAction(
    Object aiQuantity,
    Object aiValue,
    Object playerQuantity,
    Object playerValue,
  ) {
    return '回應玩家$playerQuantity個$playerValue，叫牌：$aiQuantity個$aiValue';
  }

  @override
  String get continueBiddingAction => '繼續叫牌';

  @override
  String get challengeProbabilityLog => '質疑概率計算（玩家視角）';

  @override
  String get challengeWillDefinitelySucceed => '質疑必定成功';

  @override
  String get challengeWillDefinitelyFail => '質疑必定失敗';

  @override
  String get challengeProbabilityResult => '質疑概率結果';

  @override
  String get challengeSuccessRateValue => '質疑成功率';

  @override
  String get challenger => '質疑方';

  @override
  String get intimacyTip => '只要你把我灌醉就可以提高親密度哦～';

  @override
  String get gameGreeting => '歡迎！一起玩吧！';

  @override
  String aiBidFormat(int quantity, int value) {
    return '我叫$quantity個$value';
  }

  @override
  String get defaultChallenge => '我不信';

  @override
  String get defaultValueBet => '穩穩的';

  @override
  String get defaultSemiBluff => '試試看';

  @override
  String get defaultBluff => '就這樣';

  @override
  String get defaultReverseTrap => '我...不太確定';

  @override
  String get defaultPressurePlay => '該決定了';

  @override
  String get defaultSafePlay => '求穩';

  @override
  String get defaultPatternBreak => '換個玩法';

  @override
  String get defaultInduceAggressive => '來啊';

  @override
  String get wildcard => '萬能';

  @override
  String get notWildcard => '不是萬能';

  @override
  String wildcardWithCount(int count) {
    return '（含$count×1）';
  }

  @override
  String get noWildcard => '（無萬能）';

  @override
  String currentBidDisplay(int quantity, int value) {
    return '$quantity個$value';
  }

  @override
  String bidLabel(int quantity, int value) {
    return '叫牌：$quantity個$value';
  }

  @override
  String actualLabel(int count, int value) {
    return '實際：$count個$value';
  }

  @override
  String quantityDisplay(int quantity) {
    return '$quantity';
  }

  @override
  String get nightFall => '🌙 夜深了...';

  @override
  String aiGotDrunk(String name) {
    return '$name 醉了';
  }

  @override
  String get timePassesBy => '時間悄然流逝';

  @override
  String aiAndYou(String name) {
    return '$name與你...';
  }

  @override
  String get relationshipCloser => '關係更近了一步';

  @override
  String get tapToContinue => '輕觸繼續';

  @override
  String intimacyIncreased(int points) {
    return '親密度增加了 +$points';
  }

  @override
  String get intimacyGrowing => '增長中...';

  @override
  String currentProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get maxLevel => 'MAX';

  @override
  String get upgradeToKnowMore => '升級就可以知道更多她的小秘密';

  @override
  String get youKnowAllSecrets => '你已經了解她的所有秘密';

  @override
  String get congratsIntimacyUpgrade => '恭喜！親密度升級了！';

  @override
  String get showOff => '炫耀';

  @override
  String get continueButton => '繼續';

  @override
  String get rematch => '再戰';

  @override
  String get perfectVictory => '🏆 完美勝利！';

  @override
  String get sharingImage => '分享圖片';

  @override
  String get loadingAvatar => '正在載入頭像...';

  @override
  String get generatingShareImage => '正在生成分享圖片...';

  @override
  String get challengeNow => '立即挑戰';

  @override
  String get gameSlogan => '100+等你來挑戰';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => '骰色天香';

  @override
  String get gameNameChinese => '骰色天香';

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
  String get instructionsContent =>
      '每位玩家秘密擲5個骰子。輪流叫注骰子總數。如果你認為對方在說謊就質疑！\n\n• 1為萬能點數，可以當作任何數字\n• 一旦有人叫過1，該回合1就不再是萬能點數';

  @override
  String get playerStats => '玩家統計';

  @override
  String get wins => '勝利';

  @override
  String get losses => '失敗';

  @override
  String get winRate => '勝率';

  @override
  String get totalWins => '勝場';

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
  String aiWins(Object name) {
    return '$name贏了！';
  }

  @override
  String get drink => '喝酒！';

  @override
  String get cheers => '乾杯！';

  @override
  String get drunkWarning => '你醉得不能繼續了！';

  @override
  String get drunkWarningTitle => '🥴 醉酒警告！';

  @override
  String drinksConsumedMessage(int count) {
    return '你已經喝了$count杯酒';
  }

  @override
  String soberPotionRemaining(int count) {
    return '剩餘 $count 瓶';
  }

  @override
  String drunkDescription(String name) {
    return '$name醉意朦朧地看著你';
  }

  @override
  String get soberOptions => '醒酒選項';

  @override
  String get drunkStatusDeadDrunk => '爛醉如泥';

  @override
  String get drunkStatusDizzy => '醉意朦朧';

  @override
  String get drunkStatusObvious => '明顯醉意';

  @override
  String get drunkStatusTipsy => '微醺狀態';

  @override
  String get drunkStatusSlightly => '略有酒意';

  @override
  String get drunkStatusOneDrink => '小酌一杯';

  @override
  String get drunkStatusSober => '清醒狀態';

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
  String get unlockVIPCharacter => '解鎖VIP角色';

  @override
  String get chooseUnlockMethod => '選擇以下方式解鎖此VIP角色';

  @override
  String get freePlayOneHour => '免費遊玩1小時';

  @override
  String get permanentUnlock => '永久解鎖';

  @override
  String gemsRequired(Object required, Object current) {
    return '$required寶石（你有$current寶石）';
  }

  @override
  String get laterDecide => '稍後再說';

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
  String get shareSubject => '骰色天香 - 完美勝利！';

  @override
  String shareTemplate1(String name, int drinks, int minutes) {
    return '🎉 我在骰色天香把$name灌醉了！喝了整整$drinks杯，獨處了$minutes分鐘～ #骰色天香 #完美勝利';
  }

  @override
  String shareTemplate2(String name, int drinks, int minutes) {
    return '🏆 戰績播報：$name已倒！$drinks杯下肚，親密度+$minutes！誰敢來挑戰？ #骰色天香';
  }

  @override
  String shareTemplate3(String name, int drinks, int minutes) {
    return '😎 輕鬆拿下$name！$drinks杯酒就不行了，我們還聊了$minutes分鐘的小秘密～ #骰色天香';
  }

  @override
  String shareTemplate4(String name, int drinks, int minutes) {
    return '🍺 今晚的MVP是我！$name醉倒在第$drinks杯，接下來的$minutes分鐘...你懂的😏 #骰色天香';
  }

  @override
  String get shareCardDrunk => '已醉倒';

  @override
  String get shareCardIntimacy => '親密度';

  @override
  String shareCardPrivateTime(int minutes) {
    return '獨處了 $minutes 分鐘';
  }

  @override
  String shareCardDrinkCount(int count) {
    return '$count 杯醉倒';
  }

  @override
  String get shareCardGameName => '骰色天香';

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

  @override
  String get playerDataAnalysis => '你的統計';

  @override
  String get vsRecord => '戰鬥記錄';

  @override
  String get gameStyle => '遊戲風格';

  @override
  String get bluffingTendency => '詐唱率';

  @override
  String get aggressiveness => '進攻性';

  @override
  String get challengeRate => '質疑率';

  @override
  String get styleNovice => '新手';

  @override
  String get styleBluffMaster => '詐唱大師';

  @override
  String get styleBluffer => '詐唱高手';

  @override
  String get styleHonest => '誠實玩家';

  @override
  String get styleAggressive => '激進派';

  @override
  String get styleOffensive => '進攻型';

  @override
  String get styleConservative => '保守派';

  @override
  String get styleChallenger => '挑戰者';

  @override
  String get styleCautious => '謹慎型';

  @override
  String get styleBalanced => '均衡型';

  @override
  String totalGames(Object count) {
    return '$count局';
  }

  @override
  String get win => '勝';

  @override
  String get lose => '負';

  @override
  String get debugTool => '除錯工具';

  @override
  String get noVIPCharacters => '無VIP角色';

  @override
  String minutes(Object count) {
    return '$count分鐘';
  }

  @override
  String get sober => '醒酒';

  @override
  String get useSoberPotion => '使用醒酒藥';

  @override
  String get close => '關閉';

  @override
  String aiIsDrunk(Object name) {
    return '$name喝醉了';
  }

  @override
  String get aiDrunkMessage => '她太醉了不能玩\n幫她醒酒吧';

  @override
  String get watchAdToSober => '看廣告';

  @override
  String languageSwitched(Object language) {
    return '語言已切換';
  }

  @override
  String get instructionsDetail => '詳細說明';

  @override
  String get yourDice => '你的骰子';

  @override
  String get playerDiceLabel => '你的骰子';

  @override
  String aiDiceLabel(Object name) {
    return '$name的骰子';
  }

  @override
  String bidCall(Object quantity, Object value) {
    return '叫牌';
  }

  @override
  String challengeSuccessRateDisplay(Object rate) {
    return '成功率: $rate%';
  }

  @override
  String get bidMustBeHigher => '叫牌必須更大';

  @override
  String get roundEnd => '回合結束';

  @override
  String roundNumber(int number) {
    return '第 $number 回合';
  }

  @override
  String nextBidHint(int quantity, int value) {
    return '下次叫牌：數量 > $quantity 或點數 > $value';
  }

  @override
  String get backToHome => '返回首頁';

  @override
  String get playAgain => '再玩一次';

  @override
  String get shareResult => '分享結果';

  @override
  String aiThinking(Object name) {
    return '$name正在思考...';
  }

  @override
  String get bidHistory => '叫牌歷史';

  @override
  String get completeBidHistory => '完整叫牌記錄';

  @override
  String get totalGamesCount => '總局數';

  @override
  String get watchAdSuccess => '✨ 廣告看完，完全醒酒！';

  @override
  String get usedSoberPotion => '使用醒酒藥水，清醒了2杯！';

  @override
  String aiSoberSuccess(Object name) {
    return '✨ $name醒酒了！';
  }

  @override
  String get drunkStatus => '你太醉了不能繼續！\n你需要醒醒酒';

  @override
  String get soberTip => '💡 小貼士：每10分鐘自然恢復1杯酒';

  @override
  String get watchAdToSoberTitle => '看廣告醒酒';

  @override
  String get returnToHome => '回家，自然醒酒';

  @override
  String get youRolled => '你擲出';

  @override
  String aiRolled(Object name) {
    return '$name擲出';
  }

  @override
  String get myDice => '我的骰子';

  @override
  String get challenging => '正在質疑';

  @override
  String get gameTips => '遊戲提示';

  @override
  String userIdPrefix(Object id) {
    return 'ID：';
  }

  @override
  String get vipLabel => 'VIP';

  @override
  String tempUnlockTime(Object minutes) {
    return '$minutes分鐘';
  }

  @override
  String privateTime(Object minutes) {
    return '私人時間：$minutes分鐘';
  }

  @override
  String get victory => '勝利';

  @override
  String intimacyLevelShort(Object level) {
    return 'Lv.$level';
  }

  @override
  String get watchAdUnlock => '觀看廣告';

  @override
  String drunkAndWon(Object name) {
    return '$name醉倒了，你贏了！';
  }

  @override
  String get copiedToClipboard => '已複製到剪貼板';

  @override
  String pleaseWaitThinking(Object name) {
    return '$name思考中...';
  }

  @override
  String get pleaseBid => '輪到你叫牌';

  @override
  String get showDice => '開骰子！';

  @override
  String get challengeOpponent => '質疑對手叫牌';

  @override
  String challengePlayerBid(Object quantity, Object value) {
    return '質疑玩家叫牌：$quantity個$value';
  }

  @override
  String get playerShowDice => '玩家開骰子！';

  @override
  String aiShowDice(Object name) {
    return '$name開骰子！';
  }

  @override
  String get adLoadFailed => '廣告加載失敗';

  @override
  String get adLoadFailedTryLater => '廣告加載失敗，請稍後再試';

  @override
  String get adWatchedSober => '✨ 廣告觀看完成，完全清醒了！';

  @override
  String aiSoberedUp(Object name) {
    return '✨ $name醒酒了，繼續對戰！';
  }

  @override
  String get minimumBidTwo => '起叫最少2個';

  @override
  String languageChanged(Object language) {
    return '語言已切換為$language';
  }

  @override
  String tempUnlocked(Object name) {
    return '✨ 已臨時解鎖$name，有效期1小時';
  }

  @override
  String permanentUnlocked(Object name) {
    return '🎉 成功永久解鎖$name';
  }

  @override
  String get screenshotSaved => '截圖已保存！';

  @override
  String get challengeProbability => '質疑概率計算';

  @override
  String get challengeWillSucceed => '質疑必定成功';

  @override
  String get challengeWillFail => '質疑必定失敗';

  @override
  String get challengeSuccessRate => '質疑成功率';

  @override
  String aiDecisionProcess(Object name) {
    return '$name決策過程';
  }

  @override
  String challengePlayerBidAction(Object quantity, Object value) {
    return '質疑玩家叫牌：$quantity個$value';
  }

  @override
  String get challengeOpponentAction => '質疑對手叫牌';

  @override
  String openingBidAction(Object quantity, Object value) {
    return '開局叫牌：$quantity個$value';
  }

  @override
  String respondToBidAction(
    Object aiQuantity,
    Object aiValue,
    Object playerQuantity,
    Object playerValue,
  ) {
    return '回應玩家$playerQuantity個$playerValue，叫牌：$aiQuantity個$aiValue';
  }

  @override
  String get continueBiddingAction => '繼續叫牌';

  @override
  String get challengeProbabilityLog => '質疑概率計算（玩家視角）';

  @override
  String get challengeWillDefinitelySucceed => '質疑必定成功';

  @override
  String get challengeWillDefinitelyFail => '質疑必定失敗';

  @override
  String get challengeProbabilityResult => '質疑概率結果';

  @override
  String get challengeSuccessRateValue => '質疑成功率';

  @override
  String get challenger => '質疑方';

  @override
  String get intimacyTip => '只要你把我灌醉就可以提高親密度哦～';

  @override
  String get gameGreeting => '歡迎！一起玩吧！';

  @override
  String aiBidFormat(int quantity, int value) {
    return '我叫$quantity個$value';
  }

  @override
  String get defaultChallenge => '我不信';

  @override
  String get defaultValueBet => '穩穩的';

  @override
  String get defaultSemiBluff => '試試看';

  @override
  String get defaultBluff => '就這樣';

  @override
  String get defaultReverseTrap => '我...不太確定';

  @override
  String get defaultPressurePlay => '該決定了';

  @override
  String get defaultSafePlay => '求穩';

  @override
  String get defaultPatternBreak => '換個玩法';

  @override
  String get defaultInduceAggressive => '來啊';

  @override
  String get wildcard => '萬能';

  @override
  String get notWildcard => '不是萬能';

  @override
  String wildcardWithCount(int count) {
    return '（含$count×1）';
  }

  @override
  String get noWildcard => '（無萬能）';

  @override
  String currentBidDisplay(int quantity, int value) {
    return '$quantity個$value';
  }

  @override
  String bidLabel(int quantity, int value) {
    return '叫牌：$quantity個$value';
  }

  @override
  String actualLabel(int count, int value) {
    return '實際：$count個$value';
  }

  @override
  String quantityDisplay(int quantity) {
    return '$quantity';
  }

  @override
  String get nightFall => '🌙 夜深了...';

  @override
  String aiGotDrunk(String name) {
    return '$name 醉了';
  }

  @override
  String get timePassesBy => '時間悄然流逝';

  @override
  String aiAndYou(String name) {
    return '$name與你...';
  }

  @override
  String get relationshipCloser => '關係更近了一步';

  @override
  String get tapToContinue => '輕觸繼續';

  @override
  String intimacyIncreased(int points) {
    return '親密度增加了 +$points';
  }

  @override
  String get intimacyGrowing => '增長中...';

  @override
  String currentProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get maxLevel => 'MAX';

  @override
  String get upgradeToKnowMore => '升級就可以知道更多她的小秘密';

  @override
  String get youKnowAllSecrets => '你已經了解她的所有秘密';

  @override
  String get congratsIntimacyUpgrade => '恭喜！親密度升級了！';

  @override
  String get showOff => '炫耀';

  @override
  String get continueButton => '繼續';

  @override
  String get rematch => '再戰';

  @override
  String get perfectVictory => '🏆 完美勝利！';

  @override
  String get sharingImage => '分享圖片';

  @override
  String get loadingAvatar => '正在載入頭像...';

  @override
  String get generatingShareImage => '正在生成分享圖片...';

  @override
  String get challengeNow => '立即挑戰';

  @override
  String get gameSlogan => '100+等你來挑戰';
}
