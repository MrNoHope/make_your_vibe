import '../controllers/app_locale_controller.dart';

class AppTexts {
  static String appTitle(AppLanguage language) {
    return 'Make Your Vibe';
  }

  static String appSubtitle(AppLanguage language) {
    return language == AppLanguage.vi
        ? 'Chọn mood. Bật nhạc. Tạo vibe riêng.'
        : 'Pick a mood. Press play. Make it yours.';
  }

  static String languageTitle(AppLanguage language) {
    return language == AppLanguage.vi ? 'Ngôn ngữ' : 'Language';
  }

  static String vietnamese(AppLanguage language) {
    return language == AppLanguage.vi ? 'Tiếng Việt' : 'Vietnamese';
  }

  static String english(AppLanguage language) {
    return language == AppLanguage.vi ? 'Tiếng Anh' : 'English';
  }

  static String musicLayer(AppLanguage language) {
    return language == AppLanguage.vi ? 'Nhạc chính' : 'Music';
  }

  static String ambientLayer(AppLanguage language) {
    return language == AppLanguage.vi ? 'Âm nền' : 'Ambient';
  }

  static String personalMixer(AppLanguage language) {
    return language == AppLanguage.vi ? 'Bộ trộn âm thanh' : 'Sound Mixer';
  }

  static String nowPlaying(AppLanguage language) {
    return language == AppLanguage.vi ? 'Đang phát' : 'Now Playing';
  }

  static String madeForYourVibe(AppLanguage language) {
    return language == AppLanguage.vi
        ? 'Dành cho vibe của bạn'
        : 'Made for your vibe';
  }

  static String yourMix(AppLanguage language) {
    return language == AppLanguage.vi ? 'Bản phối hiện tại' : 'Your mix';
  }
}