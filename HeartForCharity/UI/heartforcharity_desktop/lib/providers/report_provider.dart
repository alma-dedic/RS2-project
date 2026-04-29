import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_shared/providers/base_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportProvider extends BaseProvider<dynamic> {
  ReportProvider() : super('report');

  @override
  dynamic fromJson(data) => data;

  Future<void> downloadDonationsReport({
    DateTime? fromDate,
    DateTime? toDate,
    int? campaignId,
  }) async {
    await _download(
      'report/donations',
      {
        'fromDate': fromDate?.toUtc().toIso8601String(),
        'toDate': toDate?.toUtc().toIso8601String(),
        'campaignId': campaignId,
      },
      'donations-report',
    );
  }

  Future<void> downloadCampaignsReport({String? status}) async {
    await _download('report/campaigns', {'status': status}, 'campaigns-report');
  }

  Future<void> downloadVolunteersReport({int? volunteerJobId}) async {
    await _download(
      'report/volunteers',
      {'volunteerJobId': volunteerJobId},
      'volunteers-report',
    );
  }

  Future<void> _download(String endpoint, Map<String, dynamic> body, String filePrefix) async {
    final url = Uri.parse('${BaseProvider.baseUrl}$endpoint');
    final response = await executeHttp(
      () => http.post(url, headers: createHeaders(), body: jsonEncode(body)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to generate report. (${response.statusCode})');
    }

    final fileName = '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${Directory.systemTemp.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);
    await launchUrl(Uri.file(file.path));
  }
}
