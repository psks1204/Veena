import 'package:flutter/material.dart';

/// Data model representing a real-brand sponsored advertisement.
class BrandAd {
  const BrandAd({
    required this.id,
    required this.brandName,
    required this.productName,
    required this.headline,
    required this.description,
    required this.priceOrOffer,
    required this.rating,
    required this.reviewsCount,
    required this.category,
    required this.callToAction,
    required this.websiteUrl,
    required this.imageUrl,
    this.logoUrl,
    this.brandColor = const Color(0xFF1E88E5),
    this.accentColor = const Color(0xFF0D47A1),
  });

  final String id;
  final String brandName;
  final String productName;
  final String headline;
  final String description;
  final String priceOrOffer;
  final double rating;
  final String reviewsCount;
  final String category;
  final String callToAction;
  final String websiteUrl;
  final String imageUrl;
  final String? logoUrl;
  final Color brandColor;
  final Color accentColor;
}
