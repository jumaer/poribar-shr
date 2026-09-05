import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_entity.dart';
import 'expense_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const List<ExpenseCategory> kDefaultCategories = [
  ExpenseCategory(
    id: 'cat_rent',
    nameBn: 'বাড়ি ভাড়া',
    nameEn: 'Rent',
    iconCodePoint: 0xf6bb,
    colorValue: 0xFFE53935,
  ),
  ExpenseCategory(
    id: 'cat_food',
    nameBn: 'খাবার ও বাজার',
    nameEn: 'Food & Grocery',
    iconCodePoint: 0xf5bb,
    colorValue: 0xFF10B981,
  ),
  ExpenseCategory(
    id: 'cat_guest',
    nameBn: 'মেহমানদারী',
    nameEn: 'Guest & Hosting',
    iconCodePoint: 0xf760,
    colorValue: 0xFFF59E0B,
  ),
  ExpenseCategory(
    id: 'cat_utilities',
    nameBn: 'বিদ্যুৎ ও বিল',
    nameEn: 'Utilities',
    iconCodePoint: 0xf518,
    colorValue: 0xFF06B6D4,
  ),
  ExpenseCategory(
    id: 'cat_medical',
    nameBn: 'ওষুধ ও চিকিৎসা',
    nameEn: 'Medical',
    iconCodePoint: 0xf6be,
    colorValue: 0xFFEC4899,
  ),
  ExpenseCategory(
    id: 'cat_education',
    nameBn: 'শিক্ষা ও বই',
    nameEn: 'Education',
    iconCodePoint: 0xe546,
    colorValue: 0xFF8B5CF6,
  ),
  ExpenseCategory(
    id: 'cat_transport',
    nameBn: 'যাতায়াত ও ভাড়া',
    nameEn: 'Transport',
    iconCodePoint: 0xe1d5,
    colorValue: 0xFF3B82F6,
  ),
  ExpenseCategory(
    id: 'cat_shopping',
    nameBn: 'কেনাকাটা ও পোশাক',
    nameEn: 'Shopping',
    iconCodePoint: 0xf37d,
    colorValue: 0xFFF97316,
  ),
];

class CategoryListNotifier extends Notifier<List<ExpenseCategory>> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  @override
  List<ExpenseCategory> build() {
    final user = ref.watch(authUserProvider);
    final familyId = user?.activeFamilyId ?? '';

    _loadLocalCache(familyId);

    _sub?.cancel();
    if (familyId.isNotEmpty) {
      _sub = FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .collection('categories')
          .snapshots()
          .listen((snap) {
        if (snap.docs.isEmpty) {
          _seedDefaultCategories(familyId);
          state = kDefaultCategories;
          AppDatabase().categoryDao.insertAll(kDefaultCategories, familyId);
        } else {
          final list = snap.docs.map((d) {
            final data = d.data();
            return ExpenseCategory(
              id: d.id,
              nameBn: data['nameBn']?.toString() ?? '',
              nameEn: data['nameEn']?.toString() ?? '',
              iconCodePoint: (data['iconCodePoint'] as num?)?.toInt() ?? 0xf6bb,
              colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF10B981,
              isCustom: data['isCustom'] == true,
            );
          }).toList();
          state = list;
          AppDatabase().categoryDao.insertAll(list, familyId);
        }
      }, onError: (_) {
        _loadLocalCache(familyId);
      });
    }

    ref.onDispose(() {
      _sub?.cancel();
    });

    return kDefaultCategories;
  }

  Future<void> _loadLocalCache(String familyId) async {
    if (familyId.isEmpty) return;
    try {
      final cached = await AppDatabase().categoryDao.findAll(familyId);
      if (cached.isNotEmpty) {
        state = cached;
      }
    } catch (_) {}
  }

  Future<void> _seedDefaultCategories(String familyId) async {
    try {
      await AppDatabase().categoryDao.insertAll(kDefaultCategories, familyId);
      final batch = FirebaseFirestore.instance.batch();
      final catCol = FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .collection('categories');

      for (final cat in kDefaultCategories) {
        final docRef = catCol.doc(cat.id);
        batch.set(docRef, {
          'id': cat.id,
          'nameBn': cat.nameBn,
          'nameEn': cat.nameEn,
          'iconCodePoint': cat.iconCodePoint,
          'colorValue': cat.colorValue,
          'isCustom': false,
        });
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> addCustomCategory({
    required String familyId,
    required String nameBn,
    required String nameEn,
    required int colorValue,
    int iconCodePoint = 0xf5bb,
  }) async {
    final catId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final newCat = ExpenseCategory(
      id: catId,
      nameBn: nameBn,
      nameEn: nameEn,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      isCustom: true,
    );

    state = [...state, newCat];
    await AppDatabase().categoryDao.insertOrUpdate(newCat, familyId);

    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .collection('categories')
          .doc(catId)
          .set({
        'id': catId,
        'nameBn': nameBn,
        'nameEn': nameEn,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'isCustom': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> deleteCategory(String familyId, String id) async {
    state = state.where((cat) => cat.id != id || !cat.isCustom).toList();
    await AppDatabase().categoryDao.delete(id);
    if (familyId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('families')
            .doc(familyId)
            .collection('categories')
            .doc(id)
            .delete();
      } catch (_) {}
    }
  }
}

final categoryListProvider =
    NotifierProvider<CategoryListNotifier, List<ExpenseCategory>>(
  CategoryListNotifier.new,
);

class CategorySpendingSummary {
  final ExpenseCategory category;
  final double totalAmount;
  final double percentage;

  const CategorySpendingSummary({
    required this.category,
    required this.totalAmount,
    required this.percentage,
  });
}

final categoryAnalyticsProvider = Provider<List<CategorySpendingSummary>>((ref) {
  final categories = ref.watch(categoryListProvider);
  final expenses = ref.watch(expenseListProvider);

  final totalExpense = expenses
      .where((e) => e.type == TransactionType.expense)
      .fold(0.0, (total, i) => total + i.amount);

  return categories.map((cat) {
    final categoryExpenses = expenses.where((e) {
      if (e.type != TransactionType.expense) return false;
      final purposeLower = e.purpose.toLowerCase();
      final nameBnLower = cat.nameBn.toLowerCase();
      final nameEnLower = cat.nameEn.toLowerCase();
      return purposeLower.contains(nameBnLower) ||
          purposeLower.contains(nameEnLower) ||
          (cat.id == 'cat_food' && (purposeLower.contains('বাজার') || purposeLower.contains('শাকসবজি'))) ||
          (cat.id == 'cat_utilities' && purposeLower.contains('বিদ্যুৎ'));
    });

    final catTotal = categoryExpenses.fold(0.0, (total, i) => total + i.amount);
    final percentage = totalExpense > 0 ? (catTotal / totalExpense) * 100 : 0.0;

    return CategorySpendingSummary(
      category: cat,
      totalAmount: catTotal,
      percentage: percentage,
    );
  }).toList()
    ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
});
