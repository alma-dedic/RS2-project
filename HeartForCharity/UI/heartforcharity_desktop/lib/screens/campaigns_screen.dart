import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heartforcharity_desktop/model/responses/campaign.dart';
import 'package:heartforcharity_desktop/model/responses/category.dart';
import 'package:heartforcharity_desktop/model/search_objects/campaign_search_object.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';
import 'package:heartforcharity_desktop/providers/campaign_provider.dart';
import 'package:heartforcharity_desktop/providers/category_provider.dart';
import 'package:heartforcharity_desktop/screens/campaign_add_edit_screen.dart';
import 'package:heartforcharity_desktop/screens/campaign_donations_screen.dart';
import 'package:heartforcharity_desktop/utils/auth_image.dart';
import 'package:provider/provider.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final _searchController = TextEditingController();
  final int _pageSize = 5;
  Timer? _searchDebounce;

  List<Campaign> _campaigns = [];
  List<Category> _categories = [];
  int _totalCount = 0;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  int? _selectedCategoryId;
  String? _selectedStatus;

  final List<String> _statuses = ['Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCampaigns(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final provider = context.read<CategoryProvider>();
      final result = await provider.get(filter: {'pageSize': 100, 'appliesTo': 'Campaign'});
      if (mounted) setState(() => _categories = result.items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _loadCampaigns({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _campaigns = [];
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final provider = context.read<CampaignProvider>();
      final filter = CampaignSearchObject(
        fts: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        categoryId: _selectedCategoryId,
        status: _selectedStatus,
        page: _currentPage,
        pageSize: _pageSize,
        includeTotalCount: true,
      );

      final result = await provider.getMy(filter: filter.toMap());

      if (mounted) {
        setState(() {
          if (reset) {
            _campaigns = result.items;
          } else {
            _campaigns.addAll(result.items);
          }
          _totalCount = result.totalCount ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load campaigns: ${BaseProvider.cleanError(e)}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    _currentPage++;
    await _loadCampaigns();
  }

  void _openAddCampaign() async {
    final categoryProvider = context.read<CategoryProvider>();

    try {
      final categoriesResult = await categoryProvider.get(
        filter: {'appliesTo': 'Campaign', 'pageSize': 1},
      );
      if (!mounted) return;
      if (categoriesResult.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Cannot create a campaign: no Campaign categories exist. '
            'Please ask an admin to add a category first.',
          ),
        ));
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify prerequisites: ${BaseProvider.cleanError(e)}')),
        );
      }
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CampaignAddEditScreen()),
    );
    if (result == true) await _loadCampaigns(reset: true);
  }

  void _openEditCampaign(Campaign campaign) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CampaignAddEditScreen(campaign: campaign)),
    );
    if (result == true) await _loadCampaigns(reset: true);
  }

  void _openDonations(Campaign campaign) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CampaignDonationsScreen(campaign: campaign)),
    );
  }

  bool get _hasMore => _campaigns.length < _totalCount;

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
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _searchController,
              onChanged: (_) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 500), () => _loadCampaigns(reset: true));
              },
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search campaigns...',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Image.asset('assets/logo.png', height: 36, errorBuilder: (_, _, _) => const SizedBox()),
      ],
    );
  }

  Widget _buildFiltersRow() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _buildDropdown<int?>(
          value: _selectedCategoryId,
          hint: 'Category',
          items: [
            const DropdownMenuItem(value: null, child: Text('All categories')),
            ..._categories.map((c) => DropdownMenuItem(value: c.categoryId, child: Text(c.name))),
          ],
          onChanged: (val) {
            setState(() => _selectedCategoryId = val);
            _loadCampaigns(reset: true);
          },
        ),
        const SizedBox(width: 12),
        _buildDropdown<String?>(
          value: _selectedStatus,
          hint: 'Status',
          items: [
            const DropdownMenuItem(value: null, child: Text('All statuses')),
            ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
          ],
          onChanged: (val) {
            setState(() => _selectedStatus = val);
            _loadCampaigns(reset: true);
          },
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _openAddCampaign,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add new campaign'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_campaigns.isEmpty) {
      return Center(
        child: Text(
          'No campaigns found.',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Showing ${_campaigns.length} of $_totalCount campaigns',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _campaigns.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _CampaignCard(
              campaign: _campaigns[index],
              onEdit: () => _openEditCampaign(_campaigns[index]),
              onDonations: () => _openDonations(_campaigns[index]),
            ),
          ),
        ),
        if (_hasMore) ...[
          const SizedBox(height: 16),
          Center(
            child: _isLoadingMore
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    onPressed: _loadMore,
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

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onEdit;
  final VoidCallback onDonations;

  const _CampaignCard({
    required this.campaign,
    required this.onEdit,
    required this.onDonations,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final coverMedia = campaign.campaignMedias.where((m) => m.isCover).firstOrNull ??
        campaign.campaignMedias.firstOrNull;
    final progress = campaign.targetAmount > 0
        ? (campaign.currentAmount / campaign.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      height: 130,
      child: Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            child: SizedBox(
              width: 160,
              height: 120,
              child: coverMedia?.url != null
                  ? Image(
                      image: authNetworkImage(coverMedia!.url!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imagePlaceholder(colorScheme),
                    )
                  : _imagePlaceholder(colorScheme),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        campaign.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (campaign.status != null) _StatusBadge(status: campaign.status!),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    campaign.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${campaign.currentAmount.toStringAsFixed(2)} out of \$${campaign.targetAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: colorScheme.outline,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(label: 'Donations', onTap: onDonations),
                if (campaign.status == 'Active') ...[
                  const SizedBox(height: 8),
                  _ActionButton(label: 'Edit', onTap: onEdit),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.outline,
      child: Center(
        child: Icon(Icons.image_outlined, size: 40, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 100,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        child: Text(label),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = const Color(0xFF10B981);
        break;
      case 'completed':
        color = const Color(0xFF3B82F6);
        break;
      case 'cancelled':
        color = const Color(0xFF6B7280);
        break;
      default:
        color = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
