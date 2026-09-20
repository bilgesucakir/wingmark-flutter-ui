import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';

/// Hand-written localization (English/Turkish, mirroring the Swift app's
/// AppLanguage) — no arb/gen-l10n step, since that requires running the
/// `flutter` tool, which isn't available in this environment yet.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('tr')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get code => locale.languageCode == 'tr' ? 'tr' : 'en';

  String _t(String en, String tr) => code == 'tr' ? tr : en;

  // Tabs
  String get tabMap => _t('Map', 'Harita');
  String get tabGuide => _t('Guide', 'Rehber');
  String get tabDiary => _t('Diary', 'Günlük');
  String get tabBadges => _t('Badges', 'Rozetler');
  String get tabProfile => _t('Profile', 'Profil');

  // Auth
  String get appTagline =>
      _t('Log the birds you have seen, anywhere on a map.',
          'Gördüğün kuşları haritada, her yerde günlüğüne yaz.');
  String get email => _t('Email', 'E-posta');
  String get password => _t('Password', 'Şifre');
  String get logIn => _t('Log In', 'Giriş Yap');
  String get noAccountSignUp =>
      _t("Don't have an account? Sign Up", 'Hesabın yok mu? Kayıt Ol');
  String get username => _t('Username', 'Kullanıcı adı');
  String get firstName => _t('First Name', 'Ad');
  String get lastName => _t('Last Name', 'Soyad');
  String get signUp => _t('Sign Up', 'Kayıt Ol');
  String get haveAccountLogIn =>
      _t('Already have an account? Log In', 'Zaten hesabın var mı? Giriş Yap');
  String get passwordHint => _t(
      'Username: 3-30 characters. Password: at least 8 characters with a letter and a number.',
      'Kullanıcı adı: 3-30 karakter. Şifre: en az 8 karakter, bir harf ve bir rakam içermeli.');
  String get verifyEmailTitle => _t('Verify your email', 'E-postanı doğrula');
  String get verifyEmailBody => _t(
      "We've sent a verification link to your email. Please verify to continue.",
      'E-postana bir doğrulama bağlantısı gönderdik. Devam etmek için lütfen doğrula.');
  String get resendVerification =>
      _t('Resend verification email', 'Doğrulama e-postasını yeniden gönder');
  String get verificationResent =>
      _t('Verification email sent.', 'Doğrulama e-postası gönderildi.');
  String get logOut => _t('Log Out', 'Çıkış Yap');

  // Map
  String get mapTitle => _t('Map', 'Harita');
  String get mapEmpty =>
      _t('No sightings logged yet', 'Henüz gözlem eklenmedi');

  // Guide
  String get guideTitle => _t('Guide', 'Rehber');
  String get searchSpecies => _t('Search species', 'Tür ara');
  String get noSpeciesFound => _t('No species found', 'Tür bulunamadı');
  String get soundsTitle => _t('Sounds', 'Sesler');
  String get noSounds =>
      _t('No recordings available', 'Kayıt bulunamadı');

  // Diary
  String get diaryTitle => _t('Diary', 'Günlük');
  String get diaryEmpty =>
      _t('No sightings yet — tap + to log one', 'Henüz gözlem yok — eklemek için + dokun');
  String get notSureYet => _t('Not sure yet', 'Henüz emin değilim');

  // Add sighting
  String get addSightingTitle => _t('New Sighting', 'Yeni Gözlem');
  String get editSightingTitle => _t('Edit Sighting', 'Gözlemi Düzenle');
  String get sectionWhenWhere => _t('When & Where', 'Ne Zaman & Nerede');
  String get date => _t('Date', 'Tarih');
  String get locationName => _t('Location name', 'Konum adı');
  String get useCurrentLocation =>
      _t('Use current location', 'Mevcut konumu kullan');
  String get tapMapToAdjust =>
      _t('Tap the map to adjust the pin', 'Pini ayarlamak için haritaya dokun');
  String get sectionSpecies => _t('Species', 'Tür');
  String get doNotKnowSpecies =>
      _t("I don't know — that's okay", 'Bilmiyorum — sorun değil');
  String get sectionStatus => _t('How sure are you?', 'Ne kadar eminsin?');
  String get sectionLifeStage => _t('Life Stage', 'Yaşam Evresi');
  String get sectionGender => _t('Gender', 'Cinsiyet');
  String get sectionPet => _t('This is a pet', 'Bu bir evcil hayvan');
  String get sectionCustomName => _t('Custom name (optional)', 'Özel isim (opsiyonel)');
  String get sectionNotes => _t('Notes', 'Notlar');
  String get sectionPhoto => _t('Photo', 'Fotoğraf');
  String get addPhoto => _t('Add photo', 'Fotoğraf ekle');
  String get removePhoto => _t('Remove photo', 'Fotoğrafı kaldır');
  String get sectionVisibility => _t('Visibility', 'Görünürlük');
  String get visibilityPublic => _t('Public', 'Herkese açık');
  String get visibilityPrivate => _t('Private', 'Özel');
  String get save => _t('Save', 'Kaydet');
  String get cancel => _t('Cancel', 'İptal');
  String get locationRequired =>
      _t('Location is required to save a sighting.', 'Bir gözlem kaydetmek için konum gerekli.');

  // Badges
  String get badgesTitle => _t('Badges', 'Rozetler');

  // Profile
  String get profileTitle => _t('Profile', 'Profil');
  String joined(String date) => _t('Joined $date', '$date tarihinde katıldı');
  String get sightingsCount => _t('Sightings', 'Gözlemler');
  String get speciesCount => _t('Species', 'Türler');
  String get editProfileTitle => _t('Edit Profile', 'Profili Düzenle');
  String get favoriteSpecies => _t('Favorite species', 'Favori tür');
  String get noFavoriteSpecies =>
      _t('No favorite species set', 'Favori tür seçilmedi');
  String get chooseFavoriteSpecies =>
      _t('Choose favorite species', 'Favori tür seç');

  // Settings
  String get settingsTitle => _t('Settings', 'Ayarlar');
  String get language => _t('Language', 'Dil');
  String get languageFooter =>
      _t('Changes take effect immediately.', 'Değişiklikler hemen uygulanır.');
  String get units => _t('Units', 'Birimler');
  String get distance => _t('Distance', 'Mesafe');

  // Generic
  String get retry => _t('Retry', 'Tekrar dene');
  String get somethingWentWrong =>
      _t('Something went wrong.', 'Bir şeyler ters gitti.');
  String get wakingServer => _t(
      'Waking up the server — this can take up to a minute…',
      'Sunucu uyandırılıyor — bu bir dakikaya kadar sürebilir…');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
