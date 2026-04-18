import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heartforcharity_desktop/model/requests/campaign_insert_request.dart';
import 'package:heartforcharity_desktop/model/requests/campaign_media_upsert_request.dart';
import 'package:heartforcharity_desktop/model/requests/campaign_update_request.dart';
import 'package:heartforcharity_desktop/model/responses/campaign.dart';
import 'package:heartforcharity_desktop/model/responses/campaign_media.dart';
import 'package:heartforcharity_desktop/model/responses/category.dart';
import 'package:heartforcharity_desktop/providers/campaign_media_provider.dart';
import 'package:heartforcharity_desktop/providers/campaign_provider.dart';
import 'package:heartforcharity_desktop/providers/category_provider.dart';
import 'package:heartforcharity_desktop/providers/upload_provider.dart';
import 'package:provider/provider.dart';

class CampaignAddEditScreen extends StatefulWidget {
  final Campaign? campaign;

  const CampaignAddEditScreen({super.key, this.campaign});

  bool get isEdit => campaign != null;

  @override
  State<CampaignAddEditScreen> createState() => _CampaignAddEditScreenState();
}

class _CampaignAddEditScreenState extends State<CampaignAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();

  List<Category> _categories = [];
  int? _selectedCategoryId;
  DateTime? _startDate;
  DateTime? _endDate;

  // Existing images loaded from backend (edit mode only)
  List<CampaignMedia> _existingImages = [];
  final Set<int> _removedExistingIds = {};

  // New images picked from file system
  // Each item: { 'path': String, 'isCover': bool }
  final List<Map<String, dynamic>> _newImages = [];

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
    _targetAmountController.dispose();
    super.dispose();
  }

  void _prefill() {
    final c = widget.campaign!;
    _titleController.text = c.title;
    _descriptionController.text = c.description ?? '';
    _targetAmountController.text = c.targetAmount == c.targetAmount.truncateToDouble()
        ? c.targetAmount.toInt().toString()
        : c.targetAmount.toString();
    _selectedCategoryId = c.categoryId;
    _startDate = c.startDate;
    _endDate = c.endDate;
    _existingImages = List.from(c.campaignMedias);
  }

  Future<void> _loadCategories() async {
    try {
      final result = await context.read<CategoryProvider>().get(
            filter: {'retrieveAll': true, 'appliesTo': 'Campaign'},
          );
      if (mounted) setState(() => _categories = result.items);
    } catch (_) {}
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return;

    setState(() {
      for (final file in result.files) {
        if (file.path != null) {
          _newImages.add({'path': file.path!, 'isCover': false});
        }
      }
      _ensureCoverSet();
    });
  }

  void _ensureCoverSet() {
    final hasExistingCover = _existingImages.any((m) => m.isCover && !_removedExistingIds.contains(m.campaignMediaId));
    final hasNewCover = _newImages.any((i) => i['isCover'] == true);
    if (!hasExistingCover && !hasNewCover && _newImages.isNotEmpty) {
      _newImages[0]['isCover'] = true;
    }
  }

  void _removeExistingImage(CampaignMedia media) {
    setState(() {
      _removedExistingIds.add(media.campaignMediaId);
      _ensureCoverSet();
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
      _ensureCoverSet();
    });
  }

  void _setExistingCover(CampaignMedia media) {
    setState(() {
      _existingImages = _existingImages.map((m) {
        return CampaignMedia(
          campaignMediaId: m.campaignMediaId,
          url: m.url,
          mediaType: m.mediaType,
          isCover: m.campaignMediaId == media.campaignMediaId,
        );
      }).toList();
      for (int i = 0; i < _newImages.length; i++) {
        _newImages[i]['isCover'] = false;
      }
    });
  }

  void _setNewCover(int index) {
    setState(() {
      _existingImages = _existingImages.map((m) => CampaignMedia(
            campaignMediaId: m.campaignMediaId,
            url: m.url,
            mediaType: m.mediaType,
            isCover: false,
          )).toList();
      for (int i = 0; i < _newImages.length; i++) {
        _newImages[i]['isCover'] = i == index;
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now().add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
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
      final campaignProvider = context.read<CampaignProvider>();
      final mediaProvider = context.read<CampaignMediaProvider>();
      final uploadProvider = context.read<UploadProvider>();

      if (widget.isEdit) {
        final c = widget.campaign!;
        final request = CampaignUpdateRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          categoryId: _selectedCategoryId,
          startDate: _startDate,
          endDate: _endDate,
          targetAmount: double.parse(_targetAmountController.text.trim()),
          status: c.status,
        );

        await campaignProvider.update(c.campaignId, request.toJson());

        // Delete removed existing images
        for (final id in _removedExistingIds) {
          await mediaProvider.delete(id);
        }

        // Update isCover on remaining existing images
        for (final media in _existingImages) {
          if (!_removedExistingIds.contains(media.campaignMediaId)) {
            await mediaProvider.update(media.campaignMediaId, CampaignMediaUpsertRequest(
              campaignId: c.campaignId,
              url: media.url!,
              isCover: media.isCover,
            ).toJson());
          }
        }

        // Upload and insert new images
        for (final image in _newImages) {
          final url = await uploadProvider.uploadImage(image['path'] as String);
          await mediaProvider.insert(CampaignMediaUpsertRequest(
            campaignId: c.campaignId,
            url: url,
            isCover: image['isCover'] as bool,
          ).toJson());
        }
      } else {
        final request = CampaignInsertRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          categoryId: _selectedCategoryId,
          startDate: _startDate,
          endDate: _endDate,
          targetAmount: double.parse(_targetAmountController.text.trim()),
        );

        final campaign = await campaignProvider.insert(request.toJson());

        for (final image in _newImages) {
          final url = await uploadProvider.uploadImage(image['path'] as String);
          await mediaProvider.insert(CampaignMediaUpsertRequest(
            campaignId: campaign.campaignId,
            url: url,
            isCover: image['isCover'] as bool,
          ).toJson());
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save campaign: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeCampaign() async {
    final campaignProvider = context.read<CampaignProvider>();
    final confirmed = await _confirm('Complete campaign', 'Mark this campaign as completed?');
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await campaignProvider.complete(widget.campaign!.campaignId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelCampaign() async {
    final campaignProvider = context.read<CampaignProvider>();
    final confirmed = await _confirm('Cancel campaign', 'Are you sure you want to cancel this campaign? This cannot be undone.');
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await campaignProvider.cancel(widget.campaign!.campaignId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCampaign() async {
    final campaignProvider = context.read<CampaignProvider>();
    final confirmed = await _confirm('Delete campaign', 'Permanently delete this campaign? This cannot be undone.');
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await campaignProvider.delete(widget.campaign!.campaignId);
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
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
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
    final isActive = widget.campaign?.status == 'Active';
    final canDelete = isActive && (widget.campaign?.donationCount ?? 0) == 0;

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
                    errorBuilder: (context, e, s) => const SizedBox()),
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
                              widget.isEdit ? 'Edit campaign' : 'New campaign',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD1493F),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Campaign title'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _titleController,
                            enabled: !widget.isEdit || isActive,
                            decoration: _inputDecoration('Enter campaign title'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                          ),
                          const SizedBox(height: 12),

                          _buildLabel('Description'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            enabled: !widget.isEdit || isActive,
                            decoration: _inputDecoration('Enter campaign description'),
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
                                    _buildLabel('Target amount (\$)'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _targetAmountController,
                                      enabled: !widget.isEdit || isActive,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                      decoration: _inputDecoration('0.00'),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Target amount is required';
                                        final amount = double.tryParse(v.trim());
                                        if (amount == null || amount <= 0) return 'Must be greater than 0';
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

                          _buildLabel('Images'),
                          const SizedBox(height: 8),
                          _buildImagesSection(canEdit: !widget.isEdit || isActive),
                          const SizedBox(height: 20),

                          // Save / Cancel buttons (only shown if add mode OR active campaign)
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

                          // Edit-mode actions for Active campaigns
                          if (widget.isEdit && isActive) ...[
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFFE5E7EB)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading ? null : _completeCampaign,
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
                                    onPressed: _isLoading ? null : _cancelCampaign,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFEF4444),
                                      side: const BorderSide(color: Color(0xFFEF4444)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: const Text('Cancel Campaign', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                            if (canDelete) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: _isLoading ? null : _deleteCampaign,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF9CA3AF),
                                  ),
                                  child: const Text(
                                    'Delete campaign',
                                    style: TextStyle(
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],

                          // Read-only notice for non-active campaigns
                          if (widget.isEdit && !isActive) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'This campaign is ${widget.campaign!.status?.toLowerCase()} and cannot be edited.',
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1493F), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
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
            Icon(Icons.calendar_today_outlined, size: 18, color: onTap != null ? const Color(0xFF9CA3AF) : const Color(0xFFD1D5DB)),
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

  Widget _buildImagesSection({bool canEdit = true}) {
    final visibleExisting = _existingImages.where((m) => !_removedExistingIds.contains(m.campaignMediaId)).toList();
    final hasImages = visibleExisting.isNotEmpty || _newImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImages) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...visibleExisting.map((m) => _buildExistingImageTile(m, canEdit: canEdit)),
              ...List.generate(_newImages.length, (i) => _buildNewImageTile(i, canEdit: canEdit)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (canEdit)
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: const Text('Upload images'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD1493F),
              side: const BorderSide(color: Color(0xFFD1493F)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildExistingImageTile(CampaignMedia media, {bool canEdit = true}) {
    final isCover = media.isCover;

    return Stack(
      children: [
        GestureDetector(
          onTap: canEdit ? () => _setExistingCover(media) : null,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCover ? const Color(0xFFD1493F) : const Color(0xFFE5E7EB),
                width: isCover ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.network(
                media.url!,
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
        ),
        if (isCover)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD1493F),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ),
        if (canEdit)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeExistingImage(media),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Color(0xFF374151)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNewImageTile(int index, {bool canEdit = true}) {
    final image = _newImages[index];
    final isCover = image['isCover'] == true;

    return Stack(
      children: [
        GestureDetector(
          onTap: canEdit ? () => _setNewCover(index) : null,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCover ? const Color(0xFFD1493F) : const Color(0xFFE5E7EB),
                width: isCover ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.file(
                File(image['path'] as String),
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
        ),
        if (isCover)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD1493F),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ),
        if (canEdit)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeNewImage(index),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Color(0xFF374151)),
              ),
            ),
          ),
      ],
    );
  }
}
