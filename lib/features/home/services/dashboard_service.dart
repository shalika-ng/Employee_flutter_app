import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  DashboardService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<DashboardData> getMyDashboard({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.myDashboardEndpoint,
      token: token,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return DashboardData.fromJson(data);
    }
    if (data is Map) {
      return DashboardData.fromJson(
        data.map((key, value) => MapEntry('$key', value)),
      );
    }
    throw ApiException('Invalid dashboard response from server.');
  }
}
