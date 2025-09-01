// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dice Girls';

  @override
  String get gameNameChinese => 'Liar\'s Dice';

  @override
  String get loginTitle => 'Welcome';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get loginWithFacebook => 'Sign in with Facebook';

  @override
  String get skipLogin => 'Skip';

  @override
  String get or => 'OR';

  @override
  String get selectOpponent => 'Select Opponent';

  @override
  String get vipOpponents => 'VIP Opponents';

  @override
  String get gameInstructions => 'How to Play';

  @override
  String get instructionsContent =>
      'Each player rolls 5 dice secretly. Take turns bidding on the total number of dice. Challenge if you think they\'re lying! \n\n• 1s are wildcards and count as any number\n• Once someone bids on 1s, they lose wildcard status for that round';

  @override
  String get playerStats => 'Player Stats';

  @override
  String get wins => 'Wins';

  @override
  String get losses => 'Losses';

  @override
  String get winRate => 'Win Rate';

  @override
  String get totalWins => 'Wins';

  @override
  String get level => 'Level';

  @override
  String intimacyLevel(Object level) {
    return 'Intimacy Lv.$level';
  }

  @override
  String drinkCapacity(Object current, Object max) {
    return '$current/$max drinks';
  }

  @override
  String soberTimeRemaining(Object time) {
    return 'Sober in $time';
  }

  @override
  String aboutMinutes(Object minutes) {
    return 'About $minutes min';
  }

  @override
  String get startGame => 'Start Game';

  @override
  String get continueGame => 'Continue';

  @override
  String get newGame => 'New Game';

  @override
  String get exitGame => 'Exit Game';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get music => 'Music';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get logout => 'Logout';

  @override
  String get confirmLogout => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get networkError => 'Network connection failed';

  @override
  String get unknownError => 'An unknown error occurred';

  @override
  String get yourTurn => 'Your Turn';

  @override
  String opponentTurn(Object name) {
    return '$name\'s Turn';
  }

  @override
  String get bid => 'Bid';

  @override
  String get challenge => 'Challenge';

  @override
  String currentBid(Object dice, Object quantity) {
    return 'Current Bid: $quantity × $dice';
  }

  @override
  String get selectBid => 'Select Your Bid';

  @override
  String get quantity => 'Quantity';

  @override
  String get diceValue => 'Dice Value';

  @override
  String get youWin => 'You win!';

  @override
  String get youLose => 'You lose!';

  @override
  String aiWins(Object name) {
    return '$name wins!';
  }

  @override
  String get drink => 'Drink!';

  @override
  String get cheers => 'Cheers!';

  @override
  String get drunkWarning => 'You\'re too drunk to continue!';

  @override
  String get drunkWarningTitle => '🥴 Drunk Warning!';

  @override
  String drinksConsumedMessage(int count) {
    return 'You\'ve had $count drinks';
  }

  @override
  String soberPotionRemaining(int count) {
    return '$count bottles left';
  }

  @override
  String drunkDescription(String name) {
    return '$name looks at you drunkenly';
  }

  @override
  String get soberOptions => 'Sober options';

  @override
  String get drunkStatusDeadDrunk => 'Dead drunk';

  @override
  String get drunkStatusDizzy => 'Dizzy drunk';

  @override
  String get drunkStatusObvious => 'Obviously drunk';

  @override
  String get drunkStatusTipsy => 'Tipsy';

  @override
  String get drunkStatusSlightly => 'Slightly drunk';

  @override
  String get drunkStatusOneDrink => 'Had one drink';

  @override
  String get drunkStatusSober => 'Sober';

  @override
  String get soberUp => 'Wait to sober up or watch an ad';

  @override
  String get watchAd => 'Watch Ad';

  @override
  String waitTime(Object minutes) {
    return 'Wait $minutes minutes';
  }

  @override
  String get unlockVIP => 'Unlock VIP';

  @override
  String get unlockVIPCharacter => 'Unlock VIP Character';

  @override
  String get chooseUnlockMethod =>
      'Choose a method to unlock this VIP character';

  @override
  String get freePlayOneHour => 'Free play for 1 hour';

  @override
  String get permanentUnlock => 'Permanent Unlock';

  @override
  String gemsRequired(Object required, Object current) {
    return '$required gems (you have $current gems)';
  }

  @override
  String get laterDecide => 'Maybe Later';

  @override
  String get vipBenefits => 'VIP Benefits';

  @override
  String get noAds => 'No Ads';

  @override
  String get exclusiveContent => 'Exclusive Characters';

  @override
  String get bonusRewards => 'Bonus Rewards';

  @override
  String price(Object amount) {
    return 'Price: $amount';
  }

  @override
  String get purchase => 'Purchase';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get share => 'Share';

  @override
  String get shareMessage => 'I just won in Dice Girls! Can you beat me?';

  @override
  String get shareSubject => 'Dice Girls - Perfect Victory!';

  @override
  String shareTemplate1(String name, int drinks, int minutes) {
    return '🎉 I got $name drunk in Dice Girls! $drinks drinks total, $minutes minutes of private time~ #DiceGirls #PerfectVictory';
  }

  @override
  String shareTemplate2(String name, int drinks, int minutes) {
    return '🏆 Victory Report: $name is down! $drinks drinks consumed, intimacy +$minutes! Who dares to challenge? #DiceGirls';
  }

  @override
  String shareTemplate3(String name, int drinks, int minutes) {
    return '😎 Easy win against $name! Only $drinks drinks and they\'re out, we chatted for $minutes minutes~ #DiceGirls';
  }

  @override
  String shareTemplate4(String name, int drinks, int minutes) {
    return '🍺 Tonight\'s MVP is me! $name passed out after $drinks drinks, the next $minutes minutes... you know 😏 #DiceGirls';
  }

  @override
  String get shareCardDrunk => 'Drunk';

  @override
  String get shareCardIntimacy => 'Intimacy';

  @override
  String shareCardPrivateTime(int minutes) {
    return 'Private time: $minutes minutes';
  }

  @override
  String shareCardDrinkCount(int count) {
    return '$count drinks to pass out';
  }

  @override
  String get shareCardGameName => 'Dice Girls';

  @override
  String get rateApp => 'Rate App';

  @override
  String get feedback => 'Feedback';

  @override
  String get version => 'Version';

  @override
  String get allDiceValues => 'All dice';

  @override
  String get onesLoseWildcard => '1s are no longer wildcards!';

  @override
  String get wildcardActive => '1s count as any number';

  @override
  String get tutorialTitle => 'Tutorial';

  @override
  String get skipTutorial => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get done => 'Done';

  @override
  String get connectionLost => 'Connection lost';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get loginSuccess => 'Login successful';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get guestMode => 'Guest Mode';

  @override
  String get createAccount => 'Create Account';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String agreeToTerms(Object privacy, Object terms) {
    return 'By continuing, you agree to our $terms and $privacy';
  }

  @override
  String get playerDataAnalysis => 'Your Stats';

  @override
  String get vsRecord => 'Battle Record';

  @override
  String get gameStyle => 'Play Style';

  @override
  String get bluffingTendency => 'Bluff Rate';

  @override
  String get aggressiveness => 'Aggression';

  @override
  String get bluffLabel => 'Bluff';

  @override
  String get aggressiveLabel => 'Aggressive';

  @override
  String get challengeRate => 'Challenge Rate';

  @override
  String get styleNovice => 'Novice';

  @override
  String get styleBluffMaster => 'Bluff Master';

  @override
  String get styleBluffer => 'Bluffer';

  @override
  String get styleHonest => 'Steady';

  @override
  String get styleAggressive => 'Bold';

  @override
  String get styleOffensive => 'Offensive';

  @override
  String get styleConservative => 'Strategic';

  @override
  String get styleChallenger => 'Challenger';

  @override
  String get styleCautious => 'Tactical';

  @override
  String get styleBalanced => 'Balanced';

  @override
  String totalGames(Object count) {
    return '$count games';
  }

  @override
  String get win => 'W';

  @override
  String get lose => 'L';

  @override
  String get debugTool => 'Debug Tool';

  @override
  String get noVIPCharacters => 'No VIP Characters';

  @override
  String minutes(Object count) {
    return '$count minutes';
  }

  @override
  String get sober => 'Sober Up';

  @override
  String get useSoberPotion => 'Use Sober Potion';

  @override
  String get close => 'Close';

  @override
  String aiIsDrunk(Object name) {
    return '$name is drunk!';
  }

  @override
  String get aiDrunkMessage => 'She\'s too drunk to play\nHelp her sober up';

  @override
  String get watchAdToSober => 'Watch Ad';

  @override
  String languageSwitched(Object language) {
    return 'Language switched to $language';
  }

  @override
  String get instructionsDetail =>
      '• Each player rolls 5 dice secretly\n• 1s are wildcards, count as any number\n• Bids must increase in quantity or dice value\n• Challenge when you think they\'re lying';

  @override
  String get yourDice => 'You rolled';

  @override
  String get playerDiceLabel => 'You';

  @override
  String aiDiceLabel(Object name) {
    return '$name';
  }

  @override
  String bidCall(Object quantity, Object value) {
    return 'Bid: $quantity×$value';
  }

  @override
  String challengeSuccessRateDisplay(Object rate) {
    return 'Success chance: $rate%';
  }

  @override
  String get bidMustBeHigher => 'Bid must be higher than current';

  @override
  String get roundEnd => 'Round End';

  @override
  String roundNumber(int number) {
    return 'Round $number';
  }

  @override
  String nextBidHint(int quantity, int value) {
    return 'Next bid: qty > $quantity or value > $value';
  }

  @override
  String get backToHome => 'Back to Home';

  @override
  String get playAgain => 'Play Again';

  @override
  String get shareResult => 'Share Result';

  @override
  String aiThinking(Object name) {
    return 'AI is thinking...';
  }

  @override
  String get bidHistory => 'Bid History';

  @override
  String get completeBidHistory => 'Bid History';

  @override
  String roundsCount(int count) {
    return '$count rounds';
  }

  @override
  String get totalGamesCount => 'Games';

  @override
  String get watchAdSuccess => '✨ Watched ad, fully sober!';

  @override
  String get usedSoberPotion => 'Used sober potion, sobered up 2 drinks!';

  @override
  String aiSoberSuccess(Object name) {
    return '✨ $name is sober!';
  }

  @override
  String get drunkStatus => 'You\'re too drunk to continue!\nNeed to sober up';

  @override
  String get soberTip =>
      '💡 Tip: Naturally sober 1 drink per 10 min, fully recover in 1 hour';

  @override
  String get watchAdToSoberTitle => 'Watch Ad to Sober';

  @override
  String get returnToHome => 'Return home, naturally sober';

  @override
  String get youRolled => 'Your Dice';

  @override
  String aiRolled(Object name) {
    return '$name\'s Dice';
  }

  @override
  String get myDice => 'My Dice';

  @override
  String get challenging => 'Challenging';

  @override
  String get gameTips => 'Game Tips';

  @override
  String userIdPrefix(Object id) {
    return 'ID: $id';
  }

  @override
  String get vipLabel => 'VIP';

  @override
  String tempUnlockTime(Object minutes) {
    return '$minutes min';
  }

  @override
  String privateTime(Object minutes) {
    return 'Private time: $minutes minutes';
  }

  @override
  String get victory => 'Victory';

  @override
  String intimacyLevelShort(Object level) {
    return 'Lv.$level';
  }

  @override
  String get watchAdUnlock => 'Watch Ad';

  @override
  String drunkAndWon(Object name) {
    return '$name passed out, you won!';
  }

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String pleaseWaitThinking(Object name) {
    return '$name is thinking...';
  }

  @override
  String get pleaseBid => 'Make your bid';

  @override
  String get showDice => 'Call the bluff!';

  @override
  String get challengeOpponent => 'Challenge opponent\'s bid';

  @override
  String challengePlayerBid(Object quantity, Object value) {
    return 'Challenge player\'s bid: $quantity×$value';
  }

  @override
  String get playerShowDice => 'Player reveals the dice!';

  @override
  String aiShowDice(Object name) {
    return '$name reveals the dice!';
  }

  @override
  String get adLoadFailed => 'Ad failed to load';

  @override
  String get adLoadFailedTryLater =>
      'Ad failed to load, please try again later';

  @override
  String get adWatchedSober => '✨ Ad watched, fully sober!';

  @override
  String aiSoberedUp(Object name) {
    return '✨ $name sobered up, continue the game!';
  }

  @override
  String get minimumBidTwo => 'Minimum bid is 2';

  @override
  String languageChanged(Object language) {
    return 'Language changed to $language';
  }

  @override
  String tempUnlocked(Object name) {
    return '✨ Temporarily unlocked $name for 1 hour';
  }

  @override
  String permanentUnlocked(Object name) {
    return '🎉 Successfully unlocked $name permanently';
  }

  @override
  String get screenshotSaved => 'Screenshot saved!';

  @override
  String get challengeProbability => 'Challenge probability';

  @override
  String get challengeWillSucceed => 'Challenge will succeed';

  @override
  String get challengeWillFail => 'Challenge will fail';

  @override
  String get challengeSuccessRate => 'Challenge success rate';

  @override
  String aiDecisionProcess(Object name) {
    return '$name Decision Process';
  }

  @override
  String challengePlayerBidAction(Object quantity, Object value) {
    return 'Challenge player\'s bid: $quantity×$value';
  }

  @override
  String get challengeOpponentAction => 'Challenge opponent\'s bid';

  @override
  String openingBidAction(Object quantity, Object value) {
    return 'Opening bid: $quantity×$value';
  }

  @override
  String respondToBidAction(
    Object aiQuantity,
    Object aiValue,
    Object playerQuantity,
    Object playerValue,
  ) {
    return 'Respond to player\'s $playerQuantity×$playerValue, bid: $aiQuantity×$aiValue';
  }

  @override
  String get continueBiddingAction => 'Continue bidding';

  @override
  String get challengeProbabilityLog =>
      'Challenge probability calculation (Player\'s perspective)';

  @override
  String get challengeWillDefinitelySucceed =>
      'Challenge will definitely succeed';

  @override
  String get challengeWillDefinitelyFail => 'Challenge will definitely fail';

  @override
  String get challengeProbabilityResult => 'Challenge probability result';

  @override
  String get challengeSuccessRateValue => 'Challenge success rate';

  @override
  String get challenger => 'Challenger';

  @override
  String get intimacyTip => 'Get me drunk to increase intimacy~';

  @override
  String get gameGreeting => 'Welcome! Let\'s play!';

  @override
  String aiBidFormat(int quantity, int value) {
    return '$quantity $value\'s';
  }

  @override
  String get defaultChallenge => 'I don\'t believe you';

  @override
  String get defaultValueBet => 'Steady';

  @override
  String get defaultSemiBluff => 'Let\'s try';

  @override
  String get defaultBluff => 'Just like that';

  @override
  String get defaultReverseTrap => 'I\'m... not sure';

  @override
  String get defaultPressurePlay => 'Time to decide';

  @override
  String get defaultSafePlay => 'Playing safe';

  @override
  String get defaultPatternBreak => 'Change it up';

  @override
  String get defaultInduceAggressive => 'Come on';

  @override
  String get wildcard => 'Wild';

  @override
  String get notWildcard => 'Not Wild';

  @override
  String wildcardWithCount(int count) {
    return '(incl. $count×1)';
  }

  @override
  String get noWildcard => ' (no wild)';

  @override
  String currentBidDisplay(int quantity, int value) {
    return '$quantity $value\'s';
  }

  @override
  String bidLabel(int quantity, int value) {
    return 'Bid: $quantity×${value}s';
  }

  @override
  String actualLabel(int count, int value) {
    return 'Actual: $count×${value}s';
  }

  @override
  String get bidShort => 'Bid';

  @override
  String get actualShort => 'Actual';

  @override
  String get inclShort => 'incl.';

  @override
  String quantityDisplay(int quantity) {
    return '$quantity';
  }

  @override
  String get nightFall => '🌙 It\'s late...';

  @override
  String aiGotDrunk(String name) {
    return '$name is drunk';
  }

  @override
  String get timePassesBy => 'Time passes quietly';

  @override
  String aiAndYou(String name) {
    return '$name and you...';
  }

  @override
  String get relationshipCloser => 'Getting closer';

  @override
  String get tapToContinue => 'Tap to continue';

  @override
  String intimacyIncreased(int points) {
    return 'Intimacy +$points';
  }

  @override
  String get intimacyGrowing => 'Growing...';

  @override
  String currentProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get maxLevel => 'MAX';

  @override
  String get upgradeToKnowMore => 'Level up to know more of her secrets';

  @override
  String get youKnowAllSecrets => 'You know all her secrets';

  @override
  String get congratsIntimacyUpgrade => 'Intimacy +1 level!';

  @override
  String get showOff => 'Show Off';

  @override
  String get continueButton => 'Continue';

  @override
  String get rematch => 'Rematch';

  @override
  String get perfectVictory => '🏆 Perfect Victory!';

  @override
  String get sharingImage => 'Sharing image';

  @override
  String get loadingAvatar => 'Loading avatar...';

  @override
  String get generatingShareImage => 'Generating share image...';

  @override
  String get challengeNow => 'Challenge Now';

  @override
  String get gameSlogan => '100+ waiting for your challenge';

  @override
  String get youGotDrunk => 'You got drunk!';

  @override
  String get watchAdToSoberSubtitle => 'Free, instantly sober';

  @override
  String get goHomeToRest => 'Go Home to Rest';

  @override
  String get loadingNPCResources => 'Loading character resources...';

  @override
  String get npcResourcesReady => 'Character ready';

  @override
  String get npcDefaultGreeting => 'Hello!';

  @override
  String get npcDefaultWinDialogue => 'It\'s your turn to drink!';

  @override
  String get npcDefaultLoseDialogue => 'You\'re amazing!';

  @override
  String get npcDefaultThinking => '...';

  @override
  String get npcActionChallenge => 'I challenge that!';

  @override
  String get npcActionValueBet => 'I\'m betting on value.';

  @override
  String get npcActionBluff => 'Let\'s see if you believe this...';

  @override
  String get npcActionReverseTrap => 'Walking into my trap?';

  @override
  String get npcActionPressurePlay => 'Feel the pressure!';

  @override
  String get npcActionSafePlay => 'Playing it safe.';

  @override
  String get npcActionPatternBreak => 'Time to change things up!';

  @override
  String get npcActionInduceAggressive => 'Come on, be bold!';

  @override
  String get intimacyProgressTitle => 'Intimacy Progress';

  @override
  String intimacyProgressFormat(int current, int total) {
    return 'Progress: $current / $total';
  }

  @override
  String get intimacyTooltip => '💕 Get me tipsy to grow our intimacy';

  @override
  String intimacyMaxLevel(int points) {
    return 'Max level reached ($points pts)';
  }

  @override
  String get skinWardrobe => 'Wardrobe';

  @override
  String get skinCurrentLook => 'Current Look';

  @override
  String get skinTapToWear => 'Touch 👙 on her to wear';

  @override
  String get skinNeedsUnlock => 'Needs unlock';

  @override
  String skinUnlockAtLevel(int level, int needed) {
    return '❤️ Unlock at intimacy level $level ($needed more)';
  }

  @override
  String get skinUnlockWithGems => '💎 Unlock exclusive style with gems';

  @override
  String get skinCurrentlyUnavailable => '🔒 Currently unavailable';
}
