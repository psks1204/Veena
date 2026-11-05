import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/utils/count_formatter.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../channel/models/winner_response.dart';
import '../../channel/screens/public_channel_screen.dart';
import '../../channel/screens/uploads_screen.dart';
import '../models/competition_response.dart';
import '../services/competition_service.dart';

/// Dedicated Competition View for the Karaoke Tab
///
/// Implements live competition ranking, leaderboard podium, prize showcase,
/// and winner announcement according to Veena Aura design specifications.
class CompetitionView extends StatefulWidget {
  final VoidCallback onSingNowTap;

  const CompetitionView({super.key, required this.onSingNowTap});

  @override
  State<CompetitionView> createState() => _CompetitionViewState();
}

class _CompetitionViewState extends State<CompetitionView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompetitionService>().fetchOngoingCompetition();
    });
  }

  void _openPerformer(LeaderboardEntry entry) {
    if (entry.mediaId != null && entry.mediaId!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UploadsScreen(initialMediaId: entry.mediaId),
        ),
      );
    } else if (entry.channelId != null && entry.channelId!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicChannelScreen(
            channelId: entry.channelId!,
            channelName: entry.channelName ?? entry.name,
          ),
        ),
      );
    }
  }

  void _openWinnerReel(WinningReel? reel, WinnerProfile? winner) {
    if (reel?.mediaId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UploadsScreen(initialMediaId: reel!.mediaId.toString()),
        ),
      );
    } else if (winner?.channelId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicChannelScreen(
            channelId: winner!.channelId!,
            channelName: winner.channelName ?? winner.name,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final compService = context.watch<CompetitionService>();

    if (compService.isLoading && compService.currentCompetition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Loading competition...',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (compService.errorMessage != null && compService.currentCompetition == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load competition details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => compService.fetchOngoingCompetition(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final competition = compService.currentCompetition;
    if (competition == null) {
      return _buildNoCompetitionEmptyState(isDark);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => compService.fetchOngoingCompetition(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          120,
        ),
        children: [
          // Hero Banner & Info
          _buildHeroBanner(competition, isDark),
          const SizedBox(height: 18),

          // Conditional UI depending on status
          if (competition.isOngoing) ...[
            _buildOngoingSection(competition, isDark),
          ] else if (competition.isEnded) ...[
            _buildEndedSection(competition, isDark),
          ] else ...[
            _buildUpcomingSection(competition, isDark),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HERO BANNER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeroBanner(CompetitionResponse comp, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF261220), const Color(0xFF16151A)]
              : [const Color(0xFFFDE8F1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image if present
          if (comp.bannerImageUrl != null && comp.bannerImageUrl!.isNotEmpty)
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: AppNetworkImage(
                    imageUrl: comp.bannerImageUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusPill(comp),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, color: AppColors.primary, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'VEENA ARENA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusPill(comp),
                ],
              ),
            ),

          // Banner Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comp.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                if (comp.description != null && comp.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    comp.description!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (comp.prize != null && comp.prize!.isNotEmpty)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB800).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFFB800).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.card_giftcard_rounded,
                                color: Color(0xFFFFB800),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Prize: ${comp.prize}${comp.prizeValue != null ? ' (₹${comp.prizeValue!.toInt()})' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFFB800),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(CompetitionResponse comp) {
    if (comp.isOngoing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              comp.daysRemaining > 0
                  ? 'LIVE • ${comp.daysRemaining}d left'
                  : 'LIVE • Ends today',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    } else if (comp.isEnded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFD4A017),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.white, size: 14),
            SizedBox(width: 5),
            Text(
              'WINNERS DECLARED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'UPCOMING',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ONGOING COMPETITION (Ranking, Podium, Leaderboard Table, Prizes)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOngoingSection(CompetitionResponse comp, bool isDark) {
    final leaderboard = comp.leaderboard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row: "Competition Ranking" with Trophy
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFB800),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Competition Ranking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Info Pill (matching reference image)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.blue.withOpacity(0.12)
                : Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ranking based on most likes in this competition period',
                  style: TextStyle(
                    color: isDark ? Colors.blue[200] : Colors.blue[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Podium of Top 3 Performers
        if (leaderboard.isNotEmpty) ...[
          _buildPodium(leaderboard, isDark),
          const SizedBox(height: 20),
        ] else ...[
          _buildNoPerformersYetCard(isDark),
          const SizedBox(height: 20),
        ],

        // Leaderboard List (Rank 4 to 10)
        if (leaderboard.length > 3) ...[
          Text(
            'Leaderboard',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          _buildLeaderboardTable(leaderboard.sublist(3), isDark),
          const SizedBox(height: 20),
        ],

        // Prize Showcase Card
        _buildPrizeShowcaseCard(comp, isDark),
        const SizedBox(height: 24),

        // "Sing & Compete Now" CTA
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.onSingNowTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_external_on_rounded, size: 22),
                SizedBox(width: 8),
                Text(
                  'Sing & Compete Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Podium for top 3 (matching reference image)
  Widget _buildPodium(List<LeaderboardEntry> leaderboard, bool isDark) {
    final first = leaderboard[0];
    final second = leaderboard.length > 1 ? leaderboard[1] : null;
    final third = leaderboard.length > 2 ? leaderboard[2] : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF231C14), const Color(0xFF1B1713)]
              : [const Color(0xFFFFF7EC), const Color(0xFFFFF0DC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          color: const Color(0xFFFFB800).withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB800).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // #2 Performer (Left)
          Expanded(
            child: second != null
                ? _buildPodiumMember(
                    entry: second,
                    rank: 2,
                    avatarSize: 62,
                    badgeLabel: 'Most Liked',
                    badgeColor: const Color(0xFF6C5CE7),
                    ringColor: const Color(0xFFB0BEC5),
                    isDark: isDark,
                  )
                : const SizedBox.shrink(),
          ),

          // #1 Performer (Center, Higher)
          Expanded(
            child: _buildPodiumMember(
              entry: first,
              rank: 1,
              avatarSize: 76,
              badgeLabel: 'Top Performer',
              badgeColor: const Color(0xFFFFB800),
              ringColor: const Color(0xFFFFD700),
              isDark: isDark,
              isFirst: true,
            ),
          ),

          // #3 Performer (Right)
          Expanded(
            child: third != null
                ? _buildPodiumMember(
                    entry: third,
                    rank: 3,
                    avatarSize: 62,
                    badgeLabel: 'Trending',
                    badgeColor: const Color(0xFFE84393),
                    ringColor: const Color(0xFFCD7F32),
                    isDark: isDark,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumMember({
    required LeaderboardEntry entry,
    required int rank,
    required double avatarSize,
    required String badgeLabel,
    required Color badgeColor,
    required Color ringColor,
    required bool isDark,
    bool isFirst = false,
  }) {
    final photo = entry.photoUrl ?? entry.channelImageUrl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openPerformer(entry),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown for #1
          if (isFirst)
            const Text(
              '👑',
              style: TextStyle(fontSize: 24),
            )
          else
            const SizedBox(height: 12),

          // Avatar with rank border
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: avatarSize + 6,
                height: avatarSize + 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: isFirst ? 3.0 : 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: ringColor.withOpacity(0.3),
                      blurRadius: isFirst ? 12 : 6,
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(avatarSize / 2),
                child: SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: photo != null && photo.isNotEmpty
                      ? AppNetworkImage(
                          imageUrl: photo,
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                        )
                      : Container(
                          color: ringColor.withOpacity(0.2),
                          child: Icon(
                            Icons.person_rounded,
                            size: avatarSize * 0.5,
                            color: ringColor,
                          ),
                        ),
                ),
              ),
              // Rank badge overlay (for #2 and #3)
              if (!isFirst)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: ringColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Performer Name
          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isFirst ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),

          // Flame + Likes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent, size: 14),
              const SizedBox(width: 2),
              Text(
                formatCompactCount(entry.likesInCompetition),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Badge Pill (Top Performer / Most Liked / Trending)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Leaderboard Table for Ranks 4 to 10 (matching reference image)
  Widget _buildLeaderboardTable(List<LeaderboardEntry> list, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Singer',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
                Text(
                  'Likes',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
          ),

          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
            ),
            itemBuilder: (context, index) {
              final entry = list[index];
              final photo = entry.photoUrl ?? entry.channelImageUrl;
              return InkWell(
                onTap: () => _openPerformer(entry),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      // Rank
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${entry.rank}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      // Avatar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: photo != null && photo.isNotEmpty
                              ? AppNetworkImage(
                                  imageUrl: photo,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 100,
                                )
                              : Container(
                                  color: AppColors.primary.withOpacity(0.15),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Singer & Media Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (entry.mediaTitle != null && entry.mediaTitle!.isNotEmpty)
                              Text(
                                entry.mediaTitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Likes count
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: Colors.redAccent,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatCompactCount(entry.likesInCompetition),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Prize Showcase Card (matching reference image)
  Widget _buildPrizeShowcaseCard(CompetitionResponse comp, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241C10) : const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB800).withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Prize Image / Graphic
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              color: isDark ? const Color(0xFF1E1710) : Colors.white,
              child: comp.prizeImageUrl != null && comp.prizeImageUrl!.isNotEmpty
                  ? AppNetworkImage(
                      imageUrl: comp.prizeImageUrl!,
                      fit: BoxFit.contain,
                      memCacheWidth: 200,
                    )
                  : const Center(
                      child: Text('🎁', style: TextStyle(fontSize: 34)),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Prize text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Prize: ${comp.prize ?? 'Grand Trophy & Rewards'}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE67E22),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (comp.prizeValue != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Worth ₹${comp.prizeValue!.toInt()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Upload your karaoke cover reel. Performer with the most likes wins!',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPerformersYetCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          const Text('🎤', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(
            'Be the First Performer!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No performances submitted yet for this competition. Pick a track from All Songs, record your cover, and take the #1 spot!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ENDED COMPETITION (Winner Announcement - matching reference image right)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEndedSection(CompetitionResponse comp, bool isDark) {
    final winnerData = comp.winnerAnnouncement;
    final winner = winnerData?.winner;
    final reel = winnerData?.winningReel;
    final runnerUps = winnerData?.runnerUps ?? [];

    return Column(
      children: [
        // Trophy & Confetti celebration
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF261D12), const Color(0xFF1A1410)]
                  : [const Color(0xFFFFFBF2), const Color(0xFFFFF3DB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.12),
                blurRadius: 18,
              ),
            ],
          ),
          child: Column(
            children: [
              // Golden Trophy with laurel
              const Text('🏆', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 10),

              // Ribbon: WINNER ANNOUNCED
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE71D36), Color(0xFFC70D22)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE71D36).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'WINNER ANNOUNCED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Best Performance • User Favorite',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),

              // Winner Avatar
              if (winner != null) ...[
                GestureDetector(
                  onTap: () => _openWinnerReel(reel, winner),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD700),
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(44),
                        child: SizedBox(
                          width: 88,
                          height: 88,
                          child: (winner.photoUrl ?? winner.channelImageUrl) != null
                              ? AppNetworkImage(
                                  imageUrl: (winner.photoUrl ?? winner.channelImageUrl)!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 250,
                                )
                              : Container(
                                  color: Colors.amber.withOpacity(0.2),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 44,
                                    color: Colors.amber,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Winner Name with verified badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      winner.channelName ?? winner.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.blueAccent,
                      size: 18,
                    ),
                  ],
                ),

                // Winning song title
                if (reel != null && reel.title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_note_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          reel.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Stats row
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatPill(
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.deepOrangeAccent,
                      label: formatCompactCount(reel?.totalLikesInPeriod ?? 0),
                      caption: 'Likes',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 14),
                    _buildStatPill(
                      icon: Icons.play_arrow_rounded,
                      color: Colors.blueAccent,
                      label: formatCompactCount(reel?.playCount ?? 0),
                      caption: 'Views',
                      isDark: isDark,
                    ),
                    if (winner.subscriberCount > 0) ...[
                      const SizedBox(width: 14),
                      _buildStatPill(
                        icon: Icons.people_alt_rounded,
                        color: Colors.purpleAccent,
                        label: formatCompactCount(winner.subscriberCount),
                        caption: 'Fans',
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Prize Card inside Winner Announcement
              _buildPrizeShowcaseCard(comp, isDark),
              const SizedBox(height: 14),

              // Quote
              Text(
                '“Incredible performance! Truly a star of Veena Music.”',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),

              if (reel?.mediaId != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _openWinnerReel(reel, winner),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A017),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.play_circle_filled_rounded, size: 20),
                    label: const Text(
                      'Watch Winning Performance',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Runner Ups
        if (runnerUps.isNotEmpty) ...[
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Honorable Runner-Ups',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...runnerUps.map((runner) => _buildRunnerUpCard(runner, isDark)),
        ],

        const SizedBox(height: 24),
        // Next competition CTA
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: widget.onSingNowTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.music_note_rounded),
            label: const Text(
              'Practice for Next Competition',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required Color color,
    required String label,
    required String caption,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                caption,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRunnerUpCard(RunnerUp runner, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: runner.rank == 2 ? const Color(0xFFB0BEC5) : const Color(0xFFCD7F32),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${runner.rank}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 34,
              height: 34,
              child: runner.photoUrl != null && runner.photoUrl!.isNotEmpty
                  ? AppNetworkImage(
                      imageUrl: runner.photoUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 100,
                    )
                  : Container(
                      color: Colors.grey.withOpacity(0.3),
                      child: const Icon(Icons.person, size: 18),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  runner.channelName ?? runner.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (runner.mediaTitle.isNotEmpty)
                  Text(
                    runner.mediaTitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                formatCompactCount(runner.likesInPeriod),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPCOMING COMPETITION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildUpcomingSection(CompetitionResponse comp, bool isDark) {
    return Column(
      children: [
        _buildPrizeShowcaseCard(comp, isDark),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1B1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.schedule_rounded, color: Colors.blueAccent, size: 36),
              const SizedBox(height: 10),
              Text(
                'Starting Soon!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (comp.startDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Begins on ${DateFormat('MMMM d, yyyy').format(comp.startDate!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Get a head start by picking your favorite karaoke song from the All Songs tab and practicing your performance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: widget.onSingNowTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.mic_rounded),
            label: const Text(
              'Browse Karaoke Songs to Practice',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EMPTY STATE: NO ACTIVE COMPETITION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNoCompetitionEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Singing Competitions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Exciting singing contests and grand prizes are on the way! Practice your vocal skills with your favorite karaoke tracks.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onSingNowTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.mic_rounded, size: 20),
              label: const Text(
                'Explore Karaoke Songs',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
