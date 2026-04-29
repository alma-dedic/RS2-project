import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:heartforcharity_mobile/model/responses/campaign.dart';
import 'package:heartforcharity_mobile/model/responses/organisation_profile.dart';
import 'package:heartforcharity_mobile/model/responses/volunteer_application.dart';
import 'package:heartforcharity_mobile/model/responses/volunteer_job.dart';
import 'package:heartforcharity_mobile/providers/campaign_provider.dart';
import 'package:heartforcharity_mobile/providers/donation_provider.dart';
import 'package:heartforcharity_mobile/providers/upload_provider.dart';
import 'package:heartforcharity_mobile/providers/volunteer_application_provider.dart';
import 'package:heartforcharity_mobile/providers/volunteer_job_provider.dart';
import 'package:heartforcharity_mobile/screens/campaign_detail_screen.dart';
import 'package:heartforcharity_mobile/utils/auth_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OrgDetailScreen extends StatefulWidget {
  final OrganisationProfile org;
  final bool isVolunteerMode;

  const OrgDetailScreen({
    super.key,
    required this.org,
    required this.isVolunteerMode,
  });

  @override
  State<OrgDetailScreen> createState() => _OrgDetailScreenState();
}

class _OrgDetailScreenState extends State<OrgDetailScreen> {
  List<VolunteerJob> _jobs = [];
  List<Campaign> _campaigns = [];
  Map<int, VolunteerApplication> _myAppsByJobId = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final orgId = widget.org.organisationProfileId;
    final jobProvider = context.read<VolunteerJobProvider>();
    final campProvider = context.read<CampaignProvider>();
    final appProvider = context.read<VolunteerApplicationProvider>();

    try {
      if (widget.isVolunteerMode) {
        final r = await jobProvider.get(
          filter: {'organisationProfileId': orgId, 'pageSize': 50},
        );
        if (mounted) setState(() => _jobs = r.items);
        await _loadMyApplications(appProvider);
      } else {
        final r = await campProvider.get(
          filter: {'organisationProfileId': orgId, 'pageSize': 50},
        );
        if (mounted) setState(() => _campaigns = r.items);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMyApplications(VolunteerApplicationProvider provider) async {
    try {
      final r = await provider.getUserApplications(filter: {'pageSize': 200});
      if (!mounted) return;
      setState(() {
        _myAppsByJobId = {for (final a in r.items) a.volunteerJobId: a};
      });
    } catch (_) {
      if (mounted) setState(() => _myAppsByJobId = {});
    }
  }

  // ── Apply flow ──────────────────────────────────────────────────────────────

  Future<void> _showApplySheet(VolunteerJob job) async {
    final appProvider = context.read<VolunteerApplicationProvider>();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplySheet(job: job, appProvider: appProvider),
    );
    if (submitted == true) await _loadMyApplications(appProvider);
  }

  Future<void> _withdraw(VolunteerApplication app) async {
    final provider = context.read<VolunteerApplicationProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Application'),
        content: const Text('Are you sure you want to withdraw this application? You will not be able to apply again for this job.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await provider.withdraw(app.volunteerApplicationId);
      messenger.showSnackBar(const SnackBar(content: Text('Application withdrawn.')));
      await _loadMyApplications(provider);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // ── Donate / details flow ───────────────────────────────────────────────────

  Future<void> _showDonateSheet(Campaign campaign) async {
    final donationProvider = context.read<DonationProvider>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DonateSheet(
        campaign: campaign,
        provider: donationProvider,
        onDonationMade: _load,
      ),
    );
  }

  void _openCampaignDetail(Campaign campaign) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CampaignDetailScreen(campaign: campaign)),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final org = widget.org;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      appBar: AppBar(
        title: Text(org.name),
        backgroundColor: cs.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _OrgHeader(org: org)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        widget.isVolunteerMode
                            ? 'Volunteer jobs'
                            : 'Campaigns',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  if (widget.isVolunteerMode)
                    _buildJobSliver(cs)
                  else
                    _buildCampaignSliver(cs),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }

  SliverList _buildJobSliver(ColorScheme cs) {
    if (_jobs.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([_emptyState('No active jobs.')]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) {
          final job = _jobs[i];
          return _JobCard(
            job: job,
            existingApp: _myAppsByJobId[job.volunteerJobId],
            onApply: () => _showApplySheet(job),
            onWithdraw: () => _withdraw(_myAppsByJobId[job.volunteerJobId]!),
          );
        },
        childCount: _jobs.length,
      ),
    );
  }

  SliverList _buildCampaignSliver(ColorScheme cs) {
    if (_campaigns.isEmpty) {
      return SliverList(
        delegate:
            SliverChildListDelegate([_emptyState('No active campaigns.')]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _CampaignCard(
          campaign: _campaigns[i],
          onTap: () => _openCampaignDetail(_campaigns[i]),
          onDonate: () => _showDonateSheet(_campaigns[i]),
        ),
        childCount: _campaigns.length,
      ),
    );
  }

  Widget _emptyState(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            msg,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ),
      );
}

// ── Org header ────────────────────────────────────────────────────────────────

class _OrgHeader extends StatelessWidget {
  final OrganisationProfile org;
  const _OrgHeader({required this.org});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: cs.primary.withValues(alpha: 0.1),
                backgroundImage: org.logoUrl != null
                    ? authNetworkImage(org.logoUrl!)
                    : null,
                child: org.logoUrl == null
                    ? Text(
                        org.name.isNotEmpty ? org.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            org.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (org.organisationTypeName != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          org.organisationTypeName!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                    if (org.cityName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            [org.cityName, org.countryName]
                                .where((e) => e != null)
                                .join(', '),
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (org.description != null) ...[
            const SizedBox(height: 14),
            Text(
              org.description!,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant, height: 1.5),
            ),
          ],
          if (org.contactEmail != null || org.contactPhone != null) ...[
            const SizedBox(height: 12),
            if (org.contactEmail != null)
              _ContactRow(
                  icon: Icons.email_outlined, text: org.contactEmail!),
            if (org.contactPhone != null)
              _ContactRow(icon: Icons.phone_outlined, text: org.contactPhone!),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text,
              style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Job card ──────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final VolunteerJob job;
  final VolunteerApplication? existingApp;
  final VoidCallback onApply;
  final VoidCallback onWithdraw;
  const _JobCard({
    required this.job,
    required this.existingApp,
    required this.onApply,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRemote = job.isRemote;
    final locationLabel = isRemote ? 'Remote' : (job.cityName ?? 'On-site');
    final locationColor = isRemote ? const Color(0xFF10B981) : cs.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: locationColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  locationLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: locationColor,
                  ),
                ),
              ),
            ],
          ),
          if (job.description != null) ...[
            const SizedBox(height: 6),
            Text(
              job.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (job.startDate != null) ...[
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(job.startDate!),
                  style:
                      TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
              ],
              Icon(Icons.people_outline,
                  size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${job.positionsRemaining} spots left',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAction(cs),
        ],
      ),
    );
  }

  Widget _buildAction(ColorScheme cs) {
    final app = existingApp;
    if (app == null) {
      final hasSpots = job.positionsRemaining > 0;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: hasSpots ? onApply : null,
          child: Text(hasSpots ? 'Apply' : 'Full'),
        ),
      );
    }

    switch (app.status?.toLowerCase()) {
      case 'pending':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _StatusBanner(
              label: 'Application pending review',
              icon: Icons.hourglass_top_outlined,
              background: Color(0xFFFFF3CD),
              foreground: Color(0xFF856404),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onWithdraw,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                ),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Withdraw application'),
              ),
            ),
          ],
        );
      case 'approved':
        return _StatusBanner(
          label: app.isCompleted
              ? 'You completed this volunteer job'
              : "You're approved for this job",
          icon: Icons.check_circle_outline,
          background: const Color(0xFFD1E7DD),
          foreground: const Color(0xFF0A3622),
        );
      case 'rejected':
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _StatusBanner(
              label: 'Application rejected',
              icon: Icons.cancel_outlined,
              background: Color(0xFFF8D7DA),
              foreground: Color(0xFF842029),
            ),
            if (app.rejectionReason != null && app.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Reason: ${app.rejectionReason}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      case 'withdrawn':
        return const _StatusBanner(
          label: 'You withdrew your application',
          icon: Icons.do_not_disturb_alt_outlined,
          background: Color(0xFFE2E3E5),
          foreground: Color(0xFF41464B),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StatusBanner extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _StatusBanner({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Campaign card ─────────────────────────────────────────────────────────────

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;
  final VoidCallback onDonate;
  const _CampaignCard({
    required this.campaign,
    required this.onTap,
    required this.onDonate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = campaign.targetAmount > 0
        ? (campaign.currentAmount / campaign.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          if (campaign.description != null) ...[
            const SizedBox(height: 6),
            Text(
              campaign.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: cs.outline.withValues(alpha: 0.2),
              color: cs.secondary,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${campaign.currentAmount.toStringAsFixed(0)} raised',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.secondary,
                ),
              ),
              Text(
                'Goal: \$${campaign.targetAmount.toStringAsFixed(0)}',
                style:
                    TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          if (campaign.endDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Ends ${DateFormat('dd MMM yyyy').format(campaign.endDate!)}',
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDonate,
              child: const Text('Donate'),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Apply bottom sheet ────────────────────────────────────────────────────────

class _ApplySheet extends StatefulWidget {
  final VolunteerJob job;
  final VolunteerApplicationProvider appProvider;
  const _ApplySheet({required this.job, required this.appProvider});

  @override
  State<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<_ApplySheet> {
  final _coverLetterController = TextEditingController();
  bool _submitting = false;
  bool _uploadingResume = false;
  String? _resumeUrl;
  String? _resumeFileName;

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    final messenger = ScaffoldMessenger.of(context);
    final uploadProvider = context.read<UploadProvider>();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );
      if (result == null || result.files.single.path == null) return;

      final file = result.files.single;
      if (file.size > 5 * 1024 * 1024) {
        messenger.showSnackBar(const SnackBar(content: Text('Resume must be 5MB or smaller.')));
        return;
      }

      setState(() => _uploadingResume = true);
      final url = await uploadProvider.uploadFile(file.path!);
      if (!mounted) return;
      setState(() {
        _resumeUrl = url;
        _resumeFileName = file.name;
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _uploadingResume = false);
    }
  }

  void _removeResume() {
    setState(() {
      _resumeUrl = null;
      _resumeFileName = null;
    });
  }

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _submitting = true);
    try {
      await widget.appProvider.insert({
        'volunteerJobId': widget.job.volunteerJobId,
        'coverLetter': _coverLetterController.text.trim().isEmpty
            ? null
            : _coverLetterController.text.trim(),
        'resumeUrl': _resumeUrl,
      });
      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      navigator.pop(false);
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Apply for "${widget.job.title}"',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.job.organisationName,
              style: TextStyle(fontSize: 13, color: cs.primary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _coverLetterController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Cover letter (optional)',
                hintText: 'Tell the organisation why you want to volunteer...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            _ResumePicker(
              fileName: _resumeFileName,
              uploading: _uploadingResume,
              onPick: _pickResume,
              onRemove: _removeResume,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_submitting || _uploadingResume) ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumePicker extends StatelessWidget {
  final String? fileName;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ResumePicker({
    required this.fileName,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasFile = fileName != null;

    if (uploading) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Uploading resume...',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (hasFile) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.picture_as_pdf_outlined, size: 22, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resume attached',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    fileName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: cs.onSurfaceVariant),
              onPressed: onRemove,
              tooltip: 'Remove resume',
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.attach_file, size: 18),
        label: const Text('Attach resume (PDF, optional)'),
      ),
    );
  }
}

