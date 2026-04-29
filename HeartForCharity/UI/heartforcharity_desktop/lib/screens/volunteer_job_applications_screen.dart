import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:heartforcharity_desktop/model/responses/volunteer_application.dart';
import 'package:heartforcharity_desktop/model/responses/volunteer_job.dart';
import 'package:heartforcharity_desktop/model/search_objects/volunteer_application_search_object.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';
import 'package:heartforcharity_desktop/providers/volunteer_application_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VolunteerJobApplicationsScreen extends StatefulWidget {
  final VolunteerJob job;

  const VolunteerJobApplicationsScreen({super.key, required this.job});

  @override
  State<VolunteerJobApplicationsScreen> createState() => _VolunteerJobApplicationsScreenState();
}

class _VolunteerJobApplicationsScreenState extends State<VolunteerJobApplicationsScreen> {
  final int _pageSize = 5;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<VolunteerApplication> _applications = [];
  int _totalCount = 0;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _selectedStatus;

  final List<String> _statuses = ['Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() { _isLoading = true; _currentPage = 0; _applications = []; });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final filter = VolunteerApplicationSearchObject(
        volunteerJobId: widget.job.volunteerJobId,
        fts: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _selectedStatus,
        page: _currentPage,
        pageSize: _pageSize,
        includeTotalCount: true,
      );
      final result = await context.read<VolunteerApplicationProvider>().get(filter: filter.toMap());
      if (mounted) {
        setState(() {
          if (reset) {
            _applications = result.items;
          } else {
            _applications.addAll(result.items);
          }
          _totalCount = result.totalCount ?? 0;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load applications: ${BaseProvider.cleanError(e)}')));
    } finally {
      if (mounted) setState(() { _isLoading = false; _isLoadingMore = false; });
    }
  }

  Future<void> _approve(VolunteerApplication app) async {
    final provider = context.read<VolunteerApplicationProvider>();
    try {
      await provider.approve(app.volunteerApplicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application approved successfully.')),
        );
      }
      _load(reset: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(BaseProvider.cleanError(e))));
    }
  }

  Future<void> _reject(VolunteerApplication app) async {
    final provider = context.read<VolunteerApplicationProvider>();
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Reject application',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Theme.of(ctx).colorScheme.onSurface)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      icon: Icon(Icons.close, size: 20, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Optionally provide a reason:',
                    style: TextStyle(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Rejection reason (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(ctx).colorScheme.onSurface,
                        side: BorderSide(color: Theme.of(ctx).colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(ctx).colorScheme.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await provider.reject(app.volunteerApplicationId, reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application rejected.')),
        );
      }
      _load(reset: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(BaseProvider.cleanError(e))));
    }
  }

  bool get _hasMore => _applications.length < _totalCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
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
                Image.asset('assets/logo.png', height: 36, errorBuilder: (_, e, s) => const SizedBox()),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.job.title,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Positions filled ${widget.job.positionsFilled}/${widget.job.positionsAvailable}',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(const Duration(milliseconds: 500), () => _load(reset: true));
                      },
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search applicants...',
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
                ),
                const SizedBox(width: 12),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedStatus,
                      hint: Text('All statuses', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All statuses')),
                        ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedStatus = val);
                        _load(reset: true);
                      },
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                      icon: Icon(Icons.keyboard_arrow_down, size: 20, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_applications.isEmpty) {
      return Center(
        child: Text('No applications yet.', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Showing ${_applications.length} of $_totalCount applications',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _applications.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ApplicationCard(
              application: _applications[i],
              onApprove: () => _approve(_applications[i]),
              onReject: () => _reject(_applications[i]),
            ),
          ),
        ),
        if (_hasMore) ...[
          const SizedBox(height: 16),
          Center(
            child: _isLoadingMore
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    onPressed: () { _currentPage++; _load(); },
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

class _ApplicationCard extends StatelessWidget {
  final VolunteerApplication application;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApplicationCard({
    required this.application,
    required this.onApprove,
    required this.onReject,
  });

  void _showDetail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPending = application.status?.toLowerCase() == 'pending';
    final dateStr = application.appliedAt != null
        ? DateFormat('dd MMM yyyy – HH:mm').format(application.appliedAt!)
        : '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(alpha: 0.1),
                      ),
                      child: Icon(Icons.person_outline, color: colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application.applicantName ?? 'Unknown applicant',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                          ),
                          if (dateStr.isNotEmpty)
                            Text(dateStr, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    if (application.status != null) _StatusBadge(status: application.status!),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close, size: 20, color: colorScheme.onSurfaceVariant),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: colorScheme.outline),
                const SizedBox(height: 12),
                if (application.dateOfBirth != null)
                  _IconDetailRow(icon: Icons.cake_outlined, value: DateFormat('dd MMM yyyy').format(application.dateOfBirth!)),
                if (application.address != null && application.address!.isNotEmpty)
                  _IconDetailRow(icon: Icons.location_on_outlined, value: application.address!),
                if (application.phoneNumber != null && application.phoneNumber!.isNotEmpty)
                  _IconDetailRow(icon: Icons.phone_outlined, value: application.phoneNumber!),
                if (application.email != null && application.email!.isNotEmpty)
                  _IconDetailRow(icon: Icons.email_outlined, value: application.email!),
                if (application.coverLetter != null && application.coverLetter!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Cover letter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                  const SizedBox(height: 6),
                  Text(application.coverLetter!, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.5)),
                  const SizedBox(height: 12),
                ],
                if (application.resumeUrl != null && application.resumeUrl!.isNotEmpty) ...[
                  Text('Resume', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                  const SizedBox(height: 6),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(application.resumeUrl!);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFF3B82F6)),
                            SizedBox(width: 6),
                            Text(
                              'Open resume',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.open_in_new, size: 14, color: Color(0xFF3B82F6)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (application.rejectionReason != null && application.rejectionReason!.isNotEmpty) ...[
                  Text('Rejection reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.error)),
                  const SizedBox(height: 4),
                  Text(application.rejectionReason!, style: TextStyle(fontSize: 13, color: colorScheme.error, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12),
                ],
                if (isPending) ...[
                  Divider(color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () { Navigator.of(ctx).pop(); onReject(); },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () { Navigator.of(ctx).pop(); onApprove(); },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isApproved = application.status?.toLowerCase() == 'approved';
    final dateStr = application.appliedAt != null
        ? DateFormat('dd MMM yyyy').format(application.appliedAt!)
        : '';

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(Icons.person_outline, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      application.applicantName ?? 'Unknown applicant',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    ),
                    const SizedBox(width: 10),
                    if (application.status != null) _StatusBadge(status: application.status!),
                    const Spacer(),
                    Text(dateStr, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                if (application.coverLetter != null && application.coverLetter!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    application.coverLetter!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
                if (application.rejectionReason != null && application.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Rejection reason: ${application.rejectionReason}',
                    style: TextStyle(fontSize: 12, color: colorScheme.error, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          if (!isApproved) ...[
            const SizedBox(width: 16),
            SizedBox(
              width: 130,
              child: OutlinedButton(
                onPressed: () => _showDetail(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                child: const Text('See application'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconDetailRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _IconDetailRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, color: colorScheme.onSurface, fontWeight: FontWeight.w500)),
          ),
        ],
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
      case 'approved':
        color = const Color(0xFF10B981);
        break;
      case 'rejected':
        color = const Color(0xFFEF4444);
        break;
      case 'pending':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = const Color(0xFF6B7280);
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
