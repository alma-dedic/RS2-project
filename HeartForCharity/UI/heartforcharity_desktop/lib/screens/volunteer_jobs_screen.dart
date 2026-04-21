import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heartforcharity_desktop/model/responses/volunteer_job.dart';
import 'package:heartforcharity_desktop/model/search_objects/volunteer_job_search_object.dart';
import 'package:heartforcharity_desktop/providers/volunteer_job_provider.dart';
import 'package:heartforcharity_desktop/screens/volunteer_job_add_edit_screen.dart';
import 'package:heartforcharity_desktop/screens/volunteer_job_applications_screen.dart';
import 'package:provider/provider.dart';

class VolunteerJobsScreen extends StatefulWidget {
  const VolunteerJobsScreen({super.key});

  @override
  State<VolunteerJobsScreen> createState() => _VolunteerJobsScreenState();
}

class _VolunteerJobsScreenState extends State<VolunteerJobsScreen> {
  final _searchController = TextEditingController();
  final int _pageSize = 5;
  Timer? _searchDebounce;

  List<VolunteerJob> _jobs = [];
  int _totalCount = 0;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  String? _selectedStatus;
  DateTime? _startDateFrom;
  DateTime? _startDateTo;

  final List<String> _statuses = ['Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadJobs(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _jobs = [];
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final filter = VolunteerJobSearchObject(
        fts: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _selectedStatus,
        startDateFrom: _startDateFrom,
        startDateTo: _startDateTo,
        page: _currentPage,
        pageSize: _pageSize,
        includeTotalCount: true,
      );

      final result = await context.read<VolunteerJobProvider>().getMy(filter: filter.toMap());

      if (mounted) {
        setState(() {
          if (reset) {
            _jobs = result.items;
          } else {
            _jobs.addAll(result.items);
          }
          _totalCount = result.totalCount ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load volunteer jobs: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; _isLoadingMore = false; });
    }
  }

  Future<void> _loadMore() async {
    _currentPage++;
    await _loadJobs();
  }

  void _openAdd() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const VolunteerJobAddEditScreen()),
    );
    if (result == true) _loadJobs(reset: true);
  }

  void _openEdit(VolunteerJob job) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VolunteerJobAddEditScreen(job: job)),
    );
    if (result == true) _loadJobs(reset: true);
  }

  void _openApplications(VolunteerJob job) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VolunteerJobApplicationsScreen(job: job)),
    );
  }

  bool get _hasMore => _jobs.length < _totalCount;

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
                _searchDebounce = Timer(const Duration(milliseconds: 500), () => _loadJobs(reset: true));
              },
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search volunteer jobs...',
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
        Image.asset('assets/logo.png', height: 36, errorBuilder: (_, e, s) => const SizedBox()),
      ],
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? (_startDateFrom ?? DateTime.now()) : (_startDateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) { _startDateFrom = picked; } else { _startDateTo = picked; }
    });
    _loadJobs(reset: true);
  }

  Widget _buildDateButton(String label, DateTime? date, {required bool isFrom}) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasValue = date != null;
    return GestureDetector(
      onTap: () => _pickDate(isFrom: isFrom),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hasValue ? colorScheme.primary.withValues(alpha: 0.06) : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasValue ? colorScheme.primary : colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: hasValue ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              hasValue ? '${date.day}.${date.month}.${date.year}' : label,
              style: TextStyle(
                fontSize: 13,
                color: hasValue ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (hasValue) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() { if (isFrom) { _startDateFrom = null; } else { _startDateTo = null; } });
                  _loadJobs(reset: true);
                },
                child: Icon(Icons.close, size: 14, color: colorScheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _buildDropdown<String?>(
          value: _selectedStatus,
          hint: 'Status',
          items: [
            const DropdownMenuItem(value: null, child: Text('All statuses')),
            ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
          ],
          onChanged: (val) {
            setState(() => _selectedStatus = val);
            _loadJobs(reset: true);
          },
        ),
        const SizedBox(width: 10),
        _buildDateButton('Start from', _startDateFrom, isFrom: true),
        const SizedBox(width: 8),
        _buildDateButton('Start to', _startDateTo, isFrom: false),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _openAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add new volunteer job'),
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

    if (_jobs.isEmpty) {
      return Center(
        child: Text('No volunteer jobs found.', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Showing ${_jobs.length} of $_totalCount volunteer jobs',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _jobs.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _VolunteerJobCard(
              job: _jobs[index],
              onEdit: () => _openEdit(_jobs[index]),
              onApplications: () => _openApplications(_jobs[index]),
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

class _VolunteerJobCard extends StatelessWidget {
  final VolunteerJob job;
  final VoidCallback onEdit;
  final VoidCallback onApplications;

  const _VolunteerJobCard({
    required this.job,
    required this.onEdit,
    required this.onApplications,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            job.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (job.status != null) _StatusBadge(status: job.status!),
                        if (job.isRemote) ...[
                          const SizedBox(width: 6),
                          _RemoteBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        job.description ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Positions filled ${job.positionsFilled}/${job.positionsAvailable}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(label: 'Applications', onTap: onApplications),
                  if (job.status == 'Active') ...[
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
}

class _RemoteBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
      ),
      child: const Text(
        'Remote',
        style: TextStyle(fontSize: 11, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600),
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
      width: 110,
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
