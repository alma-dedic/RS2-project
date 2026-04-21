import 'package:flutter/material.dart';
import 'package:heartforcharity_desktop/providers/report_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum _ReportType { donations, campaigns, volunteers }

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  _ReportType _selected = _ReportType.donations;
  bool _isLoading = false;

  // Donations filters
  DateTime? _fromDate;
  DateTime? _toDate;

  // Campaigns filter
  String? _campaignStatus;

  Future<void> _export() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<ReportProvider>();
      switch (_selected) {
        case _ReportType.donations:
          await provider.downloadDonationsReport(fromDate: _fromDate, toDate: _toDate);
        case _ReportType.campaigns:
          await provider.downloadCampaignsReport(status: _campaignStatus);
        case _ReportType.volunteers:
          await provider.downloadVolunteersReport();
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Generate Report',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, size: 20, color: colorScheme.onSurfaceVariant),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Report type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _TypeChip(label: 'Donations', icon: Icons.monetization_on_outlined,
                      selected: _selected == _ReportType.donations,
                      onTap: () => setState(() => _selected = _ReportType.donations)),
                  const SizedBox(width: 8),
                  _TypeChip(label: 'Campaigns', icon: Icons.volunteer_activism_outlined,
                      selected: _selected == _ReportType.campaigns,
                      onTap: () => setState(() => _selected = _ReportType.campaigns)),
                  const SizedBox(width: 8),
                  _TypeChip(label: 'Volunteers', icon: Icons.people_outline,
                      selected: _selected == _ReportType.volunteers,
                      onTap: () => setState(() => _selected = _ReportType.volunteers)),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: colorScheme.outline),
              const SizedBox(height: 16),
              _buildFilters(colorScheme),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _export,
                    icon: _isLoading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(ColorScheme colorScheme) {
    switch (_selected) {
      case _ReportType.donations:
        return _buildDonationsFilters(colorScheme);
      case _ReportType.campaigns:
        return _buildCampaignsFilters(colorScheme);
      case _ReportType.volunteers:
        return _buildVolunteersFilters(colorScheme);
    }
  }

  Widget _buildDonationsFilters(ColorScheme colorScheme) {
    final fmt = DateFormat('dd MMM yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date range (optional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DatePickerField(
                label: 'From',
                value: _fromDate,
                onPick: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _fromDate = picked);
                },
                onClear: () => setState(() => _fromDate = null),
                formatted: _fromDate != null ? fmt.format(_fromDate!) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DatePickerField(
                label: 'To',
                value: _toDate,
                onPick: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _toDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _toDate = picked);
                },
                onClear: () => setState(() => _toDate = null),
                formatted: _toDate != null ? fmt.format(_toDate!) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCampaignsFilters(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status filter (optional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            _FilterChip(label: 'All', selected: _campaignStatus == null,
                onTap: () => setState(() => _campaignStatus = null)),
            _FilterChip(label: 'Active', selected: _campaignStatus == 'Active',
                onTap: () => setState(() => _campaignStatus = 'Active')),
            _FilterChip(label: 'Completed', selected: _campaignStatus == 'Completed',
                onTap: () => setState(() => _campaignStatus = 'Completed')),
            _FilterChip(label: 'Cancelled', selected: _campaignStatus == 'Cancelled',
                onTap: () => setState(() => _campaignStatus = 'Cancelled')),
          ],
        ),
      ],
    );
  }

  Widget _buildVolunteersFilters(ColorScheme colorScheme) {
    return Text(
      'This report includes all approved volunteers across all your volunteer jobs.',
      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.5),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary.withValues(alpha: 0.08) : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : colorScheme.onSurfaceVariant,
            )),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String? formatted;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.formatted,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formatted ?? label,
                style: TextStyle(
                  fontSize: 13,
                  color: formatted != null ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 16, color: colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
