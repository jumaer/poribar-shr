class ExpenseCategory {
  final String id;
  final String nameBn;
  final String nameEn;
  final int iconCodePoint;
  final int colorValue;
  final bool isCustom;

  const ExpenseCategory({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.iconCodePoint,
    required this.colorValue,
    this.isCustom = false,
  });

  ExpenseCategory copyWith({
    String? id,
    String? nameBn,
    String? nameEn,
    int? iconCodePoint,
    int? colorValue,
    bool? isCustom,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      nameBn: nameBn ?? this.nameBn,
      nameEn: nameEn ?? this.nameEn,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
