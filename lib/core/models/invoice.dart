class InvoiceResponse {
  const InvoiceResponse({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceType,
    required this.referenceId,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.currency,
    required this.status,
    this.userId,
    this.userName,
    this.userEmail,
    this.paymentMethod,
    this.paymentId,
    this.billingName,
    this.billingEmail,
    this.billingPhone,
    this.billingAddress,
    this.notes,
    this.pdfUrl,
    this.createdAt,
  });

  final int id;
  final String invoiceNumber;
  final String invoiceType;
  final int referenceId;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String currency;
  final String status;

  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? paymentMethod;
  final String? paymentId;
  final String? billingName;
  final String? billingEmail;
  final String? billingPhone;
  final String? billingAddress;
  final String? notes;
  final String? pdfUrl;
  final DateTime? createdAt;

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      invoiceType: json['invoiceType'] as String? ?? '',
      referenceId: (json['referenceId'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      status: json['status'] as String? ?? '',
      userId: json['userId']?.toString(),
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      paymentId: json['paymentId'] as String?,
      billingName: json['billingName'] as String?,
      billingEmail: json['billingEmail'] as String?,
      billingPhone: json['billingPhone'] as String?,
      billingAddress: json['billingAddress'] as String?,
      notes: json['notes'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
