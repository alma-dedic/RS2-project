import 'package:flutter/material.dart';
import 'package:heartforcharity_mobile/model/responses/donation.dart';
import 'package:heartforcharity_mobile/model/responses/volunteer_application.dart';
import 'package:heartforcharity_mobile/providers/donation_provider.dart';
import 'package:heartforcharity_shared/providers/review_provider.dart';
import 'package:heartforcharity_mobile/providers/volunteer_application_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        appBar: AppBar(
          title: const Text('Activity', style: TextStyle(fontWeight: FontWeight.w700)),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Applications'),
              Tab(text: 'Volunteering'),
              Tab(text: 'Donations'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ApplicationsTab(),
            _VolunteeringTab(),
            _DonationsTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _statusBadge(String status) {
  final colors = {
    'Pending': (const Color(0xFFFFF3CD), const Color(0xFF856404)),
    'Approved': (const Color(0xFFD1E7DD), const Color(0xFF0A3622)),
    'Rejected': (const Color(0xFFF8D7DA), const Color(0xFF842029)),
    'Withdrawn': (const Color(0xFFE2E3E5), const Color(0xFF41464B)),
    'Completed': (const Color(0xFFCFE2FF), const Color(0xFF084298)),
    'Success': (const Color(0xFFD1E7DD), const Color(0xFF0A3622)),
    'Failed': (const Color(0xFFF8D7DA), const Color(0xFF842029)),
  };
  final pair = colors[status] ?? (const Color(0xFFE2E3E5), const Color(0xFF41464B));
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: pair.$1, borderRadius: BorderRadius.circular(20)),
    child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pair.$2)),
  );
}

Widget _emptyState(String message) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );

// ─── Applications Tab ─────────────────────────────────────────────────────────

class _ApplicationsTab extends StatefulWidget {
  const _ApplicationsTab();

  @override
  State<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<_ApplicationsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<VolunteerApplication> _items = [];
  bool _loading = true;
  String _statusFilter = 'All';

  final _statuses = ['All', 'Pending', 'Approved', 'Rejected', 'Withdrawn'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final provider = context.read<VolunteerApplicationProvider>();
    try {
      final filter = <String, dynamic>{'pageSize': 100};
      if (_statusFilter != 'All') filter['status'] = _statusFilter;
      final result = await provider.getUserApplications(filter: filter);
      setState(() => _items = result.items);
    } catch (_) {
      setState(() => _items = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _withdraw(int id) async {
    final provider = context.read<VolunteerApplicationProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Application'),
        content: const Text('Are you sure you want to withdraw this application?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await provider.withdraw(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application withdrawn.')),
        );
        _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to withdraw application.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((s) {
                final selected = _statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (_) { setState(() => _statusFilter = s); _load(); },
                    selectedColor: colorScheme.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? _emptyState('No applications found.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _ApplicationCard(
                          item: _items[i],
                          onWithdraw: _withdraw,
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final VolunteerApplication item;
  final Future<void> Function(int) onWithdraw;

  const _ApplicationCard({required this.item, required this.onWithdraw});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPending = item.status == 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.jobTitle ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                _statusBadge(item.status ?? ''),
              ],
            ),
            const SizedBox(height: 6),
            if (item.appliedAt != null)
              Text(
                'Applied ${DateFormat('dd MMM yyyy').format(item.appliedAt!)}',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            if (item.rejectionReason != null && item.status == 'Rejected') ...[
              const SizedBox(height: 6),
              Text(
                'Reason: ${item.rejectionReason}',
                style: TextStyle(fontSize: 12, color: colorScheme.error),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => onWithdraw(item.volunteerApplicationId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Withdraw', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Volunteering Tab ─────────────────────────────────────────────────────────

class _VolunteeringTab extends StatefulWidget {
  const _VolunteeringTab();

  @override
  State<_VolunteeringTab> createState() => _VolunteeringTabState();
}

class _VolunteeringTabState extends State<_VolunteeringTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<VolunteerApplication> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final provider = context.read<VolunteerApplicationProvider>();
    try {
      final result = await provider.getUserApplications(
        filter: {'pageSize': 100, 'status': 'Approved'},
      );
      setState(() => _items = result.items);
    } catch (_) {
      setState(() => _items = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _leaveReview(VolunteerApplication item) async {
    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => _ReviewDialog(applicationId: item.volunteerApplicationId),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted.')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return _emptyState('No approved volunteering found.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (_, i) => _VolunteeringCard(item: _items[i], onReview: _leaveReview),
      ),
    );
  }
}

class _VolunteeringCard extends StatelessWidget {
  final VolunteerApplication item;
  final Future<void> Function(VolunteerApplication) onReview;

  const _VolunteeringCard({required this.item, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.jobTitle ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                _statusBadge(item.isCompleted ? 'Completed' : 'Approved'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Reviewed by: ${item.reviewedByName ?? '—'}',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            if (item.isCompleted && !item.hasReview) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => onReview(item),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Leave Review', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
            if (item.isCompleted && item.hasReview) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                const SizedBox(width: 4),
                Text(
                  'Review submitted',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final int applicationId;
  const _ReviewDialog({required this.applicationId});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _saving = true; _error = null; });
    final provider = context.read<ReviewProvider>();
    try {
      await provider.insert({
        'volunteerApplicationId': widget.applicationId,
        'rating': _rating,
        'comment': _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to submit review. You may have already reviewed this.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Leave a Review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber.shade600,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Comment (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: colorScheme.error, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

// ─── Donations Tab ─────────────────────────────────────────────────────────────

class _DonationsTab extends StatefulWidget {
  const _DonationsTab();

  @override
  State<_DonationsTab> createState() => _DonationsTabState();
}

class _DonationsTabState extends State<_DonationsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Donation> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final provider = context.read<DonationProvider>();
    try {
      final result = await provider.getUserDonations(filter: {'pageSize': 100, 'status': 'Success'});
      setState(() => _items = result.items);
    } catch (_) {
      setState(() => _items = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return _emptyState('No donations found.');

    final totalAmount = _items.fold<double>(0, (sum, d) => sum + d.amount);
    final campaigns = _items.map((d) => d.campaignId).toSet().length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem('Donations', '${_items.length}', Icons.volunteer_activism),
                _divider(),
                _summaryItem('Campaigns', '$campaigns', Icons.campaign_outlined),
                _divider(),
                _summaryItem('Total', '\$${totalAmount.toStringAsFixed(2)}', Icons.attach_money),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._items.map((d) => _DonationCard(item: d)),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) => Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      );

  Widget _divider() => Container(width: 1, height: 40, color: Colors.white24);
}

class _DonationCard extends StatelessWidget {
  final Donation item;
  const _DonationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.favorite, color: colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.campaignTitle ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.donationDateTime != null)
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(item.donationDateTime!),
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  if (item.isAnonymous)
                    Text(
                      'Anonymous',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.amount.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: colorScheme.primary),
                ),
                _statusBadge(item.status ?? ''),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
