import 'package:flutter/foundation.dart';

import '../models/attendance_models.dart';

enum AttendanceLoadStatus { initial, loading, success, failure }

@immutable
class AttendanceState {
  const AttendanceState({
    this.monthStatus = AttendanceLoadStatus.initial,
    this.monthData,
    this.monthError,
    this.dayStatus = AttendanceLoadStatus.initial,
    this.selectedDate,
    this.dayData,
    this.dayError,
  });

  final AttendanceLoadStatus monthStatus;
  final AttendanceMonthData? monthData;
  final String? monthError;
  final AttendanceLoadStatus dayStatus;
  final String? selectedDate;
  final AttendanceDayData? dayData;
  final String? dayError;

  AttendanceState copyWith({
    AttendanceLoadStatus? monthStatus,
    AttendanceMonthData? monthData,
    String? monthError,
    bool clearMonthError = false,
    AttendanceLoadStatus? dayStatus,
    String? selectedDate,
    AttendanceDayData? dayData,
    String? dayError,
    bool clearDayData = false,
    bool clearDayError = false,
  }) {
    return AttendanceState(
      monthStatus: monthStatus ?? this.monthStatus,
      monthData: monthData ?? this.monthData,
      monthError: clearMonthError ? null : monthError ?? this.monthError,
      dayStatus: dayStatus ?? this.dayStatus,
      selectedDate: selectedDate ?? this.selectedDate,
      dayData: clearDayData ? null : dayData ?? this.dayData,
      dayError: clearDayError ? null : dayError ?? this.dayError,
    );
  }
}
