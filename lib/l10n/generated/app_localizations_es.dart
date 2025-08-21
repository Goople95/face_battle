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
      'Cada jugador lanza 5 dados en secreto. Se turnan para apostar sobre el número total de dados. ¡Desafía si crees que están mintiendo!';

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
}
