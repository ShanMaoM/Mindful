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

/// Dependency injection entry point for the sleep log data source.
final sleepLogDataSourceProvider = Provider<SleepLogDataSource>(
  (ref) => SleepLogService.instance,
);

/// Provides the list of recently logged sleep entries.
final sleepSessionsProvider =
    AsyncNotifierProvider<SleepSessionsNotifier, List<SleepEntry>>(
  SleepSessionsNotifier.new,
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

class SleepSessionsNotifier extends AsyncNotifier<List<SleepEntry>> {
  static const _maxEntries = 60;

  SleepLogDataSource get _dataSource => ref.read(sleepLogDataSourceProvider);

  @override
  Future<List<SleepEntry>> build() async {
    final sessions =
        await _dataSource.fetchRecentSessions(limit: _maxEntries);
    return _sortAndLimit(sessions);
  }

  List<SleepEntry> _sortAndLimit(List<SleepEntry> sessions) {
    final sorted = [...sessions]
      ..sort((a, b) => b.sleepAt.compareTo(a.sleepAt));

    if (sorted.length > _maxEntries) {
      sorted.removeRange(_maxEntries, sorted.length);
    }

    return sorted;
  }

  Future<void> addSession({
    required DateTime sleepAt,
    required DateTime wakeAt,
  }) async {
    final durationMinutes = wakeAt.difference(sleepAt).inMinutes;
    if (durationMinutes <= 0) {
      throw ArgumentError('Wake time must be after sleep time.');
    }

    try {
      final id = await _dataSource.insertSession(
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

      final existing = state.value ?? const <SleepEntry>[];
      state = AsyncValue.data(
        _sortAndLimit([session, ...existing]),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> removeSession(int id) async {
    try {
      await _dataSource.deleteSession(id);
      final existing = state.value ?? const <SleepEntry>[];
      state = AsyncValue.data(
        existing.where((session) => session.id != id).toList(growable: false),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final sessions =
          await _dataSource.fetchRecentSessions(limit: _maxEntries);
      return _sortAndLimit(sessions);
    });
  }
}
