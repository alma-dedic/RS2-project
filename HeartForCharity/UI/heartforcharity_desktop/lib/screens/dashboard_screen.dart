import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:heartforcharity_desktop/model/responses/dashboard_response.dart';
import 'package:heartforcharity_desktop/providers/dashboard_provider.dart';
import 'package:heartforcharity_desktop/screens/report_dialog.dart';
import 'package:heartforcharity_desktop/utils/auth_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardResponse? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await context.read<DashboardProvider>().getDashboard();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final d = _data!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Dashboard',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                context: context,
                builder: (_) => const ReportDialog(),
              ),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Get Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatCards(d),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildDonationsChart(d)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildReviews(d)),
              ],
            ),
          ),
          if (d.campaignProgress.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCampaignProgress(d),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCards(DashboardResponse d) {
    final colorScheme = Theme.of(context).colorScheme;
    final moneyFmt = NumberFormat('#,##0.00', 'en_US');
    return Row(
      children: [
        _StatCard(
          label: 'Active Campaigns',
          value: '${d.activeCampaigns}',
          icon: Icons.volunteer_activism,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Finished Campaigns',
          value: '${d.finishedCampaigns}',
          icon: Icons.check_circle_outline,
          color: colorScheme.secondary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Volunteers',
          value: '${d.totalVolunteers}',
          icon: Icons.people_outline,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Total Raised',
          value: '€${moneyFmt.format(d.totalRaised)}',
          icon: Icons.monetization_on_outlined,
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildDonationsChart(DashboardResponse d) {
    final colorScheme = Theme.of(context).colorScheme;
    final months = d.monthlyDonations;
    final maxY = months.isEmpty ? 100.0 : months.map((m) => m.total).reduce((a, b) => a > b ? a : b) * 1.2;
    final totalDonations = months.fold(0, (sum, m) => sum + m.count);
    final totalAmount = months.fold(0.0, (sum, m) => sum + m.total);
    final moneyFmt = NumberFormat('#,##0.00', 'en_US');

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Donations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text('Last 6 months', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('€${moneyFmt.format(totalAmount)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colorScheme.primary)),
                  Text('$totalDonations donations',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: months.isEmpty
                ? Center(child: Text('No donation data yet.', style: TextStyle(color: colorScheme.onSurfaceVariant)))
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      barGroups: List.generate(months.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: months[i].total,
                              color: colorScheme.primary,
                              width: 22,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= months.length) return const SizedBox();
                              final m = months[i];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat('MMM').format(DateTime(m.year, m.month)),
                                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: Color(0xFFF3F4F6),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF1A1A2E),
                          getTooltipItem: (group, _, rod, _) {
                            final m = months[group.x];
                            return BarTooltipItem(
                              '€${NumberFormat('#,##0.00').format(rod.toY)}\n${m.count} donations',
                              const TextStyle(color: Colors.white, fontSize: 12),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews(DashboardResponse d) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Volunteer Reviews',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          if (d.recentReviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No reviews yet.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: d.recentReviews.map((r) => _ReviewTile(review: r)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCampaignProgress(DashboardResponse d) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Campaign Funding Progress',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          ...d.campaignProgress.map((c) => _CampaignProgressTile(item: c)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                  Text(label,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final DashboardReviewItem review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                backgroundImage: review.reviewerAvatarUrl != null && review.reviewerAvatarUrl!.isNotEmpty
                    ? authNetworkImage(review.reviewerAvatarUrl!)
                    : null,
                child: review.reviewerAvatarUrl == null || review.reviewerAvatarUrl!.isEmpty
                    ? Text(review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.primary))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                    Text(DateFormat('dd MMM yyyy').format(review.createdAt),
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              _StarRating(rating: review.rating),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment!,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
        size: 14,
        color: const Color(0xFFF59E0B),
      )),
    );
  }
}

class _CampaignProgressTile extends StatelessWidget {
  final CampaignProgressItem item;
  const _CampaignProgressTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final moneyFmt = NumberFormat('#,##0.00', 'en_US');
    final pct = (item.progress * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('$pct%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.progress,
              backgroundColor: const Color(0xFFF3F4F6),
              color: colorScheme.primary,
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 4),
          Text('€${moneyFmt.format(item.currentAmount)} raised of €${moneyFmt.format(item.targetAmount)}',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
