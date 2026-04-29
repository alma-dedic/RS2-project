import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:heartforcharity_mobile/model/responses/volunteer_application.dart';
import 'package:heartforcharity_mobile/model/responses/volunteer_job.dart';
import 'package:heartforcharity_mobile/providers/upload_provider.dart';
import 'package:heartforcharity_mobile/providers/volunteer_application_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VolunteerJobDetailScreen extends StatefulWidget {
  final VolunteerJob job;
  const VolunteerJobDetailScreen({super.key, required this.job});

  @override
  State<VolunteerJobDetailScreen> createState() => _VolunteerJobDetailScreenState();
}

class _VolunteerJobDetailScreenState extends State<VolunteerJobDetailScreen> {
  VolunteerApplication? _existingApp;
  bool _loadingApp = true;
  bool _withdrawing = false;

  VolunteerJob get job => widget.job;

  @override
  void initState() {
    super.initState();
    _loadExistingApplication();
  }

  Future<void> _loadExistingApplication() async {
    setState(() => _loadingApp = true);
    try {
      final provider = context.read<VolunteerApplicationProvider>();
      final result = await provider.getUserApplications(filter: {
        'volunteerJobId': job.volunteerJobId,
        'pageSize': 1,
      });
      if (!mounted) return;
      setState(() => _existingApp = result.items.isEmpty ? null : result.items.first);
    } catch (_) {
      if (mounted) setState(() => _existingApp = null);
    } finally {
      if (mounted) setState(() => _loadingApp = false);
    }
  }

  Future<void> _openApplySheet() async {
    final provider = context.read<VolunteerApplicationProvider>();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplySheet(job: job, provider: provider),
    );
    if (submitted == true) await _loadExistingApplication();
  }

  Future<void> _withdraw() async {
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
    if (confirmed != true || _existingApp == null) return;

    setState(() => _withdrawing = true);
    try {
      await provider.withdraw(_existingApp!.volunteerApplicationId);
      messenger.showSnackBar(const SnackBar(content: Text('Application withdrawn.')));
      await _loadExistingApplication();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }

  String _dateRange() {
    final fmt = DateFormat('dd MMM yyyy');
    if (job.startDate != null && job.endDate != null) {
      return '${fmt.format(job.startDate!)} – ${fmt.format(job.endDate!)}';
    }
    if (job.startDate != null) return 'From ${fmt.format(job.startDate!)}';
    if (job.endDate != null) return 'Until ${fmt.format(job.endDate!)}';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRemote = job.isRemote;
    final locationLabel = isRemote ? 'Remote' : (job.cityName ?? 'On-site');
    final locationColor = isRemote ? const Color(0xFF10B981) : cs.primary;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      appBar: AppBar(title: const Text('Details of volunteer job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.organisationName,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (job.categoryName != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        job.categoryName!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: locationLabel,
                    iconColor: locationColor,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date and time',
                    value: _dateRange(),
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.business_outlined,
                    label: 'Organiser',
                    value: job.organisationName,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.people_outline,
                    label: 'Number of volunteers',
                    value:
                        '${job.positionsRemaining} spot${job.positionsRemaining == 1 ? '' : 's'} remaining'
                        ' (${job.positionsAvailable} total)',
                  ),
                ],
              ),
            ),
            if (job.description != null) ...[
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About this job',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      job.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (job.requiredSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required skills',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: job.requiredSkills.map((skill) => Chip(
                        label: Text(skill.name, style: TextStyle(fontSize: 12, color: cs.primary)),
                        backgroundColor: cs.primary.withValues(alpha: 0.08),
                        side: BorderSide(color: cs.primary.withValues(alpha: 0.25)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _buildBottomAction(cs),
        ),
      ),
    );
  }

  Widget _buildBottomAction(ColorScheme cs) {
    if (_loadingApp) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final app = _existingApp;
    if (app == null) {
      final hasSpots = job.positionsRemaining > 0;
      return ElevatedButton(
        onPressed: hasSpots ? _openApplySheet : null,
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        child: Text(hasSpots ? 'Apply' : 'No spots available'),
      );
    }

    final status = app.status?.toLowerCase();

    switch (status) {
      case 'pending':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBanner(
              label: 'Application pending review',
              icon: Icons.hourglass_top_outlined,
              background: const Color(0xFFFFF3CD),
              foreground: const Color(0xFF856404),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _withdrawing ? null : _withdraw,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                ),
                icon: _withdrawing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.error),
                      )
                    : const Icon(Icons.close, size: 18),
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
            _StatusBanner(
              label: 'Application rejected',
              icon: Icons.cancel_outlined,
              background: const Color(0xFFF8D7DA),
              foreground: const Color(0xFF842029),
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
        return _StatusBanner(
          label: 'You withdrew your application',
          icon: Icons.do_not_disturb_alt_outlined,
          background: const Color(0xFFE2E3E5),
          foreground: const Color(0xFF41464B),
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
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = iconColor ?? cs.onSurfaceVariant;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

// ── Apply sheet ───────────────────────────────────────────────────────────────

class _ApplySheet extends StatefulWidget {
  final VolunteerJob job;
  final VolunteerApplicationProvider provider;
  const _ApplySheet({required this.job, required this.provider});

  @override
  State<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<_ApplySheet> {
  final _coverLetterCtrl = TextEditingController();
  bool _submitting = false;
  bool _uploadingResume = false;
  String? _resumeUrl;
  String? _resumeFileName;

  @override
  void dispose() {
    _coverLetterCtrl.dispose();
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
      await widget.provider.insert({
        'volunteerJobId': widget.job.volunteerJobId,
        'coverLetter': _coverLetterCtrl.text.trim().isEmpty
            ? null
            : _coverLetterCtrl.text.trim(),
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
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                  controller: _coverLetterCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Cover letter (optional)',
                    hintText:
                        'Tell the organisation why you want to volunteer...',
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
                const SizedBox(height: 16),
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
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit application'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
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
