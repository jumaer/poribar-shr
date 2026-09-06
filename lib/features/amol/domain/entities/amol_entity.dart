class AmolItem {
  final String id;
  final String nameBn;
  final String nameAr;
  final String virtue;
  final int count;
  final int target;

  const AmolItem({
    required this.id,
    required this.nameBn,
    required this.nameAr,
    required this.virtue,
    this.count = 0,
    this.target = 33,
  });

  AmolItem copyWith({
    int? count,
    int? target,
  }) {
    return AmolItem(
      id: id,
      nameBn: nameBn,
      nameAr: nameAr,
      virtue: virtue,
      count: count ?? this.count,
      target: target ?? this.target,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameBn': nameBn,
      'nameAr': nameAr,
      'virtue': virtue,
      'count': count,
      'target': target,
    };
  }

  factory AmolItem.fromMap(Map<String, dynamic> map) {
    return AmolItem(
      id: map['id']?.toString() ?? '',
      nameBn: map['nameBn']?.toString() ?? '',
      nameAr: map['nameAr']?.toString() ?? '',
      virtue: map['virtue']?.toString() ?? '',
      count: (map['count'] as num?)?.toInt() ?? 0,
      target: (map['target'] as num?)?.toInt() ?? 33,
    );
  }
}
