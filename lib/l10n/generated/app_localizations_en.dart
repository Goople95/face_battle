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
      'Each player rolls 5 dice secretly. Take turns bidding on the total number of dice. Challenge if you think they\'re lying!';

  @override
  String get playerStats => 'Player Stats';

  @override
  String get wins => 'Wins';

  @override
  String get losses => 'Losses';

  @override
  String get winRate => 'Win Rate';

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
  String get youWin => 'You Win!';

  @override
  String get youLose => 'You Lose!';

  @override
  String get drink => 'Drink!';

  @override
  String get cheers => 'Cheers!';

  @override
  String get drunkWarning => 'You\'re too drunk to continue!';

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
  String get rateApp => 'Rate App';

  @override
  String get feedback => 'Feedback';

  @override
  String version(Object version) {
    return 'Version $version';
  }

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
  String get playerDataAnalysis => 'Your Data Analysis';

  @override
  String get vsRecord => 'Battle Record';

  @override
  String get gameStyle => 'Game Style';

  @override
  String get bluffingTendency => 'Bluffing Tendency';

  @override
  String get aggressiveness => 'Aggressiveness';

  @override
  String get challengeRate => 'Challenge Rate';

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
  String bidCall(Object quantity, Object value) {
    return 'Bid: $quantity×$value';
  }

  @override
  String challengeSuccessRate(Object rate) {
    return 'Challenge Success: $rate%';
  }

  @override
  String get bidMustBeHigher => 'Bid must be higher than current';

  @override
  String get roundEnd => 'Round End';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get playAgain => 'Play Again';

  @override
  String get shareResult => 'Share Result';

  @override
  String get aiThinking => 'AI is thinking...';

  @override
  String get bidHistory => 'Bid History';

  @override
  String get completeBidHistory => 'Complete Bid History';

  @override
  String get totalGamesCount => 'Games';

  @override
  String get watchAdSuccess => '✨ Watched ad, fully sober!';

  @override
  String get usedSoberPotion => 'Used sober potion, -2 drinks!';

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
}
