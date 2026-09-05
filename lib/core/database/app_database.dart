import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'app_settings_dao.dart';
import 'category_dao.dart';
import 'family_member_dao.dart';
import 'private_vault_dao.dart';
import 'transaction_dao.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;
  TransactionDao? _transactionDao;
  CategoryDao? _categoryDao;
  FamilyMemberDao? _familyMemberDao;
  PrivateVaultDao? _privateVaultDao;
  AppSettingsDao? _appSettingsDao;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  TransactionDao get transactionDao {
    _transactionDao ??= SqliteTransactionDao(this);
    return _transactionDao!;
  }

  CategoryDao get categoryDao {
    _categoryDao ??= SqliteCategoryDao(this);
    return _categoryDao!;
  }

  FamilyMemberDao get familyMemberDao {
    _familyMemberDao ??= SqliteFamilyMemberDao(this);
    return _familyMemberDao!;
  }

  PrivateVaultDao get privateVaultDao {
    _privateVaultDao ??= SqlitePrivateVaultDao(this);
    return _privateVaultDao!;
  }

  AppSettingsDao get appSettingsDao {
    _appSettingsDao ??= SqliteAppSettingsDao(this);
    return _appSettingsDao!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'shr_family_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        familyId TEXT,
        type TEXT,
        category TEXT,
        amount REAL,
        purpose TEXT,
        description TEXT,
        timestamp INTEGER,
        recordedByUserId TEXT,
        recordedByUserName TEXT,
        imageBase64 TEXT,
        imagePath TEXT,
        lastModified INTEGER
      )
    ''');

    // 2. Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        familyId TEXT,
        nameBn TEXT,
        nameEn TEXT,
        iconCode INTEGER,
        colorValue INTEGER,
        budgetLimit REAL
      )
    ''');

    // 3. Family members table
    await db.execute('''
      CREATE TABLE family_members (
        phoneNumber TEXT PRIMARY KEY,
        id TEXT,
        familyId TEXT,
        name TEXT,
        role TEXT,
        relation TEXT,
        photoUrl TEXT,
        canUpload INTEGER,
        canViewExpenses INTEGER,
        canSendPushNotification INTEGER,
        joinedAt TEXT
      )
    ''');

    // 4. Private vault table
    await db.execute('''
      CREATE TABLE private_vault (
        id TEXT PRIMARY KEY,
        userId TEXT,
        category TEXT,
        title TEXT,
        secretContent TEXT,
        timestamp INTEGER
      )
    ''');

    // 5. Offline users table
    await db.execute('''
      CREATE TABLE users (
        phoneNumber TEXT PRIMARY KEY,
        uid TEXT,
        fullName TEXT,
        password TEXT,
        activeFamilyId TEXT,
        role TEXT,
        isFamilyOwner INTEGER
      )
    ''');

    // 6. Key-Value App settings
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        updatedAt INTEGER
      )
    ''');
  }
}
