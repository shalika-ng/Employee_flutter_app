import 'package:redux/redux.dart';

import '../../../redux/app_state.dart';
import '../models/request_models.dart';
import '../services/request_service.dart';
import 'request_actions.dart';

/// Add to your store:  middleware: [...createRequestMiddleware(RequestService())]
List<Middleware<AppState>> createRequestMiddleware(RequestService service) {
  /* ------------------------------ fetches --------------------------------- */
  void fetchLeave(Store<AppState> store, FetchLeaveRequestsAction a,
      NextDispatcher next) async {
    next(a);
    try {
      store.dispatch(
          FetchLeaveRequestsSuccess(await service.fetchLeaveRequests(a.filter)));
    } catch (e) {
      store.dispatch(FetchLeaveRequestsFailure(requestErrorMessage(e)));
    }
  }

  void fetchPermission(Store<AppState> store, FetchPermissionRequestsAction a,
      NextDispatcher next) async {
    next(a);
    try {
      store.dispatch(FetchPermissionRequestsSuccess(
          await service.fetchPermissionRequests(a.filter)));
    } catch (e) {
      store.dispatch(FetchPermissionRequestsFailure(requestErrorMessage(e)));
    }
  }

  void fetchRegularization(Store<AppState> store,
      FetchRegularizationRequestsAction a, NextDispatcher next) async {
    next(a);
    try {
      store.dispatch(FetchRegularizationRequestsSuccess(
          await service.fetchRegularizationRequests(a.filter)));
    } catch (e) {
      store.dispatch(FetchRegularizationRequestsFailure(requestErrorMessage(e)));
    }
  }

  void fetchBalance(Store<AppState> store, FetchPermissionBalanceAction a,
      NextDispatcher next) async {
    next(a);
    try {
      store.dispatch(
          FetchPermissionBalanceSuccess(await service.fetchPermissionBalance()));
    } catch (e) {
      store.dispatch(FetchPermissionBalanceFailure(requestErrorMessage(e)));
    }
  }

  /// Reload whatever month the screen is showing.
  void refresh(Store<AppState> store, {bool balance = false}) {
    final f = store.state.request.filter;
    if (f != null) {
      store.dispatch(FetchLeaveRequestsAction(f));
      store.dispatch(FetchPermissionRequestsAction(f));
      store.dispatch(FetchRegularizationRequestsAction(f));
    }
    if (balance) store.dispatch(FetchPermissionBalanceAction());
  }

  /* ------------------------------- applies -------------------------------- */
  void applyLeave(
      Store<AppState> store, ApplyLeaveAction a, NextDispatcher next) async {
    next(a);
    store.dispatch(SubmitStarted(RequestKind.leave));
    try {
      final r = await service.applyForLeave(a.payload);
      store.dispatch(SubmitSucceeded(RequestKind.leave, leaveBalance: r.balance));
      refresh(store);
      a.onDone?.call(null);
    } catch (e) {
      final msg = requestErrorMessage(e);
      store.dispatch(SubmitFailed(RequestKind.leave, msg));
      a.onDone?.call(msg);
    }
  }

  void applyPermission(Store<AppState> store, ApplyPermissionAction a,
      NextDispatcher next) async {
    next(a);
    store.dispatch(SubmitStarted(RequestKind.permission));
    try {
      final r = await service.applyForPermission(a.payload);
      store.dispatch(
          SubmitSucceeded(RequestKind.permission, permissionBalance: r.balance));
      refresh(store);
      a.onDone?.call(null);
    } catch (e) {
      final msg = requestErrorMessage(e);
      store.dispatch(SubmitFailed(RequestKind.permission, msg));
      a.onDone?.call(msg);
    }
  }

  void applyRegularization(Store<AppState> store, ApplyRegularizationAction a,
      NextDispatcher next) async {
    next(a);
    store.dispatch(SubmitStarted(RequestKind.regularization));
    try {
      await service.applyForRegularization(a.payload);
      store.dispatch(SubmitSucceeded(RequestKind.regularization));
      refresh(store);
      a.onDone?.call(null);
    } catch (e) {
      final msg = requestErrorMessage(e);
      store.dispatch(SubmitFailed(RequestKind.regularization, msg));
      a.onDone?.call(msg);
    }
  }

  /* ------------------------------- cancels -------------------------------- */
  void cancelLeave(
      Store<AppState> store, CancelLeaveAction a, NextDispatcher next) async {
    next(a);
    store.dispatch(CancelStarted());
    try {
      await service.cancelLeave(a.id);
      store.dispatch(CancelSucceeded());
      refresh(store);
      a.onDone?.call(null);
    } catch (e) {
      final msg = requestErrorMessage(e);
      store.dispatch(CancelFailed(msg));
      a.onDone?.call(msg);
    }
  }

  void cancelPermission(Store<AppState> store, CancelPermissionAction a,
      NextDispatcher next) async {
    next(a);
    store.dispatch(CancelStarted());
    try {
      await service.cancelPermission(a.id);
      store.dispatch(CancelSucceeded());
      refresh(store, balance: true);
      a.onDone?.call(null);
    } catch (e) {
      final msg = requestErrorMessage(e);
      store.dispatch(CancelFailed(msg));
      a.onDone?.call(msg);
    }
  }

  return [
    TypedMiddleware<AppState, FetchLeaveRequestsAction>(fetchLeave).call,
    TypedMiddleware<AppState, FetchPermissionRequestsAction>(fetchPermission).call,
    TypedMiddleware<AppState, FetchRegularizationRequestsAction>(
            fetchRegularization)
        .call,
    TypedMiddleware<AppState, FetchPermissionBalanceAction>(fetchBalance).call,
    TypedMiddleware<AppState, ApplyLeaveAction>(applyLeave).call,
    TypedMiddleware<AppState, ApplyPermissionAction>(applyPermission).call,
    TypedMiddleware<AppState, ApplyRegularizationAction>(applyRegularization).call,
    TypedMiddleware<AppState, CancelLeaveAction>(cancelLeave).call,
    TypedMiddleware<AppState, CancelPermissionAction>(cancelPermission).call,
  ];
}