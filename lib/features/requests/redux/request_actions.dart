import '../models/request_models.dart';

/// Called when an apply/cancel finishes. `error == null` means success.
typedef RequestDoneCallback = void Function(String? error);

/* ------------------------------- FETCH ---------------------------------- */

class FetchLeaveRequestsAction {
  final RequestMonthFilter filter;
  FetchLeaveRequestsAction(this.filter);
}

class FetchLeaveRequestsSuccess {
  final List<LeaveRequest> requests;
  FetchLeaveRequestsSuccess(this.requests);
}

class FetchLeaveRequestsFailure {
  final String error;
  FetchLeaveRequestsFailure(this.error);
}

class FetchPermissionRequestsAction {
  final RequestMonthFilter filter;
  FetchPermissionRequestsAction(this.filter);
}

class FetchPermissionRequestsSuccess {
  final List<PermissionRequest> requests;
  FetchPermissionRequestsSuccess(this.requests);
}

class FetchPermissionRequestsFailure {
  final String error;
  FetchPermissionRequestsFailure(this.error);
}

class FetchRegularizationRequestsAction {
  final RequestMonthFilter filter;
  FetchRegularizationRequestsAction(this.filter);
}

class FetchRegularizationRequestsSuccess {
  final List<RegularizationRequest> requests;
  FetchRegularizationRequestsSuccess(this.requests);
}

class FetchRegularizationRequestsFailure {
  final String error;
  FetchRegularizationRequestsFailure(this.error);
}

class FetchPermissionBalanceAction {}

class FetchPermissionBalanceSuccess {
  final PermissionBalance balance;
  FetchPermissionBalanceSuccess(this.balance);
}

class FetchPermissionBalanceFailure {
  final String error;
  FetchPermissionBalanceFailure(this.error);
}

/* ------------------------------- APPLY ---------------------------------- */

class ApplyLeaveAction {
  final LeaveRequestPayload payload;
  final RequestDoneCallback? onDone;
  ApplyLeaveAction(this.payload, {this.onDone});
}

class ApplyPermissionAction {
  final PermissionRequestPayload payload;
  final RequestDoneCallback? onDone;
  ApplyPermissionAction(this.payload, {this.onDone});
}

class ApplyRegularizationAction {
  final RegularizationRequestPayload payload;
  final RequestDoneCallback? onDone;
  ApplyRegularizationAction(this.payload, {this.onDone});
}

class SubmitStarted {
  final RequestKind kind;
  SubmitStarted(this.kind);
}

class SubmitSucceeded {
  final RequestKind kind;
  final LeaveBalance? leaveBalance;
  final PermissionApplyBalance? permissionBalance;
  SubmitSucceeded(this.kind, {this.leaveBalance, this.permissionBalance});
}

class SubmitFailed {
  final RequestKind kind;
  final String error;
  SubmitFailed(this.kind, this.error);
}

/* ------------------------------- CANCEL --------------------------------- */

class CancelLeaveAction {
  final String id;
  final RequestDoneCallback? onDone;
  CancelLeaveAction(this.id, {this.onDone});
}

class CancelPermissionAction {
  final String id;
  final RequestDoneCallback? onDone;
  CancelPermissionAction(this.id, {this.onDone});
}

class CancelStarted {}

class CancelSucceeded {}

class CancelFailed {
  final String error;
  CancelFailed(this.error);
}

class ClearRequestErrorAction {}