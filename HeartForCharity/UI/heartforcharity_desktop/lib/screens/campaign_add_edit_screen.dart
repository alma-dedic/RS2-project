import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heartforcharity_desktop/utils/auth_image.dart';
import 'package:heartforcharity_desktop/model/requests/campaign_insert_request.dart';
import 'package:heartforcharity_desktop/model/requests/campaign_media_upsert_request.dart';
import 'package:heartforcharity_desktop/model/requests/campaign_update_request.dart';
import 'package:heartforcharity_desktop/model/responses/campaign.dart';
import 'package:heartforcharity_desktop/model/responses/campaign_media.dart';
import 'package:heartforcharity_desktop/model/responses/category.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';
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
  String? _startDateError;
  String? _endDateError;

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
            filter: {'pageSize': 100, 'appliesTo': 'Campaign'},
          );
      if (mounted) setState(() => _categories = result.items);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
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
      builder: (context, child) => child!,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
      _startDateError = null;
      _endDateError = null;
    });
  }

  bool _validateDates() {
    String? startErr;
    String? endErr;
    if (_startDate == null) startErr = 'Start date is required.';
    if (_endDate == null) endErr = 'End date is required.';
    if (startErr == null && endErr == null && !_endDate!.isAfter(_startDate!)) {
      endErr = 'End date must be after start date.';
    }
    setState(() {
      _startDateError = startErr;
      _endDateError = endErr;
    });
    return startErr == null && endErr == null;
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    final datesOk = _validateDates();
    if (!formOk || !datesOk) return;

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? 'Campaign updated successfully.' : 'Campaign created successfully.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save campaign: ${BaseProvider.cleanError(e)}')),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign marked as completed.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(BaseProvider.cleanError(e))));
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign cancelled.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(BaseProvider.cleanError(e))));
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
                style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.primary),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = widget.campaign?.status == 'Active';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
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
                      color: colorScheme.surface,
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Campaign title'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _titleController,
                            enabled: !widget.isEdit || isActive,
                            maxLength: 200,
                            decoration: _inputDecoration('Enter campaign title', colorScheme),
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
                            decoration: _inputDecoration('Enter campaign description', colorScheme),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      colorScheme: colorScheme,
                                      errorText: _startDateError,
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
                                      colorScheme: colorScheme,
                                      errorText: _endDateError,
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
                                      decoration: _inputDecoration('0.00', colorScheme),
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
                                    _buildCategoryDropdown(enabled: !widget.isEdit || isActive, colorScheme: colorScheme),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          _buildLabel('Images'),
                          const SizedBox(height: 8),
                          _buildImagesSection(canEdit: !widget.isEdit || isActive, colorScheme: colorScheme),
                          const SizedBox(height: 20),

                          // Save / Cancel buttons (only shown if add mode OR active campaign)
                          if (!widget.isEdit || isActive) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.onSurface,
                                    side: BorderSide(color: colorScheme.outlineVariant),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
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
                            Divider(color: colorScheme.outline),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading ? null : _completeCampaign,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colorScheme.secondary,
                                      side: BorderSide(color: colorScheme.secondary),
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
                                      foregroundColor: colorScheme.error,
                                      side: BorderSide(color: colorScheme.error),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: const Text('Cancel Campaign', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Read-only notice for non-active campaigns
                          if (widget.isEdit && !isActive) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'This campaign is ${widget.campaign!.status?.toLowerCase()} and cannot be edited.',
                                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
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
    return Text(text, style: Theme.of(context).textTheme.titleSmall);
  }

  InputDecoration _inputDecoration(String hint, ColorScheme colorScheme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorScheme.outlineVariant, fontSize: 14),
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
    );
  }

  Widget _buildDateField({required DateTime? value, required String hint, VoidCallback? onTap, required ColorScheme colorScheme, String? errorText}) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: hasError ? colorScheme.error : colorScheme.outline),
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
                      color: value != null ? colorScheme.onSurface : colorScheme.outlineVariant,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 18, color: onTap != null ? colorScheme.onSurfaceVariant : colorScheme.outlineVariant),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText,
              style: TextStyle(fontSize: 12, color: colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryDropdown({bool enabled = true, required ColorScheme colorScheme}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: enabled ? colorScheme.surfaceContainerLow : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _categories.any((c) => c.categoryId == _selectedCategoryId) ? _selectedCategoryId : null,
          hint: Text('Select category', style: TextStyle(color: colorScheme.outlineVariant, fontSize: 14)),
          isExpanded: true,
          onChanged: enabled ? (val) => setState(() => _selectedCategoryId = val) : null,
          items: [
            const DropdownMenuItem(value: null, child: Text('No category')),
            ..._categories.map((c) => DropdownMenuItem(value: c.categoryId, child: Text(c.name))),
          ],
          style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down, size: 20, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildImagesSection({bool canEdit = true, required ColorScheme colorScheme}) {
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
              ...visibleExisting.map((m) => _buildExistingImageTile(m, canEdit: canEdit, colorScheme: colorScheme)),
              ...List.generate(_newImages.length, (i) => _buildNewImageTile(i, canEdit: canEdit, colorScheme: colorScheme)),
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
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildExistingImageTile(CampaignMedia media, {bool canEdit = true, required ColorScheme colorScheme}) {
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
                color: isCover ? colorScheme.primary : colorScheme.outline,
                width: isCover ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image(
                image: authNetworkImage(media.url!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, color: colorScheme.onSurfaceVariant),
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
                color: colorScheme.primary,
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
                child: Icon(Icons.close, size: 14, color: colorScheme.onSurface),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNewImageTile(int index, {bool canEdit = true, required ColorScheme colorScheme}) {
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
                color: isCover ? colorScheme.primary : colorScheme.outline,
                width: isCover ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.file(
                File(image['path'] as String),
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => Icon(Icons.broken_image_outlined, color: colorScheme.onSurfaceVariant),
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
                color: colorScheme.primary,
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
                child: Icon(Icons.close, size: 14, color: colorScheme.onSurface),
              ),
            ),
          ),
      ],
    );
  }
}
