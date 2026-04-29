import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:heartforcharity_mobile/model/responses/campaign.dart';
import 'package:heartforcharity_mobile/model/responses/volunteer_job.dart';
import 'package:heartforcharity_mobile/model/responses/recommended_campaign.dart';
import 'package:heartforcharity_mobile/model/responses/recommended_job.dart';
import 'package:heartforcharity_mobile/providers/campaign_provider.dart';
import 'package:heartforcharity_mobile/providers/donation_provider.dart';
import 'package:heartforcharity_mobile/providers/recommender_provider.dart';
import 'package:heartforcharity_mobile/providers/user_profile_provider.dart';
import 'package:heartforcharity_mobile/providers/volunteer_job_provider.dart';
import 'package:heartforcharity_mobile/providers/volunteer_skill_provider.dart';
import 'package:heartforcharity_mobile/screens/campaign_detail_screen.dart';
import 'package:heartforcharity_mobile/screens/skills_onboarding_screen.dart';
import 'package:heartforcharity_mobile/screens/volunteer_job_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  static const _storage = FlutterSecureStorage();
  static const _modeKey = 'home_mode';

  bool _isVolunteerMode = false;
  bool _loading = true;
  String _firstName = '';
  List<VolunteerJob> _jobs = [];
  List<Campaign> _campaigns = [];
  List<RecommendedJob> _recommendedJobs = [];
  List<RecommendedCampaign> _recommendedCampaigns = [];

  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadContent();
    });
  }

  Future<void> _initialize() async {
    final profileProvider = context.read<UserProfileProvider>();
    final jobProvider = context.read<VolunteerJobProvider>();
    final campaignProvider = context.read<CampaignProvider>();

    final savedMode = await _storage.read(key: _modeKey);
    final isVolunteer = savedMode == 'volunteer';
    if (mounted) setState(() => _isVolunteerMode = isVolunteer);

    try {
      final profile = await profileProvider.getMe();
      if (mounted && profile != null) {
        setState(() => _firstName = profile.firstName);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }

    if (isVolunteer) await _maybeShowSkillsOnboarding();

    await Future.wait([
      _loadContent(jobProvider: jobProvider, campaignProvider: campaignProvider),
      _loadRecommendations(),
    ]);
  }

  Future<void> maybeShowOnboarding() async {
    if (_isVolunteerMode) await _maybeShowSkillsOnboarding();
  }

  Future<void> _maybeShowSkillsOnboarding() async {
    if (!mounted) return;
    try {
      final skills = await context.read<VolunteerSkillProvider>().getMySkills();
      if (!mounted || skills.isNotEmpty) return;
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const SkillsOnboardingScreen()),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;
    try {
      final provider = context.read<RecommenderProvider>();
      if (_isVolunteerMode) {
        final jobs = await provider.getJobRecommendations();
        if (mounted) setState(() => _recommendedJobs = jobs);
      } else {
        final campaigns = await provider.getCampaignRecommendations();
        if (mounted) setState(() => _recommendedCampaigns = campaigns);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _loadContent({
    VolunteerJobProvider? jobProvider,
    CampaignProvider? campaignProvider,
  }) async {
    if (!mounted) return;
    setState(() => _loading = true);

    final jp = jobProvider ?? context.read<VolunteerJobProvider>();
    final cp = campaignProvider ?? context.read<CampaignProvider>();
    final query = _searchController.text.trim();

    try {
      if (_isVolunteerMode) {
        final filter = <String, dynamic>{'status': 'Active', 'pageSize': 20};
        if (query.isNotEmpty) filter['fts'] = query;
        final result = await jp.get(filter: filter);
        if (mounted) setState(() => _jobs = result.items);
      } else {
        final filter = <String, dynamic>{'status': 'Active', 'pageSize': 20};
        if (query.isNotEmpty) filter['fts'] = query;
        final result = await cp.get(filter: filter);
        if (mounted) setState(() => _campaigns = result.items);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setMode(bool isVolunteer) async {
    await _storage.write(
      key: _modeKey,
      value: isVolunteer ? 'volunteer' : 'donor',
    );
    if (!mounted) return;
    _searchController.clear();
    _debounce?.cancel();
    setState(() => _isVolunteerMode = isVolunteer);

    if (isVolunteer) await _maybeShowSkillsOnboarding();

    await Future.wait([_loadContent(), _loadRecommendations()]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      appBar: AppBar(
        title: Text(_firstName.isNotEmpty ? 'Hello, $_firstName' : 'Hello'),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([_loadContent(), _loadRecommendations()]),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ModeToggle(
                isVolunteerMode: _isVolunteerMode,
                onChanged: _setMode,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: _isVolunteerMode
                        ? 'Search volunteer jobs...'
                        : 'Search campaigns...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: ListenableBuilder(
                      listenable: _searchController,
                      builder: (_, _) => _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadContent();
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            if (_isVolunteerMode && _recommendedJobs.isNotEmpty)
              SliverToBoxAdapter(
                child: _RecommendedJobsSection(jobs: _recommendedJobs),
              ),
            if (!_isVolunteerMode && _recommendedCampaigns.isNotEmpty)
              SliverToBoxAdapter(
                child: _RecommendedCampaignsSection(campaigns: _recommendedCampaigns),
              ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_isVolunteerMode)
              _buildJobSliver(cs)
            else
              _buildCampaignSliver(cs),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ColorScheme cs, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      );

  Widget _emptyState(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ),
      );

  SliverList _buildJobSliver(ColorScheme cs) {
    if (_jobs.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate(
          [_emptyState('No active volunteer jobs available.')],
        ),
      );
    }
    return SliverList(
      delegate: SliverChildListDelegate([
        _sectionTitle(cs, 'Active volunteer jobs'),
        ..._jobs.map((j) => _JobCard(job: j)),
        const SizedBox(height: 16),
      ]),
    );
  }

  SliverList _buildCampaignSliver(ColorScheme cs) {
    if (_campaigns.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate(
          [_emptyState('No active campaigns available.')],
        ),
      );
    }
    return SliverList(
      delegate: SliverChildListDelegate([
        _sectionTitle(cs, 'Active campaigns'),
        ..._campaigns.map((c) => _CampaignCard(campaign: c)),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ── Mode toggle ───────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final bool isVolunteerMode;
  final void Function(bool) onChanged;

  const _ModeToggle({required this.isVolunteerMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _ToggleChip(
              label: 'Volunteer',
              icon: Icons.volunteer_activism,
              isActive: isVolunteerMode,
              onTap: () => onChanged(true),
            ),
            _ToggleChip(
              label: 'Donor',
              icon: Icons.favorite_border,
              isActive: !isVolunteerMode,
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Volunteer job card ────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final VolunteerJob job;
  const _JobCard({required this.job});

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.organisationName,
                      style: TextStyle(fontSize: 13, color: cs.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const SizedBox(height: 10),
          Row(
            children: [
              if (job.startDate != null) ...[
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(job.startDate!),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
              ],
              Icon(Icons.people_outline, size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${job.positionsRemaining} spots left',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          if (job.categoryName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                job.categoryName!,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VolunteerJobDetailScreen(job: job),
                ),
              ),
              child: const Text('See more'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recommended jobs section ──────────────────────────────────────────────────

class _RecommendedJobsSection extends StatelessWidget {
  final List<RecommendedJob> jobs;
  const _RecommendedJobsSection({required this.jobs});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Recommended for you',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: jobs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _RecommendedJobCard(job: jobs[i]),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _RecommendedJobCard extends StatelessWidget {
  final RecommendedJob job;
  const _RecommendedJobCard({required this.job});

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<VolunteerJobProvider>();
    try {
      final full = await provider.getById(job.volunteerJobId);
      await navigator.push(
        MaterialPageRoute(builder: (_) => VolunteerJobDetailScreen(job: full)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locationLabel = job.isRemote ? 'Remote' : (job.cityName ?? 'On-site');
    final locationColor = job.isRemote ? const Color(0xFF10B981) : cs.primary;

    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: locationColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  locationLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: locationColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            job.organisationName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: cs.primary),
          ),
          const Spacer(),
          if (job.reasons.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                job.reasons.first,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

// ── Recommended campaigns section ─────────────────────────────────────────────

class _RecommendedCampaignsSection extends StatelessWidget {
  final List<RecommendedCampaign> campaigns;
  const _RecommendedCampaignsSection({required this.campaigns});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Recommended for you',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: campaigns.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _RecommendedCampaignCard(campaign: campaigns[i]),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _RecommendedCampaignCard extends StatelessWidget {
  final RecommendedCampaign campaign;
  const _RecommendedCampaignCard({required this.campaign});

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<CampaignProvider>();
    try {
      final full = await provider.getById(campaign.campaignId);
      await navigator.push(
        MaterialPageRoute(builder: (_) => CampaignDetailScreen(campaign: full)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = campaign.targetAmount > 0
        ? (campaign.currentAmount / campaign.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            campaign.organisationName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: cs.primary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: cs.outline.withValues(alpha: 0.2),
              color: cs.secondary,
              minHeight: 5,
            ),
          ),
          const Spacer(),
          if (campaign.reasons.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                campaign.reasons.first,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

// ── Campaign card ─────────────────────────────────────────────────────────────

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  const _CampaignCard({required this.campaign});

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CampaignDetailScreen(campaign: campaign),
      ),
    );
  }

  void _openDonate(BuildContext context) {
    final provider = context.read<DonationProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DonateSheet(campaign: campaign, provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = campaign.targetAmount > 0
        ? (campaign.currentAmount / campaign.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);

    return GestureDetector(
      onTap: () => _openDetail(context),
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
            const SizedBox(height: 2),
            Text(
              campaign.organisationName,
              style: TextStyle(fontSize: 13, color: cs.primary),
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
                  '\$${campaign.currentAmount.toStringAsFixed(0)} raised ($pct%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.secondary,
                  ),
                ),
                Text(
                  'Goal: \$${campaign.targetAmount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            if (campaign.endDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 12, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Ends ${DateFormat('dd MMM yyyy').format(campaign.endDate!)}',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.people_outline,
                      size: 12, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${campaign.donationCount} donations',
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openDonate(context),
                child: const Text('Donate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
