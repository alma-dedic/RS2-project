import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heartforcharity_desktop/model/responses/campaign.dart';
import 'package:heartforcharity_desktop/model/responses/donation.dart';
import 'package:heartforcharity_desktop/model/search_objects/donation_search_object.dart';
import 'package:heartforcharity_desktop/providers/donation_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CampaignDonationsScreen extends StatefulWidget {
  final Campaign campaign;

  const CampaignDonationsScreen({super.key, required this.campaign});

  @override
  State<CampaignDonationsScreen> createState() => _CampaignDonationsScreenState();
}

class _CampaignDonationsScreenState extends State<CampaignDonationsScreen> {
  final int _pageSize = 5;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<Donation> _donations = [];
  int _totalCount = 0;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  String _dateOrder = 'desc';
  String _amountOrder = 'desc';
  String _activeSort = 'date';

  @override
  void initState() {
    super.initState();
    _loadDonations(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDonations({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _donations = [];
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final provider = context.read<DonationProvider>();
      final filter = DonationSearchObject(
        campaignId: widget.campaign.campaignId,
        fts: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        page: _currentPage,
        pageSize: _pageSize,
        includeTotalCount: true,
        orderBy: _activeSort,
        orderDescending: _activeSort == 'date' ? (_dateOrder == 'desc') : (_amountOrder == 'desc'),
      );

      final result = await provider.get(filter: filter.toMap());

      if (mounted) {
        setState(() {
          if (reset) {
            _donations = result.items;
          } else {
            _donations.addAll(result.items);
          }
          _totalCount = result.totalCount ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load donations: $e')),
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
    await _loadDonations();
  }

  bool get _hasMore => _donations.length < _totalCount;

  double get _progress => widget.campaign.targetAmount > 0
      ? (widget.campaign.currentAmount / widget.campaign.targetAmount).clamp(0.0, 1.0)
      : 0.0;

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
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
                const Spacer(),
                Image.asset('assets/logo.png', height: 36, errorBuilder: (context, e, s) => const SizedBox()),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.campaign.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${widget.campaign.currentAmount.toStringAsFixed(2)} out of \$${widget.campaign.targetAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: colorScheme.outline,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(const Duration(milliseconds: 400), () => _loadDonations(reset: true));
                      },
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by donor name...',
                        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                        prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSortRow(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortRow() {
    return Row(
      children: [
        _buildSortDropdown(
          label: 'Date',
          descLabel: 'Newest first',
          ascLabel: 'Oldest first',
          value: _dateOrder,
          isActive: _activeSort == 'date',
          onChanged: (val) {
            setState(() {
              _dateOrder = val!;
              _activeSort = 'date';
            });
            _loadDonations(reset: true);
          },
        ),
        const SizedBox(width: 12),
        _buildSortDropdown(
          label: 'Amount',
          descLabel: 'Highest first',
          ascLabel: 'Lowest first',
          value: _amountOrder,
          isActive: _activeSort == 'amount',
          onChanged: (val) {
            setState(() {
              _amountOrder = val!;
              _activeSort = 'amount';
            });
            _loadDonations(reset: true);
          },
        ),
      ],
    );
  }

  Widget _buildSortDropdown({
    required String label,
    required String descLabel,
    required String ascLabel,
    required String value,
    required bool isActive,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primary.withValues(alpha: 0.06) : colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? colorScheme.primary : colorScheme.outline,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: [
            DropdownMenuItem(value: 'desc', child: Text(descLabel)),
            DropdownMenuItem(value: 'asc', child: Text(ascLabel)),
          ],
          onChanged: onChanged,
          style: TextStyle(
            color: isActive ? colorScheme.primary : colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_donations.isEmpty) {
      return Center(
        child: Text(
          'No donations yet.',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Showing ${_donations.length} of $_totalCount donations',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _donations.length,
            separatorBuilder: (context, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _DonationCard(donation: _donations[index]),
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

class _DonationCard extends StatelessWidget {
  final Donation donation;

  const _DonationCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final donorName = donation.isAnonymous || donation.donorName == null
        ? 'Anonymous donor'
        : donation.donorName!;
    final dateStr = donation.donationDateTime != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(donation.donationDateTime!)
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest,
            ),
            child: Icon(Icons.person, size: 24, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              donorName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            dateStr,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 24),
          Text(
            '\$${donation.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
