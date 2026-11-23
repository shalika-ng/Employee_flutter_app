import '../models/request_models.dart';
import 'request_actions.dart';
import 'request_state.dart';

RequestState requestReducer(RequestState state, dynamic action) {
  /* ------------------------------ fetch lists ----------------------------- */
  if (action is FetchLeaveRequestsAction) {
    return state.copyWith(
      filter: action.filter,
      leaveRequestsLoading: true,
      leaveRequestsError: null,
      leaveRequests: const [],
    );
  }
  if (action is FetchLeaveRequestsSuccess) {
    return state.copyWith(
      leaveRequestsLoading: false,
      leaveRequests: action.requests,
    );
  }
  if (action is FetchLeaveRequestsFailure) {
    return state.copyWith(
      leaveRequestsLoading: false,
      leaveRequestsError: action.error,
    );
  }

  if (action is FetchPermissionRequestsAction) {
    return state.copyWith(
      filter: action.filter,
      permissionRequestsLoading: true,
      permissionRequestsError: null,
      permissionRequests: const [],
    );
  }
  if (action is FetchPermissionRequestsSuccess) {
    return state.copyWith(
      permissionRequestsLoading: false,
      permissionRequests: action.requests,
    );
  }
  if (action is FetchPermissionRequestsFailure) {
    return state.copyWith(
      permissionRequestsLoading: false,
      permissionRequestsError: action.error,
    );
  }

  if (action is FetchRegularizationRequestsAction) {
    return state.copyWith(
      filter: action.filter,
      regularizationRequestsLoading: true,
      regularizationRequestsError: null,
      regularizationRequests: const [],
    );
  }
  if (action is FetchRegularizationRequestsSuccess) {
    return state.copyWith(
      regularizationRequestsLoading: false,
      regularizationRequests: action.requests,
    );
  }
  if (action is FetchRegularizationRequestsFailure) {
    return state.copyWith(
      regularizationRequestsLoading: false,
      regularizationRequestsError: action.error,
    );
  }

  /* --------------------------- permission balance ------------------------- */
  if (action is FetchPermissionBalanceAction) {
    return state.copyWith(
      permissionBalanceLoading: true,
      permissionBalanceError: null,
      error: null,
    );
  }
  if (action is FetchPermissionBalanceSuccess) {
    return state.copyWith(
      permissionBalanceLoading: false,
      permissionBalanceError: null,
      permissionBalance: action.balance,
    );
  }
  if (action is FetchPermissionBalanceFailure) {
    return state.copyWith(
      permissionBalanceLoading: false,
      permissionBalanceError: action.error,
      error: action.error,
    );
  }

  /* --------------------------------- apply -------------------------------- */
  if (action is SubmitStarted) {
    switch (action.kind) {
      case RequestKind.leave:
        return state.copyWith(applying: true, error: null);
      case RequestKind.permission:
        return state.copyWith(applyingPermission: true, error: null);
      case RequestKind.regularization:
        return state.copyWith(applyingRegularization: true, error: null);
    }
  }
  if (action is SubmitSucceeded) {
    switch (action.kind) {
      case RequestKind.leave:
        return state.copyWith(
          applying: false,
          leaveBalance: action.leaveBalance,
        );
      case RequestKind.permission:
        final b = state.permissionBalance;
        final r = action.permissionBalance;
        return state.copyWith(
          applyingPermission: false,
          permissionBalance: (b != null && r != null)
              ? b.copyWith(
                  usedMinutes: r.approvedMinutes,
                  pendingMinutes: r.pendingMinutes,
                  remainingMinutes: r.remainingAfterReservation,
                )
              : b,
        );
      case RequestKind.regularization:
        return state.copyWith(applyingRegularization: false);
    }
  }
  if (action is SubmitFailed) {
    switch (action.kind) {
      case RequestKind.leave:
        return state.copyWith(applying: false, error: action.error);
      case RequestKind.permission:
        return state.copyWith(applyingPermission: false, error: action.error);
      case RequestKind.regularization:
        return state.copyWith(
            applyingRegularization: false, error: action.error);
    }
  }

  /* --------------------------------- cancel ------------------------------- */
  if (action is CancelStarted) {
    return state.copyWith(cancelling: true, error: null);
  }
  if (action is CancelSucceeded) {
    return state.copyWith(cancelling: false);
  }
  if (action is CancelFailed) {
    return state.copyWith(cancelling: false, error: action.error);
  }

  if (action is ClearRequestErrorAction) {
    return state.copyWith(error: null);
  }

  return state;
}