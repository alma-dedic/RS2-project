import 'package:flutter/material.dart';
import 'package:heartforcharity_mobile/model/responses/skill.dart';
import 'package:heartforcharity_mobile/providers/volunteer_skill_provider.dart';
import 'package:provider/provider.dart';

class SkillsOnboardingScreen extends StatefulWidget {
  const SkillsOnboardingScreen({super.key});

  @override
  State<SkillsOnboardingScreen> createState() => _SkillsOnboardingScreenState();
}

class _SkillsOnboardingScreenState extends State<SkillsOnboardingScreen> {
  static const _minSkills = 3;

  List<Skill> _allSkills = [];
  final Set<int> _selectedIds = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final result = await context.read<VolunteerSkillProvider>().getAllSkills();
      if (mounted) setState(() { _allSkills = result.items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load skills.'; _loading = false; });
    }
  }

  Future<void> _continue() async {
    if (_selectedIds.length < _minSkills) return;
    setState(() { _saving = true; _error = null; });
    final provider = context.read<VolunteerSkillProvider>();
    try {
      for (final id in _selectedIds) {
        await provider.addSkill(id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skills saved successfully.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = _minSkills - _selectedIds.length;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.volunteer_activism, size: 40, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                'What are your skills?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Select at least $_minSkills skills to help us match you with the right volunteer opportunities.',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_error != null && _allSkills.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: TextStyle(color: cs.error)),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _loadSkills, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allSkills.map((skill) {
                      final selected = _selectedIds.contains(skill.skillId);
                      return FilterChip(
                        label: Text(skill.name),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          if (selected) {
                            _selectedIds.remove(skill.skillId);
                          } else {
                            _selectedIds.add(skill.skillId);
                          }
                        }),
                        selectedColor: cs.primary.withValues(alpha: 0.15),
                        checkmarkColor: cs.primary,
                        labelStyle: TextStyle(
                          color: selected ? cs.primary : cs.onSurface,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: selected ? cs.primary : cs.outline,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
                ],
                const SizedBox(height: 16),
                if (remaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Select $remaining more skill${remaining == 1 ? '' : 's'} to continue',
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_selectedIds.length >= _minSkills && !_saving) ? _continue : null,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Continue'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
