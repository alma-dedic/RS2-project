import 'package:flutter/material.dart';
import 'package:heartforcharity_mobile/model/responses/campaign.dart';
import 'package:heartforcharity_mobile/model/responses/donation.dart';
import 'package:heartforcharity_mobile/providers/campaign_provider.dart';
import 'package:heartforcharity_mobile/providers/donation_provider.dart';
import 'package:heartforcharity_mobile/screens/paypal_webview_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;
  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  late Campaign _campaign;
  List<Donation> _donations = [];
  bool _donationsLoading = true;

  @override
  void initState() {
    super.initState();
    _campaign = widget.campaign;
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    final provider = context.read<DonationProvider>();
    try {
      final result = await provider.getCampaignDonations(_campaign.campaignId);
      if (mounted) setState(() => _donations = result.items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _donationsLoading = false);
    }
  }

  Future<void> _refreshCampaign() async {
    final provider = context.read<CampaignProvider>();
    try {
      final fresh = await provider.getById(_campaign.campaignId);
      if (mounted) setState(() => _campaign = fresh);
    } catch (_) {}
  }

  Future<void> _onDonationMade() async {
    await Future.wait([_loadDonations(), _refreshCampaign()]);
  }

  void _openDonateSheet() {
    final provider = context.read<DonationProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DonateSheet(
        campaign: _campaign,
        provider: provider,
        onDonationMade: _onDonationMade,
      ),
    );
  }

  String _dateRange() {
    final fmt = DateFormat('dd MMM yyyy');
    final c = _campaign;
    if (c.startDate != null && c.endDate != null) {
      return '${fmt.format(c.startDate!)} – ${fmt.format(c.endDate!)}';
    }
    if (c.endDate != null) return 'Ends ${fmt.format(c.endDate!)}';
    return 'Started ${fmt.format(c.startDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final campaign = _campaign;
    final progress = campaign.targetAmount > 0
        ? (campaign.currentAmount / campaign.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      appBar: AppBar(title: Text(campaign.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    campaign.organisationName,
                    style: TextStyle(
                        fontSize: 14,
                        color: cs.primary,
                        fontWeight: FontWeight.w500),
                  ),
                  if (campaign.categoryName != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        campaign.categoryName!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '\$${campaign.currentAmount.toStringAsFixed(0)} out of '
                    '\$${campaign.targetAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: cs.outline.withValues(alpha: 0.2),
                      color: cs.primary,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$pct% funded',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        '${campaign.donationCount} donations',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (campaign.startDate != null || campaign.endDate != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 5),
                        Text(
                          _dateRange(),
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (campaign.description != null) ...[
              const SizedBox(height: 12),
              _InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About this campaign',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      campaign.description!,
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
            const SizedBox(height: 12),
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donations',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_donationsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_donations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No donations yet. Be the first!',
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ...(_donations.map((d) => _DonationRow(donation: d))),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: _openDonateSheet,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Donate'),
          ),
        ),
      ),
    );
  }
}

class _DonationRow extends StatelessWidget {
  final Donation donation;
  const _DonationRow({required this.donation});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = (donation.isAnonymous || donation.donorName == null)
        ? 'Anonymous donor'
        : donation.donorName!;
    final dateStr = donation.donationDateTime != null
        ? DateFormat('dd MMM yyyy').format(donation.donationDateTime!)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primary.withValues(alpha: 0.1),
            child: Icon(
              donation.isAnonymous ? Icons.person_outline : Icons.favorite,
              size: 16,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${donation.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.secondary,
                ),
              ),
              if (donation.isPaid)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Paid',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.secondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

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

// ── Donate sheet (2-step) ─────────────────────────────────────────────────────

class DonateSheet extends StatefulWidget {
  final Campaign campaign;
  final DonationProvider provider;
  final VoidCallback? onDonationMade;

  const DonateSheet({
    super.key,
    required this.campaign,
    required this.provider,
    this.onDonationMade,
  });

  @override
  State<DonateSheet> createState() => _DonateSheetState();
}

class _DonateSheetState extends State<DonateSheet> {
  final _amountFormKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isAnonymous = false;
  bool _submitting = false;
  int _currentPage = 0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _goNext() => setState(() => _currentPage = 1);
  void _goBack() => setState(() => _currentPage = 0);

  Future<void> _submit() async {
    if (!_amountFormKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());

    setState(() => _submitting = true);

    // Capture these before any await — context may be gone after pop
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final campaign = widget.campaign;
    final provider = widget.provider;

    try {
      final order = await provider.createOrder(
        campaignId: campaign.campaignId,
        amount: amount,
        isAnonymous: _isAnonymous,
      );

      final approvalUrl = order['approvalUrl'] as String;
      final orderId = order['orderId'] as String;

      navigator.pop(); // close the sheet
      navigator.push(MaterialPageRoute(
        builder: (_) => PayPalWebViewScreen(
          approvalUrl: approvalUrl,
          orderId: orderId,
          provider: provider,
          onSuccess: () {
            messenger.showSnackBar(SnackBar(
              content: Text(
                'Thank you! \$${amount.toStringAsFixed(2)} donated to '
                '"${campaign.title}".',
              ),
              backgroundColor: const Color(0xFF10B981),
            ));
            widget.onDonationMade?.call();
          },
          onCancelled: () => messenger.showSnackBar(
            const SnackBar(content: Text('Payment cancelled.')),
          ),
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepDot(active: _currentPage == 0),
                    const SizedBox(width: 8),
                    _StepDot(active: _currentPage == 1),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: _currentPage == 0
                    ? _buildStep1(cs)
                    : _buildStep2(cs),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Step 1 — anonymous choice
  Widget _buildStep1(ColorScheme cs) {
    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you want to donate anonymously?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.campaign.title,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _isAnonymous = !_isAnonymous),
            child: Row(
              children: [
                Checkbox(
                  value: _isAnonymous,
                  activeColor: cs.primary,
                  onChanged: (v) =>
                      setState(() => _isAnonymous = v ?? false),
                ),
                Text(
                  'Be anonymous',
                  style: TextStyle(fontSize: 15, color: cs.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _goNext,
              icon: Icon(Icons.arrow_forward, size: 16, color: cs.primary),
              label: Text(
                'Continue',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2 — amount entry
  Widget _buildStep2(ColorScheme cs) {
    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Enter the donation amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _amountFormKey,
            child: TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '\$ ',
                hintStyle: TextStyle(
                    fontSize: 26,
                    color: cs.outline,
                    fontWeight: FontWeight.w400),
                helperText: 'Min \$1.00 · Max \$10,000.00',
                helperStyle: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter an amount.';
                final parsed = double.tryParse(v.trim());
                if (parsed == null) return 'Enter a valid number.';
                if (parsed < 1.0) return 'Minimum donation is \$1.00.';
                if (parsed > 10000.0) return 'Maximum donation is \$10,000.00.';
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: _goBack,
                child: Text(
                  'Back',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Donate with PayPal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? cs.primary : cs.outline,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
