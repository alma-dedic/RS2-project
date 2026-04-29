import 'package:flutter/material.dart';
import 'package:heartforcharity_shared/model/responses/review.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';
import 'package:heartforcharity_desktop/providers/organisation_profile_provider.dart';
import 'package:heartforcharity_shared/providers/review_provider.dart';
import 'package:heartforcharity_desktop/utils/auth_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final int _pageSize = 10;

  List<Review> _reviews = [];
  int _totalCount = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  int? _organisationProfileId;
  int? _minRating;
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _loadOrgThenReviews();
  }

  Future<void> _loadOrgThenReviews() async {
    try {
      final profile = await context.read<OrganisationProfileProvider>().getMe();
      if (!mounted) return;
      setState(() => _organisationProfileId = profile.organisationProfileId);
      await _loadReviews(reset: true);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReviews({bool reset = false}) async {
    if (_organisationProfileId == null) return;

    if (reset) {
      setState(() { _isLoading = true; _currentPage = 0; _reviews = []; });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final Map<String, dynamic> filter = {
        'organisationProfileId': _organisationProfileId,
        'page': _currentPage,
        'pageSize': _pageSize,
        'includeTotalCount': true,
        if (_minRating != null) 'minRating': _minRating,
      };

      final result = await context.read<ReviewProvider>().get(filter: filter);

      if (mounted) {
        var items = result.items;
        items = _applySorting(items);
        setState(() {
          if (reset) {
            _reviews = items;
          } else {
            _reviews.addAll(items);
          }
          _totalCount = result.totalCount ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reviews: ${BaseProvider.cleanError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; _isLoadingMore = false; });
    }
  }

  List<Review> _applySorting(List<Review> items) {
    final sorted = List<Review>.from(items);
    switch (_sortBy) {
      case 'newest':
        sorted.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        break;
      case 'oldest':
        sorted.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
        break;
      case 'highest':
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowest':
        sorted.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }
    return sorted;
  }

  bool get _hasMore => _reviews.length < _totalCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            const SizedBox(height: 20),
            _buildFiltersRow(),
            const SizedBox(height: 24),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text('Reviews', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
        const Spacer(),
        Image.asset('assets/logo.png', height: 36, errorBuilder: (_, e, s) => const SizedBox()),
      ],
    );
  }

  Widget _buildFiltersRow() {
    return Row(
      children: [
        _buildDropdown<int?>(
          value: _minRating,
          hint: 'All ratings',
          items: [
            const DropdownMenuItem(value: null, child: Text('All ratings')),
            ...List.generate(5, (i) => i + 1).map((r) => DropdownMenuItem(
              value: r,
              child: Row(
                children: [
                  ...List.generate(r, (_) => const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B))),
                  ...List.generate(5 - r, (_) => const Icon(Icons.star_outline, size: 14, color: Color(0xFFD1D5DB))),
                  const SizedBox(width: 4),
                  Text('$r+'),
                ],
              ),
            )),
          ],
          onChanged: (val) {
            setState(() => _minRating = val);
            _loadReviews(reset: true);
          },
        ),
        const SizedBox(width: 10),
        _buildDropdown<String>(
          value: _sortBy,
          hint: 'Sort',
          items: const [
            DropdownMenuItem(value: 'newest', child: Text('Newest first')),
            DropdownMenuItem(value: 'oldest', child: Text('Oldest first')),
            DropdownMenuItem(value: 'highest', child: Text('Highest rating')),
            DropdownMenuItem(value: 'lowest', child: Text('Lowest rating')),
          ],
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _sortBy = val;
              _reviews = _applySorting(_reviews);
            });
          },
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
          items: items,
          onChanged: onChanged,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down, size: 20, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_reviews.isEmpty) {
      return Center(
        child: Text('No reviews yet.', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Showing ${_reviews.length} of $_totalCount reviews',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _reviews.length,
            separatorBuilder: (context, i) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ReviewCard(review: _reviews[i]),
          ),
        ),
        if (_hasMore) ...[
          const SizedBox(height: 16),
          Center(
            child: _isLoadingMore
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    onPressed: () { _currentPage++; _loadReviews(); },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    ),
                    child: const Text('Load more', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = review.createdAt != null
        ? DateFormat('dd MMM yyyy').format(review.createdAt!)
        : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            backgroundImage: review.reviewerAvatarUrl != null && review.reviewerAvatarUrl!.isNotEmpty
                ? authNetworkImage(review.reviewerAvatarUrl!)
                : null,
            child: review.reviewerAvatarUrl == null || review.reviewerAvatarUrl!.isEmpty
                ? Text(
                    (review.reviewerName != null && review.reviewerName!.isNotEmpty)
                        ? review.reviewerName![0].toUpperCase()
                        : '?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.primary),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      review.reviewerName ?? 'Anonymous',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    ),
                    const Spacer(),
                    Text(dateStr, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_outline,
                    size: 18,
                    color: const Color(0xFFF59E0B),
                  )),
                ),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(review.comment!, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
