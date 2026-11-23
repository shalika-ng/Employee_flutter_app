import '../models/request_models.dart';

const Object _unset = Object();

class RequestState {
  /// Month currently shown (used to refetch after apply / cancel).
  final RequestMonthFilter? filter;

  final bool applying;
  final bool cancelling;
  final String? error;

  final LeaveBalance? leaveBalance;
  final PermissionBalance? permissionBalance;
  final bool permissionBalanceLoading;
  final String? permissionBalanceError;

  final bool applyingPermission;
  final bool applyingRegularization;

  final List<LeaveRequest> leaveRequests;
  final bool leaveRequestsLoading;
  final String? leaveRequestsError;

  final List<PermissionRequest> permissionRequests;
  final bool permissionRequestsLoading;
  final String? permissionRequestsError;

  final List<RegularizationRequest> regularizationRequests;
  final bool regularizationRequestsLoading;
  final String? regularizationRequestsError;

  const RequestState({
    this.filter,
    this.applying = false,
    this.cancelling = false,
    this.error,
    this.leaveBalance,
    this.permissionBalance,
    this.permissionBalanceLoading = false,
    this.permissionBalanceError,
    this.applyingPermission = false,
    this.applyingRegularization = false,
    this.leaveRequests = const [],
    this.leaveRequestsLoading = false,
    this.leaveRequestsError,
    this.permissionRequests = const [],
    this.permissionRequestsLoading = false,
    this.permissionRequestsError,
    this.regularizationRequests = const [],
    this.regularizationRequestsLoading = false,
    this.regularizationRequestsError,
  });

  factory RequestState.initial() => const RequestState();

  bool get isLoading =>
      leaveRequestsLoading ||
      permissionRequestsLoading ||
      regularizationRequestsLoading;

  String? get firstListError =>
      leaveRequestsError ?? permissionRequestsError ?? regularizationRequestsError;

  /// Nullable fields use a sentinel so you can pass `null` to clear them.
  RequestState copyWith({
    RequestMonthFilter? filter,
    bool? applying,
    bool? cancelling,
    Object? error = _unset,
    LeaveBalance? leaveBalance,
    PermissionBalance? permissionBalance,
    bool? permissionBalanceLoading,
    Object? permissionBalanceError = _unset,
    bool? applyingPermission,
    bool? applyingRegularization,
    List<LeaveRequest>? leaveRequests,
    bool? leaveRequestsLoading,
    Object? leaveRequestsError = _unset,
    List<PermissionRequest>? permissionRequests,
    bool? permissionRequestsLoading,
    Object? permissionRequestsError = _unset,
    List<RegularizationRequest>? regularizationRequests,
    bool? regularizationRequestsLoading,
    Object? regularizationRequestsError = _unset,
  }) {
    return RequestState(
      filter: filter ?? this.filter,
      applying: applying ?? this.applying,
      cancelling: cancelling ?? this.cancelling,
      error: identical(error, _unset) ? this.error : error as String?,
      leaveBalance: leaveBalance ?? this.leaveBalance,
      permissionBalance: permissionBalance ?? this.permissionBalance,
      permissionBalanceLoading:
          permissionBalanceLoading ?? this.permissionBalanceLoading,
      permissionBalanceError: identical(permissionBalanceError, _unset)
          ? this.permissionBalanceError
          : permissionBalanceError as String?,
      applyingPermission: applyingPermission ?? this.applyingPermission,
      applyingRegularization:
          applyingRegularization ?? this.applyingRegularization,
      leaveRequests: leaveRequests ?? this.leaveRequests,
      leaveRequestsLoading: leaveRequestsLoading ?? this.leaveRequestsLoading,
      leaveRequestsError: identical(leaveRequestsError, _unset)
          ? this.leaveRequestsError
          : leaveRequestsError as String?,
      permissionRequests: permissionRequests ?? this.permissionRequests,
      permissionRequestsLoading:
          permissionRequestsLoading ?? this.permissionRequestsLoading,
      permissionRequestsError: identical(permissionRequestsError, _unset)
          ? this.permissionRequestsError
          : permissionRequestsError as String?,
      regularizationRequests:
          regularizationRequests ?? this.regularizationRequests,
      regularizationRequestsLoading:
          regularizationRequestsLoading ?? this.regularizationRequestsLoading,
      regularizationRequestsError: identical(regularizationRequestsError, _unset)
          ? this.regularizationRequestsError
          : regularizationRequestsError as String?,
    );
  }
}