// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Dice Girls';

  @override
  String get gameNameChinese => 'Dadu Pembohong';

  @override
  String get loginTitle => 'Selamat Datang';

  @override
  String get loginWithGoogle => 'Masuk dengan Google';

  @override
  String get loginWithFacebook => 'Masuk dengan Facebook';

  @override
  String get skipLogin => 'Lewati';

  @override
  String get or => 'ATAU';

  @override
  String get selectOpponent => 'Pilih Lawan';

  @override
  String get vipOpponents => 'Lawan VIP';

  @override
  String get gameInstructions => 'Cara Bermain';

  @override
  String get instructionsContent =>
      'Setiap pemain melempar 5 dadu secara rahasia. Bergantian bertaruh pada jumlah total dadu. Tantang jika Anda pikir mereka berbohong!\n\n• Angka 1 adalah wildcard dan bisa dihitung sebagai angka apa pun\n• Setelah seseorang bertaruh pada angka 1, maka 1 tidak lagi menjadi wildcard untuk ronde itu';

  @override
  String get playerStats => 'Statistik Pemain';

  @override
  String get wins => 'Menang';

  @override
  String get losses => 'Kalah';

  @override
  String get winRate => 'Tingkat Kemenangan';

  @override
  String get level => 'Level';

  @override
  String intimacyLevel(Object level) {
    return 'Keintiman Lv.$level';
  }

  @override
  String drinkCapacity(Object current, Object max) {
    return '$current/$max minuman';
  }

  @override
  String soberTimeRemaining(Object time) {
    return 'Sadar dalam $time';
  }

  @override
  String aboutMinutes(Object minutes) {
    return 'Sekitar $minutes menit';
  }

  @override
  String get startGame => 'Mulai Permainan';

  @override
  String get continueGame => 'Lanjutkan';

  @override
  String get newGame => 'Permainan Baru';

  @override
  String get exitGame => 'Keluar Permainan';

  @override
  String get settings => 'Pengaturan';

  @override
  String get language => 'Bahasa';

  @override
  String get soundEffects => 'Efek Suara';

  @override
  String get music => 'Musik';

  @override
  String get on => 'Aktif';

  @override
  String get off => 'Nonaktif';

  @override
  String get logout => 'Keluar';

  @override
  String get confirmLogout => 'Apakah Anda yakin ingin keluar?';

  @override
  String get cancel => 'Batal';

  @override
  String get confirm => 'Konfirmasi';

  @override
  String get loading => 'Memuat...';

  @override
  String get error => 'Kesalahan';

  @override
  String get networkError => 'Gagal koneksi jaringan';

  @override
  String get unknownError => 'Terjadi kesalahan yang tidak diketahui';

  @override
  String get yourTurn => 'Giliran Anda';

  @override
  String opponentTurn(Object name) {
    return 'Giliran $name';
  }

  @override
  String get bid => 'Bertaruh';

  @override
  String get challenge => 'Tantang';

  @override
  String currentBid(Object dice, Object quantity) {
    return 'Taruhan Saat Ini: $quantity × $dice';
  }

  @override
  String get selectBid => 'Pilih Taruhan Anda';

  @override
  String get quantity => 'Jumlah';

  @override
  String get diceValue => 'Nilai Dadu';

  @override
  String get youWin => 'Anda Menang!';

  @override
  String get youLose => 'Anda Kalah!';

  @override
  String get drink => 'Minum!';

  @override
  String get cheers => 'Bersulang!';

  @override
  String get drunkWarning => 'Anda terlalu mabuk untuk melanjutkan!';

  @override
  String get soberUp => 'Tunggu untuk sadar atau tonton iklan';

  @override
  String get watchAd => 'Tonton Iklan';

  @override
  String waitTime(Object minutes) {
    return 'Tunggu $minutes menit';
  }

  @override
  String get unlockVIP => 'Buka VIP';

  @override
  String get vipBenefits => 'Keuntungan VIP';

  @override
  String get noAds => 'Tanpa Iklan';

  @override
  String get exclusiveContent => 'Karakter Eksklusif';

  @override
  String get bonusRewards => 'Hadiah Bonus';

  @override
  String price(Object amount) {
    return 'Harga: $amount';
  }

  @override
  String get purchase => 'Beli';

  @override
  String get restorePurchases => 'Pulihkan Pembelian';

  @override
  String get share => 'Bagikan';

  @override
  String get shareMessage =>
      'Saya baru saja menang di Dice Girls! Bisakah Anda mengalahkan saya?';

  @override
  String get rateApp => 'Nilai Aplikasi';

  @override
  String get feedback => 'Umpan Balik';

  @override
  String version(Object version) {
    return 'Versi $version';
  }

  @override
  String get allDiceValues => 'Semua dadu';

  @override
  String get onesLoseWildcard => '1 tidak lagi wildcard!';

  @override
  String get wildcardActive => '1 dihitung sebagai angka apa pun';

  @override
  String get tutorialTitle => 'Tutorial';

  @override
  String get skipTutorial => 'Lewati';

  @override
  String get next => 'Berikutnya';

  @override
  String get previous => 'Sebelumnya';

  @override
  String get done => 'Selesai';

  @override
  String get connectionLost => 'Koneksi terputus';

  @override
  String get reconnecting => 'Menghubungkan kembali...';

  @override
  String get loginSuccess => 'Login berhasil';

  @override
  String get loginFailed => 'Login gagal';

  @override
  String get guestMode => 'Mode Tamu';

  @override
  String get createAccount => 'Buat Akun';

  @override
  String get forgotPassword => 'Lupa Kata Sandi?';

  @override
  String get rememberMe => 'Ingat Saya';

  @override
  String get termsOfService => 'Ketentuan Layanan';

  @override
  String get privacyPolicy => 'Kebijakan Privasi';

  @override
  String agreeToTerms(Object privacy, Object terms) {
    return 'Dengan melanjutkan, Anda menyetujui $terms dan $privacy kami';
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
  String get playerDiceLabel => 'Dadu Anda';

  @override
  String aiDiceLabel(Object name) {
    return 'Dadu $name';
  }

  @override
  String bidCall(Object quantity, Object value) {
    return 'Bid: $quantity×$value';
  }

  @override
  String challengeSuccessRateDisplay(Object rate) {
    return 'Tingkat sukses: $rate%';
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
  String get usedSoberPotion =>
      'Menggunakan ramuan sadar, membersihkan 2 minuman!';

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
    return '$name sedang berpikir...';
  }

  @override
  String get pleaseBid => 'Silakan bertaruh';

  @override
  String get showDice => 'Tunjukkan dadu!';

  @override
  String get challengeOpponent => 'Tantang taruhan lawan';

  @override
  String challengePlayerBid(Object quantity, Object value) {
    return 'Tantang taruhan pemain: $quantity×$value';
  }

  @override
  String get playerShowDice => 'Pemain menunjukkan dadu!';

  @override
  String aiShowDice(Object name) {
    return '$name menunjukkan dadu!';
  }

  @override
  String get soberOptions => 'Opsi untuk sadar';

  @override
  String get adLoadFailed => 'Gagal memuat iklan';

  @override
  String get adWatchedSober => '✨ Iklan ditonton, sepenuhnya sadar!';

  @override
  String aiSoberedUp(Object name) {
    return '✨ $name sadar, lanjutkan permainan!';
  }

  @override
  String get challengeProbability => 'Probabilitas tantangan';

  @override
  String get challengeWillSucceed => 'Tantangan akan berhasil';

  @override
  String get challengeWillFail => 'Tantangan akan gagal';

  @override
  String get challengeSuccessRate => 'Tingkat keberhasilan tantangan';

  @override
  String aiDecisionProcess(Object name) {
    return 'Proses keputusan $name';
  }

  @override
  String challengePlayerBidAction(Object quantity, Object value) {
    return 'Tantang taruhan pemain: $quantity×$value';
  }

  @override
  String get challengeOpponentAction => 'Tantang taruhan lawan';

  @override
  String openingBidAction(Object quantity, Object value) {
    return 'Taruhan pembuka: $quantity×$value';
  }

  @override
  String respondToBidAction(
    Object aiQuantity,
    Object aiValue,
    Object playerQuantity,
    Object playerValue,
  ) {
    return 'Menanggapi $playerQuantity×$playerValue pemain, bertaruh: $aiQuantity×$aiValue';
  }

  @override
  String get continueBiddingAction => 'Lanjutkan bertaruh';

  @override
  String get challengeProbabilityLog =>
      'Perhitungan probabilitas tantangan (Perspektif pemain)';

  @override
  String get challengeWillDefinitelySucceed => 'Tantangan pasti akan berhasil';

  @override
  String get challengeWillDefinitelyFail => 'Tantangan pasti akan gagal';

  @override
  String get challengeProbabilityResult => 'Hasil probabilitas tantangan';

  @override
  String get challengeSuccessRateValue => 'Tingkat keberhasilan tantangan';

  @override
  String get challenger => 'Penantang';

  @override
  String get intimacyTip => 'Buat aku mabuk untuk meningkatkan keintiman~';

  @override
  String get gameGreeting => 'Selamat datang! Ayo bermain!';
}
