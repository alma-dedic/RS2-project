import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:heartforcharity_mobile/model/responses/organisation_profile.dart';
import 'package:heartforcharity_mobile/providers/organisation_profile_provider.dart';
import 'package:heartforcharity_mobile/screens/org_detail_screen.dart';
import 'package:heartforcharity_mobile/utils/auth_image.dart';
import 'package:provider/provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen> {
  static const _storage = FlutterSecureStorage();

  final _searchController = TextEditingController();
  Timer? _debounce;

  List<OrganisationProfile> _orgs = [];
  bool _loading = true;
  bool _isVolunteerMode = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final provider = context.read<OrganisationProfileProvider>();
    final mode = await _storage.read(key: 'home_mode');
    if (mounted && mode != null) {
      setState(() => _isVolunteerMode = mode == 'volunteer');
    }
    await _load(provider: provider);
  }

  Future<void> refreshMode() async {
    final mode = await _storage.read(key: 'home_mode');
    final newIsVolunteer = mode == 'volunteer';
    if (!mounted || newIsVolunteer == _isVolunteerMode) return;
    setState(() => _isVolunteerMode = newIsVolunteer);
  }

  Future<void> _load({OrganisationProfileProvider? provider, String? fts}) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final p = provider ?? context.read<OrganisationProfileProvider>();
    try {
      final filter = <String, dynamic>{'pageSize': 50};
      if (fts != null && fts.trim().isNotEmpty) filter['fts'] = fts.trim();
      final result = await p.get(filter: filter);
      if (mounted) setState(() => _orgs = result.items);
    } catch (_) {
      if (mounted) setState(() => _orgs = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _load(fts: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('Explore'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search organisations...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(fts: _searchController.text),
              child: _orgs.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off,
                                  size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No organisations found',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _orgs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 0),
                      itemBuilder: (_, i) => _OrgCard(
                        org: _orgs[i],
                        isVolunteerMode: _isVolunteerMode,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrgDetailScreen(
                              org: _orgs[i],
                              isVolunteerMode: _isVolunteerMode,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
    );
  }
}

class _OrgCard extends StatelessWidget {
  final OrganisationProfile org;
  final bool isVolunteerMode;
  final VoidCallback onTap;

  const _OrgCard({
    required this.org,
    required this.isVolunteerMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrgAvatar(name: org.name, logoUrl: org.logoUrl),
            const SizedBox(width: 12),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (org.organisationTypeName != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
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
                            size: 12, color: cs.onSurfaceVariant),
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
                  if (org.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      org.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isVolunteerMode
                            ? 'See volunteer jobs'
                            : 'See campaigns',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: cs.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrgAvatar extends StatelessWidget {
  final String name;
  final String? logoUrl;

  const _OrgAvatar({required this.name, this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 26,
      backgroundColor: cs.primary.withValues(alpha: 0.1),
      backgroundImage: logoUrl != null ? authNetworkImage(logoUrl!) : null,
      child: logoUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            )
          : null,
    );
  }
}
