import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/app_settings_dao.dart';
import '../database/category_dao.dart';
import '../database/family_member_dao.dart';
import '../database/private_vault_dao.dart';
import '../database/transaction_dao.dart';
import '../services/firestore_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.transactionDao;
});

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.categoryDao;
});

final familyMemberDaoProvider = Provider<FamilyMemberDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.familyMemberDao;
});

final privateVaultDaoProvider = Provider<PrivateVaultDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.privateVaultDao;
});

final appSettingsDaoProvider = Provider<AppSettingsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.appSettingsDao;
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
