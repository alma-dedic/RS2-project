import 'package:heartforcharity_desktop/model/responses/skill.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';

class SkillProvider extends BaseProvider<Skill> {
  SkillProvider() : super('skill');

  @override
  Skill fromJson(data) => Skill.fromJson(data);
}
