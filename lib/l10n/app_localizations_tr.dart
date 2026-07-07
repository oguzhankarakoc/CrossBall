// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'CrossBall';

  @override
  String get tagline => 'Kulüpleri bağla. Futbol zekânı kanıtla.';

  @override
  String get homeTitle => 'CrossBall';

  @override
  String get dailyChallenge => 'Günlük Mücadele';

  @override
  String get dailyChallengeDesc => 'Günde bir bulmaca. Serini oluştur.';

  @override
  String dailyRefreshSchedule(String localTime, String countdown) {
    return 'Yerel saatinizle $localTime\'de güncellenir (00:00 UTC) · Sonraki: $countdown';
  }

  @override
  String get dailyPuzzleRefreshTitle => 'Bugünün bulmacası hazırlanıyor';

  @override
  String get dailyPuzzleRefreshBody =>
      'Her gün UTC gece yarısında kulüp verilerini yenileyip yeni global ızgara oluşturuyoruz. Yeni bulmaca gelene kadar dünkü bulmaca kapalıdır.';

  @override
  String dailyPuzzleRefreshElapsed(String elapsed) {
    return 'Hazırlanıyor: $elapsed';
  }

  @override
  String get dailyPuzzleRefreshWindowHint =>
      'Bu işlem genelde birkaç dakika sürer. Sabrınız için teşekkürler.';

  @override
  String dailyPuzzleRefreshAutoHint(int seconds) {
    return '$seconds sn sonra otomatik tekrar kontrol edeceğiz.';
  }

  @override
  String get dailyPuzzleRefreshCheckAgain => 'Tekrar kontrol et';

  @override
  String get dailyPuzzleRefreshRetry => 'Yeniden dene';

  @override
  String get dailyPuzzleRefreshFailedTitle =>
      'Bugünün bulmacası henüz hazır değil';

  @override
  String get dailyPuzzleRefreshFailedBody =>
      'Yenileme sonrası bugünün bulmacası yayınlanamadı. Tekrar deneyebilirsiniz — arka planda güvenli bir yedek denemesi yapılır.';

  @override
  String get dailyPuzzleRefreshHomeSubtitle =>
      'Yeni bulmaca yolda — 00:00 UTC yenilemesi devam ediyor.';

  @override
  String get dailyPuzzleRefreshHomeHint => 'Bugünün bulmacası hazırlanıyor…';

  @override
  String get dailyPuzzleRefreshBadge => 'Yenileniyor';

  @override
  String get friendChallenge => 'Arkadaş Mücadelesi';

  @override
  String get friendChallengeDesc => 'Link paylaş ve async yarış.';

  @override
  String get practice => 'Antrenman';

  @override
  String get practiceDesc =>
      'Günde 5 antrenman. Sonraki oturumlar için reklam izle.';

  @override
  String get stats => 'İstatistikler';

  @override
  String get activeEvents => 'Aktif Etkinlikler';

  @override
  String get eventLockedBadge => 'Yakında';

  @override
  String get eventLockedMessage =>
      'Bu etkinlik için özel kulüp ızgaraları henüz hazır değil. Takipte kal!';

  @override
  String get communityGoals => 'Topluluk Hedefleri';

  @override
  String get maintenanceNotice => 'Bakım';

  @override
  String get maintenanceNoticeBody =>
      'Bazı hizmetler sınırlı olabilir. Bulmaca oynamaya devam edebilirsiniz.';

  @override
  String get settings => 'Ayarlar';

  @override
  String get premium => 'Premium';

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingStart => 'Hadi Oynayalım';

  @override
  String get onboarding1Title => 'Bir hücre seç';

  @override
  String get onboarding1Body => 'Çözmeye başlamak için bir hücreye dokun.';

  @override
  String get onboarding2Title => 'İki kulübü bağla';

  @override
  String get onboarding2Body => 'Her iki kulüpte de oynamış bir futbolcu bul.';

  @override
  String get onboarding3Title => 'Nadir seçimler daha çok puan';

  @override
  String get onboarding3Body =>
      'Daha az bilinen oyuncular daha fazla puan verir.';

  @override
  String get comingSoon => 'Yükleniyor...';

  @override
  String get puzzleLoadFailed =>
      'Günün bulmacası yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get practiceLoadFailed =>
      'Antrenman bulmacası yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get gamesPlayed => 'Oynanan Oyun';

  @override
  String get level => 'Seviye';

  @override
  String get experiencePoints => 'XP';

  @override
  String get competitiveRating => 'Derece';

  @override
  String get league => 'Lig';

  @override
  String get currentStreak => 'Mevcut Seri';

  @override
  String get bestStreak => 'En İyi Seri';

  @override
  String get totalScore => 'Toplam Puan';

  @override
  String get rarityBreakdown => 'Nadirlik Dağılımı';

  @override
  String get createChallenge => 'Mücadele Oluştur';

  @override
  String get createChallengeDesc =>
      'Önce bugünün bulmacasını çöz, sonra skorunu paylaş.';

  @override
  String get joinChallenge => 'Mücadeleye Katıl';

  @override
  String get challengeDesc =>
      'Arkadaşlarına async meydan oku. Aynı bulmaca, skorları karşılaştır.';

  @override
  String get challengeCodeHint => 'Mücadele kodunu gir';

  @override
  String get copyLink => 'Linki Kopyala';

  @override
  String get share => 'Paylaş';

  @override
  String get copied => 'Link kopyalandı!';

  @override
  String get language => 'Dil';

  @override
  String get premiumTitle => 'CrossBall Premium';

  @override
  String get premiumDesc =>
      'Günde 10 reklamsız antrenman, gelişmiş istatistikler, reklamsız.';

  @override
  String get upgradePremium => 'Premium\'a Yükselt';

  @override
  String get searchPlayer => 'Oyuncu ara...';

  @override
  String get recentPicks => 'Son seçimler';

  @override
  String get popularPicks => 'Popüler seçimler';

  @override
  String get suggestedForCell => 'Bu hücre için önerilen';

  @override
  String get noPlayersFound => 'Oyuncu bulunamadı';

  @override
  String get puzzleComplete => 'Bulmaca Tamamlandı!';

  @override
  String get backToHome => 'Ana Sayfaya Dön';

  @override
  String get mistakes => 'Hatalar';

  @override
  String get hintsUsed => 'Kullanılan ipuçları';

  @override
  String get score => 'Puan';

  @override
  String get correct => 'Doğru';

  @override
  String get incorrect => 'Yanlış';

  @override
  String get tier => 'Seviye';

  @override
  String usedBy(String percent) {
    return '%$percent tarafından seçildi';
  }

  @override
  String get continueButton => 'Devam';

  @override
  String get appearance => 'Görünüm';

  @override
  String get themeSystem => 'Sistem Varsayılanı';

  @override
  String get themeDark => 'Dark Stadium';

  @override
  String get themeLight => 'Light Pitch';

  @override
  String get themeSystemDesc => 'Cihaz görünümünü takip et';

  @override
  String get themeDarkDesc =>
      'Siyah saha, stadyum ışıkları, saha yeşili vurgular';

  @override
  String get themeLightDesc => 'Yumuşak saha yeşili, premium altın vurgular';

  @override
  String get localeSystem => 'Sistem varsayılanı';

  @override
  String get localeEnglish => 'English';

  @override
  String get localeTurkish => 'Türkçe';

  @override
  String get localeGerman => 'Deutsch';

  @override
  String get hintNationality => 'Milliyet ipucu için reklam izle';

  @override
  String get hintPosition => 'Pozisyon ipucu için reklam izle';

  @override
  String get hintFirstLetter => 'İlk harf ipucu için reklam izle';

  @override
  String get hintCareerLeague => 'Kariyer ligi ipucu için reklam izle';

  @override
  String get hintRetiredStatus => 'Aktif/emekli ipucu için reklam izle';

  @override
  String get hintCareerClub => 'Kulüp ipucu için reklam izle';

  @override
  String get hintNationalityPremium => 'Milliyet ipucunu göster';

  @override
  String get hintPositionPremium => 'Pozisyon ipucunu göster';

  @override
  String get hintFirstLetterPremium => 'İlk harf ipucunu göster';

  @override
  String get hintCareerLeaguePremium => 'Lig ipucunu göster';

  @override
  String get hintRetiredStatusPremium => 'Aktif/emekli ipucunu göster';

  @override
  String get hintCareerClubPremium => 'Kulüp ipucunu göster';

  @override
  String get searchCompetitiveEmpty =>
      'Oyuncu adını yazarak ara. İpuçları için yukarıdaki butonu kullan.';

  @override
  String get practiceLimitReached =>
      'Bugünkü antrenman hakkın bitti. Yarın tekrar dene veya Premium\'a yükselt.';

  @override
  String get practiceAdRequiredTitle => 'Sonraki antrenman';

  @override
  String get practiceAdRequired =>
      'Yeni bir antrenman için kısa bir reklam izlemen gerekiyor.';

  @override
  String get practiceWatchAdForNewSession => 'Reklam izle — yeni antrenman';

  @override
  String get practiceNewSession => 'Yeni antrenman';

  @override
  String get practiceCompleteDesc =>
      'Her antrenmanda farklı takım kombinasyonları.';

  @override
  String get practiceFinishTraining => 'Antrenmanı bitir';

  @override
  String get practiceFinishConfirmTitle => 'Antrenmanı bitir?';

  @override
  String get practiceFinishConfirmBody =>
      'Bu oturum sona erer ve günlük antrenman hakkından 1 düşer.';

  @override
  String get practiceResultTitle => 'Antrenman tamamlandı';

  @override
  String get practiceResultEarlyDesc =>
      'Erken bitirdin — skorun ve ilerlemen kaydedildi.';

  @override
  String practiceSessionProgress(int current, int limit) {
    return 'Antrenman $current/$limit';
  }

  @override
  String practiceDailyProgress(int used, int limit) {
    return 'Bugün $used/$limit antrenman kullanıldı';
  }

  @override
  String get practiceAdGateHint =>
      'Ücretsiz planda sonraki antrenmanlar için kısa bir reklam izlemen gerekir.';

  @override
  String get practicePremiumSkipAds =>
      'Premium ile reklam beklemeden günde 10 antrenman.';

  @override
  String get cancel => 'Vazgeç';

  @override
  String practiceSessionsRemaining(int count) {
    return 'Bugün $count antrenman hakkın kaldı';
  }

  @override
  String get premiumFeatureGrid => '4×4 premium ızgaralar';

  @override
  String get premiumFeaturePractice => 'Günde 10 reklamsız antrenman';

  @override
  String get premiumFeatureStats => 'Gelişmiş istatistikler';

  @override
  String get premiumFeatureThemes => 'Özel temalar';

  @override
  String get premiumFeatureNoAds => 'Reklamsız';

  @override
  String get premiumActivated => 'Premium aktif!';

  @override
  String get premiumActive => 'Premium aktif';

  @override
  String get premiumPurchaseFailed =>
      'Premium etkinleştirilemedi. Lütfen tekrar deneyin.';

  @override
  String get premiumVerificationFailed =>
      'Satın alma doğrulanamadı. Satın Alımları Geri Yükle\'yi deneyin veya destekle iletişime geçin.';

  @override
  String get premiumPurchaseUnavailable =>
      'Premium mağazada henüz kullanılamıyor. App Store kurulumunu kontrol edin.';

  @override
  String get premiumDevNotConfigured =>
      'Sunucuda geliştirici premium kapalı. Supabase\'de IAP_SKIP_VERIFY=true ayarlayın veya IAP_ENABLED=true ile StoreKit kullanın.';

  @override
  String get premiumPurchasePending =>
      'Bekleyen App Store satın alımı tamamlanıyor. Biraz bekleyip tekrar deneyin veya Satın Alımları Geri Yükle\'ye basın.';

  @override
  String get restorePurchases => 'Satın alımları geri yükle';

  @override
  String get completeDailyFirst =>
      'Mücadele oluşturmak için önce bugünün günlük bulmacasını tamamla.';

  @override
  String get challengeYouWon => 'Mücadeleyi kazandın!';

  @override
  String get challengeYouLost => 'Bu turu kaybettin.';

  @override
  String get challengeTie => 'Berabere!';

  @override
  String get challengeCreator => 'Oluşturan';

  @override
  String get challengeYou => 'Sen';

  @override
  String get playerNickname => 'Takma ad';

  @override
  String get playerNicknameDesc =>
      'Mücadeleler ve sıralamalarda görünecek isteğe bağlı isim.';

  @override
  String get playerNicknameHint => '3–20 karakter';

  @override
  String get playerNicknameSaved => 'Takma ad kaydedildi';

  @override
  String get playerNicknameTaken => 'Bu takma ad zaten kullanılıyor';

  @override
  String get playerNicknameInvalid =>
      '3–20 harf, rakam, nokta, tire veya alt çizgi kullanın';

  @override
  String get gridSelectCell => 'SEÇ';

  @override
  String get achievements => 'Başarımlar';

  @override
  String get achievementPoints => 'Başarım Puanı';

  @override
  String get achievementUnlocked => 'Başarım açıldı!';

  @override
  String get noAchievementsYet => 'Başarımları açmak için bulmacaları tamamla.';

  @override
  String get dailyMissions => 'Günlük Görevler';

  @override
  String missionsProgress(int completed, int total) {
    return '$completed/$total tamamlandı';
  }

  @override
  String get shareResult => 'Sonucu paylaş';

  @override
  String get leaderboard => 'Sıralama';

  @override
  String get leaderboardEmpty =>
      'Henüz sıralama yok. Listeye girmek için bulmaca tamamla.';

  @override
  String get pushNotifications => 'Bildirimler';

  @override
  String get pushNotificationsOn => 'Seri hatırlatıcıları açık';

  @override
  String get pushNotificationsOff => 'Bildirimler kapalı';

  @override
  String get hintAdRequired => 'Bu ipucu için reklam izlemen gerekiyor.';

  @override
  String get errorGeneric => 'Bir şeyler ters gitti. Lütfen tekrar dene.';

  @override
  String get errorNetwork => 'Ağ hatası. Bağlantını kontrol et.';

  @override
  String get themeDarkGold => 'Altın Stadyum';

  @override
  String get themeLightClassic => 'Klasik Saha';

  @override
  String get themeDarkGoldDesc => 'Premium: altın vurgulu karanlık stadyum';

  @override
  String get themeLightClassicDesc => 'Premium: altın vurgulu klasik açık saha';

  @override
  String get mythicCelebration => 'MİTİK!';

  @override
  String get mythicCelebrationBody => 'Ultra nadir seçim — elit futbol zekası.';

  @override
  String get challengeFromAnySession =>
      'Son tamamladığın bulmacayı arkadaşınla paylaş.';

  @override
  String get challengeNeedSession =>
      'Mücadele için önce herhangi bir bulmacayı tamamla.';

  @override
  String get challengeRematch => 'Rövanş — yeni link paylaş';

  @override
  String get dailyChallengeEasyDesc =>
      'Öğrenirken daha kolay bulmaca — serini koru.';

  @override
  String seasonPoints(int points) {
    return '$points SP';
  }

  @override
  String seasonNextReward(int points, String reward) {
    return 'Sonraki ödül $points SP: $reward';
  }

  @override
  String get clubMastery => 'Kulüp Ustalığı';

  @override
  String get clubMasteryEmpty => 'Kesişim çözerek kulüp ustalığını artır.';

  @override
  String get hintCareerClubTaste =>
      'Haftalık ücretsiz deneme: başka bir kulüp ipucu';

  @override
  String get practiceGrid4Title => '4×4 Premium Izgara';

  @override
  String get practiceGrid4Desc =>
      'Daha fazla kulüp kombinasyonu ile büyük ızgara.';

  @override
  String get premiumGridRequired => '4×4 ızgaralar Premium özelliğidir.';

  @override
  String get timelineMode => 'Zaman Çizelgesi Antrenmanı';

  @override
  String get timelineModeDesc =>
      'Her doğru cevaptan sonra kariyer yıllarını gör.';

  @override
  String timelineSheetTitle(String name) {
    return '$name — kariyer zaman çizelgesi';
  }

  @override
  String get timelineEmpty => 'Bu oyuncu için kariyer verisi yok.';

  @override
  String get present => 'Günümüz';

  @override
  String get activityFeed => 'Topluluk Aktivitesi';

  @override
  String activityDailyCompleted(String name, String score) {
    return '$name günlük bulmacayı tamamladı ($score puan)';
  }

  @override
  String activityChallengeCompleted(String name) {
    return '$name bir arkadaş mücadelesi bitirdi';
  }

  @override
  String activityTimelineCompleted(String name, String score) {
    return '$name zaman çizelgesi antrenmanını bitirdi ($score puan)';
  }

  @override
  String activityGeneric(String name, String action) {
    return '$name: $action';
  }

  @override
  String get footballFactTitle => 'Biliyor muydun?';

  @override
  String get footballFactTip1 =>
      'İki kulübün kesişiminde az bilinen isimler çoğu zaman daha yüksek puan getirir — cesur tahminler seni öne taşır.';

  @override
  String get footballFactTip2 =>
      'Futbol IQ sadece yıldızları bilmek değil; gizli kariyer patikalarını hatırlamaktır.';

  @override
  String get footballFactTip3 =>
      'Kulüp rozetlerine değil, hafızana güven. Nadir cevaplar liderlik tablosunun anahtarıdır.';

  @override
  String get footballFactTip4 =>
      'Popüler isimler kolay puan vermez — derinlerdeki isimler parlar.';

  @override
  String get footballFactTip5 =>
      'Her hücre bir futbol hikâyesi saklar. Doğru oyuncu, doğru kesişim noktasıdır.';

  @override
  String get footballFactTimeline1 =>
      'Zaman çizelgesinde doğru yıl, doğru oyuncuyu bulmanın anahtarıdır — kariyer sırasını iyi oku.';

  @override
  String get footballFactTimeline2 =>
      'Transfer yıllarına dikkat et; bir sezon farkı bazen tüm tabloyu değiştirir.';

  @override
  String get footballFactTimeline3 =>
      'Kronoloji modunda hızlı hatırlama kazanır — kulüp dönemlerini zihninde sırala.';

  @override
  String get tournament => 'Turnuva';

  @override
  String get tournamentDesc => 'Haftalık yüksek skor yarışması';

  @override
  String get tournamentInactive =>
      'Şu an aktif turnuva yok. Yakında tekrar bak.';

  @override
  String get tournamentEmpty => 'Henüz skor yok — ilk sen oyna!';

  @override
  String tournamentYourRank(int rank) {
    return 'Sıralaman: #$rank';
  }
}
