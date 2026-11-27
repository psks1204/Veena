import 'package:flutter/material.dart';

import '../../core/services/brand_ads_service.dart';
import '../../core/theme/app_spacing.dart';
import 'subscription_modal.dart';

/// House ad for NitShop (nitshop.in), shown in the web home carousel ahead of
/// the brand ads.
///
/// Every claim here is one nitshop.in makes itself (its home page hero and
/// plan prices): your own branded store; UPI, COD, GST invoices, shipping and
/// WhatsApp updates; 0% commission; no card needed; a person helps you set up;
/// a 7-day free trial; plans from ₹2,999/month. Change them together.
///
/// Built to the carousel's fixed 250px height in three widths: wide (copy +
/// an illustration of a store), medium (copy only) and compact (phone).
class NitShopBannerAd extends StatelessWidget {
  const NitShopBannerAd({super.key});

  // NitShop brand palette (NitShop repo, brand/build.mjs).
  static const Color orange = Color(0xFFEE6420);
  static const Color slate = Color(0xFF4A5866);
  static const Color night = Color(0xFF0E1217);

  /// Tagged so NitShop's analytics can tell Veena's visitors apart.
  static const String _utm =
      'utm_source=veena&utm_medium=web_carousel&utm_campaign=veena_house_ad';
  static const String signupUrl = 'https://nitshop.in/signup?$_utm';
  static const String siteUrl = 'https://nitshop.in/?$_utm';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : orange.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => BrandAdsService.launchAdWebsite(siteUrl),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [night, Color(0xFF1A212B)]
                    : const [Color(0xFFFFF3EA), Colors.white],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final compact = width < 520;
                final showStore = width >= 760;
                return Stack(
                  children: [
                    // Soft brand-orange glow behind the illustration.
                    Positioned(
                      right: -60,
                      top: -70,
                      child: _Glow(size: 260, opacity: isDark ? 0.16 : 0.12),
                    ),
                    Positioned(
                      left: -50,
                      bottom: -80,
                      child: _Glow(size: 180, opacity: isDark ? 0.08 : 0.06),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Copy(isDark: isDark, compact: compact),
                          ),
                          if (showStore) ...[
                            const SizedBox(width: 20),
                            SizedBox(
                              width: (width * 0.36).clamp(270.0, 360.0),
                              child: _StoreIllustration(isDark: isDark),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              NitShopBannerAd.orange.withValues(alpha: opacity),
              NitShopBannerAd.orange.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo, headline, what you get, and the call to action.
class _Copy extends StatelessWidget {
  const _Copy({required this.isDark, required this.compact});
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? const Color(0xFFE8EDF2) : const Color(0xFF1F2933);
    final muted = isDark ? const Color(0xFF9AA6B2) : NitShopBannerAd.slate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Image.asset(
              isDark
                  ? 'assets/images/nitshop_logo_dark.png'
                  : 'assets/images/nitshop_logo.png',
              height: compact ? 22 : 26,
              filterQuality: FilterQuality.medium,
              semanticLabel: 'NitShop',
            ),
            const Spacer(),
            _SponsoredTag(isDark: isDark),
          ],
        ),
        SizedBox(height: compact ? 8 : 10),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Your business deserves its own '),
              TextSpan(
                text: 'online store.',
                style: TextStyle(color: NitShopBannerAd.orange),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: compact ? 17 : 20,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: compact ? 5 : 6),
        Text(
          'Sell with UPI, COD, GST invoices, shipping and WhatsApp updates '
          '— all in one place.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: muted,
            fontSize: compact ? 12 : 12.5,
            height: 1.3,
          ),
        ),
        SizedBox(height: compact ? 10 : 12),
        Row(
          children: [
            // Shrinks (and scales its label down) rather than overflow on
            // narrow phones or with large text.
            Flexible(
              flex: 3,
              child: ElevatedButton(
                onPressed: () =>
                    BrandAdsService.launchAdWebsite(NitShopBannerAd.signupUrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NitShopBannerAd.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 14 : 18,
                    vertical: compact ? 9 : 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start free for 7 days',
                        style: TextStyle(
                          fontSize: compact ? 12.5 : 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 14),
              Flexible(
                flex: 2,
                child: Text(
                  'Plans from ₹2,999/month',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    for (final (i, point) in (compact
                            ? const ['0% commission', 'No card needed']
                            : const [
                                '0% commission',
                                'No card needed',
                                'Free setup help',
                              ])
                        .indexed) ...[
                      if (i > 0) const TextSpan(text: '   '),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      TextSpan(text: ' $point'),
                    ],
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted,
                  fontSize: compact ? 11 : 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => showSubscriptionModal(context),
              style: TextButton.styleFrom(
                foregroundColor: muted,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Hide ads',
                style: TextStyle(
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SponsoredTag extends StatelessWidget {
  const _SponsoredTag({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
      ),
      child: Text(
        'Sponsored',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }
}

/// A store on NitShop: its own address, a few products, and the moments the
/// platform handles — payment, GST invoice, WhatsApp update. Illustrative.
class _StoreIllustration extends StatelessWidget {
  const _StoreIllustration({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final panel = isDark ? const Color(0xFF161D26) : Colors.white;
    final line = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);
    final bar = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE7EBEF);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The store window.
        Positioned.fill(
          top: 10,
          bottom: 26,
          left: 14,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address bar: every store gets its own address.
                Row(
                  children: [
                    for (final c in const [
                      Color(0xFFFF5F57),
                      Color(0xFFFEBC2E),
                      Color(0xFF28C840),
                    ]) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: bar.withValues(alpha: isDark ? 0.5 : 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 9,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'yourbrand.nitshop.in',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Store header.
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: NitShopBannerAd.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Y',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Your Brand',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1F2933),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 15,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                // Products.
                Expanded(
                  child: Row(
                    children: [
                      for (final (i, p) in const [
                        (Icons.checkroom_rounded, Color(0xFFFDE7DA)),
                        (Icons.diamond_outlined, Color(0xFFE3EDF7)),
                        (Icons.spa_outlined, Color(0xFFE6F4EA)),
                      ].indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _ProductTile(
                            icon: p.$1,
                            tint: p.$2,
                            isDark: isDark,
                            bar: bar,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // What NitShop takes care of for every order.
        Positioned(
          left: 0,
          bottom: 4,
          child: _Toast(
            isDark: isDark,
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF16A34A),
            title: 'Payment received',
            subtitle: 'UPI · straight to your account',
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: _Pill(
            isDark: isDark,
            icon: Icons.chat_rounded,
            iconColor: const Color(0xFF25D366),
            label: 'WhatsApp update sent',
          ),
        ),
        Positioned(
          right: 0,
          bottom: 14,
          child: _Pill(
            isDark: isDark,
            icon: Icons.receipt_long_rounded,
            iconColor: NitShopBannerAd.orange,
            label: 'GST invoice ready',
          ),
        ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.icon,
    required this.tint,
    required this.isDark,
    required this.bar,
  });
  final IconData icon;
  final Color tint;
  final bool isDark;
  final Color bar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? tint.withValues(alpha: 0.16) : tint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.75)
                  : NitShopBannerAd.slate.withValues(alpha: 0.75),
            ),
          ),
        ),
        const SizedBox(height: 5),
        FractionallySizedBox(
          widthFactor: 0.85,
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: bar,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 3),
        FractionallySizedBox(
          widthFactor: 0.5,
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: NitShopBannerAd.orange.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _floatingCard(bool isDark) => BoxDecoration(
  color: isDark ? const Color(0xFF222B36) : Colors.white,
  borderRadius: BorderRadius.circular(10),
  border: Border.all(
    color: isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06),
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ],
);

class _Toast extends StatelessWidget {
  const _Toast({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: _floatingCard(isDark),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 7),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1F2933),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
  });
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: _floatingCard(isDark),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2933),
            ),
          ),
        ],
      ),
    );
  }
}
