import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heartforcharity_desktop/model/requests/volunteer_job_insert_request.dart';
import 'package:heartforcharity_desktop/model/requests/volunteer_job_update_request.dart';
import 'package:heartforcharity_desktop/model/responses/category.dart';
import 'package:heartforcharity_desktop/model/responses/volunteer_job.dart';
import 'package:heartforcharity_desktop/providers/category_provider.dart';
import 'package:heartforcharity_desktop/providers/volunteer_job_provider.dart';
import 'package:provider/provider.dart';

class VolunteerJobAddEditScreen extends StatefulWidget {
  final VolunteerJob? job;

  const VolunteerJobAddEditScreen({super.key, this.job});

  bool get isEdit => job != null;

  @override
  State<VolunteerJobAddEditScreen> createState() => _VolunteerJobAddEditScreenState();
}

class _VolunteerJobAddEditScreenState extends State<VolunteerJobAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _positionsController = TextEditingController();

  List<Category> _categories = [];
  int? _selectedCategoryId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isRemote = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.isEdit) _prefill();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _positionsController.dispose();
    super.dispose();
  }

  void _prefill() {
    final j = widget.job!;
    _titleController.text = j.title;
    _descriptionController.text = j.description ?? '';
    _requirementsController.text = j.requirements ?? '';
    _positionsController.text = j.positionsAvailable.toString();
    _selectedCategoryId = j.categoryId;
    _startDate = j.startDate;
    _endDate = j.endDate;
    _isRemote = j.isRemote;
  }

  Future<void> _loadCategories() async {
    try {
      final result = await context.read<CategoryProvider>().get(
            filter: {'retrieveAll': true, 'appliesTo': 'VolunteerJob'},
          );
      if (mounted) setState(() => _categories = result.items);
    } catch (_) {}
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now().add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFD1493F)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final jobProvider = context.read<VolunteerJobProvider>();
      final positions = int.parse(_positionsController.text.trim());

      if (widget.isEdit) {
        final j = widget.job!;
        final request = VolunteerJobUpdateRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          requirements: _requirementsController.text.trim().isEmpty ? null : _requirementsController.text.trim(),
          categoryId: _selectedCategoryId,
          startDate: _startDate,
          endDate: _endDate,
          isRemote: _isRemote,
          positionsAvailable: positions,
          status: j.status,
        );
        await jobProvider.update(j.volunteerJobId, request.toJson());
      } else {
        final request = VolunteerJobInsertRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          requirements: _requirementsController.text.trim().isEmpty ? null : _requirementsController.text.trim(),
          categoryId: _selectedCategoryId,
          startDate: _startDate,
          endDate: _endDate,
          isRemote: _isRemote,
          positionsAvailable: positions,
        );
        await jobProvider.insert(request.toJson());
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeJob() async {
    final jobProvider = context.read<VolunteerJobProvider>();
    final confirmed = await _confirm('Complete job', 'Mark this volunteer job as completed?');
    if (!confirmed) return;
    setState(() => _isLoading = true);
    try {
      await jobProvider.complete(widget.job!.volunteerJobId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelJob() async {
    final jobProvider = context.read<VolunteerJobProvider>();
    final confirmed = await _confirm('Cancel job', 'Cancel this volunteer job? This cannot be undone.');
    if (!confirmed) return;
    setState(() => _isLoading = true);
    try {
      await jobProvider.cancel(widget.job!.volunteerJobId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteJob() async {
    final jobProvider = context.read<VolunteerJobProvider>();
    final confirmed = await _confirm('Delete job', 'Permanently delete this volunteer job? This cannot be undone.');
    if (!confirmed) return;
    setState(() => _isLoading = true);
    try {
      await jobProvider.delete(widget.job!.volunteerJobId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFD1493F)),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.job?.status == 'Active';
    final canDelete = isActive && (widget.job?.positionsFilled ?? 0) == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
                const Spacer(),
                Image.asset('assets/logo.png', height: 36,
                    errorBuilder: (ctx, e, s) => const SizedBox()),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: 600,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              widget.isEdit ? 'Edit volunteer job' : 'New volunteer job',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD1493F),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Job title'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _titleController,
                            enabled: !widget.isEdit || isActive,
                            maxLength: 200,
                            decoration: _inputDecoration('Enter job title'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                          ),
                          const SizedBox(height: 12),

                          _buildLabel('Description'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            maxLength: 4000,
                            enabled: !widget.isEdit || isActive,
                            decoration: _inputDecoration('Enter job description'),
                          ),
                          const SizedBox(height: 12),

                          _buildLabel('Requirements'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _requirementsController,
                            maxLines: 2,
                            maxLength: 2000,
                            enabled: !widget.isEdit || isActive,
                            decoration: _inputDecoration('Enter requirements (optional)'),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Start date'),
                                    const SizedBox(height: 5),
                                    _buildDateField(
                                      value: _startDate,
                                      hint: 'Select start date',
                                      onTap: (!widget.isEdit || isActive) ? () => _pickDate(isStart: true) : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('End date'),
                                    const SizedBox(height: 5),
                                    _buildDateField(
                                      value: _endDate,
                                      hint: 'Select end date',
                                      onTap: (!widget.isEdit || isActive) ? () => _pickDate(isStart: false) : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Positions available'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _positionsController,
                                      enabled: !widget.isEdit || isActive,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: _inputDecoration('e.g. 10'),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Required';
                                        final n = int.tryParse(v.trim());
                                        if (n == null || n <= 0) return 'Must be greater than 0';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Category'),
                                    const SizedBox(height: 6),
                                    _buildCategoryDropdown(enabled: !widget.isEdit || isActive),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Remote toggle
                          Row(
                            children: [
                              Switch(
                                value: _isRemote,
                                onChanged: (!widget.isEdit || isActive)
                                    ? (val) => setState(() => _isRemote = val)
                                    : null,
                                activeThumbColor: const Color(0xFFD1493F),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remote position',
                                style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          if (!widget.isEdit || isActive) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF374151),
                                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD1493F),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],

                          if (widget.isEdit && isActive) ...[
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFFE5E7EB)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading ? null : _completeJob,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF059669),
                                      side: const BorderSide(color: Color(0xFF059669)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: const Text('Mark as Completed', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading ? null : _cancelJob,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFEF4444),
                                      side: const BorderSide(color: Color(0xFFEF4444)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: const Text('Cancel Job', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                            if (canDelete) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: _isLoading ? null : _deleteJob,
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF9CA3AF)),
                                  child: const Text(
                                    'Delete job',
                                    style: TextStyle(fontSize: 13, decoration: TextDecoration.underline),
                                  ),
                                ),
                              ),
                            ],
                          ],

                          if (widget.isEdit && !isActive) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'This job is ${widget.job!.status?.toLowerCase()} and cannot be edited.',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Go back'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1493F), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEF4444))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
    );
  }

  Widget _buildDateField({required DateTime? value, required String hint, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: onTap != null ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null
                    ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
                    : hint,
                style: TextStyle(
                  fontSize: 14,
                  color: value != null ? const Color(0xFF111827) : const Color(0xFFD1D5DB),
                ),
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 18,
                color: onTap != null ? const Color(0xFF9CA3AF) : const Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown({bool enabled = true}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _categories.any((c) => c.categoryId == _selectedCategoryId) ? _selectedCategoryId : null,
          hint: const Text('Select category', style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14)),
          isExpanded: true,
          onChanged: enabled ? (val) => setState(() => _selectedCategoryId = val) : null,
          items: [
            const DropdownMenuItem(value: null, child: Text('No category')),
            ..._categories.map((c) => DropdownMenuItem(value: c.categoryId, child: Text(c.name))),
          ],
          style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF9CA3AF)),
        ),
      ),
    );
  }
}
