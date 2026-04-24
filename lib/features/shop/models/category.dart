/// Shop Category Models
class CategoryResponse {
  final int id;
  final String name;
  final String? slug;
  final String? description;
  final String? imageUrl;
  final int? parentId;
  final String? parentName;
  final int displayOrder;
  final bool isActive;
  final List<CategoryResponse> children;
  final int productCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryResponse({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.imageUrl,
    this.parentId,
    this.parentName,
    this.displayOrder = 0,
    this.isActive = true,
    this.children = const [],
    this.productCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      parentId: json['parentId'] as int?,
      parentName: json['parentName'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      children:
          (json['children'] as List<dynamic>?)
              ?.map((e) => CategoryResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      productCount: json['productCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
