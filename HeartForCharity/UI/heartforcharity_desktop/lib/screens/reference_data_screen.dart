import 'package:flutter/material.dart';
import 'package:heartforcharity_desktop/model/responses/category.dart';
import 'package:heartforcharity_desktop/model/responses/city.dart';
import 'package:heartforcharity_desktop/model/responses/country.dart';
import 'package:heartforcharity_desktop/model/responses/organisation_type.dart';
import 'package:heartforcharity_desktop/model/responses/skill.dart';
import 'package:heartforcharity_desktop/providers/category_provider.dart';
import 'package:heartforcharity_desktop/providers/city_provider.dart';
import 'package:heartforcharity_desktop/providers/country_provider.dart';
import 'package:heartforcharity_desktop/providers/organisation_type_provider.dart';
import 'package:heartforcharity_desktop/providers/skill_provider.dart';
import 'package:provider/provider.dart';

class ReferenceDataScreen extends StatefulWidget {
  const ReferenceDataScreen({super.key});

  @override
  State<ReferenceDataScreen> createState() => _ReferenceDataScreenState();
}

class _ReferenceDataScreenState extends State<ReferenceDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: Text('Reference Data',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
          ),
          const SizedBox(height: 16),
          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
              tabs: const [
                Tab(text: 'Categories'),
                Tab(text: 'Skills'),
                Tab(text: 'Organisation Types'),
                Tab(text: 'Countries'),
                Tab(text: 'Cities'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CategoriesTab(),
                _SkillsTab(),
                _OrganisationTypesTab(),
                _CountriesTab(),
                _CitiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Generic helpers ────────────────────────────────────────────────────────

Widget _buildLabel(String text, ColorScheme colorScheme) => Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
    );

Widget _buildField(TextEditingController ctrl, String label, ColorScheme colorScheme, {int maxLines = 1, String? error}) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, colorScheme),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: label,
            errorText: error,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );

Future<bool?> _confirm(BuildContext context, String message) => showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

Widget _buildCard({required Widget child, required ColorScheme colorScheme}) => Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );

// ─── Categories ─────────────────────────────────────────────────────────────

class _CategoriesTab extends StatefulWidget {
  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  List<Category> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await context.read<CategoryProvider>().get(filter: {'pageSize': 200});
      if (mounted) setState(() => _items = result.items);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDialog([Category? item]) async {
    final colorScheme = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    String appliesTo = item?.appliesTo ?? 'Both';
    String? nameError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(item == null ? 'Add Category' : 'Edit Category'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(nameCtrl, 'Name', colorScheme, error: nameError),
                const SizedBox(height: 12),
                _buildField(descCtrl, 'Description', colorScheme, maxLines: 2),
                const SizedBox(height: 12),
                _buildLabel('Applies To', colorScheme),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: appliesTo,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ['Both', 'Campaign', 'VolunteerJob']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setS(() => appliesTo = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  setS(() => nameError = 'Name is required');
                  return;
                }
                final body = {'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim(), 'appliesTo': appliesTo};
                try {
                  if (item == null) {
                    await context.read<CategoryProvider>().insert(body);
                  } else {
                    await context.read<CategoryProvider>().update(item.categoryId, body);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Category item) async {
    final ok = await _confirm(context, 'Delete category "${item.name}"?');
    if (ok != true || !mounted) return;
    final provider = context.read<CategoryProvider>();
    try {
      await provider.delete(item.categoryId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _RefDataList(
      loading: _loading,
      onAdd: () => _showDialog(),
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          return _buildCard(
            colorScheme: colorScheme,
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: item.description?.isNotEmpty == true
                  ? Text(item.description!, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(item.appliesTo ?? 'Both', style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.w500)),
                  ),
                  IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurfaceVariant), onPressed: () => _showDialog(item)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _delete(item)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Skills ──────────────────────────────────────────────────────────────────

class _SkillsTab extends StatefulWidget {
  @override
  State<_SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends State<_SkillsTab> {
  List<Skill> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await context.read<SkillProvider>().get(filter: {'pageSize': 200});
      if (mounted) setState(() => _items = result.items);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDialog([Skill? item]) async {
    final colorScheme = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    String? nameError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(item == null ? 'Add Skill' : 'Edit Skill'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(nameCtrl, 'Name', colorScheme, error: nameError),
                const SizedBox(height: 12),
                _buildField(descCtrl, 'Description', colorScheme, maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  setS(() => nameError = 'Name is required');
                  return;
                }
                final body = {'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim()};
                try {
                  if (item == null) {
                    await context.read<SkillProvider>().insert(body);
                  } else {
                    await context.read<SkillProvider>().update(item.skillId, body);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Skill item) async {
    final ok = await _confirm(context, 'Delete skill "${item.name}"?');
    if (ok != true || !mounted) return;
    final provider = context.read<SkillProvider>();
    try {
      await provider.delete(item.skillId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _RefDataList(
      loading: _loading,
      onAdd: () => _showDialog(),
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          return _buildCard(
            colorScheme: colorScheme,
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: item.description?.isNotEmpty == true
                  ? Text(item.description!, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurfaceVariant), onPressed: () => _showDialog(item)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _delete(item)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Organisation Types ──────────────────────────────────────────────────────

class _OrganisationTypesTab extends StatefulWidget {
  @override
  State<_OrganisationTypesTab> createState() => _OrganisationTypesTabState();
}

class _OrganisationTypesTabState extends State<_OrganisationTypesTab> {
  List<OrganisationType> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await context.read<OrganisationTypeProvider>().get(filter: {'pageSize': 200});
      if (mounted) setState(() => _items = result.items);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDialog([OrganisationType? item]) async {
    final colorScheme = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    String? nameError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(item == null ? 'Add Organisation Type' : 'Edit Organisation Type'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(nameCtrl, 'Name', colorScheme, error: nameError),
                const SizedBox(height: 12),
                _buildField(descCtrl, 'Description', colorScheme, maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  setS(() => nameError = 'Name is required');
                  return;
                }
                final body = {'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim()};
                try {
                  if (item == null) {
                    await context.read<OrganisationTypeProvider>().insert(body);
                  } else {
                    await context.read<OrganisationTypeProvider>().update(item.organisationTypeId, body);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(OrganisationType item) async {
    final ok = await _confirm(context, 'Delete organisation type "${item.name}"?');
    if (ok != true || !mounted) return;
    final provider = context.read<OrganisationTypeProvider>();
    try {
      await provider.delete(item.organisationTypeId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _RefDataList(
      loading: _loading,
      onAdd: () => _showDialog(),
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          return _buildCard(
            colorScheme: colorScheme,
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: item.description?.isNotEmpty == true
                  ? Text(item.description!, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurfaceVariant), onPressed: () => _showDialog(item)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _delete(item)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Countries ───────────────────────────────────────────────────────────────

class _CountriesTab extends StatefulWidget {
  @override
  State<_CountriesTab> createState() => _CountriesTabState();
}

class _CountriesTabState extends State<_CountriesTab> {
  List<Country> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await context.read<CountryProvider>().get(filter: {'pageSize': 300});
      if (mounted) setState(() => _items = result.items);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDialog([Country? item]) async {
    final colorScheme = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final isoCtrl = TextEditingController(text: item?.isoCode ?? '');
    String? nameError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(item == null ? 'Add Country' : 'Edit Country'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(nameCtrl, 'Name', colorScheme, error: nameError),
                const SizedBox(height: 12),
                _buildField(isoCtrl, 'ISO Code (e.g. BA)', colorScheme),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  setS(() => nameError = 'Name is required');
                  return;
                }
                final body = {'name': nameCtrl.text.trim(), 'iSOCode': isoCtrl.text.trim()};
                try {
                  if (item == null) {
                    await context.read<CountryProvider>().insert(body);
                  } else {
                    await context.read<CountryProvider>().update(item.countryId, body);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Country item) async {
    final ok = await _confirm(context, 'Delete country "${item.name}"?');
    if (ok != true || !mounted) return;
    final provider = context.read<CountryProvider>();
    try {
      await provider.delete(item.countryId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _RefDataList(
      loading: _loading,
      onAdd: () => _showDialog(),
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          return _buildCard(
            colorScheme: colorScheme,
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.isoCode != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(item.isoCode!, style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                    ),
                  IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurfaceVariant), onPressed: () => _showDialog(item)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _delete(item)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Cities ──────────────────────────────────────────────────────────────────

class _CitiesTab extends StatefulWidget {
  @override
  State<_CitiesTab> createState() => _CitiesTabState();
}

class _CitiesTabState extends State<_CitiesTab> {
  List<City> _items = [];
  List<Country> _countries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cityProvider = context.read<CityProvider>();
    final countryProvider = context.read<CountryProvider>();
    try {
      final citiesResult = await cityProvider.get(filter: {'pageSize': 500});
      final countriesResult = await countryProvider.get(filter: {'pageSize': 300});
      if (mounted) {
        setState(() {
          _items = citiesResult.items;
          _countries = countriesResult.items;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDialog([City? item]) async {
    final colorScheme = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    int? selectedCountryId = item?.countryId;
    String? nameError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(item == null ? 'Add City' : 'Edit City'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(nameCtrl, 'Name', colorScheme, error: nameError),
                const SizedBox(height: 12),
                _buildLabel('Country', colorScheme),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: selectedCountryId,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Select country',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _countries
                      .map((c) => DropdownMenuItem(value: c.countryId, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setS(() => selectedCountryId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  setS(() => nameError = 'Name is required');
                  return;
                }
                if (selectedCountryId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please select a country')));
                  return;
                }
                final body = {'name': nameCtrl.text.trim(), 'countryId': selectedCountryId};
                final cityProvider = context.read<CityProvider>();
                try {
                  if (item == null) {
                    await cityProvider.insert(body);
                  } else {
                    await cityProvider.update(item.cityId, body);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(City item) async {
    final ok = await _confirm(context, 'Delete city "${item.name}"?');
    if (ok != true || !mounted) return;
    try {
      await context.read<CityProvider>().delete(item.cityId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _RefDataList(
      loading: _loading,
      onAdd: () => _showDialog(),
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          return _buildCard(
            colorScheme: colorScheme,
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: item.countryName.isNotEmpty
                  ? Text(item.countryName, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurfaceVariant), onPressed: () => _showDialog(item)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _delete(item)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Shared wrapper ───────────────────────────────────────────────────────────

class _RefDataList extends StatelessWidget {
  final bool loading;
  final VoidCallback onAdd;
  final Widget child;

  const _RefDataList({required this.loading, required this.onAdd, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        loading
            ? const Center(child: CircularProgressIndicator())
            : child,
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton(
            onPressed: onAdd,
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
