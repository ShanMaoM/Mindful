/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/extensions/ext_date_time.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/services/sleep_log_service.dart';
import 'package:mindful/core/utils/date_time_utils.dart';
import 'package:mindful/models/sleep_entry_model.dart';
import 'package:mindful/models/sleep_summary_model.dart';

/// Provides the list of recently logged sleep entries.
final sleepSessionsProvider =
    StateNotifierProvider<SleepSessionsNotifier, AsyncValue<List<SleepEntry>>>(
  (ref) => SleepSessionsNotifier(),
);

/// Provides weekly sleep summary for the last 7 days including durations and average sleep.
final weeklySleepSummaryProvider = Provider<SleepSummary>((ref) {
  final sessionsAsync = ref.watch(sleepSessionsProvider);

  return sessionsAsync.when(
    data: (sessions) {
      final startDay = dateToday.subtract(6.days);
      final Map<DateTime, Duration> weeklyDurations = {
        for (var i = 0; i < 7; i++) startDay.add(i.days): Duration.zero,
      };

      for (final session in sessions) {
        final day = session.sleepAt.dateOnly;
        if (!day.isBefore(startDay)) {
          weeklyDurations.update(
            day,
            (value) => value + Duration(minutes: session.durationMinutes),
            ifAbsent: () => Duration(minutes: session.durationMinutes),
          );
        }
      }

      final recordedDurations =
          weeklyDurations.values.where((duration) => duration > Duration.zero);
      final totalMinutes = recordedDurations.fold<int>(
        0,
        (previousValue, element) => previousValue + element.inMinutes,
      );
      final averageMinutes = recordedDurations.isEmpty
          ? 0
          : (totalMinutes / recordedDurations.length).round();

      return SleepSummary(
        weeklyDurations: weeklyDurations,
        averageDuration: Duration(minutes: averageMinutes),
      );
    },
    error: (_, __) => SleepSummary.empty(),
    loading: () => SleepSummary.empty(isLoading: true),
  );
});

/// Holds the currently selected day for the sleep chart.
final selectedSleepDayProvider = StateProvider<DateTime>((ref) => dateToday);

class SleepSessionsNotifier
    extends StateNotifier<AsyncValue<List<SleepEntry>>> {
  SleepSessionsNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final entries = await SleepLogService.instance.fetchRecentSessions();
      state = AsyncValue.data(entries);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSession({
    required DateTime sleepAt,
    required DateTime wakeAt,
  }) async {
    final durationMinutes = wakeAt.difference(sleepAt).inMinutes;

    final id = await SleepLogService.instance.insertSession(
      sleepAt: sleepAt,
      wakeAt: wakeAt,
      durationMinutes: durationMinutes,
    );

    final session = SleepEntry(
      id: id,
      sleepAt: sleepAt,
      wakeAt: wakeAt,
      durationMinutes: durationMinutes,
    );

    state = state.whenData((value) {
      return [session, ...value]
        ..sort((a, b) => b.sleepAt.compareTo(a.sleepAt));
    });
  }

  Future<void> removeSession(int id) async {
    await SleepLogService.instance.deleteSession(id);

    state = state.whenData(
      (value) => value.where((session) => session.id != id).toList(),
    );
  }
}
