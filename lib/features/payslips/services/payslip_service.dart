import 'dart:typed_data';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/payslip.dart';

class PayslipService {
  PayslipService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PayslipCollection> getMyPayslips({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.myPayslipsEndpoint,
      token: token,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Invalid payslip response from server.');
    }
    try {
      return PayslipCollection.fromJson(data);
    } on FormatException {
      throw ApiException('Invalid payslip response from server.');
    }
  }

  Future<Uint8List> download(Payslip payslip, {required String token}) {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(payslip.id)) {
      throw ApiException('Invalid payslip identifier.');
    }
    return _apiClient.getPdf(
      '${ApiConstants.myPayslipsEndpoint}/${payslip.id}/download',
      token: token,
    );
  }
}
