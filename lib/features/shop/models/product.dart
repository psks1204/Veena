/// Shop Product Models
class ProductImage {
  final int id;
  final String imageUrl;
  final String? altText;
  final int displayOrder;
  final bool isPrimary;

  const ProductImage({
    required this.id,
    required this.imageUrl,
    this.altText,
    this.displayOrder = 0,
    this.isPrimary = false,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as int,
      imageUrl: json['imageUrl'] as String? ?? '',
      altText: json['altText'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

class ProductVariant {
  final int id;
  final String name;
  final String? sku;
  final double price;
  final int quantity;
  final Map<String, String> attributes;
  final bool isActive;
  final bool inStock;

  const ProductVariant({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    this.quantity = 0,
    this.attributes = const {},
    this.isActive = true,
    this.inStock = false,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final rawAttrs = json['attributes'] as Map<String, dynamic>? ?? {};
    return ProductVariant(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 0,
      attributes: rawAttrs.map((k, v) => MapEntry(k, v.toString())),
      isActive: json['isActive'] as bool? ?? true,
      inStock: json['inStock'] as bool? ?? false,
    );
  }
}

class ProductResponse {
  final int id;
  final String name;
  final String? slug;
  final String? description;
  final String? shortDescription;
  final String? sku;
  final double price;
  final double? compareAtPrice;
  final double? costPrice;
  final int quantity;
  final int? lowStockThreshold;
  final int? weightGrams;
  final double? lengthCm;
  final double? breadthCm;
  final double? heightCm;
  final bool isActive;
  final bool isFeatured;
  final String? hsnCode;
  final double taxPercent;
  final bool inStock;
  final double discountPercent;
  final int? categoryId;
  final String? categoryName;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductResponse({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.shortDescription,
    this.sku,
    required this.price,
    this.compareAtPrice,
    this.costPrice,
    this.quantity = 0,
    this.lowStockThreshold,
    this.weightGrams,
    this.lengthCm,
    this.breadthCm,
    this.heightCm,
    this.isActive = true,
    this.isFeatured = false,
    this.hsnCode,
    this.taxPercent = 0.0,
    this.inStock = false,
    this.discountPercent = 0.0,
    this.categoryId,
    this.categoryName,
    this.images = const [],
    this.variants = const [],
    this.createdAt,
    this.updatedAt,
  });

  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final primary = images.where((i) => i.isPrimary);
    if (primary.isNotEmpty) return primary.first.imageUrl;
    return images.first.imageUrl;
  }

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      shortDescription: json['shortDescription'] as String?,
      sku: json['sku'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble(),
      costPrice: (json['costPrice'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 0,
      lowStockThreshold: json['lowStockThreshold'] as int?,
      weightGrams: json['weightGrams'] as int?,
      lengthCm: (json['lengthCm'] as num?)?.toDouble(),
      breadthCm: (json['breadthCm'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      hsnCode: json['hsnCode'] as String?,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0.0,
      inStock: json['inStock'] as bool? ?? false,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      variants:
          (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
