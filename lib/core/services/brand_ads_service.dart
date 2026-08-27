import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/brand_ad.dart';

/// Service providing real-brand advertisements, outbound navigation, and rotation.
class BrandAdsService {
  BrandAdsService._();

  static int _currentIndex = 0;
  static final Random _random = Random();

  /// 20 curated real trending brands and authentic products
  static final List<BrandAd> brandAds = [
    // 1. Apple
    const BrandAd(
      id: 'apple_iphone_16_pro',
      brandName: 'Apple',
      productName: 'iPhone 16 Pro',
      headline: 'Titanium. So strong. So light. So Pro.',
      description:
          'Featuring the breakthrough A18 Pro chip, 48MP Fusion camera with 5x Telephoto, and all-day battery life.',
      priceOrOffer: 'From \$999 or \$41.62/mo.',
      rating: 4.9,
      reviewsCount: '48.5k+',
      category: 'Smartphones & Tech',
      callToAction: 'Buy iPhone 16 Pro',
      websiteUrl: 'https://www.apple.com/iphone-16-pro/',
      imageUrl:
          'https://images.unsplash.com/photo-1695048133142-1a20484d2569?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFF0071E3),
      accentColor: Color(0xFF1D1D1F),
    ),

    // 2. Nike
    const BrandAd(
      id: 'nike_air_max_dn',
      brandName: 'Nike',
      productName: 'Nike Air Max Dn',
      headline: 'Feel the unreal. The next era of Air.',
      description:
          'Dual-pressure tubes provide responsive bounce and a smooth transition with every single step.',
      priceOrOffer: 'Starting at \$160 · Free Shipping',
      rating: 4.8,
      reviewsCount: '19.2k+',
      category: 'Footwear & Sportswear',
      callToAction: 'Shop Nike Air Max',
      websiteUrl: 'https://www.nike.com/',
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFFFF4500),
      accentColor: Color(0xFF111111),
    ),

    // 3. Sony
    const BrandAd(
      id: 'sony_wh1000xm5',
      brandName: 'Sony',
      productName: 'Sony WH-1000XM5',
      headline: 'Your world. Nothing else. Industry-leading Noise Cancelling.',
      description:
          'Two processors and 8 microphones deliver magnificent acoustic performance and crystal-clear hands-free calls.',
      priceOrOffer: '\$399.99 · Save \$50 Today',
      rating: 4.9,
      reviewsCount: '34.8k+',
      category: 'Audio & Acoustics',
      callToAction: 'Experience Sony Sound',
      websiteUrl:
          'https://electronics.sony.com/audio/headphones/headband-headphones/p/wh1000xm5-b',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFF003791),
      accentColor: Color(0xFF1F1F1F),
    ),

    // 4. Samsung
    const BrandAd(
      id: 'samsung_galaxy_s24_ultra',
      brandName: 'Samsung',
      productName: 'Galaxy S24 Ultra',
      headline: 'Galaxy AI is here. Epic mobile intelligence.',
      description:
          'Circle to Search, Live Translate, and a 200MP camera with Quad Telephoto zoom in sleek titanium armor.',
      priceOrOffer: 'From \$1,299 + up to \$750 trade-in',
      rating: 4.8,
      reviewsCount: '31.4k+',
      category: 'Smartphones & Mobile AI',
      callToAction: 'Explore Galaxy S24',
      websiteUrl: 'https://www.samsung.com/galaxy-s24-ultra/',
      imageUrl:
          'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFF1428A0),
      accentColor: Color(0xFF0A1128),
    ),

    // 5. Bose
    const BrandAd(
      id: 'bose_qc_ultra',
      brandName: 'Bose',
      productName: 'QuietComfort Ultra',
      headline: 'Sound just got real. World-class spatialized audio.',
      description:
          'CustomTune technology customizes sound to your ears. Immersive Audio for breathtaking realism and quiet.',
      priceOrOffer: '\$429.00 · Free 30-Day Home Trial',
      rating: 4.8,
      reviewsCount: '15.6k+',
      category: 'Premium Audio',
      callToAction: 'Shop Bose Ultra',
      websiteUrl:
          'https://www.bose.com/p/headphones/bose-quietcomfort-ultra-headphones/QCU-HEADPHONEARN.html',
      imageUrl:
          'https://images.unsplash.com/photo-1546435770-a3e426bf472b?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFF000000),
      accentColor: Color(0xFF333333),
    ),

    // 6. Spotify
    const BrandAd(
      id: 'spotify_premium',
      brandName: 'Spotify',
      productName: 'Spotify Premium',
      headline: 'Music without limits. Ad-free, offline & on-demand.',
      description:
          'Download songs to listen offline, play any track on mobile, and enjoy unlimited high-fidelity skips.',
      priceOrOffer: 'Try 3 Months Free · Then \$11.99/mo',
      rating: 4.9,
      reviewsCount: '102k+',
      category: 'Music Streaming',
      callToAction: 'Get 3 Months Free',
      websiteUrl: 'https://www.spotify.com/premium/',
      imageUrl:
          'https://images.unsplash.com/photo-1614680376593-902f749f7ffc?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFF1DB954),
      accentColor: Color(0xFF191414),
    ),

    // 7. Dyson
    const BrandAd(
      id: 'dyson_airwrap',
      brandName: 'Dyson',
      productName: 'Dyson Airwrap Multi-Styler',
      headline: 'Style with air, not extreme heat. Coanda effect.',
      description:
          'Dry, curl, shape, and smooth without heat damage. Powered by the high-speed Dyson digital motor V9.',
      priceOrOffer: '\$599.99 · Includes 6 attachments',
      rating: 4.9,
      reviewsCount: '24.1k+',
      category: 'Beauty Tech & Haircare',
      callToAction: 'Discover Dyson Airwrap',
      websiteUrl: 'https://www.dyson.com/hair-care/hair-stylers/airwrap',
      imageUrl:
          'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFFFF1493),
      accentColor: Color(0xFF2C2C2C),
    ),

    // 8. Tesla
    const BrandAd(
      id: 'tesla_model_y',
      brandName: 'Tesla',
      productName: 'Tesla Model Y & Model 3',
      headline: 'The world’s best-selling car. 330+ miles range.',
      description:
          'Instant acceleration, 5-star safety rating, Autopilot capability, and access to 50,000+ global Superchargers.',
      priceOrOffer: 'Starting at \$31,490 after Federal Tax Credit',
      rating: 4.9,
      reviewsCount: '70.2k+',
      category: 'Electric Vehicles',
      callToAction: 'Order Custom Model Y',
      websiteUrl: 'https://www.tesla.com/modely',
      imageUrl:
          'https://images.unsplash.com/photo-1560958089-b8a1929cea89?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFFE82127),
      accentColor: Color(0xFF111111),
    ),

    // 9. Coca-Cola
    const BrandAd(
      id: 'coca_cola_zero',
      brandName: 'Coca-Cola',
      productName: 'Coca-Cola Zero Sugar',
      headline: 'Real Magic. Best Coke Ever? Take a taste.',
      description:
          'Deliciously refreshing Coca-Cola taste with zero sugar and zero calories. Iconic refreshment perfected.',
      priceOrOffer: 'Ice cold refreshment at all retailers',
      rating: 4.8,
      reviewsCount: '92.3k+',
      category: 'Beverages',
      callToAction: 'Taste Coca-Cola Zero',
      websiteUrl: 'https://www.coca-cola.com/',
      imageUrl:
          'https://images.unsplash.com/photo-1554866585-cd94860890b7?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFFF40009),
      accentColor: Color(0xFF000000),
    ),

    // 10. Starbucks
    const BrandAd(
      id: 'starbucks_cold_brew',
      brandName: 'Starbucks',
      productName: 'Starbucks Nitro Cold Brew',
      headline: 'Slow-steeped. Ultra-smooth. Velvety crema.',
      description:
          'Small-batch cold brew infused with nitrogen for a naturally sweet flavor and silky microfoam finish.',
      priceOrOffer: 'Earn Stars with Starbucks Rewards',
      rating: 4.8,
      reviewsCount: '44.9k+',
      category: 'Coffee & Refreshment',
      callToAction: 'Order on Starbucks App',
      websiteUrl: 'https://www.starbucks.com/menu',
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFF006241),
      accentColor: Color(0xFF1E3932),
    ),

    // 11. Amazon Prime
    const BrandAd(
      id: 'amazon_prime',
      brandName: 'Amazon',
      productName: 'Amazon Prime',
      headline: 'Fast, free delivery on 300M+ items + Prime Video.',
      description:
          'Stream award-winning movies and originals, listen to millions of songs, and get exclusive member deals.',
      priceOrOffer: 'Start your 30-day Free Trial',
      rating: 4.8,
      reviewsCount: '130k+',
      category: 'Shopping & Entertainment',
      callToAction: 'Try Prime Free',
      websiteUrl: 'https://www.amazon.com/amazonprime',
      imageUrl:
          'https://images.unsplash.com/photo-1523474253246-72cb9dcdd8b6?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFFFF9900),
      accentColor: Color(0xFF232F3E),
    ),

    // 12. Google Pixel
    const BrandAd(
      id: 'google_pixel_9_pro',
      brandName: 'Google',
      productName: 'Google Pixel 9 Pro',
      headline: 'Oh hi, Gemini. The powerhouse AI smartphone.',
      description:
          'Super Actua display, pro triple-lens camera system, and 7 years of flagship Pixel Feature Drops.',
      priceOrOffer: 'From \$999 + \$200 Google Store Credit',
      rating: 4.8,
      reviewsCount: '21.7k+',
      category: 'Tech & Artificial Intelligence',
      callToAction: 'Buy Pixel 9 Pro',
      websiteUrl: 'https://store.google.com/product/pixel_9_pro',
      imageUrl:
          'https://images.unsplash.com/photo-1598327105666-5b89351aff97?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFF4285F4),
      accentColor: Color(0xFF34A853),
    ),

    // 13. PlayStation
    const BrandAd(
      id: 'playstation_5',
      brandName: 'PlayStation',
      productName: 'PlayStation 5 Slim',
      headline: 'Play Has No Limits. Ultra-high speed SSD.',
      description:
          'Haptic feedback, adaptive triggers, 3D Audio immersion, and an all-new generation of blockbuster games.',
      priceOrOffer: 'From \$449.99 · Holiday Bundles Live',
      rating: 4.9,
      reviewsCount: '82.5k+',
      category: 'Gaming & Entertainment',
      callToAction: 'Explore PS5 Games',
      websiteUrl: 'https://www.playstation.com/ps5/',
      imageUrl:
          'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFF003791),
      accentColor: Color(0xFF001E50),
    ),

    // 14. Ray-Ban
    const BrandAd(
      id: 'rayban_meta',
      brandName: 'Ray-Ban',
      productName: 'Ray-Ban Meta Smart Glasses',
      headline: 'Capture, share, and listen. Meta AI built in.',
      description:
          '12MP ultra-wide camera, discreet open-ear speakers, and hands-free voice commands in iconic Wayfarer frames.',
      priceOrOffer: 'Starting at \$299 · Free Shipping & Returns',
      rating: 4.8,
      reviewsCount: '13.1k+',
      category: 'Smart Eyewear & Wearables',
      callToAction: 'Shop Ray-Ban Meta',
      websiteUrl: 'https://www.ray-ban.com/usa/ray-ban-meta-smart-glasses',
      imageUrl:
          'https://images.unsplash.com/photo-1511499767150-a48a237f0083?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFFD32F2F),
      accentColor: Color(0xFF212121),
    ),

    // 15. Adidas
    const BrandAd(
      id: 'adidas_ultraboost',
      brandName: 'Adidas',
      productName: 'Adidas Ultraboost Light',
      headline: 'Epic energy return. 30% lighter BOOST cushioning.',
      description:
          'Primeknit+ upper with Linear Energy Push system for highest responsiveness during runs and daily wear.',
      priceOrOffer: '\$190 · Join adiClub for 15% off',
      rating: 4.8,
      reviewsCount: '26.8k+',
      category: 'Footwear & Athletic Gear',
      callToAction: 'Shop Ultraboost',
      websiteUrl: 'https://www.adidas.com/ultraboost',
      imageUrl:
          'https://images.unsplash.com/photo-1587563871167-1ee9c731aefb?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFF000000),
      accentColor: Color(0xFF1F1F1F),
    ),

    // 16. Canon
    const BrandAd(
      id: 'canon_eos_r5',
      brandName: 'Canon',
      productName: 'Canon EOS R5 Mark II',
      headline: 'Master the moment. 45MP full-frame powerhouse.',
      description:
          'Accelerated Capture processor, 8.5-stop In-Body IS, and 8K 60p RAW video recording for creators and pros.',
      priceOrOffer: '\$4,299.00 · Official Warranty',
      rating: 4.9,
      reviewsCount: '9.4k+',
      category: 'Cameras & Photography',
      callToAction: 'Discover EOS R5 II',
      websiteUrl: 'https://www.usa.canon.com/cameras/eos-r-system',
      imageUrl:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFFCC0000),
      accentColor: Color(0xFF1E1E1E),
    ),

    // 17. Airbnb
    const BrandAd(
      id: 'airbnb_guest_favorites',
      brandName: 'Airbnb',
      productName: 'Airbnb Guest Favorites',
      headline: 'Find rooms, beachfront villas & iconic cabins.',
      description:
          'The most loved homes on Airbnb based on ratings, reviews, and reliability from over 500M guests worldwide.',
      priceOrOffer: 'Book unique stays worldwide',
      rating: 4.9,
      reviewsCount: '160k+',
      category: 'Travel & Stays',
      callToAction: 'Find Your Next Stay',
      websiteUrl: 'https://www.airbnb.com/',
      imageUrl:
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFFFF5A5F),
      accentColor: Color(0xFF484848),
    ),

    // 18. Audible
    const BrandAd(
      id: 'audible_premium_plus',
      brandName: 'Audible',
      productName: 'Audible Premium Plus',
      headline: 'Stories that speak to you. Bestselling audiobooks.',
      description:
          'Listen to exclusive originals, podcasts, and get monthly audio credits. Listen anytime, anywhere on any device.',
      priceOrOffer: '30-Day Free Trial · 1 Free Audio Title',
      rating: 4.8,
      reviewsCount: '62.4k+',
      category: 'Audiobooks & Spoken Audio',
      callToAction: 'Start Free Trial',
      websiteUrl: 'https://www.audible.com/',
      imageUrl:
          'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFFF8991D),
      accentColor: Color(0xFF232F3E),
    ),

    // 19. Rolex
    const BrandAd(
      id: 'rolex_submariner',
      brandName: 'Rolex',
      productName: 'Rolex Submariner Date',
      headline: 'The reference among divers’ luxury watches.',
      description:
          'Oystersteel case, unidirectional Cerachrom ceramic bezel, luminescent Chromalight display, waterproof to 300m.',
      priceOrOffer: 'Official Rolex Jeweler Network',
      rating: 5.0,
      reviewsCount: '41.2k+',
      category: 'Luxury Swiss Watches',
      callToAction: 'Discover Submariner',
      websiteUrl: 'https://www.rolex.com/watches/submariner',
      imageUrl:
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFF006039),
      accentColor: Color(0xFFA37E2C),
    ),

    // 20. Netflix
    const BrandAd(
      id: 'netflix_streaming',
      brandName: 'Netflix',
      productName: 'Netflix Standard & 4K',
      headline: 'Watch anywhere. Cancel anytime.',
      description:
          'Endless award-winning movies, TV shows, anime, and original series in 4K Ultra HD and spatial audio.',
      priceOrOffer: 'Plans starting from \$6.99/month',
      rating: 4.8,
      reviewsCount: '220k+',
      category: 'Entertainment & Streaming',
      callToAction: 'Join Netflix Now',
      websiteUrl: 'https://www.netflix.com/',
      imageUrl:
          'https://images.unsplash.com/photo-1574375927938-d5a98e8ffe85?q=80&w=1200&auto=format&fit=crop',
      brandColor: Color(0xFFE50914),
      accentColor: Color(0xFF141414),
    ),
  ];

  /// Get the next ad sequentially
  static BrandAd getNextAd() {
    final ad = brandAds[_currentIndex % brandAds.length];
    _currentIndex++;
    return ad;
  }

  /// Get a random ad from the 20 brands
  static BrandAd getRandomAd() {
    return brandAds[_random.nextInt(brandAds.length)];
  }

  /// Launch the brand's official website in an external tab
  static Future<bool> launchAdWebsite(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('[BrandAdsService] Failed to launch $url: $e');
      return false;
    }
  }
}
