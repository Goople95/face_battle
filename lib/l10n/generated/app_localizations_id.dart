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
  String get totalWins => 'Menang';

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
  String aiWins(Object name) {
    return '$name menang!';
  }

  @override
  String get drink => 'Minum!';

  @override
  String get cheers => 'Bersulang!';

  @override
  String get drunkWarning => 'Anda terlalu mabuk untuk melanjutkan!';

  @override
  String get drunkWarningTitle => '🥴 Peringatan Mabuk!';

  @override
  String drinksConsumedMessage(int count) {
    return 'Anda sudah minum $count gelas';
  }

  @override
  String soberPotionRemaining(int count) {
    return 'Tersisa $count botol';
  }

  @override
  String drunkDescription(String name) {
    return '$name menatapmu dengan tatapan mabuk';
  }

  @override
  String get soberOptions => 'Opsi untuk sadar';

  @override
  String get drunkStatusDeadDrunk => 'Mabuk berat';

  @override
  String get drunkStatusDizzy => 'Mabuk pusing';

  @override
  String get drunkStatusObvious => 'Jelas mabuk';

  @override
  String get drunkStatusTipsy => 'Sedikit mabuk';

  @override
  String get drunkStatusSlightly => 'Agak mabuk';

  @override
  String get drunkStatusOneDrink => 'Satu gelas';

  @override
  String get drunkStatusSober => 'Sadar';

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
  String get unlockVIPCharacter => 'Buka Karakter VIP';

  @override
  String get chooseUnlockMethod => 'Pilih cara untuk membuka karakter VIP ini';

  @override
  String get freePlayOneHour => 'Main gratis selama 1 jam';

  @override
  String get permanentUnlock => 'Buka Permanen';

  @override
  String gemsRequired(Object required, Object current) {
    return '$required permata (kamu punya $current permata)';
  }

  @override
  String get laterDecide => 'Mungkin nanti';

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
  String get shareSubject => 'Dice Girls - Kemenangan Sempurna!';

  @override
  String shareTemplate1(String name, int drinks, int minutes) {
    return '🎉 Saya membuat $name mabuk di Dice Girls! Total $drinks minuman, $minutes menit berduaan~ #DiceGirls #KemenanganSempurna';
  }

  @override
  String shareTemplate2(String name, int drinks, int minutes) {
    return '🏆 Laporan Kemenangan: $name tumbang! $drinks minuman dikonsumsi, keintiman +$minutes! Siapa yang berani? #DiceGirls';
  }

  @override
  String shareTemplate3(String name, int drinks, int minutes) {
    return '😎 Mudah menang melawan $name! Hanya $drinks minuman dan mereka pingsan, kami ngobrol $minutes menit~ #DiceGirls';
  }

  @override
  String shareTemplate4(String name, int drinks, int minutes) {
    return '🍺 MVP malam ini adalah saya! $name pingsan setelah $drinks minuman, $minutes menit berikutnya... kamu tahu 😏 #DiceGirls';
  }

  @override
  String get shareCardDrunk => 'Mabuk';

  @override
  String get shareCardIntimacy => 'Keintiman';

  @override
  String shareCardPrivateTime(int minutes) {
    return 'Waktu berduaan: $minutes menit';
  }

  @override
  String shareCardDrinkCount(int count) {
    return '$count minuman sampai pingsan';
  }

  @override
  String get shareCardGameName => 'Dice Girls';

  @override
  String get rateApp => 'Nilai Aplikasi';

  @override
  String get feedback => 'Umpan Balik';

  @override
  String get version => 'Versi';

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
  String get playerDataAnalysis => 'Statistik Anda';

  @override
  String get vsRecord => 'Catatan Pertempuran';

  @override
  String get gameStyle => 'Gaya Bermain';

  @override
  String get bluffingTendency => 'Tingkat Gertakan';

  @override
  String get aggressiveness => 'Agresivitas';

  @override
  String get bluffLabel => 'Gertakan';

  @override
  String get aggressiveLabel => 'Agresif';

  @override
  String get challengeRate => 'Tingkat Tantangan';

  @override
  String get styleNovice => 'Pemula';

  @override
  String get styleBluffMaster => 'Master Gertakan';

  @override
  String get styleBluffer => 'Penggertak';

  @override
  String get styleHonest => 'Stabil';

  @override
  String get styleAggressive => 'Berani';

  @override
  String get styleOffensive => 'Ofensif';

  @override
  String get styleConservative => 'Strategis';

  @override
  String get styleChallenger => 'Penantang';

  @override
  String get styleCautious => 'Taktis';

  @override
  String get styleBalanced => 'Seimbang';

  @override
  String totalGames(Object count) {
    return '$count permainan';
  }

  @override
  String get win => 'M';

  @override
  String get lose => 'K';

  @override
  String get debugTool => 'Alat Debug';

  @override
  String get noVIPCharacters => 'Tidak Ada Karakter VIP';

  @override
  String minutes(Object count) {
    return '$count menit';
  }

  @override
  String get sober => 'Sadar';

  @override
  String get useSoberPotion => 'Gunakan Ramuan Sadar';

  @override
  String get close => 'Tutup';

  @override
  String aiIsDrunk(Object name) {
    return '$name sedang mabuk';
  }

  @override
  String get aiDrunkMessage =>
      'Dia terlalu mabuk untuk bermain\nBantu dia sadar';

  @override
  String get watchAdToSober => 'Tonton Iklan';

  @override
  String languageSwitched(Object language) {
    return 'Bahasa diubah';
  }

  @override
  String get instructionsDetail => 'Instruksi detail';

  @override
  String get yourDice => 'Dadu Anda';

  @override
  String get playerDiceLabel => 'Anda';

  @override
  String aiDiceLabel(Object name) {
    return '$name';
  }

  @override
  String bidCall(Object quantity, Object value) {
    return 'Taruhan';
  }

  @override
  String challengeSuccessRateDisplay(Object rate) {
    return 'Peluang sukses: $rate%';
  }

  @override
  String get bidMustBeHigher => 'Taruhan harus lebih tinggi';

  @override
  String get roundEnd => 'Akhir Putaran';

  @override
  String roundNumber(int number) {
    return 'Putaran $number';
  }

  @override
  String nextBidHint(int quantity, int value) {
    return 'Berikutnya: jml > $quantity atau nilai > $value';
  }

  @override
  String get backToHome => 'Kembali ke Beranda';

  @override
  String get playAgain => 'Main Lagi';

  @override
  String get shareResult => 'Bagikan Hasil';

  @override
  String aiThinking(Object name) {
    return '$name sedang berpikir...';
  }

  @override
  String get bidHistory => 'Riwayat Taruhan';

  @override
  String get completeBidHistory => 'Riwayat Lengkap';

  @override
  String roundsCount(int count) {
    return '$count ronde';
  }

  @override
  String get totalGamesCount => 'Total Permainan';

  @override
  String get watchAdSuccess => '✨ Iklan ditonton, sepenuhnya sadar!';

  @override
  String get usedSoberPotion =>
      'Menggunakan ramuan sadar, membersihkan 2 minuman!';

  @override
  String aiSoberSuccess(Object name) {
    return '✨ $name sudah sadar!';
  }

  @override
  String get drunkStatus =>
      'Anda terlalu mabuk untuk melanjutkan!\nAnda perlu sadar';

  @override
  String get soberTip =>
      '💡 Tips: Secara alami sadar 1 minuman setiap 10 menit';

  @override
  String get watchAdToSoberTitle => 'Tonton Iklan untuk Sadar';

  @override
  String get returnToHome => 'Kembali ke rumah, sadar secara alami';

  @override
  String get youRolled => 'Anda melempar';

  @override
  String aiRolled(Object name) {
    return '$name melempar';
  }

  @override
  String get myDice => 'Dadu Saya';

  @override
  String get challenging => 'Menantang';

  @override
  String get gameTips => 'Tips Permainan';

  @override
  String userIdPrefix(Object id) {
    return 'ID:';
  }

  @override
  String get vipLabel => 'VIP';

  @override
  String tempUnlockTime(Object minutes) {
    return '$minutes menit';
  }

  @override
  String privateTime(Object minutes) {
    return 'Waktu pribadi: $minutes menit';
  }

  @override
  String get victory => 'Kemenangan';

  @override
  String intimacyLevelShort(Object level) {
    return 'Lv.$level';
  }

  @override
  String get watchAdUnlock => 'Tonton Iklan';

  @override
  String drunkAndWon(Object name) {
    return '$name pingsan, Anda menang!';
  }

  @override
  String get copiedToClipboard => 'Disalin ke papan klip';

  @override
  String pleaseWaitThinking(Object name) {
    return '$name sedang berpikir...';
  }

  @override
  String get pleaseBid => 'Buat taruhanmu';

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
  String get adLoadFailed => 'Gagal memuat iklan';

  @override
  String get adLoadFailedTryLater => 'Gagal memuat iklan, coba lagi nanti';

  @override
  String get adWatchedSober => '✨ Iklan ditonton, sepenuhnya sadar!';

  @override
  String aiSoberedUp(Object name) {
    return '✨ $name sadar, lanjutkan permainan!';
  }

  @override
  String get minimumBidTwo => 'Taruhan minimum adalah 2';

  @override
  String languageChanged(Object language) {
    return 'Bahasa diubah ke $language';
  }

  @override
  String tempUnlocked(Object name) {
    return '✨ $name dibuka sementara selama 1 jam';
  }

  @override
  String permanentUnlocked(Object name) {
    return '🎉 $name berhasil dibuka permanen';
  }

  @override
  String get screenshotSaved => 'Tangkapan layar tersimpan!';

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

  @override
  String aiBidFormat(int quantity, int value) {
    return '$quantity angka $value';
  }

  @override
  String get defaultChallenge => 'Saya tidak percaya';

  @override
  String get defaultValueBet => 'Mantap';

  @override
  String get defaultSemiBluff => 'Coba saja';

  @override
  String get defaultBluff => 'Begitu saja';

  @override
  String get defaultReverseTrap => 'Saya... tidak yakin';

  @override
  String get defaultPressurePlay => 'Saatnya memutuskan';

  @override
  String get defaultSafePlay => 'Main aman';

  @override
  String get defaultPatternBreak => 'Ganti cara';

  @override
  String get defaultInduceAggressive => 'Ayo';

  @override
  String get wildcard => 'Wildcard';

  @override
  String get notWildcard => 'Bukan wildcard';

  @override
  String wildcardWithCount(int count) {
    return '(+$count×1)';
  }

  @override
  String get noWildcard => '(tanpa wildcard)';

  @override
  String currentBidDisplay(int quantity, int value) {
    return '$quantity $value';
  }

  @override
  String bidLabel(int quantity, int value) {
    return 'Taruhan: $quantity $value';
  }

  @override
  String actualLabel(int count, int value) {
    return 'Aktual: $count $value';
  }

  @override
  String get bidShort => 'Taruhan';

  @override
  String get actualShort => 'Aktual';

  @override
  String get inclShort => 'tmsk.';

  @override
  String quantityDisplay(int quantity) {
    return '$quantity';
  }

  @override
  String get nightFall => '🌙 Malam larut...';

  @override
  String aiGotDrunk(String name) {
    return '$name mabuk';
  }

  @override
  String get timePassesBy => 'Waktu berlalu diam-diam';

  @override
  String aiAndYou(String name) {
    return '$name dan kamu...';
  }

  @override
  String get relationshipCloser => 'Semakin dekat';

  @override
  String get tapToContinue => 'Ketuk untuk lanjut';

  @override
  String intimacyIncreased(int points) {
    return 'Keintiman +$points';
  }

  @override
  String get intimacyGrowing => 'Bertumbuh...';

  @override
  String currentProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get maxLevel => 'MAKS';

  @override
  String get upgradeToKnowMore =>
      'Naik level untuk tahu lebih banyak rahasianya';

  @override
  String get youKnowAllSecrets => 'Kamu sudah tahu semua rahasianya';

  @override
  String get congratsIntimacyUpgrade => 'Keintiman +1 level!';

  @override
  String get showOff => 'Pamer';

  @override
  String get continueButton => 'Lanjut';

  @override
  String get rematch => 'Main Lagi';

  @override
  String get perfectVictory => '🏆 Kemenangan Sempurna!';

  @override
  String get sharingImage => 'Membagikan gambar';

  @override
  String get loadingAvatar => 'Memuat avatar...';

  @override
  String get generatingShareImage => 'Membuat gambar untuk dibagikan...';

  @override
  String get challengeNow => 'Tantang Sekarang';

  @override
  String get gameSlogan => '100+ menunggu tantangan Anda';

  @override
  String get youGotDrunk => 'Anda mabuk!';

  @override
  String get watchAdToSoberSubtitle => 'Gratis, langsung sadar';

  @override
  String get goHomeToRest => 'Pulang untuk Istirahat';
}
