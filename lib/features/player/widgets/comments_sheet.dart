import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/services/comment_service.dart';
import '../../../core/models/paged_response.dart';
import '../../../core/models/comment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/profile_provider.dart';
import '../../channel/services/channel_service.dart';

enum CommentsSource { mainMedia, channel }

class _ReplyThreadState {
  const _ReplyThreadState({
    this.loadedReplies = const <Comment>[],
    this.visibleCount = 0,
    this.currentPage = -1,
    this.totalElements = 0,
    this.isExpanded = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<Comment> loadedReplies;
  final int visibleCount;
  final int currentPage;
  final int totalElements;
  final bool isExpanded;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  _ReplyThreadState copyWith({
    List<Comment>? loadedReplies,
    int? visibleCount,
    int? currentPage,
    int? totalElements,
    bool? isExpanded,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return _ReplyThreadState(
      loadedReplies: loadedReplies ?? this.loadedReplies,
      visibleCount: visibleCount ?? this.visibleCount,
      currentPage: currentPage ?? this.currentPage,
      totalElements: totalElements ?? this.totalElements,
      isExpanded: isExpanded ?? this.isExpanded,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final String mediaId;
  final CommentsSource source;

  const CommentsSheet({
    super.key,
    required this.mediaId,
    this.source = CommentsSource.mainMedia,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  bool _isPosting = false;
  bool _isLoading = true;
  List<Comment> _comments = [];
  int _commentCount = 0;
  int? _replyToCommentId;
  String? _replyToUsername;
  final Map<int, _ReplyThreadState> _replyThreads = <int, _ReplyThreadState>{};

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final PagedResponse<Comment> commentsPage;

      if (widget.source == CommentsSource.channel) {
        final channelService = context.read<ChannelService>();
        commentsPage = await channelService.getMediaComments(widget.mediaId);
      } else {
        final commentService = context.read<CommentService>();
        commentsPage = await commentService.getComments(widget.mediaId);
      }

      if (mounted) {
        final rootComments = commentsPage.content
            .where((comment) => comment.isRootComment)
            .toList(growable: false);
        setState(() {
          _comments = rootComments;
          _commentCount = commentsPage.totalElements;
          _replyThreads.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading comments: $e')));
      }
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final parentCommentId = _replyToCommentId;

    setState(() => _isPosting = true);
    try {
      final success = widget.source == CommentsSource.channel
          ? await context.read<ChannelService>().postMediaComment(
              widget.mediaId,
              content,
              parentCommentId: parentCommentId,
            )
          : await context.read<CommentService>().postComment(
              widget.mediaId,
              content,
              parentCommentId: parentCommentId,
            );

      if (success) {
        final repliedTo = _replyToCommentId;
        _commentController.clear();
        _clearReplyTarget();
        await _loadComments();
        if (repliedTo != null) {
          await _loadReplies(repliedTo, forceRefresh: true);
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to post comment')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _setReplyTarget(Comment comment) {
    if (!comment.isRootComment) return;
    setState(() {
      _replyToCommentId = comment.id;
      _replyToUsername = comment.username;
    });
    _commentFocusNode.requestFocus();
  }

  void _clearReplyTarget() {
    if (_replyToCommentId == null && _replyToUsername == null) return;
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = null;
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return DateFormat.yMMMd().format(dateTime);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _deleteComment(int commentId, {int? parentCommentId}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Delete Comment',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this comment?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = widget.source == CommentsSource.channel
          ? await context.read<ChannelService>().deleteMediaComment(
              widget.mediaId,
              commentId,
            )
          : await context.read<CommentService>().deleteComment(
              widget.mediaId,
              commentId,
            );

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete comment')),
          );
        }
        return;
      }

      await _loadComments();
      if (parentCommentId != null && parentCommentId > 0) {
        await _loadReplies(parentCommentId, forceRefresh: true);
      }
      if (_replyToCommentId == commentId) {
        _clearReplyTarget();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  _ReplyThreadState _getThreadState(int commentId) {
    return _replyThreads[commentId] ?? const _ReplyThreadState();
  }

  Future<PagedResponse<Comment>> _fetchReplies(
    int commentId, {
    required int page,
    required int size,
  }) {
    if (widget.source == CommentsSource.channel) {
      return context.read<ChannelService>().getMediaCommentReplies(
        widget.mediaId,
        commentId,
        page: page,
        size: size,
      );
    }

    return context.read<CommentService>().getReplies(
      widget.mediaId,
      commentId,
      page: page,
      size: size,
    );
  }

  Future<void> _loadReplies(
    int commentId, {
    bool loadMore = false,
    bool forceRefresh = false,
  }) async {
    final current = _getThreadState(commentId);

    if ((current.isLoading || current.isLoadingMore) && !forceRefresh) {
      return;
    }

    if (loadMore &&
        current.totalElements > 0 &&
        current.loadedReplies.length >= current.totalElements) {
      return;
    }

    if (!loadMore &&
        !forceRefresh &&
        current.loadedReplies.isNotEmpty &&
        !current.isExpanded) {
      setState(() {
        _replyThreads[commentId] = current.copyWith(
          isExpanded: true,
          error: null,
        );
      });
      return;
    }

    final nextPage = loadMore ? current.currentPage + 1 : 0;

    setState(() {
      _replyThreads[commentId] = current.copyWith(
        isExpanded: true,
        isLoading: !loadMore,
        isLoadingMore: loadMore,
        error: null,
      );
    });

    try {
      final pageData = await _fetchReplies(commentId, page: nextPage, size: 10);
      final mergedReplies = loadMore
          ? <Comment>[...current.loadedReplies, ...pageData.content]
          : pageData.content;

      final targetVisible = loadMore
          ? current.visibleCount + 10
          : (mergedReplies.length < 3 ? mergedReplies.length : 3);
      final nextVisible = targetVisible > mergedReplies.length
          ? mergedReplies.length
          : targetVisible;

      if (!mounted) return;
      setState(() {
        _replyThreads[commentId] = _ReplyThreadState(
          loadedReplies: mergedReplies,
          visibleCount: nextVisible,
          currentPage: nextPage,
          totalElements: pageData.totalElements,
          isExpanded: true,
          isLoading: false,
          isLoadingMore: false,
          error: null,
        );
      });
    } catch (e) {
      if (!mounted) return;
      final latest = _getThreadState(commentId);
      setState(() {
        _replyThreads[commentId] = latest.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: e.toString(),
          isExpanded: true,
        );
      });
    }
  }

  void _toggleReplies(Comment rootComment) {
    final thread = _getThreadState(rootComment.id);

    if (thread.isExpanded) {
      setState(() {
        _replyThreads[rootComment.id] = thread.copyWith(isExpanded: false);
      });
      return;
    }

    if (thread.loadedReplies.isEmpty || thread.error != null) {
      _loadReplies(rootComment.id, forceRefresh: true);
      return;
    }

    setState(() {
      _replyThreads[rootComment.id] = thread.copyWith(isExpanded: true);
    });
  }

  Future<void> _showMoreReplies(int commentId) async {
    final thread = _getThreadState(commentId);
    if (thread.isLoadingMore) return;

    if (thread.visibleCount < thread.loadedReplies.length) {
      final nextVisible =
          (thread.visibleCount + 10) > thread.loadedReplies.length
          ? thread.loadedReplies.length
          : thread.visibleCount + 10;
      setState(() {
        _replyThreads[commentId] = thread.copyWith(visibleCount: nextVisible);
      });
      return;
    }

    await _loadReplies(commentId, loadMore: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = context.watch<ProfileProvider>().profile?.id;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments ($_commentCount)',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        const Text(
                          'Be the first to share your thoughts!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return _buildRootCommentTile(
                        comment,
                        isOwnComment: comment.userId == currentUserId,
                        isDark: isDark,
                        currentUserId: currentUserId,
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

          // Comment Input
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_replyToCommentId != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Replying to ${_replyToUsername ?? 'comment'}',
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: _clearReplyTarget,
                                icon: const Icon(Icons.close_rounded, size: 16),
                                visualDensity: VisualDensity.compact,
                                splashRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: _replyToCommentId == null
                                ? 'Add a comment...'
                                : 'Write a reply...',
                            border: InputBorder.none,
                            hintStyle: const TextStyle(color: Colors.grey),
                          ),
                          maxLines: null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isPosting ? null : _postComment,
                  icon: _isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: AppColors.primary,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRootCommentTile(
    Comment comment, {
    required bool isOwnComment,
    required bool isDark,
    required String? currentUserId,
  }) {
    final theme = Theme.of(context);
    final thread = _getThreadState(comment.id);
    final canToggleReplies =
        comment.replyCount > 0 || thread.loadedReplies.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(comment),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            comment.username,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeAgo(comment.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              if (isOwnComment)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: IconButton(
                    onPressed: () => _deleteComment(comment.id),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    splashRadius: 18,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Wrap(
              spacing: 2,
              children: [
                TextButton(
                  onPressed: () => _setReplyTarget(comment),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reply'),
                ),
                if (canToggleReplies)
                  TextButton(
                    onPressed: () => _toggleReplies(comment),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      thread.isExpanded
                          ? 'Hide replies'
                          : 'View replies (${comment.replyCount})',
                    ),
                  ),
              ],
            ),
          ),
          if (thread.isExpanded)
            _buildRepliesSection(
              parentComment: comment,
              thread: thread,
              isDark: isDark,
              currentUserId: currentUserId,
            ),
        ],
      ),
    );
  }

  Widget _buildRepliesSection({
    required Comment parentComment,
    required _ReplyThreadState thread,
    required bool isDark,
    required String? currentUserId,
  }) {
    final theme = Theme.of(context);

    if (thread.isLoading && thread.loadedReplies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: 48, top: 8, bottom: 8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (thread.error != null && thread.loadedReplies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
        child: TextButton(
          onPressed: () => _loadReplies(parentComment.id, forceRefresh: true),
          child: const Text('Failed to load replies. Tap to retry.'),
        ),
      );
    }

    final visibleReplies = thread.loadedReplies
        .take(thread.visibleCount)
        .toList();
    final canShowMore = thread.visibleCount < thread.totalElements;

    return Padding(
      padding: const EdgeInsets.only(left: 50, top: 8),
      child: Column(
        children: [
          for (final reply in visibleReplies)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(reply, radius: 14),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                reply.username,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatTimeAgo(reply.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reply.content,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (reply.userId == currentUserId)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: IconButton(
                        onPressed: () => _deleteComment(
                          reply.id,
                          parentCommentId: parentComment.id,
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        splashRadius: 16,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (canShowMore)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: thread.isLoadingMore
                    ? null
                    : () => _showMoreReplies(parentComment.id),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  thread.isLoadingMore
                      ? 'Loading replies...'
                      : 'See more replies',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Comment comment, {double radius = 18}) {
    final canUseImage =
        comment.userImageUrl != null && comment.userImageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      backgroundImage: canUseImage
          ? CachedNetworkImageProvider(comment.userImageUrl!)
          : null,
      child: !canUseImage
          ? Text(
              comment.username.isNotEmpty
                  ? comment.username[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: radius * 0.75,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}
