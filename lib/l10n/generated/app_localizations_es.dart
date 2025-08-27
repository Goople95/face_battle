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
  String get totalWins => 'Victorias';

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
  String aiWins(Object name) {
    return '¡$name gana!';
  }

  @override
  String get drink => '¡Bebe!';

  @override
  String get cheers => '¡Salud!';

  @override
  String get drunkWarning => '¡Estás demasiado borracho para continuar!';

  @override
  String get drunkWarningTitle => '🥴 ¡Advertencia de borrachera!';

  @override
  String drinksConsumedMessage(int count) {
    return 'Has tomado $count bebidas';
  }

  @override
  String soberPotionRemaining(int count) {
    return 'Quedan $count botellas';
  }

  @override
  String drunkDescription(String name) {
    return '$name te mira con ojos ebrios';
  }

  @override
  String get soberOptions => 'Opciones para desembriagar';

  @override
  String get drunkStatusDeadDrunk => 'Borracho perdido';

  @override
  String get drunkStatusDizzy => 'Mareado';

  @override
  String get drunkStatusObvious => 'Obviamente borracho';

  @override
  String get drunkStatusTipsy => 'Achispado';

  @override
  String get drunkStatusSlightly => 'Ligeramente ebrio';

  @override
  String get drunkStatusOneDrink => 'Una copa';

  @override
  String get drunkStatusSober => 'Sobrio';

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
  String get unlockVIPCharacter => 'Desbloquear Personaje VIP';

  @override
  String get chooseUnlockMethod =>
      'Elige un método para desbloquear este personaje VIP';

  @override
  String get freePlayOneHour => 'Juega gratis por 1 hora';

  @override
  String get permanentUnlock => 'Desbloqueo Permanente';

  @override
  String gemsRequired(Object required, Object current) {
    return '$required gemas (tienes $current gemas)';
  }

  @override
  String get laterDecide => 'Tal vez más tarde';

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
  String get shareSubject => 'Dice Girls - ¡Victoria Perfecta!';

  @override
  String shareTemplate1(String name, int drinks, int minutes) {
    return '🎉 ¡Emborraché a $name en Dice Girls! $drinks bebidas en total, $minutes minutos a solas~ #DiceGirls #VictoriaPerfecta';
  }

  @override
  String shareTemplate2(String name, int drinks, int minutes) {
    return '🏆 Reporte de Victoria: ¡$name cayó! $drinks bebidas consumidas, intimidad +$minutes! ¿Quién se atreve? #DiceGirls';
  }

  @override
  String shareTemplate3(String name, int drinks, int minutes) {
    return '😎 Fácil victoria contra $name! Solo $drinks bebidas y quedó fuera, charlamos $minutes minutos~ #DiceGirls';
  }

  @override
  String shareTemplate4(String name, int drinks, int minutes) {
    return '🍺 ¡El MVP de esta noche soy yo! $name se desmayó después de $drinks bebidas, los siguientes $minutes minutos... ya sabes 😏 #DiceGirls';
  }

  @override
  String get shareCardDrunk => 'Borracho';

  @override
  String get shareCardIntimacy => 'Intimidad';

  @override
  String shareCardPrivateTime(int minutes) {
    return 'Tiempo a solas: $minutes minutos';
  }

  @override
  String shareCardDrinkCount(int count) {
    return '$count bebidas para desmayarse';
  }

  @override
  String get shareCardGameName => 'Dice Girls';

  @override
  String get rateApp => 'Calificar App';

  @override
  String get feedback => 'Comentarios';

  @override
  String get version => 'Versión';

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
  String get playerDataAnalysis => 'Tus Estadísticas';

  @override
  String get vsRecord => 'Registro de Batallas';

  @override
  String get gameStyle => 'Estilo de Juego';

  @override
  String get bluffingTendency => 'Tasa de Farol';

  @override
  String get aggressiveness => 'Agresión';

  @override
  String get challengeRate => 'Tasa de Desafío';

  @override
  String get styleNovice => 'Novice';

  @override
  String get styleBluffMaster => 'Bluff Master';

  @override
  String get styleBluffer => 'Bluffer';

  @override
  String get styleHonest => 'Honest';

  @override
  String get styleAggressive => 'Aggressive';

  @override
  String get styleOffensive => 'Offensive';

  @override
  String get styleConservative => 'Conservative';

  @override
  String get styleChallenger => 'Challenger';

  @override
  String get styleCautious => 'Cautious';

  @override
  String get styleBalanced => 'Balanced';

  @override
  String totalGames(Object count) {
    return '$count juegos';
  }

  @override
  String get win => 'V';

  @override
  String get lose => 'D';

  @override
  String get debugTool => 'Herramienta de Depuración';

  @override
  String get noVIPCharacters => 'Sin Personajes VIP';

  @override
  String minutes(Object count) {
    return '$count minutos';
  }

  @override
  String get sober => 'Despejar';

  @override
  String get useSoberPotion => 'Usar Poción de Sobriedad';

  @override
  String get close => 'Cerrar';

  @override
  String aiIsDrunk(Object name) {
    return '$name está borracha';
  }

  @override
  String get aiDrunkMessage =>
      'Está demasiado borracha para jugar\nAyúdala a despejarse';

  @override
  String get watchAdToSober => 'Ver Anuncio';

  @override
  String languageSwitched(Object language) {
    return 'Idioma cambiado';
  }

  @override
  String get instructionsDetail => 'Instrucciones detalladas';

  @override
  String get yourDice => 'Tus Dados';

  @override
  String get playerDiceLabel => 'Tus dados';

  @override
  String aiDiceLabel(Object name) {
    return 'Dados de $name';
  }

  @override
  String bidCall(Object quantity, Object value) {
    return 'Apuesta';
  }

  @override
  String challengeSuccessRateDisplay(Object rate) {
    return 'Probabilidad de éxito: $rate%';
  }

  @override
  String get bidMustBeHigher => 'La apuesta debe ser mayor';

  @override
  String get roundEnd => 'Fin de Ronda';

  @override
  String roundNumber(int number) {
    return 'Ronda $number';
  }

  @override
  String nextBidHint(int quantity, int value) {
    return 'Siguiente: cant > $quantity o valor > $value';
  }

  @override
  String get backToHome => 'Volver al Inicio';

  @override
  String get playAgain => 'Jugar de Nuevo';

  @override
  String get shareResult => 'Compartir Resultado';

  @override
  String aiThinking(Object name) {
    return '$name está pensando...';
  }

  @override
  String get bidHistory => 'Historial de Apuestas';

  @override
  String get completeBidHistory => 'Historial Completo';

  @override
  String get totalGamesCount => 'Total de Juegos';

  @override
  String get watchAdSuccess => '✨ Anuncio visto, completamente sobrio!';

  @override
  String get usedSoberPotion =>
      '¡Usaste poción de sobriedad, despejaste 2 bebidas!';

  @override
  String aiSoberSuccess(Object name) {
    return '✨ ¡$name está sobria!';
  }

  @override
  String get drunkStatus =>
      '¡Estás demasiado borracho para continuar!\nNecesitas despejarte';

  @override
  String get soberTip => '💡 Consejo: Naturalmente sobrio 1 bebida cada 10 min';

  @override
  String get watchAdToSoberTitle => 'Ver Anuncio para Despejar';

  @override
  String get returnToHome => 'Volver a casa, naturalmente sobrio';

  @override
  String get youRolled => 'Sacaste';

  @override
  String aiRolled(Object name) {
    return '$name sacó';
  }

  @override
  String get myDice => 'Mis Dados';

  @override
  String get challenging => 'Desafiando';

  @override
  String get gameTips => 'Consejos del Juego';

  @override
  String userIdPrefix(Object id) {
    return 'ID:';
  }

  @override
  String get vipLabel => 'VIP';

  @override
  String tempUnlockTime(Object minutes) {
    return '$minutes min';
  }

  @override
  String privateTime(Object minutes) {
    return 'Tiempo privado: $minutes minutos';
  }

  @override
  String get victory => 'Victoria';

  @override
  String intimacyLevelShort(Object level) {
    return 'Nv.$level';
  }

  @override
  String get watchAdUnlock => 'Ver Anuncio';

  @override
  String drunkAndWon(Object name) {
    return '$name se desmayó, ¡ganaste!';
  }

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String pleaseWaitThinking(Object name) {
    return '$name está pensando...';
  }

  @override
  String get pleaseBid => 'Haz tu apuesta';

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
  String get adLoadFailed => 'Error al cargar el anuncio';

  @override
  String get adLoadFailedTryLater =>
      'Error al cargar el anuncio, inténtalo de nuevo';

  @override
  String get adWatchedSober => '✨ ¡Anuncio visto, completamente sobrio!';

  @override
  String aiSoberedUp(Object name) {
    return '✨ ¡$name se desembriagó, continúa el juego!';
  }

  @override
  String get minimumBidTwo => 'La apuesta mínima es 2';

  @override
  String languageChanged(Object language) {
    return 'Idioma cambiado a $language';
  }

  @override
  String tempUnlocked(Object name) {
    return '✨ $name desbloqueado temporalmente por 1 hora';
  }

  @override
  String permanentUnlocked(Object name) {
    return '🎉 $name desbloqueado permanentemente';
  }

  @override
  String get screenshotSaved => '¡Captura guardada!';

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

  @override
  String aiBidFormat(int quantity, int value) {
    return '$quantity $value';
  }

  @override
  String get defaultChallenge => 'No te creo';

  @override
  String get defaultValueBet => 'Seguro';

  @override
  String get defaultSemiBluff => 'Probemos';

  @override
  String get defaultBluff => 'Así es';

  @override
  String get defaultReverseTrap => 'No... estoy seguro';

  @override
  String get defaultPressurePlay => 'Hora de decidir';

  @override
  String get defaultSafePlay => 'Jugando seguro';

  @override
  String get defaultPatternBreak => 'Cambiemos';

  @override
  String get defaultInduceAggressive => 'Vamos';

  @override
  String get wildcard => 'Comodín';

  @override
  String get notWildcard => 'No comodín';

  @override
  String wildcardWithCount(int count) {
    return '(+$count×1)';
  }

  @override
  String get noWildcard => '(sin comodines)';

  @override
  String currentBidDisplay(int quantity, int value) {
    return '$quantity $value';
  }

  @override
  String bidLabel(int quantity, int value) {
    return 'Apuesta: $quantity $value';
  }

  @override
  String actualLabel(int count, int value) {
    return 'Real: $count $value';
  }

  @override
  String quantityDisplay(int quantity) {
    return '$quantity';
  }

  @override
  String get nightFall => '🌙 Es tarde...';

  @override
  String aiGotDrunk(String name) {
    return '$name está borracha';
  }

  @override
  String get timePassesBy => 'El tiempo pasa silenciosamente';

  @override
  String aiAndYou(String name) {
    return '$name y tú...';
  }

  @override
  String get relationshipCloser => 'Más cerca';

  @override
  String get tapToContinue => 'Toca para continuar';

  @override
  String intimacyIncreased(int points) {
    return 'Intimidad +$points';
  }

  @override
  String get intimacyGrowing => 'Creciendo...';

  @override
  String currentProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get maxLevel => 'MÁX';

  @override
  String get upgradeToKnowMore =>
      'Sube de nivel para conocer más de sus secretos';

  @override
  String get youKnowAllSecrets => 'Ya conoces todos sus secretos';

  @override
  String get congratsIntimacyUpgrade => '¡Intimidad +1 nivel!';

  @override
  String get showOff => 'Presumir';

  @override
  String get continueButton => 'Continuar';

  @override
  String get rematch => 'Revancha';

  @override
  String get perfectVictory => '🏆 ¡Victoria Perfecta!';

  @override
  String get sharingImage => 'Compartiendo imagen';

  @override
  String get loadingAvatar => 'Cargando avatar...';

  @override
  String get generatingShareImage => 'Generando imagen para compartir...';

  @override
  String get challengeNow => 'Desafiar Ahora';

  @override
  String get gameSlogan => '100+ esperando tu desafío';
}
