import 'dart:convert';
import 'package:heartforcharity_mobile/model/responses/recommended_campaign.dart';
import 'package:heartforcharity_mobile/model/responses/recommended_job.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class RecommenderProvider extends BaseProvider<Object> {
  RecommenderProvider() : super('recommender');

  @override
  Object fromJson(data) => data;

  Future<List<RecommendedJob>> getJobRecommendations() async {
    final uri = Uri.parse('${BaseProvider.baseUrl}recommender/jobs');
    final response = await executeHttp(() => http.get(uri, headers: createHeaders()));
    isValidResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => RecommendedJob.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RecommendedCampaign>> getCampaignRecommendations() async {
    final uri = Uri.parse('${BaseProvider.baseUrl}recommender/campaigns');
    final response = await executeHttp(() => http.get(uri, headers: createHeaders()));
    isValidResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => RecommendedCampaign.fromJson(e as Map<String, dynamic>)).toList();
  }
}
