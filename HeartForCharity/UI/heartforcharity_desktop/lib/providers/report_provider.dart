import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_shared/providers/base_provider.dart';
import 'package:printing/printing.dart';
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
    final bytes = await _fetchDonationsBytes(fromDate: fromDate, toDate: toDate, campaignId: campaignId);
    await _saveAndOpen(bytes, 'donations-report');
  }

  Future<void> downloadCampaignsReport({String? status}) async {
    final bytes = await _fetchCampaignsBytes(status: status);
    await _saveAndOpen(bytes, 'campaigns-report');
  }

  Future<void> downloadVolunteersReport({int? volunteerJobId}) async {
    final bytes = await _fetchVolunteersBytes(volunteerJobId: volunteerJobId);
    await _saveAndOpen(bytes, 'volunteers-report');
  }

  Future<void> printDonationsReport({
    DateTime? fromDate,
    DateTime? toDate,
    int? campaignId,
  }) async {
    final bytes = await _fetchDonationsBytes(fromDate: fromDate, toDate: toDate, campaignId: campaignId);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'Donations report');
  }

  Future<void> printCampaignsReport({String? status}) async {
    final bytes = await _fetchCampaignsBytes(status: status);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'Campaigns report');
  }

  Future<void> printVolunteersReport({int? volunteerJobId}) async {
    final bytes = await _fetchVolunteersBytes(volunteerJobId: volunteerJobId);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'Volunteers report');
  }

  Future<Uint8List> _fetchDonationsBytes({
    DateTime? fromDate,
    DateTime? toDate,
    int? campaignId,
  }) {
    return _fetchBytes('report/donations', {
      'fromDate': fromDate?.toUtc().toIso8601String(),
      'toDate': toDate?.toUtc().toIso8601String(),
      'campaignId': campaignId,
    });
  }

  Future<Uint8List> _fetchCampaignsBytes({String? status}) {
    return _fetchBytes('report/campaigns', {'status': status});
  }

  Future<Uint8List> _fetchVolunteersBytes({int? volunteerJobId}) {
    return _fetchBytes('report/volunteers', {'volunteerJobId': volunteerJobId});
  }

  Future<Uint8List> _fetchBytes(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${BaseProvider.baseUrl}$endpoint');
    final response = await executeHttp(
      () => http.post(url, headers: createHeaders(), body: jsonEncode(body)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to generate report. (${response.statusCode})');
    }

    return response.bodyBytes;
  }

  Future<void> _saveAndOpen(Uint8List bytes, String filePrefix) async {
    final fileName = '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${Directory.systemTemp.path}/$fileName');
    await file.writeAsBytes(bytes);
    await launchUrl(Uri.file(file.path));
  }
}
