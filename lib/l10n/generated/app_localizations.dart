import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Dice Girls'**
  String get appTitle;

  /// Game name in Chinese characters
  ///
  /// In en, this message translates to:
  /// **'Liar\'s Dice'**
  String get gameNameChinese;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get loginTitle;

  /// Google login button text
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginWithGoogle;

  /// Facebook login button text
  ///
  /// In en, this message translates to:
  /// **'Sign in with Facebook'**
  String get loginWithFacebook;

  /// Skip login button text
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipLogin;

  /// Or separator
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// Select opponent title
  ///
  /// In en, this message translates to:
  /// **'Select Opponent'**
  String get selectOpponent;

  /// VIP opponents section title
  ///
  /// In en, this message translates to:
  /// **'VIP Opponents'**
  String get vipOpponents;

  /// Game instructions title
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get gameInstructions;

  /// Game instructions content
  ///
  /// In en, this message translates to:
  /// **'Each player rolls 5 dice secretly. Take turns bidding on the total number of dice. Challenge if you think they\'re lying!'**
  String get instructionsContent;

  /// Player statistics title
  ///
  /// In en, this message translates to:
  /// **'Player Stats'**
  String get playerStats;

  /// Wins label
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// Losses label
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get losses;

  /// Win rate label
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get winRate;

  /// Level label
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// Intimacy level label
  ///
  /// In en, this message translates to:
  /// **'Intimacy Lv.{level}'**
  String intimacyLevel(Object level);

  /// Drink capacity label
  ///
  /// In en, this message translates to:
  /// **'{current}/{max} drinks'**
  String drinkCapacity(Object current, Object max);

  /// Sober time remaining
  ///
  /// In en, this message translates to:
  /// **'Sober in {time}'**
  String soberTimeRemaining(Object time);

  /// Approximately X minutes
  ///
  /// In en, this message translates to:
  /// **'About {minutes} min'**
  String aboutMinutes(Object minutes);

  /// Start game button
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// Continue game button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// New game button
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGame;

  /// Exit game button
  ///
  /// In en, this message translates to:
  /// **'Exit Game'**
  String get exitGame;

  /// Settings menu title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Sound effects setting
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// Music setting
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// On/enabled state
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// Off/disabled state
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error message prefix
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network connection failed'**
  String get networkError;

  /// Unknown error message
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownError;

  /// Your turn indicator
  ///
  /// In en, this message translates to:
  /// **'Your Turn'**
  String get yourTurn;

  /// Opponent's turn indicator
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Turn'**
  String opponentTurn(Object name);

  /// Bid button
  ///
  /// In en, this message translates to:
  /// **'Bid'**
  String get bid;

  /// Challenge button
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challenge;

  /// Current bid display
  ///
  /// In en, this message translates to:
  /// **'Current Bid: {quantity} × {dice}'**
  String currentBid(Object dice, Object quantity);

  /// Select bid prompt
  ///
  /// In en, this message translates to:
  /// **'Select Your Bid'**
  String get selectBid;

  /// Quantity label
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Dice value label
  ///
  /// In en, this message translates to:
  /// **'Dice Value'**
  String get diceValue;

  /// You win message
  ///
  /// In en, this message translates to:
  /// **'You Win!'**
  String get youWin;

  /// You lose message
  ///
  /// In en, this message translates to:
  /// **'You Lose!'**
  String get youLose;

  /// Drink action
  ///
  /// In en, this message translates to:
  /// **'Drink!'**
  String get drink;

  /// Cheers message
  ///
  /// In en, this message translates to:
  /// **'Cheers!'**
  String get cheers;

  /// Drunk warning message
  ///
  /// In en, this message translates to:
  /// **'You\'re too drunk to continue!'**
  String get drunkWarning;

  /// Sober up message
  ///
  /// In en, this message translates to:
  /// **'Wait to sober up or watch an ad'**
  String get soberUp;

  /// Watch ad button
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAd;

  /// Wait time message
  ///
  /// In en, this message translates to:
  /// **'Wait {minutes} minutes'**
  String waitTime(Object minutes);

  /// Unlock VIP button
  ///
  /// In en, this message translates to:
  /// **'Unlock VIP'**
  String get unlockVIP;

  /// VIP benefits title
  ///
  /// In en, this message translates to:
  /// **'VIP Benefits'**
  String get vipBenefits;

  /// No ads benefit
  ///
  /// In en, this message translates to:
  /// **'No Ads'**
  String get noAds;

  /// Exclusive content benefit
  ///
  /// In en, this message translates to:
  /// **'Exclusive Characters'**
  String get exclusiveContent;

  /// Bonus rewards benefit
  ///
  /// In en, this message translates to:
  /// **'Bonus Rewards'**
  String get bonusRewards;

  /// Price label
  ///
  /// In en, this message translates to:
  /// **'Price: {amount}'**
  String price(Object amount);

  /// Purchase button
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// Restore purchases button
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// Share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Share message template
  ///
  /// In en, this message translates to:
  /// **'I just won in Dice Girls! Can you beat me?'**
  String get shareMessage;

  /// Rate app button
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// Feedback button
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(Object version);

  /// All dice values indicator
  ///
  /// In en, this message translates to:
  /// **'All dice'**
  String get allDiceValues;

  /// Ones lose wildcard status message
  ///
  /// In en, this message translates to:
  /// **'1s are no longer wildcards!'**
  String get onesLoseWildcard;

  /// Wildcard active message
  ///
  /// In en, this message translates to:
  /// **'1s count as any number'**
  String get wildcardActive;

  /// Tutorial title
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorialTitle;

  /// Skip tutorial button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipTutorial;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Previous button
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Connection lost message
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get connectionLost;

  /// Reconnecting message
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// Login success message
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccess;

  /// Login failed message
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// Guest mode label
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get guestMode;

  /// Create account button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Remember me checkbox
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// Terms of service link
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Privacy policy link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Agree to terms message
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our {terms} and {privacy}'**
  String agreeToTerms(Object privacy, Object terms);

  /// No description provided for @playerDataAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Your Data Analysis'**
  String get playerDataAnalysis;

  /// No description provided for @vsRecord.
  ///
  /// In en, this message translates to:
  /// **'Battle Record'**
  String get vsRecord;

  /// No description provided for @gameStyle.
  ///
  /// In en, this message translates to:
  /// **'Game Style'**
  String get gameStyle;

  /// No description provided for @bluffingTendency.
  ///
  /// In en, this message translates to:
  /// **'Bluffing Tendency'**
  String get bluffingTendency;

  /// No description provided for @aggressiveness.
  ///
  /// In en, this message translates to:
  /// **'Aggressiveness'**
  String get aggressiveness;

  /// No description provided for @challengeRate.
  ///
  /// In en, this message translates to:
  /// **'Challenge Rate'**
  String get challengeRate;

  /// No description provided for @totalGames.
  ///
  /// In en, this message translates to:
  /// **'{count} games'**
  String totalGames(Object count);

  /// No description provided for @win.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get win;

  /// No description provided for @lose.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get lose;

  /// No description provided for @debugTool.
  ///
  /// In en, this message translates to:
  /// **'Debug Tool'**
  String get debugTool;

  /// No description provided for @noVIPCharacters.
  ///
  /// In en, this message translates to:
  /// **'No VIP Characters'**
  String get noVIPCharacters;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String minutes(Object count);

  /// No description provided for @sober.
  ///
  /// In en, this message translates to:
  /// **'Sober Up'**
  String get sober;

  /// No description provided for @useSoberPotion.
  ///
  /// In en, this message translates to:
  /// **'Use Sober Potion'**
  String get useSoberPotion;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @aiIsDrunk.
  ///
  /// In en, this message translates to:
  /// **'{name} is drunk!'**
  String aiIsDrunk(Object name);

  /// No description provided for @aiDrunkMessage.
  ///
  /// In en, this message translates to:
  /// **'She\'s too drunk to play\nHelp her sober up'**
  String get aiDrunkMessage;

  /// No description provided for @watchAdToSober.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAdToSober;

  /// No description provided for @languageSwitched.
  ///
  /// In en, this message translates to:
  /// **'Language switched to {language}'**
  String languageSwitched(Object language);

  /// No description provided for @instructionsDetail.
  ///
  /// In en, this message translates to:
  /// **'• Each player rolls 5 dice secretly\n• 1s are wildcards, count as any number\n• Bids must increase in quantity or dice value\n• Challenge when you think they\'re lying'**
  String get instructionsDetail;

  /// No description provided for @yourDice.
  ///
  /// In en, this message translates to:
  /// **'You rolled'**
  String get yourDice;

  /// No description provided for @bidCall.
  ///
  /// In en, this message translates to:
  /// **'Bid: {quantity}×{value}'**
  String bidCall(Object quantity, Object value);

  /// No description provided for @challengeSuccessRate.
  ///
  /// In en, this message translates to:
  /// **'Challenge Success: {rate}%'**
  String challengeSuccessRate(Object rate);

  /// No description provided for @bidMustBeHigher.
  ///
  /// In en, this message translates to:
  /// **'Bid must be higher than current'**
  String get bidMustBeHigher;

  /// No description provided for @roundEnd.
  ///
  /// In en, this message translates to:
  /// **'Round End'**
  String get roundEnd;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @shareResult.
  ///
  /// In en, this message translates to:
  /// **'Share Result'**
  String get shareResult;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'AI is thinking...'**
  String get aiThinking;

  /// No description provided for @bidHistory.
  ///
  /// In en, this message translates to:
  /// **'Bid History'**
  String get bidHistory;

  /// No description provided for @completeBidHistory.
  ///
  /// In en, this message translates to:
  /// **'Complete Bid History'**
  String get completeBidHistory;

  /// No description provided for @totalGamesCount.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get totalGamesCount;

  /// No description provided for @watchAdSuccess.
  ///
  /// In en, this message translates to:
  /// **'✨ Watched ad, fully sober!'**
  String get watchAdSuccess;

  /// No description provided for @usedSoberPotion.
  ///
  /// In en, this message translates to:
  /// **'Used sober potion, -2 drinks!'**
  String get usedSoberPotion;

  /// No description provided for @aiSoberSuccess.
  ///
  /// In en, this message translates to:
  /// **'✨ {name} is sober!'**
  String aiSoberSuccess(Object name);

  /// No description provided for @drunkStatus.
  ///
  /// In en, this message translates to:
  /// **'You\'re too drunk to continue!\nNeed to sober up'**
  String get drunkStatus;

  /// No description provided for @soberTip.
  ///
  /// In en, this message translates to:
  /// **'💡 Tip: Naturally sober 1 drink per 10 min, fully recover in 1 hour'**
  String get soberTip;

  /// No description provided for @watchAdToSoberTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad to Sober'**
  String get watchAdToSoberTitle;

  /// No description provided for @returnToHome.
  ///
  /// In en, this message translates to:
  /// **'Return home, naturally sober'**
  String get returnToHome;

  /// No description provided for @youRolled.
  ///
  /// In en, this message translates to:
  /// **'Your Dice'**
  String get youRolled;

  /// No description provided for @aiRolled.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Dice'**
  String aiRolled(Object name);

  /// No description provided for @myDice.
  ///
  /// In en, this message translates to:
  /// **'My Dice'**
  String get myDice;

  /// No description provided for @challenging.
  ///
  /// In en, this message translates to:
  /// **'Challenging'**
  String get challenging;

  /// No description provided for @gameTips.
  ///
  /// In en, this message translates to:
  /// **'Game Tips'**
  String get gameTips;

  /// No description provided for @userIdPrefix.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String userIdPrefix(Object id);

  /// No description provided for @vipLabel.
  ///
  /// In en, this message translates to:
  /// **'VIP'**
  String get vipLabel;

  /// No description provided for @tempUnlockTime.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String tempUnlockTime(Object minutes);

  /// No description provided for @privateTime.
  ///
  /// In en, this message translates to:
  /// **'Private time: {minutes} minutes'**
  String privateTime(Object minutes);

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get victory;

  /// No description provided for @intimacyLevelShort.
  ///
  /// In en, this message translates to:
  /// **'Lv.{level}'**
  String intimacyLevelShort(Object level);

  /// No description provided for @watchAdUnlock.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAdUnlock;

  /// No description provided for @drunkAndWon.
  ///
  /// In en, this message translates to:
  /// **'{name} passed out, you won!'**
  String drunkAndWon(Object name);

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
