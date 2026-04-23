import 'package:http/http.dart' as http;
import 'package:heartforcharity_mobile/model/responses/notification.dart';
import 'package:heartforcharity_mobile/providers/base_provider.dart';

class NotificationProvider extends BaseProvider<AppNotification> {
  NotificationProvider() : super('notification');

  @override
  AppNotification fromJson(data) => AppNotification.fromJson(data);

  Future<void> markAsRead(int id) async {
    final res = await http.patch(
      Uri.parse('${BaseProvider.baseUrl}notification/$id/read'),
      headers: createHeaders(),
    );
    isValidResponse(res);
  }

  Future<void> markAllAsRead() async {
    final res = await http.patch(
      Uri.parse('${BaseProvider.baseUrl}notification/read-all'),
      headers: createHeaders(),
    );
    isValidResponse(res);
  }
}
