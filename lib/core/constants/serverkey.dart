/// Centralized Server and Database Keys for Firebase Firestore & Storage.
/// Super global data (Amols, Surahs, Duas, Common Categories, Prayer Timings, FCM)
/// are governed by these keys.
library;

class ServerKey {
  // -------------------------------------------------------------
  // FIRESTORE COLLECTIONS
  // -------------------------------------------------------------
  static const String colSuperGlobal = 'super_global';
  static const String colAppConfig = 'app_config';
  static const String colFamilies = 'families';
  static const String colUsers = 'users';
  static const String colFamilyInvitations = 'family_invitations';
  static const String colSosAlerts = 'sos_alerts';

  // Sub-collections under families/{familyId}/...
  static const String subColExpenses = 'expenses';
  static const String subColCategories = 'categories';
  static const String subColNotifications = 'notifications';
  static const String subColMessages = 'messages';
  static const String subColMembers = 'members';
  static const String subColReminders = 'reminders';
  static const String subColPrayerAlarms = 'prayer_alarms';
  static const String subColAmols = 'amols';

  // -------------------------------------------------------------
  // SUPER GLOBAL & APP CONFIG DOCUMENTS
  // -------------------------------------------------------------
  static const String docAmolTemplates = 'amol_templates';
  static const String docSurahsDuas = 'surahs_duas';
  static const String docCommonCategories = 'common_categories';
  static const String docDefaultPrayerTimes = 'default_prayer_times';
  static const String docFcmConfig = 'fcm_config';

  // -------------------------------------------------------------
  // SURAHS & DUAS ITEM KEYS (Super Global)
  // -------------------------------------------------------------
  static const String keyDuaQunut = 'dua_qunut';
  static const String keySuraArRahman = 'sura_ar_rahman';
  static const String keySuraYasin = 'sura_yasin';
  static const String keySuraMulk = 'sura_mulk';
  static const String keySuraKahaf = 'sura_kahaf';
  static const String keyAyatulKursi = 'ayatul_kursi';

  // -------------------------------------------------------------
  // COMMON CATEGORY KEYS (Super Global)
  // -------------------------------------------------------------
  static const String catIncome = 'cat_income';
  static const String catExpense = 'cat_expense';
  static const String catLoanGiven = 'cat_loan_given';
  static const String catLoanTaken = 'cat_loan_taken';
  static const String catEmiInstallment = 'cat_emi_installment';
  static const String catRent = 'cat_rent';
  static const String catElectricityBill = 'cat_electricity_bill';
  static const String catNetBill = 'cat_net_bill';
  static const String catPayToSomeone = 'cat_pay_to_someone';
  static const String catGetBySomeone = 'cat_get_by_someone';
  static const String catFood = 'cat_food';
  static const String catMedical = 'cat_medical';
  static const String catEducation = 'cat_education';
  static const String catTransport = 'cat_transport';
  static const String catShopping = 'cat_shopping';
  static const String catGuest = 'cat_guest';

  // -------------------------------------------------------------
  // DATABASE DATA FIELDS
  // -------------------------------------------------------------
  static const String fieldId = 'id';
  static const String fieldTitle = 'title';
  static const String fieldNameBn = 'nameBn';
  static const String fieldNameEn = 'nameEn';
  static const String fieldNameAr = 'nameAr';
  static const String fieldArabicScript = 'arabicScript';
  static const String fieldPronunciationBn = 'pronunciationBn';
  static const String fieldMeaningBn = 'meaningBn';
  static const String fieldVirtue = 'virtue';
  static const String fieldTarget = 'target';
  static const String fieldCount = 'count';
  static const String fieldSurahNumber = 'surahNumber';
  static const String fieldTotalAyahs = 'totalAyahs';
  static const String fieldIconCodePoint = 'iconCodePoint';
  static const String fieldColorValue = 'colorValue';
  static const String fieldIsCustom = 'isCustom';
  static const String fieldAudioUrl = 'audioUrl';
  static const String fieldImageUrl = 'imageUrl';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldCreatedAt = 'createdAt';

  // -------------------------------------------------------------
  // FIREBASE STORAGE / FILE PATH KEYS
  // -------------------------------------------------------------
  static const String storagePathReceipts = 'receipts';
  static const String storagePathProfiles = 'profiles';
  static const String storagePathAudio = 'super_global/audio';
  static const String storagePathSplash = 'app_config/splash';

  // -------------------------------------------------------------
  // PUSH NOTIFICATION & FCM CONFIGURATION
  // -------------------------------------------------------------
  /// Legacy / HTTP v1 server key fallback if not loaded from Firestore
  /// User can also paste it in Firestore doc: app_config/fcm_config -> { 'serverKey': 'YOUR_KEY' }
  static const String defaultFcmServerKey = '';
  static const String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';
  static const String fcmChannelFamily = 'srh_family_channel';
  static const String fcmChannelPrayer = 'srh_prayer_alarm_channel';
}
