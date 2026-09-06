class SurahDuaEntity {
  final String id;
  final String titleBn;
  final String titleAr;
  final String surahNumber;
  final String arabicScript;
  final String pronunciationBn;
  final String meaningBn;
  final String virtue;
  final String? audioUrl;
  final String? imageUrl;

  const SurahDuaEntity({
    required this.id,
    required this.titleBn,
    required this.titleAr,
    required this.surahNumber,
    required this.arabicScript,
    required this.pronunciationBn,
    required this.meaningBn,
    required this.virtue,
    this.audioUrl,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titleBn': titleBn,
      'titleAr': titleAr,
      'surahNumber': surahNumber,
      'arabicScript': arabicScript,
      'pronunciationBn': pronunciationBn,
      'meaningBn': meaningBn,
      'virtue': virtue,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
    };
  }

  factory SurahDuaEntity.fromMap(Map<String, dynamic> map) {
    return SurahDuaEntity(
      id: map['id']?.toString() ?? '',
      titleBn: map['titleBn']?.toString() ?? '',
      titleAr: map['titleAr']?.toString() ?? '',
      surahNumber: map['surahNumber']?.toString() ?? '',
      arabicScript: map['arabicScript']?.toString() ?? '',
      pronunciationBn: map['pronunciationBn']?.toString() ?? '',
      meaningBn: map['meaningBn']?.toString() ?? '',
      virtue: map['virtue']?.toString() ?? '',
      audioUrl: map['audioUrl']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
    );
  }
}
