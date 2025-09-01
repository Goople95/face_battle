import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_id.dart';
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
    Locale('id'),
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
  /// **'Each player rolls 5 dice secretly. Take turns bidding on the total number of dice. Challenge if you think they\'re lying! \n\n• 1s are wildcards and count as any number\n• Once someone bids on 1s, they lose wildcard status for that round'**
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

  /// Total wins label
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get totalWins;

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
  /// **'You win!'**
  String get youWin;

  /// You lose message
  ///
  /// In en, this message translates to:
  /// **'You lose!'**
  String get youLose;

  /// No description provided for @aiWins.
  ///
  /// In en, this message translates to:
  /// **'{name} wins!'**
  String aiWins(Object name);

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

  /// No description provided for @drunkWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'🥴 Drunk Warning!'**
  String get drunkWarningTitle;

  /// No description provided for @drinksConsumedMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve had {count} drinks'**
  String drinksConsumedMessage(int count);

  /// No description provided for @soberPotionRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} bottles left'**
  String soberPotionRemaining(int count);

  /// No description provided for @drunkDescription.
  ///
  /// In en, this message translates to:
  /// **'{name} looks at you drunkenly'**
  String drunkDescription(String name);

  /// No description provided for @soberOptions.
  ///
  /// In en, this message translates to:
  /// **'Sober options'**
  String get soberOptions;

  /// No description provided for @drunkStatusDeadDrunk.
  ///
  /// In en, this message translates to:
  /// **'Dead drunk'**
  String get drunkStatusDeadDrunk;

  /// No description provided for @drunkStatusDizzy.
  ///
  /// In en, this message translates to:
  /// **'Dizzy drunk'**
  String get drunkStatusDizzy;

  /// No description provided for @drunkStatusObvious.
  ///
  /// In en, this message translates to:
  /// **'Obviously drunk'**
  String get drunkStatusObvious;

  /// No description provided for @drunkStatusTipsy.
  ///
  /// In en, this message translates to:
  /// **'Tipsy'**
  String get drunkStatusTipsy;

  /// No description provided for @drunkStatusSlightly.
  ///
  /// In en, this message translates to:
  /// **'Slightly drunk'**
  String get drunkStatusSlightly;

  /// No description provided for @drunkStatusOneDrink.
  ///
  /// In en, this message translates to:
  /// **'Had one drink'**
  String get drunkStatusOneDrink;

  /// No description provided for @drunkStatusSober.
  ///
  /// In en, this message translates to:
  /// **'Sober'**
  String get drunkStatusSober;

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

  /// Unlock VIP character title
  ///
  /// In en, this message translates to:
  /// **'Unlock VIP Character'**
  String get unlockVIPCharacter;

  /// Choose unlock method subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose a method to unlock this VIP character'**
  String get chooseUnlockMethod;

  /// Free play for one hour
  ///
  /// In en, this message translates to:
  /// **'Free play for 1 hour'**
  String get freePlayOneHour;

  /// Permanent unlock
  ///
  /// In en, this message translates to:
  /// **'Permanent Unlock'**
  String get permanentUnlock;

  /// Gems required for unlock
  ///
  /// In en, this message translates to:
  /// **'{required} gems (you have {current} gems)'**
  String gemsRequired(Object required, Object current);

  /// Later decide button
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get laterDecide;

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

  /// No description provided for @shareSubject.
  ///
  /// In en, this message translates to:
  /// **'Dice Girls - Perfect Victory!'**
  String get shareSubject;

  /// No description provided for @shareTemplate1.
  ///
  /// In en, this message translates to:
  /// **'🎉 I got {name} drunk in Dice Girls! {drinks} drinks total, {minutes} minutes of private time~ #DiceGirls #PerfectVictory'**
  String shareTemplate1(String name, int drinks, int minutes);

  /// No description provided for @shareTemplate2.
  ///
  /// In en, this message translates to:
  /// **'🏆 Victory Report: {name} is down! {drinks} drinks consumed, intimacy +{minutes}! Who dares to challenge? #DiceGirls'**
  String shareTemplate2(String name, int drinks, int minutes);

  /// No description provided for @shareTemplate3.
  ///
  /// In en, this message translates to:
  /// **'😎 Easy win against {name}! Only {drinks} drinks and they\'re out, we chatted for {minutes} minutes~ #DiceGirls'**
  String shareTemplate3(String name, int drinks, int minutes);

  /// No description provided for @shareTemplate4.
  ///
  /// In en, this message translates to:
  /// **'🍺 Tonight\'s MVP is me! {name} passed out after {drinks} drinks, the next {minutes} minutes... you know 😏 #DiceGirls'**
  String shareTemplate4(String name, int drinks, int minutes);

  /// No description provided for @shareCardDrunk.
  ///
  /// In en, this message translates to:
  /// **'Drunk'**
  String get shareCardDrunk;

  /// No description provided for @shareCardIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Intimacy'**
  String get shareCardIntimacy;

  /// No description provided for @shareCardPrivateTime.
  ///
  /// In en, this message translates to:
  /// **'Private time: {minutes} minutes'**
  String shareCardPrivateTime(int minutes);

  /// No description provided for @shareCardDrinkCount.
  ///
  /// In en, this message translates to:
  /// **'{count} drinks to pass out'**
  String shareCardDrinkCount(int count);

  /// No description provided for @shareCardGameName.
  ///
  /// In en, this message translates to:
  /// **'Dice Girls'**
  String get shareCardGameName;

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
  /// **'Version'**
  String get version;

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
  /// **'Your Stats'**
  String get playerDataAnalysis;

  /// No description provided for @vsRecord.
  ///
  /// In en, this message translates to:
  /// **'Battle Record'**
  String get vsRecord;

  /// No description provided for @gameStyle.
  ///
  /// In en, this message translates to:
  /// **'Play Style'**
  String get gameStyle;

  /// No description provided for @bluffingTendency.
  ///
  /// In en, this message translates to:
  /// **'Bluff Rate'**
  String get bluffingTendency;

  /// No description provided for @aggressiveness.
  ///
  /// In en, this message translates to:
  /// **'Aggression'**
  String get aggressiveness;

  /// No description provided for @bluffLabel.
  ///
  /// In en, this message translates to:
  /// **'Bluff'**
  String get bluffLabel;

  /// No description provided for @aggressiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Aggressive'**
  String get aggressiveLabel;

  /// No description provided for @challengeRate.
  ///
  /// In en, this message translates to:
  /// **'Challenge Rate'**
  String get challengeRate;

  /// No description provided for @styleNovice.
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get styleNovice;

  /// No description provided for @styleBluffMaster.
  ///
  /// In en, this message translates to:
  /// **'Bluff Master'**
  String get styleBluffMaster;

  /// No description provided for @styleBluffer.
  ///
  /// In en, this message translates to:
  /// **'Bluffer'**
  String get styleBluffer;

  /// No description provided for @styleHonest.
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get styleHonest;

  /// No description provided for @styleAggressive.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get styleAggressive;

  /// No description provided for @styleOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive'**
  String get styleOffensive;

  /// No description provided for @styleConservative.
  ///
  /// In en, this message translates to:
  /// **'Strategic'**
  String get styleConservative;

  /// No description provided for @styleChallenger.
  ///
  /// In en, this message translates to:
  /// **'Challenger'**
  String get styleChallenger;

  /// No description provided for @styleCautious.
  ///
  /// In en, this message translates to:
  /// **'Tactical'**
  String get styleCautious;

  /// No description provided for @styleBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get styleBalanced;

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

  /// No description provided for @playerDiceLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get playerDiceLabel;

  /// No description provided for @aiDiceLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String aiDiceLabel(Object name);

  /// No description provided for @bidCall.
  ///
  /// In en, this message translates to:
  /// **'Bid: {quantity}×{value}'**
  String bidCall(Object quantity, Object value);

  /// No description provided for @challengeSuccessRateDisplay.
  ///
  /// In en, this message translates to:
  /// **'Success chance: {rate}%'**
  String challengeSuccessRateDisplay(Object rate);

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

  /// No description provided for @roundNumber.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String roundNumber(int number);

  /// No description provided for @nextBidHint.
  ///
  /// In en, this message translates to:
  /// **'Next bid: qty > {quantity} or value > {value}'**
  String nextBidHint(int quantity, int value);

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
  String aiThinking(Object name);

  /// No description provided for @bidHistory.
  ///
  /// In en, this message translates to:
  /// **'Bid History'**
  String get bidHistory;

  /// No description provided for @completeBidHistory.
  ///
  /// In en, this message translates to:
  /// **'Bid History'**
  String get completeBidHistory;

  /// No description provided for @roundsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} rounds'**
  String roundsCount(int count);

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
  /// **'Used sober potion, sobered up 2 drinks!'**
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

  /// No description provided for @pleaseWaitThinking.
  ///
  /// In en, this message translates to:
  /// **'{name} is thinking...'**
  String pleaseWaitThinking(Object name);

  /// No description provided for @pleaseBid.
  ///
  /// In en, this message translates to:
  /// **'Make your bid'**
  String get pleaseBid;

  /// No description provided for @showDice.
  ///
  /// In en, this message translates to:
  /// **'Call the bluff!'**
  String get showDice;

  /// No description provided for @challengeOpponent.
  ///
  /// In en, this message translates to:
  /// **'Challenge opponent\'s bid'**
  String get challengeOpponent;

  /// No description provided for @challengePlayerBid.
  ///
  /// In en, this message translates to:
  /// **'Challenge player\'s bid: {quantity}×{value}'**
  String challengePlayerBid(Object quantity, Object value);

  /// No description provided for @playerShowDice.
  ///
  /// In en, this message translates to:
  /// **'Player reveals the dice!'**
  String get playerShowDice;

  /// No description provided for @aiShowDice.
  ///
  /// In en, this message translates to:
  /// **'{name} reveals the dice!'**
  String aiShowDice(Object name);

  /// No description provided for @adLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Ad failed to load'**
  String get adLoadFailed;

  /// No description provided for @adLoadFailedTryLater.
  ///
  /// In en, this message translates to:
  /// **'Ad failed to load, please try again later'**
  String get adLoadFailedTryLater;

  /// No description provided for @adWatchedSober.
  ///
  /// In en, this message translates to:
  /// **'✨ Ad watched, fully sober!'**
  String get adWatchedSober;

  /// No description provided for @aiSoberedUp.
  ///
  /// In en, this message translates to:
  /// **'✨ {name} sobered up, continue the game!'**
  String aiSoberedUp(Object name);

  /// No description provided for @minimumBidTwo.
  ///
  /// In en, this message translates to:
  /// **'Minimum bid is 2'**
  String get minimumBidTwo;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageChanged(Object language);

  /// No description provided for @tempUnlocked.
  ///
  /// In en, this message translates to:
  /// **'✨ Temporarily unlocked {name} for 1 hour'**
  String tempUnlocked(Object name);

  /// No description provided for @permanentUnlocked.
  ///
  /// In en, this message translates to:
  /// **'🎉 Successfully unlocked {name} permanently'**
  String permanentUnlocked(Object name);

  /// No description provided for @screenshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Screenshot saved!'**
  String get screenshotSaved;

  /// No description provided for @challengeProbability.
  ///
  /// In en, this message translates to:
  /// **'Challenge probability'**
  String get challengeProbability;

  /// No description provided for @challengeWillSucceed.
  ///
  /// In en, this message translates to:
  /// **'Challenge will succeed'**
  String get challengeWillSucceed;

  /// No description provided for @challengeWillFail.
  ///
  /// In en, this message translates to:
  /// **'Challenge will fail'**
  String get challengeWillFail;

  /// No description provided for @challengeSuccessRate.
  ///
  /// In en, this message translates to:
  /// **'Challenge success rate'**
  String get challengeSuccessRate;

  /// No description provided for @aiDecisionProcess.
  ///
  /// In en, this message translates to:
  /// **'{name} Decision Process'**
  String aiDecisionProcess(Object name);

  /// No description provided for @challengePlayerBidAction.
  ///
  /// In en, this message translates to:
  /// **'Challenge player\'s bid: {quantity}×{value}'**
  String challengePlayerBidAction(Object quantity, Object value);

  /// No description provided for @challengeOpponentAction.
  ///
  /// In en, this message translates to:
  /// **'Challenge opponent\'s bid'**
  String get challengeOpponentAction;

  /// No description provided for @openingBidAction.
  ///
  /// In en, this message translates to:
  /// **'Opening bid: {quantity}×{value}'**
  String openingBidAction(Object quantity, Object value);

  /// No description provided for @respondToBidAction.
  ///
  /// In en, this message translates to:
  /// **'Respond to player\'s {playerQuantity}×{playerValue}, bid: {aiQuantity}×{aiValue}'**
  String respondToBidAction(
    Object aiQuantity,
    Object aiValue,
    Object playerQuantity,
    Object playerValue,
  );

  /// No description provided for @continueBiddingAction.
  ///
  /// In en, this message translates to:
  /// **'Continue bidding'**
  String get continueBiddingAction;

  /// No description provided for @challengeProbabilityLog.
  ///
  /// In en, this message translates to:
  /// **'Challenge probability calculation (Player\'s perspective)'**
  String get challengeProbabilityLog;

  /// No description provided for @challengeWillDefinitelySucceed.
  ///
  /// In en, this message translates to:
  /// **'Challenge will definitely succeed'**
  String get challengeWillDefinitelySucceed;

  /// No description provided for @challengeWillDefinitelyFail.
  ///
  /// In en, this message translates to:
  /// **'Challenge will definitely fail'**
  String get challengeWillDefinitelyFail;

  /// No description provided for @challengeProbabilityResult.
  ///
  /// In en, this message translates to:
  /// **'Challenge probability result'**
  String get challengeProbabilityResult;

  /// No description provided for @challengeSuccessRateValue.
  ///
  /// In en, this message translates to:
  /// **'Challenge success rate'**
  String get challengeSuccessRateValue;

  /// No description provided for @challenger.
  ///
  /// In en, this message translates to:
  /// **'Challenger'**
  String get challenger;

  /// No description provided for @intimacyTip.
  ///
  /// In en, this message translates to:
  /// **'Get me drunk to increase intimacy~'**
  String get intimacyTip;

  /// No description provided for @gameGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Let\'s play!'**
  String get gameGreeting;

  /// Format for AI bid announcement
  ///
  /// In en, this message translates to:
  /// **'{quantity} {value}\'s'**
  String aiBidFormat(int quantity, int value);

  /// No description provided for @defaultChallenge.
  ///
  /// In en, this message translates to:
  /// **'I don\'t believe you'**
  String get defaultChallenge;

  /// No description provided for @defaultValueBet.
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get defaultValueBet;

  /// No description provided for @defaultSemiBluff.
  ///
  /// In en, this message translates to:
  /// **'Let\'s try'**
  String get defaultSemiBluff;

  /// No description provided for @defaultBluff.
  ///
  /// In en, this message translates to:
  /// **'Just like that'**
  String get defaultBluff;

  /// No description provided for @defaultReverseTrap.
  ///
  /// In en, this message translates to:
  /// **'I\'m... not sure'**
  String get defaultReverseTrap;

  /// No description provided for @defaultPressurePlay.
  ///
  /// In en, this message translates to:
  /// **'Time to decide'**
  String get defaultPressurePlay;

  /// No description provided for @defaultSafePlay.
  ///
  /// In en, this message translates to:
  /// **'Playing safe'**
  String get defaultSafePlay;

  /// No description provided for @defaultPatternBreak.
  ///
  /// In en, this message translates to:
  /// **'Change it up'**
  String get defaultPatternBreak;

  /// No description provided for @defaultInduceAggressive.
  ///
  /// In en, this message translates to:
  /// **'Come on'**
  String get defaultInduceAggressive;

  /// No description provided for @wildcard.
  ///
  /// In en, this message translates to:
  /// **'Wild'**
  String get wildcard;

  /// No description provided for @notWildcard.
  ///
  /// In en, this message translates to:
  /// **'Not Wild'**
  String get notWildcard;

  /// No description provided for @wildcardWithCount.
  ///
  /// In en, this message translates to:
  /// **'(incl. {count}×1)'**
  String wildcardWithCount(int count);

  /// No description provided for @noWildcard.
  ///
  /// In en, this message translates to:
  /// **' (no wild)'**
  String get noWildcard;

  /// No description provided for @currentBidDisplay.
  ///
  /// In en, this message translates to:
  /// **'{quantity} {value}\'s'**
  String currentBidDisplay(int quantity, int value);

  /// No description provided for @bidLabel.
  ///
  /// In en, this message translates to:
  /// **'Bid: {quantity}×{value}s'**
  String bidLabel(int quantity, int value);

  /// No description provided for @actualLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual: {count}×{value}s'**
  String actualLabel(int count, int value);

  /// No description provided for @bidShort.
  ///
  /// In en, this message translates to:
  /// **'Bid'**
  String get bidShort;

  /// No description provided for @actualShort.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get actualShort;

  /// No description provided for @inclShort.
  ///
  /// In en, this message translates to:
  /// **'incl.'**
  String get inclShort;

  /// No description provided for @quantityDisplay.
  ///
  /// In en, this message translates to:
  /// **'{quantity}'**
  String quantityDisplay(int quantity);

  /// No description provided for @nightFall.
  ///
  /// In en, this message translates to:
  /// **'🌙 It\'s late...'**
  String get nightFall;

  /// No description provided for @aiGotDrunk.
  ///
  /// In en, this message translates to:
  /// **'{name} is drunk'**
  String aiGotDrunk(String name);

  /// No description provided for @timePassesBy.
  ///
  /// In en, this message translates to:
  /// **'Time passes quietly'**
  String get timePassesBy;

  /// No description provided for @aiAndYou.
  ///
  /// In en, this message translates to:
  /// **'{name} and you...'**
  String aiAndYou(String name);

  /// No description provided for @relationshipCloser.
  ///
  /// In en, this message translates to:
  /// **'Getting closer'**
  String get relationshipCloser;

  /// No description provided for @tapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue'**
  String get tapToContinue;

  /// No description provided for @intimacyIncreased.
  ///
  /// In en, this message translates to:
  /// **'Intimacy +{points}'**
  String intimacyIncreased(int points);

  /// No description provided for @intimacyGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing...'**
  String get intimacyGrowing;

  /// No description provided for @currentProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String currentProgress(int current, int total);

  /// No description provided for @maxLevel.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get maxLevel;

  /// No description provided for @upgradeToKnowMore.
  ///
  /// In en, this message translates to:
  /// **'Level up to know more of her secrets'**
  String get upgradeToKnowMore;

  /// No description provided for @youKnowAllSecrets.
  ///
  /// In en, this message translates to:
  /// **'You know all her secrets'**
  String get youKnowAllSecrets;

  /// No description provided for @congratsIntimacyUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Intimacy +1 level!'**
  String get congratsIntimacyUpgrade;

  /// No description provided for @showOff.
  ///
  /// In en, this message translates to:
  /// **'Show Off'**
  String get showOff;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @rematch.
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get rematch;

  /// No description provided for @perfectVictory.
  ///
  /// In en, this message translates to:
  /// **'🏆 Perfect Victory!'**
  String get perfectVictory;

  /// No description provided for @sharingImage.
  ///
  /// In en, this message translates to:
  /// **'Sharing image'**
  String get sharingImage;

  /// No description provided for @loadingAvatar.
  ///
  /// In en, this message translates to:
  /// **'Loading avatar...'**
  String get loadingAvatar;

  /// No description provided for @generatingShareImage.
  ///
  /// In en, this message translates to:
  /// **'Generating share image...'**
  String get generatingShareImage;

  /// No description provided for @challengeNow.
  ///
  /// In en, this message translates to:
  /// **'Challenge Now'**
  String get challengeNow;

  /// No description provided for @gameSlogan.
  ///
  /// In en, this message translates to:
  /// **'100+ waiting for your challenge'**
  String get gameSlogan;

  /// No description provided for @youGotDrunk.
  ///
  /// In en, this message translates to:
  /// **'You got drunk!'**
  String get youGotDrunk;

  /// No description provided for @watchAdToSoberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free, instantly sober'**
  String get watchAdToSoberSubtitle;

  /// No description provided for @goHomeToRest.
  ///
  /// In en, this message translates to:
  /// **'Go Home to Rest'**
  String get goHomeToRest;

  /// No description provided for @loadingNPCResources.
  ///
  /// In en, this message translates to:
  /// **'Loading character resources...'**
  String get loadingNPCResources;

  /// No description provided for @npcResourcesReady.
  ///
  /// In en, this message translates to:
  /// **'Character ready'**
  String get npcResourcesReady;

  /// Default NPC greeting when no dialogue data is found
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get npcDefaultGreeting;

  /// Default NPC win dialogue
  ///
  /// In en, this message translates to:
  /// **'It\'s your turn to drink!'**
  String get npcDefaultWinDialogue;

  /// Default NPC lose dialogue
  ///
  /// In en, this message translates to:
  /// **'You\'re amazing!'**
  String get npcDefaultLoseDialogue;

  /// Default NPC thinking placeholder
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get npcDefaultThinking;

  /// Default challenge action dialogue
  ///
  /// In en, this message translates to:
  /// **'I challenge that!'**
  String get npcActionChallenge;

  /// Default value bet action dialogue
  ///
  /// In en, this message translates to:
  /// **'I\'m betting on value.'**
  String get npcActionValueBet;

  /// Default bluff action dialogue
  ///
  /// In en, this message translates to:
  /// **'Let\'s see if you believe this...'**
  String get npcActionBluff;

  /// Default reverse trap action dialogue
  ///
  /// In en, this message translates to:
  /// **'Walking into my trap?'**
  String get npcActionReverseTrap;

  /// Default pressure play action dialogue
  ///
  /// In en, this message translates to:
  /// **'Feel the pressure!'**
  String get npcActionPressurePlay;

  /// Default safe play action dialogue
  ///
  /// In en, this message translates to:
  /// **'Playing it safe.'**
  String get npcActionSafePlay;

  /// Default pattern break action dialogue
  ///
  /// In en, this message translates to:
  /// **'Time to change things up!'**
  String get npcActionPatternBreak;

  /// Default induce aggressive action dialogue
  ///
  /// In en, this message translates to:
  /// **'Come on, be bold!'**
  String get npcActionInduceAggressive;

  /// Intimacy progress title
  ///
  /// In en, this message translates to:
  /// **'Intimacy Progress'**
  String get intimacyProgressTitle;

  /// Intimacy progress format
  ///
  /// In en, this message translates to:
  /// **'Progress: {current} / {total}'**
  String intimacyProgressFormat(int current, int total);

  /// Intimacy increase tooltip
  ///
  /// In en, this message translates to:
  /// **'💕 Get me tipsy to grow our intimacy'**
  String get intimacyTooltip;

  /// Max intimacy level reached
  ///
  /// In en, this message translates to:
  /// **'Max level reached ({points} pts)'**
  String intimacyMaxLevel(int points);

  /// Skin wardrobe title
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get skinWardrobe;

  /// Current equipped skin
  ///
  /// In en, this message translates to:
  /// **'Current Look'**
  String get skinCurrentLook;

  /// Tap to wear this skin
  ///
  /// In en, this message translates to:
  /// **'Touch 👙 on her to wear'**
  String get skinTapToWear;

  /// Skin needs to be unlocked
  ///
  /// In en, this message translates to:
  /// **'Needs unlock'**
  String get skinNeedsUnlock;

  /// Unlock skin at intimacy level
  ///
  /// In en, this message translates to:
  /// **'❤️ Unlock at intimacy level {level} ({needed} more)'**
  String skinUnlockAtLevel(int level, int needed);

  /// Unlock skin with gems
  ///
  /// In en, this message translates to:
  /// **'💎 Unlock exclusive style with gems'**
  String get skinUnlockWithGems;

  /// Skin currently unavailable
  ///
  /// In en, this message translates to:
  /// **'🔒 Currently unavailable'**
  String get skinCurrentlyUnavailable;
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
      <String>['en', 'es', 'id', 'pt', 'zh'].contains(locale.languageCode);

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
    case 'id':
      return AppLocalizationsId();
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
