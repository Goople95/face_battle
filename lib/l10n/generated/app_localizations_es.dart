// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Dice Girls';

  @override
  String get gameNameChinese => 'Dados Mentirosos';

  @override
  String get loginTitle => 'Bienvenido';

  @override
  String get loginWithGoogle => 'Iniciar sesión con Google';

  @override
  String get loginWithFacebook => 'Iniciar sesión con Facebook';

  @override
  String get skipLogin => 'Omitir';

  @override
  String get or => 'O';

  @override
  String get selectOpponent => 'Seleccionar Oponente';

  @override
  String get vipOpponents => 'Oponentes VIP';

  @override
  String get gameInstructions => 'Cómo Jugar';

  @override
  String get instructionsContent =>
      'Cada jugador lanza 5 dados en secreto. Se turnan para apostar sobre el número total de dados. ¡Desafía si crees que están mintiendo!\n\n• Los 1 son comodines y cuentan como cualquier número\n• Una vez que alguien apuesta por 1s, pierden su estatus de comodín en esa ronda';

  @override
  String get playerStats => 'Estadísticas del Jugador';

  @override
  String get wins => 'Victorias';

  @override
  String get losses => 'Derrotas';

  @override
  String get winRate => 'Tasa de Victoria';

  @override
  String get level => 'Nivel';

  @override
  String intimacyLevel(Object level) {
    return 'Intimidad Nv.$level';
  }

  @override
  String drinkCapacity(Object current, Object max) {
    return '$current/$max bebidas';
  }

  @override
  String soberTimeRemaining(Object time) {
    return 'Sobrio en $time';
  }

  @override
  String aboutMinutes(Object minutes) {
    return 'Unos $minutes min';
  }

  @override
  String get startGame => 'Iniciar Juego';

  @override
  String get continueGame => 'Continuar';

  @override
  String get newGame => 'Nuevo Juego';

  @override
  String get exitGame => 'Salir del Juego';

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma';

  @override
  String get soundEffects => 'Efectos de Sonido';

  @override
  String get music => 'Música';

  @override
  String get on => 'Activado';

  @override
  String get off => 'Desactivado';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get confirmLogout => '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get networkError => 'Fallo de conexión de red';

  @override
  String get unknownError => 'Ocurrió un error desconocido';

  @override
  String get yourTurn => 'Tu Turno';

  @override
  String opponentTurn(Object name) {
    return 'Turno de $name';
  }

  @override
  String get bid => 'Apostar';

  @override
  String get challenge => 'Desafiar';

  @override
  String currentBid(Object dice, Object quantity) {
    return 'Apuesta Actual: $quantity × $dice';
  }

  @override
  String get selectBid => 'Selecciona Tu Apuesta';

  @override
  String get quantity => 'Cantidad';

  @override
  String get diceValue => 'Valor del Dado';

  @override
  String get youWin => '¡Ganaste!';

  @override
  String get youLose => '¡Perdiste!';

  @override
  String get drink => '¡Bebe!';

  @override
  String get cheers => '¡Salud!';

  @override
  String get drunkWarning => '¡Estás demasiado borracho para continuar!';

  @override
  String get soberUp => 'Espera para estar sobrio o mira un anuncio';

  @override
  String get watchAd => 'Ver Anuncio';

  @override
  String waitTime(Object minutes) {
    return 'Espera $minutes minutos';
  }

  @override
  String get unlockVIP => 'Desbloquear VIP';

  @override
  String get vipBenefits => 'Beneficios VIP';

  @override
  String get noAds => 'Sin Anuncios';

  @override
  String get exclusiveContent => 'Personajes Exclusivos';

  @override
  String get bonusRewards => 'Recompensas Extra';

  @override
  String price(Object amount) {
    return 'Precio: $amount';
  }

  @override
  String get purchase => 'Comprar';

  @override
  String get restorePurchases => 'Restaurar Compras';

  @override
  String get share => 'Compartir';

  @override
  String get shareMessage => '¡Acabo de ganar en Dice Girls! ¿Puedes vencerme?';

  @override
  String get rateApp => 'Calificar App';

  @override
  String get feedback => 'Comentarios';

  @override
  String version(Object version) {
    return 'Versión $version';
  }

  @override
  String get allDiceValues => 'Todos los dados';

  @override
  String get onesLoseWildcard => '¡Los 1 ya no son comodines!';

  @override
  String get wildcardActive => 'Los 1 cuentan como cualquier número';

  @override
  String get tutorialTitle => 'Tutorial';

  @override
  String get skipTutorial => 'Omitir';

  @override
  String get next => 'Siguiente';

  @override
  String get previous => 'Anterior';

  @override
  String get done => 'Hecho';

  @override
  String get connectionLost => 'Conexión perdida';

  @override
  String get reconnecting => 'Reconectando...';

  @override
  String get loginSuccess => 'Inicio de sesión exitoso';

  @override
  String get loginFailed => 'Inicio de sesión fallido';

  @override
  String get guestMode => 'Modo Invitado';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get forgotPassword => '¿Olvidaste tu Contraseña?';

  @override
  String get rememberMe => 'Recuérdame';

  @override
  String get termsOfService => 'Términos de Servicio';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String agreeToTerms(Object privacy, Object terms) {
    return 'Al continuar, aceptas nuestros $terms y $privacy';
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
  String get playerDiceLabel => 'Tus dados';

  @override
  String aiDiceLabel(Object name) {
    return 'Dados de $name';
  }

  @override
  String bidCall(Object quantity, Object value) {
    return 'Bid: $quantity×$value';
  }

  @override
  String challengeSuccessRateDisplay(Object rate) {
    return 'Tasa de éxito: $rate%';
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
      '¡Usaste poción de sobriedad, despejaste 2 bebidas!';

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
    return '$name está pensando...';
  }

  @override
  String get pleaseBid => 'Por favor apuesta';

  @override
  String get showDice => '¡Mostrar dados!';

  @override
  String get challengeOpponent => 'Desafiar apuesta del oponente';

  @override
  String challengePlayerBid(Object quantity, Object value) {
    return 'Desafiar apuesta del jugador: $quantity×$value';
  }

  @override
  String get playerShowDice => '¡El jugador muestra los dados!';

  @override
  String aiShowDice(Object name) {
    return '¡$name muestra los dados!';
  }

  @override
  String get soberOptions => 'Opciones para desembriagar';

  @override
  String get adLoadFailed => 'Error al cargar el anuncio';

  @override
  String get adWatchedSober => '✨ ¡Anuncio visto, completamente sobrio!';

  @override
  String aiSoberedUp(Object name) {
    return '✨ ¡$name se desembriagó, continúa el juego!';
  }

  @override
  String get challengeProbability => 'Probabilidad de desafío';

  @override
  String get challengeWillSucceed => 'El desafío tendrá éxito';

  @override
  String get challengeWillFail => 'El desafío fallará';

  @override
  String get challengeSuccessRate => 'Tasa de éxito del desafío';

  @override
  String aiDecisionProcess(Object name) {
    return 'Proceso de decisión de $name';
  }

  @override
  String challengePlayerBidAction(Object quantity, Object value) {
    return 'Desafiar apuesta del jugador: $quantity×$value';
  }

  @override
  String get challengeOpponentAction => 'Desafiar apuesta del oponente';

  @override
  String openingBidAction(Object quantity, Object value) {
    return 'Apuesta inicial: $quantity×$value';
  }

  @override
  String respondToBidAction(
    Object aiQuantity,
    Object aiValue,
    Object playerQuantity,
    Object playerValue,
  ) {
    return 'Responder a $playerQuantity×$playerValue del jugador, apostar: $aiQuantity×$aiValue';
  }

  @override
  String get continueBiddingAction => 'Continuar apostando';

  @override
  String get challengeProbabilityLog =>
      'Cálculo de probabilidad de desafío (Perspectiva del jugador)';

  @override
  String get challengeWillDefinitelySucceed =>
      'El desafío definitivamente tendrá éxito';

  @override
  String get challengeWillDefinitelyFail =>
      'El desafío definitivamente fallará';

  @override
  String get challengeProbabilityResult =>
      'Resultado de probabilidad de desafío';

  @override
  String get challengeSuccessRateValue => 'Tasa de éxito del desafío';

  @override
  String get challenger => 'Retador';

  @override
  String get intimacyTip => '¡Emboráchame para aumentar la intimidad~!';

  @override
  String get gameGreeting => '¡Bienvenido! ¡Juguemos!';
}
