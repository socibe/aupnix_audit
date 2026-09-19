class BusinessImage {
  const BusinessImage({
    required this.id,
    required this.businessId,
    required this.storageKey,
    required this.imageRole,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
    this.altText,
  });

  final String id;
  final String businessId;
  final String storageKey;
  final String imageRole;
  final String? altText;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const profileRole = 'profile';
  static const bannerRole = 'banner';

  factory BusinessImage.fromMap(Map<String, dynamic> map) {
    final imageRole = map['image_role'] as String;

    if (imageRole != profileRole && imageRole != bannerRole) {
      throw FormatException(
        'Unsupported business image role: $imageRole',
      );
    }

    return BusinessImage(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      storageKey: map['storage_key'] as String,
      imageRole: imageRole,
      altText: map['alt_text'] as String?,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'storage_key': storageKey,
      'image_role': imageRole,
      'alt_text': altText,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}


