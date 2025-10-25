import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful/core/services/sleep_log_service.dart';
import 'package:mindful/core/utils/date_time_utils.dart';
import 'package:mindful/models/sleep_entry_model.dart';
import 'package:mindful/providers/bedtime/sleep_sessions_provider.dart';

class InMemorySleepLogDataSource implements SleepLogDataSource {
  InMemorySleepLogDataSource();

  final List<SleepEntry> _entries = [];
  int _nextId = 1;

  void seed(List<SleepEntry> entries) {
    _entries
      ..clear()
      ..addAll(entries);

    if (_entries.isNotEmpty) {
      _nextId =
          _entries.map((entry) => entry.id).reduce((a, b) => a > b ? a : b) + 1;
    } else {
      _nextId = 1;
    }
  }

  @override
  Future<void> deleteSession(int id) async {
    _entries.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<List<SleepEntry>> fetchRecentSessions({int limit = 60}) async {
    final sorted = [..._entries]
      ..sort((a, b) => b.sleepAt.compareTo(a.sleepAt));
    return sorted.take(limit).toList(growable: false);
  }

  @override
  Future<int> insertSession({
    required DateTime sleepAt,
    required DateTime wakeAt,
    required int durationMinutes,
  }) async {
    final id = _nextId++;
    _entries.add(
      SleepEntry(
        id: id,
        sleepAt: sleepAt,
        wakeAt: wakeAt,
        durationMinutes: durationMinutes,
      ),
    );
    return id;
  }
}

void main() {
  group('sleepSessionsProvider', () {
    late ProviderContainer container;
    late InMemorySleepLogDataSource dataSource;

    setUp(() {
      dataSource = InMemorySleepLogDataSource();
      container = ProviderContainer(
        overrides: [
          sleepLogDataSourceProvider.overrideWithValue(dataSource),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loads sleep entries sorted by most recent sleep time', () async {
      final now = DateTime.now();
      final yesterdayLate =
          now.subtract(const Duration(days: 1)).add(const Duration(hours: 1));
      dataSource.seed([
        SleepEntry(
          id: 1,
          sleepAt: now.subtract(const Duration(days: 2)),
          wakeAt:
              now.subtract(const Duration(days: 2)).add(const Duration(hours: 7)),
          durationMinutes: 420,
        ),
        SleepEntry(
          id: 2,
          sleepAt: yesterdayLate,
          wakeAt: yesterdayLate.add(const Duration(hours: 7)),
          durationMinutes: 410,
        ),
        SleepEntry(
          id: 3,
          sleepAt: now,
          wakeAt: now.add(const Duration(hours: 7)),
          durationMinutes: 415,
        ),
      ]);

      final sessions = await container.read(sleepSessionsProvider.future);

      expect(sessions, hasLength(3));
      expect(sessions.first.id, 3);
      expect(sessions[1].id, 2);
      expect(sessions.last.id, 1);
    });

    test('caps the in-memory list to the latest 60 sessions', () async {
      final start = DateTime.now();
      dataSource.seed([
        for (var i = 0; i < 65; i++)
          SleepEntry(
            id: i + 1,
            sleepAt: start.subtract(Duration(days: i)),
            wakeAt: start
                .subtract(Duration(days: i))
                .add(const Duration(hours: 7)),
            durationMinutes: 420,
          ),
      ]);

      final sessions = await container.read(sleepSessionsProvider.future);

      expect(sessions, hasLength(60));
      expect(sessions.first.id, 65);
      expect(sessions.last.id, 6);
    });

    test('adds a new session and keeps entries ordered', () async {
      final now = DateTime.now();
      dataSource.seed([
        SleepEntry(
          id: 1,
          sleepAt: now.subtract(const Duration(days: 1)),
          wakeAt:
              now.subtract(const Duration(days: 1)).add(const Duration(hours: 7)),
          durationMinutes: 410,
        ),
      ]);

      await container.read(sleepSessionsProvider.future);
      final notifier = container.read(sleepSessionsProvider.notifier);

      final sleepAt = now.add(const Duration(hours: 1));
      final wakeAt = sleepAt.add(const Duration(hours: 8));
      await notifier.addSession(sleepAt: sleepAt, wakeAt: wakeAt);

      final sessions = container.read(sleepSessionsProvider).value!;
      expect(sessions.first.sleepAt, sleepAt);
      expect(sessions.first.durationMinutes, 480);
      expect(sessions, hasLength(2));
    });

    test('removes a session by id', () async {
      final now = DateTime.now();
      dataSource.seed([
        SleepEntry(
          id: 1,
          sleepAt: now.subtract(const Duration(days: 1)),
          wakeAt:
              now.subtract(const Duration(days: 1)).add(const Duration(hours: 7)),
          durationMinutes: 420,
        ),
        SleepEntry(
          id: 2,
          sleepAt: now,
          wakeAt: now.add(const Duration(hours: 7)),
          durationMinutes: 420,
        ),
      ]);

      await container.read(sleepSessionsProvider.future);
      final notifier = container.read(sleepSessionsProvider.notifier);

      await notifier.removeSession(1);

      final sessions = container.read(sleepSessionsProvider).value!;
      expect(sessions, hasLength(1));
      expect(sessions.first.id, 2);
    });

    test('computes weekly summary with average duration', () async {
      final today = dateToday;
      dataSource.seed([
        SleepEntry(
          id: 1,
          sleepAt:
              today.subtract(const Duration(days: 1)).add(const Duration(hours: 22)),
          wakeAt:
              today.subtract(const Duration(days: 1)).add(const Duration(hours: 30)),
          durationMinutes: 480,
        ),
        SleepEntry(
          id: 2,
          sleepAt:
              today.subtract(const Duration(days: 3)).add(const Duration(hours: 23)),
          wakeAt:
              today.subtract(const Duration(days: 3)).add(const Duration(hours: 31)),
          durationMinutes: 480,
        ),
      ]);

      await container.read(sleepSessionsProvider.future);

      final summary = container.read(weeklySleepSummaryProvider);
      expect(summary.weeklyDurations[today.subtract(const Duration(days: 1))],
          const Duration(hours: 8));
      expect(summary.weeklyDurations[today.subtract(const Duration(days: 3))],
          const Duration(hours: 8));
      expect(summary.averageDuration, const Duration(hours: 8));
    });
  });
}
