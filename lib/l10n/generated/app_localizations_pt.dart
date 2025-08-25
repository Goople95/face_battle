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
      'Cada jogador lança 5 dados secretamente. Revezem-se apostando no número total de dados. Desafie se achar que estão mentindo!\n\n• Os 1s são curingas e contam como qualquer número\n• Quando alguém apostar em 1s, eles perdem o status de curinga naquela rodada';

  @override
  String get playerStats => 'Estatísticas do Jogador';

  @override
  String get wins => 'Vitórias';

  @override
  String get losses => 'Derrotas';

  @override
  String get winRate => 'Taxa de Vitória';

  @override
  String get totalWins => 'Vitórias';

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
  String aiWins(Object name) {
    return '$name venceu!';
  }

  @override
  String get drink => 'Beba!';

  @override
  String get cheers => 'Saúde!';

  @override
  String get drunkWarning => 'Você está bêbado demais para continuar!';

  @override
  String get drunkWarningTitle => '🥴 Aviso de Embriaguez!';

  @override
  String drinksConsumedMessage(int count) {
    return 'Você bebeu $count doses';
  }

  @override
  String soberPotionRemaining(int count) {
    return 'Restam $count garrafas';
  }

  @override
  String drunkDescription(String name) {
    return '$name olha para você embriagada';
  }

  @override
  String get soberOptions => 'Opções para ficar sóbrio';

  @override
  String get drunkStatusDeadDrunk => 'Bêbado morto';

  @override
  String get drunkStatusDizzy => 'Tonto de bêbado';

  @override
  String get drunkStatusObvious => 'Obviamente bêbado';

  @override
  String get drunkStatusTipsy => 'Alegre';

  @override
  String get drunkStatusSlightly => 'Levemente bêbado';

  @override
  String get drunkStatusOneDrink => 'Uma dose';

  @override
  String get drunkStatusSober => 'Sóbrio';

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
  String get unlockVIPCharacter => 'Desbloquear Personagem VIP';

  @override
  String get chooseUnlockMethod =>
      'Escolha um método para desbloquear este personagem VIP';

  @override
  String get freePlayOneHour => 'Jogue grátis por 1 hora';

  @override
  String get permanentUnlock => 'Desbloqueio Permanente';

  @override
  String gemsRequired(Object required, Object current) {
    return '$required gemas (você tem $current gemas)';
  }

  @override
  String get laterDecide => 'Talvez mais tarde';

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
  String get shareSubject => 'Dice Girls - Vitória Perfeita!';

  @override
  String shareTemplate1(String name, int drinks, int minutes) {
    return '🎉 Embebedei $name no Dice Girls! $drinks bebidas no total, $minutes minutos a sós~ #DiceGirls #VitóriaPerfeita';
  }

  @override
  String shareTemplate2(String name, int drinks, int minutes) {
    return '🏆 Relatório de Vitória: $name caiu! $drinks bebidas consumidas, intimidade +$minutes! Quem se atreve? #DiceGirls';
  }

  @override
  String shareTemplate3(String name, int drinks, int minutes) {
    return '😎 Vitória fácil contra $name! Apenas $drinks bebidas e ficou fora, conversamos $minutes minutos~ #DiceGirls';
  }

  @override
  String shareTemplate4(String name, int drinks, int minutes) {
    return '🍺 O MVP desta noite sou eu! $name desmaiou após $drinks bebidas, os próximos $minutes minutos... você sabe 😏 #DiceGirls';
  }

  @override
  String get shareCardDrunk => 'Bêbado';

  @override
  String get shareCardIntimacy => 'Intimidade';

  @override
  String shareCardPrivateTime(int minutes) {
    return 'Tempo a sós: $minutes minutos';
  }

  @override
  String shareCardDrinkCount(int count) {
    return '$count bebidas para desmaiar';
  }

  @override
  String get shareCardGameName => 'Dice Girls';

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

  @override
  String get playerDataAnalysis => 'Suas Estatísticas';

  @override
  String get vsRecord => 'Registro de Batalhas';

  @override
  String get gameStyle => 'Estilo de Jogo';

  @override
  String get bluffingTendency => 'Taxa de Blefe';

  @override
  String get aggressiveness => 'Agressividade';

  @override
  String get challengeRate => 'Taxa de Desafio';

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
    return '$count jogos';
  }

  @override
  String get win => 'V';

  @override
  String get lose => 'D';

  @override
  String get debugTool => 'Ferramenta de Depuração';

  @override
  String get noVIPCharacters => 'Sem Personagens VIP';

  @override
  String minutes(Object count) {
    return '$count minutos';
  }

  @override
  String get sober => 'Sóbrio';

  @override
  String get useSoberPotion => 'Usar Poção de Sobriedade';

  @override
  String get close => 'Fechar';

  @override
  String aiIsDrunk(Object name) {
    return '$name está bêbada';
  }

  @override
  String get aiDrunkMessage =>
      'Ela está bêbada demais para jogar\nAjude-a a ficar sóbria';

  @override
  String get watchAdToSober => 'Assistir Anúncio';

  @override
  String languageSwitched(Object language) {
    return 'Idioma alterado';
  }

  @override
  String get instructionsDetail => 'Instruções detalhadas';

  @override
  String get yourDice => 'Seus Dados';

  @override
  String get playerDiceLabel => 'Seus dados';

  @override
  String aiDiceLabel(Object name) {
    return 'Dados de $name';
  }

  @override
  String bidCall(Object quantity, Object value) {
    return 'Aposta';
  }

  @override
  String challengeSuccessRateDisplay(Object rate) {
    return 'Chance de sucesso: $rate%';
  }

  @override
  String get bidMustBeHigher => 'A aposta deve ser maior';

  @override
  String get roundEnd => 'Fim da Rodada';

  @override
  String roundNumber(int number) {
    return 'Rodada $number';
  }

  @override
  String nextBidHint(int quantity, int value) {
    return 'Próxima: qtd > $quantity ou valor > $value';
  }

  @override
  String get backToHome => 'Voltar ao Início';

  @override
  String get playAgain => 'Jogar Novamente';

  @override
  String get shareResult => 'Compartilhar Resultado';

  @override
  String aiThinking(Object name) {
    return '$name está pensando...';
  }

  @override
  String get bidHistory => 'Histórico de Apostas';

  @override
  String get completeBidHistory => 'Histórico Completo';

  @override
  String get totalGamesCount => 'Total de Jogos';

  @override
  String get watchAdSuccess => '✨ Anúncio assistido, completamente sóbrio!';

  @override
  String get usedSoberPotion =>
      'Usou poção de sobriedade, ficou sóbrio de 2 bebidas!';

  @override
  String aiSoberSuccess(Object name) {
    return '✨ $name está sóbria!';
  }

  @override
  String get drunkStatus =>
      'Você está bêbado demais para continuar!\nVocê precisa ficar sóbrio';

  @override
  String get soberTip => '💡 Dica: Naturalmente sóbrio 1 bebida a cada 10 min';

  @override
  String get watchAdToSoberTitle => 'Assistir Anúncio para Ficar Sóbrio';

  @override
  String get returnToHome => 'Voltar para casa, ficar sóbrio naturalmente';

  @override
  String get youRolled => 'Você tirou';

  @override
  String aiRolled(Object name) {
    return '$name tirou';
  }

  @override
  String get myDice => 'Meus Dados';

  @override
  String get challenging => 'Desafiando';

  @override
  String get gameTips => 'Dicas do Jogo';

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
    return 'Tempo privado: $minutes minutos';
  }

  @override
  String get victory => 'Vitória';

  @override
  String intimacyLevelShort(Object level) {
    return 'Nv.$level';
  }

  @override
  String get watchAdUnlock => 'Assistir Anúncio';

  @override
  String drunkAndWon(Object name) {
    return '$name desmaiou, você ganhou!';
  }

  @override
  String get copiedToClipboard => 'Copiado para a área de transferência';

  @override
  String pleaseWaitThinking(Object name) {
    return '$name está pensando...';
  }

  @override
  String get pleaseBid => 'Faça sua aposta';

  @override
  String get showDice => 'Mostrar dados!';

  @override
  String get challengeOpponent => 'Desafiar aposta do oponente';

  @override
  String challengePlayerBid(Object quantity, Object value) {
    return 'Desafiar aposta do jogador: $quantity×$value';
  }

  @override
  String get playerShowDice => 'Jogador mostra os dados!';

  @override
  String aiShowDice(Object name) {
    return '$name mostra os dados!';
  }

  @override
  String get adLoadFailed => 'Falha ao carregar anúncio';

  @override
  String get adLoadFailedTryLater =>
      'Falha ao carregar anúncio, tente novamente';

  @override
  String get adWatchedSober => '✨ Anúncio assistido, completamente sóbrio!';

  @override
  String aiSoberedUp(Object name) {
    return '✨ $name ficou sóbrio, continue o jogo!';
  }

  @override
  String get minimumBidTwo => 'Aposta mínima é 2';

  @override
  String languageChanged(Object language) {
    return 'Idioma alterado para $language';
  }

  @override
  String tempUnlocked(Object name) {
    return '✨ $name desbloqueado temporariamente por 1 hora';
  }

  @override
  String permanentUnlocked(Object name) {
    return '🎉 $name desbloqueado permanentemente';
  }

  @override
  String get screenshotSaved => 'Captura salva!';

  @override
  String get challengeProbability => 'Probabilidade de desafio';

  @override
  String get challengeWillSucceed => 'O desafio terá sucesso';

  @override
  String get challengeWillFail => 'O desafio falhará';

  @override
  String get challengeSuccessRate => 'Taxa de sucesso do desafio';

  @override
  String aiDecisionProcess(Object name) {
    return 'Processo de decisão de $name';
  }

  @override
  String challengePlayerBidAction(Object quantity, Object value) {
    return 'Desafiar aposta do jogador: $quantity×$value';
  }

  @override
  String get challengeOpponentAction => 'Desafiar aposta do oponente';

  @override
  String openingBidAction(Object quantity, Object value) {
    return 'Aposta inicial: $quantity×$value';
  }

  @override
  String respondToBidAction(
    Object aiQuantity,
    Object aiValue,
    Object playerQuantity,
    Object playerValue,
  ) {
    return 'Responder a $playerQuantity×$playerValue do jogador, apostar: $aiQuantity×$aiValue';
  }

  @override
  String get continueBiddingAction => 'Continuar apostando';

  @override
  String get challengeProbabilityLog =>
      'Cálculo de probabilidade de desafio (Perspectiva do jogador)';

  @override
  String get challengeWillDefinitelySucceed =>
      'O desafio definitivamente terá sucesso';

  @override
  String get challengeWillDefinitelyFail => 'O desafio definitivamente falhará';

  @override
  String get challengeProbabilityResult =>
      'Resultado da probabilidade de desafio';

  @override
  String get challengeSuccessRateValue => 'Taxa de sucesso do desafio';

  @override
  String get challenger => 'Desafiador';

  @override
  String get intimacyTip => 'Me deixe bêbado para aumentar a intimidade~';

  @override
  String get gameGreeting => 'Bem-vindo! Vamos jogar!';

  @override
  String aiBidFormat(int quantity, int value) {
    return '$quantity $value';
  }

  @override
  String get defaultChallenge => 'Não acredito';

  @override
  String get defaultValueBet => 'Firme';

  @override
  String get defaultSemiBluff => 'Vamos tentar';

  @override
  String get defaultBluff => 'É assim';

  @override
  String get defaultReverseTrap => 'Não... tenho certeza';

  @override
  String get defaultPressurePlay => 'Hora de decidir';

  @override
  String get defaultSafePlay => 'Jogando seguro';

  @override
  String get defaultPatternBreak => 'Vamos mudar';

  @override
  String get defaultInduceAggressive => 'Vamos lá';

  @override
  String get wildcard => 'Curinga';

  @override
  String get notWildcard => 'Não curinga';

  @override
  String wildcardWithCount(int count) {
    return '(+$count×1)';
  }

  @override
  String get noWildcard => '(sem curingas)';

  @override
  String currentBidDisplay(int quantity, int value) {
    return '$quantity $value';
  }

  @override
  String bidLabel(int quantity, int value) {
    return 'Aposta: $quantity $value';
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
  String get nightFall => '🌙 Está tarde...';

  @override
  String aiGotDrunk(String name) {
    return '$name está bêbada';
  }

  @override
  String get timePassesBy => 'O tempo passa silenciosamente';

  @override
  String aiAndYou(String name) {
    return '$name e você...';
  }

  @override
  String get relationshipCloser => 'Mais próximos';

  @override
  String get tapToContinue => 'Toque para continuar';

  @override
  String intimacyIncreased(int points) {
    return 'Intimidade +$points';
  }

  @override
  String get intimacyGrowing => 'Crescendo...';

  @override
  String currentProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get maxLevel => 'MÁX';

  @override
  String get upgradeToKnowMore =>
      'Suba de nível para conhecer mais segredos dela';

  @override
  String get youKnowAllSecrets => 'Você já conhece todos os segredos dela';

  @override
  String get congratsIntimacyUpgrade => 'Intimidade +1 nível!';

  @override
  String get showOff => 'Exibir';

  @override
  String get continueButton => 'Continuar';

  @override
  String get rematch => 'Revanche';

  @override
  String get perfectVictory => '🏆 Vitória Perfeita!';

  @override
  String get sharingImage => 'Compartilhando imagem';

  @override
  String get loadingAvatar => 'Carregando avatar...';

  @override
  String get generatingShareImage => 'Gerando imagem de compartilhamento...';

  @override
  String get challengeNow => 'Desafiar Agora';

  @override
  String get gameSlogan => '100+ esperando seu desafio';
}
