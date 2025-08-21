// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Dice Girls';

  @override
  String get gameNameChinese => 'Dados Mentirosos';

  @override
  String get loginTitle => 'Bem-vindo';

  @override
  String get loginWithGoogle => 'Entrar com Google';

  @override
  String get loginWithFacebook => 'Entrar com Facebook';

  @override
  String get skipLogin => 'Pular';

  @override
  String get or => 'OU';

  @override
  String get selectOpponent => 'Selecionar Oponente';

  @override
  String get vipOpponents => 'Oponentes VIP';

  @override
  String get gameInstructions => 'Como Jogar';

  @override
  String get instructionsContent =>
      'Cada jogador lança 5 dados secretamente. Revezem-se apostando no número total de dados. Desafie se achar que estão mentindo!';

  @override
  String get playerStats => 'Estatísticas do Jogador';

  @override
  String get wins => 'Vitórias';

  @override
  String get losses => 'Derrotas';

  @override
  String get winRate => 'Taxa de Vitória';

  @override
  String get level => 'Nível';

  @override
  String intimacyLevel(Object level) {
    return 'Intimidade Nv.$level';
  }

  @override
  String drinkCapacity(Object current, Object max) {
    return '$current/$max bebidas';
  }

  @override
  String soberTimeRemaining(Object time) {
    return 'Sóbrio em $time';
  }

  @override
  String aboutMinutes(Object minutes) {
    return 'Cerca de $minutes min';
  }

  @override
  String get startGame => 'Iniciar Jogo';

  @override
  String get continueGame => 'Continuar';

  @override
  String get newGame => 'Novo Jogo';

  @override
  String get exitGame => 'Sair do Jogo';

  @override
  String get settings => 'Configurações';

  @override
  String get language => 'Idioma';

  @override
  String get soundEffects => 'Efeitos Sonoros';

  @override
  String get music => 'Música';

  @override
  String get on => 'Ligado';

  @override
  String get off => 'Desligado';

  @override
  String get logout => 'Sair';

  @override
  String get confirmLogout => 'Tem certeza que deseja sair?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get loading => 'Carregando...';

  @override
  String get error => 'Erro';

  @override
  String get networkError => 'Falha na conexão de rede';

  @override
  String get unknownError => 'Ocorreu um erro desconhecido';

  @override
  String get yourTurn => 'Sua Vez';

  @override
  String opponentTurn(Object name) {
    return 'Vez de $name';
  }

  @override
  String get bid => 'Apostar';

  @override
  String get challenge => 'Desafiar';

  @override
  String currentBid(Object dice, Object quantity) {
    return 'Aposta Atual: $quantity × $dice';
  }

  @override
  String get selectBid => 'Selecione Sua Aposta';

  @override
  String get quantity => 'Quantidade';

  @override
  String get diceValue => 'Valor do Dado';

  @override
  String get youWin => 'Você Ganhou!';

  @override
  String get youLose => 'Você Perdeu!';

  @override
  String get drink => 'Beba!';

  @override
  String get cheers => 'Saúde!';

  @override
  String get drunkWarning => 'Você está bêbado demais para continuar!';

  @override
  String get soberUp => 'Espere ficar sóbrio ou assista um anúncio';

  @override
  String get watchAd => 'Assistir Anúncio';

  @override
  String waitTime(Object minutes) {
    return 'Aguarde $minutes minutos';
  }

  @override
  String get unlockVIP => 'Desbloquear VIP';

  @override
  String get vipBenefits => 'Benefícios VIP';

  @override
  String get noAds => 'Sem Anúncios';

  @override
  String get exclusiveContent => 'Personagens Exclusivos';

  @override
  String get bonusRewards => 'Recompensas Extras';

  @override
  String price(Object amount) {
    return 'Preço: $amount';
  }

  @override
  String get purchase => 'Comprar';

  @override
  String get restorePurchases => 'Restaurar Compras';

  @override
  String get share => 'Compartilhar';

  @override
  String get shareMessage =>
      'Acabei de ganhar no Dice Girls! Você consegue me vencer?';

  @override
  String get rateApp => 'Avaliar App';

  @override
  String get feedback => 'Feedback';

  @override
  String version(Object version) {
    return 'Versão $version';
  }

  @override
  String get allDiceValues => 'Todos os dados';

  @override
  String get onesLoseWildcard => '1s não são mais curingas!';

  @override
  String get wildcardActive => '1s contam como qualquer número';

  @override
  String get tutorialTitle => 'Tutorial';

  @override
  String get skipTutorial => 'Pular';

  @override
  String get next => 'Próximo';

  @override
  String get previous => 'Anterior';

  @override
  String get done => 'Concluído';

  @override
  String get connectionLost => 'Conexão perdida';

  @override
  String get reconnecting => 'Reconectando...';

  @override
  String get loginSuccess => 'Login bem-sucedido';

  @override
  String get loginFailed => 'Falha no login';

  @override
  String get guestMode => 'Modo Convidado';

  @override
  String get createAccount => 'Criar Conta';

  @override
  String get forgotPassword => 'Esqueceu a Senha?';

  @override
  String get rememberMe => 'Lembrar-me';

  @override
  String get termsOfService => 'Termos de Serviço';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String agreeToTerms(Object privacy, Object terms) {
    return 'Ao continuar, você concorda com nossos $terms e $privacy';
  }
}
