import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../widgets/glass_text_field.dart';

class DropdownConfigModel {
  final List<String> familyRelations;
  final List<String> vaultCategories;
  final List<String> quickPingTemplates;
  final List<String> pushCategories;

  const DropdownConfigModel({
    required this.familyRelations,
    required this.vaultCategories,
    required this.quickPingTemplates,
    required this.pushCategories,
  });

  static const DropdownConfigModel defaults = DropdownConfigModel(
    familyRelations: [
      'পিতা / বাবা',
      'মাতা / মা',
      'স্বামী / স্ত্রী',
      'সন্তান',
      'ভাই',
      'বোন',
      'দাদা / নানা',
      'দাদী / নানী',
      'চাচা / মামা',
      'ফুফু / খালা',
      'অন্যান্য',
    ],
    vaultCategories: [
      'গোপন আইটেম',
      'ব্যক্তিগত মেহমান',
      'জরুরি দলিল',
      'পাসওয়ার্ড ও পিন',
    ],
    quickPingTemplates: [
      'জরুরি প্রয়োজনে যোগাযোগ করুন',
      'আজকের বাজার/বাজারের হিসাব হয়েছে?',
      'সবাই সাবধানে থাকবেন',
      'নামাজের সময় হয়েছে',
      'বাসায় দ্রুত আসুন',
    ],
    pushCategories: [
      'সাধারণ বিজ্ঞপ্তি',
      'জরুরি পারিবারিক ঘোষণা',
      'বকেয়া পরিশোধ রিমাইন্ডার',
      'মাসিক হিসাব সম্পন্ন',
    ],
  );

  factory DropdownConfigModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) return defaults;
    return DropdownConfigModel(
      familyRelations: data['familyRelations'] is List
          ? List<String>.from(data['familyRelations'])
          : defaults.familyRelations,
      vaultCategories: data['vaultCategories'] is List
          ? List<String>.from(data['vaultCategories'])
          : defaults.vaultCategories,
      quickPingTemplates: data['quickPingTemplates'] is List
          ? List<String>.from(data['quickPingTemplates'])
          : defaults.quickPingTemplates,
      pushCategories: data['pushCategories'] is List
          ? List<String>.from(data['pushCategories'])
          : defaults.pushCategories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyRelations': familyRelations,
      'vaultCategories': vaultCategories,
      'quickPingTemplates': quickPingTemplates,
      'pushCategories': pushCategories,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class FirebaseDropdownConfigService {
  static final FirebaseDropdownConfigService _instance =
      FirebaseDropdownConfigService._internal();
  factory FirebaseDropdownConfigService() => _instance;
  FirebaseDropdownConfigService._internal();

  DropdownConfigModel _cached = DropdownConfigModel.defaults;
  DropdownConfigModel get current => _cached;

  /// Stream listening to real-time dropdown updates in Firestore
  Stream<DropdownConfigModel> get dropdownStream {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('app_config')
          .doc('dropdown_options');

      return docRef.snapshots().map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          // Auto-seed to Firebase if document is missing
          _seedDefaults(docRef);
          return DropdownConfigModel.defaults;
        }
        final model = DropdownConfigModel.fromMap(snapshot.data());
        _cached = model;
        return model;
      }).handleError((error) {
        debugPrint('FirebaseDropdownConfigService stream error: $error');
        return _cached;
      });
    } catch (e) {
      debugPrint('FirebaseDropdownConfigService stream init error: $e');
      return Stream.value(_cached);
    }
  }

  Future<void> _seedDefaults(DocumentReference docRef) async {
    try {
      await docRef.set(
        DropdownConfigModel.defaults.toMap(),
        SetOptions(merge: true),
      );
      debugPrint('Seeded default dropdown options into Firebase Firestore');
    } catch (e) {
      debugPrint('Error seeding dropdown options to Firestore: $e');
    }
  }

  /// Manually update any dropdown list directly in Firestore
  Future<void> updateCategoryList({
    required String fieldKey,
    required List<String> newList,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('app_config')
          .doc('dropdown_options')
          .set({
        fieldKey: newList,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to update dropdown list $fieldKey: $e');
      rethrow;
    }
  }

  /// Add a single new option to a dropdown list in Firestore
  Future<void> addNewOption({
    required String fieldKey,
    required String newOption,
  }) async {
    final trimmed = newOption.trim();
    if (trimmed.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('app_config')
          .doc('dropdown_options')
          .set({
        fieldKey: FieldValue.arrayUnion([trimmed]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Added new option "$trimmed" to $fieldKey in Firestore');
    } catch (e) {
      debugPrint('Failed to add new option to $fieldKey: $e');
      rethrow;
    }
  }

  /// Show interactive dialog allowing user to add a new option to any dropdown
  static Future<void> showAddOptionDialog(
    BuildContext context, {
    required String fieldKey,
    required String title,
    String? hintText,
  }) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.iosDivider),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassTextField(
              controller: controller,
              label: 'নতুন আইটেম / ক্যাটাগরি',
              hint: hintText ?? 'নাম লিখুন...',
              prefixIcon: Icons.add_circle_outline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                await FirebaseDropdownConfigService().addNewOption(
                  fieldKey: fieldKey,
                  newOption: text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$text" সফলভাবে ফায়ারবেসে যোগ করা হয়েছে!'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'যোগ করুন',
              style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

final dropdownOptionsProvider = StreamProvider<DropdownConfigModel>((ref) {
  return FirebaseDropdownConfigService().dropdownStream;
});
