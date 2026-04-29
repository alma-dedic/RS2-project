import 'dart:convert';
import 'package:heartforcharity_mobile/model/responses/skill.dart';
import 'package:heartforcharity_mobile/model/responses/volunteer_skill.dart';
import 'package:heartforcharity_shared/model/search_result.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class VolunteerSkillProvider extends BaseProvider<VolunteerSkill> {
  VolunteerSkillProvider() : super('volunteerskill');

  @override
  VolunteerSkill fromJson(data) => VolunteerSkill.fromJson(data);

  Future<List<VolunteerSkill>> getMySkills() async {
    final uri = Uri.parse('${BaseProvider.baseUrl}volunteerskill/my');
    final response = await executeHttp(() => http.get(uri, headers: createHeaders()));
    isValidResponse(response);
    final data = jsonDecode(response.body);
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => VolunteerSkill.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VolunteerSkill> addSkill(int skillId) async {
    return insert({'skillId': skillId});
  }

  Future<bool> removeSkill(int volunteerSkillId) async {
    return delete(volunteerSkillId);
  }

  Future<SearchResult<Skill>> getAllSkills() async {
    final uri = Uri.parse('${BaseProvider.baseUrl}skill?pageSize=100');
    final response = await executeHttp(() => http.get(uri, headers: createHeaders()));
    isValidResponse(response);
    final data = jsonDecode(response.body);
    final result = SearchResult<Skill>();
    result.totalCount = data['totalCount'];
    result.items = (data['items'] as List<dynamic>)
        .map((e) => Skill.fromJson(e as Map<String, dynamic>))
        .toList();
    return result;
  }
}
