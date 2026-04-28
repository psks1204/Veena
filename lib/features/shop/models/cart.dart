/// Shop Cart Models
library;

class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int? variantId;
  final String? variantName;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final bool inStock;
  final int availableQuantity;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    this.variantId,
    this.variantName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.inStock = true,
    this.availableQuantity = 0,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      productId: json['productId'] as int,
      productName: json['productName'] as String? ?? '',
      productImage: json['productImage'] as String?,
      variantId: json['variantId'] as int?,
      variantName: json['variantName'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      inStock: json['inStock'] as bool? ?? true,
      availableQuantity: json['availableQuantity'] as int? ?? 0,
    );
  }
}

class CartResponse {
  final int id;
  final List<CartItem> items;
  final int totalItems;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;

  const CartResponse({
    required this.id,
    required this.items,
    this.totalItems = 0,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      id: json['id'] as int,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalItems: json['totalItems'] as int? ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AddToCartRequest {
  final int productId;
  final int? variantId;
  final int quantity;

  const AddToCartRequest({
    required this.productId,
    this.variantId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    if (variantId != null) 'variantId': variantId,
    'quantity': quantity,
  };
}

class UpdateCartItemRequest {
  final int quantity;
  const UpdateCartItemRequest({required this.quantity});
  Map<String, dynamic> toJson() => {'quantity': quantity};
}
