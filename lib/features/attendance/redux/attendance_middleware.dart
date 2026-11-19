import 'package:redux/redux.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../services/attendance_service.dart';
import 'attendance_actions.dart';

List<Middleware<State>> createAttendanceMiddleware<State>({
  AttendanceService? attendanceService,
  SecureStorageService? secureStorage,
}) {
  final service = attendanceService ?? AttendanceService();
  final storage = secureStorage ?? SecureStorageService();

  Future<String> readAccessToken() async {
    final token = await storage.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Please log in to view attendance.', statusCode: 401);
    }
    return token;
  }

  Future<void> handleMonth(
    Store<State> store,
    FetchAttendanceMonthAction action,
    NextDispatcher next,
  ) async {
    next(action);
    try {
      final data = await service.getMyAttendance(
        month: action.month,
        year: action.year,
        token: await readAccessToken(),
      );
      store.dispatch(AttendanceMonthSuccessAction(data));
    } on ApiException catch (error) {
      store.dispatch(AttendanceMonthFailureAction(error.message));
    } catch (_) {
      store.dispatch(
        const AttendanceMonthFailureAction(
          'Unable to load attendance. Please try again.',
        ),
      );
    }
  }

  Future<void> handleDay(
    Store<State> store,
    FetchAttendanceDayAction action,
    NextDispatcher next,
  ) async {
    next(action);
    try {
      final data = await service.getMyAttendanceDay(
        date: action.date,
        token: await readAccessToken(),
      );
      store.dispatch(AttendanceDaySuccessAction(data));
    } on ApiException catch (error) {
      store.dispatch(AttendanceDayFailureAction(error.message));
    } catch (_) {
      store.dispatch(
        const AttendanceDayFailureAction(
          'Unable to load day details. Please try again.',
        ),
      );
    }
  }

  return [
    TypedMiddleware<State, FetchAttendanceMonthAction>(handleMonth).call,
    TypedMiddleware<State, FetchAttendanceDayAction>(handleDay).call,
  ];
}
