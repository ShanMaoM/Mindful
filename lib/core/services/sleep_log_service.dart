/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:drift/drift.dart';
import 'package:mindful/core/services/drift_db_service.dart';
import 'package:mindful/models/sleep_entry_model.dart';

/// Contract used to persist and retrieve sleep log sessions.
abstract class SleepLogDataSource {
  Future<List<SleepEntry>> fetchRecentSessions({int limit = 60});

  Future<int> insertSession({
    required DateTime sleepAt,
    required DateTime wakeAt,
    required int durationMinutes,
  });

  Future<void> deleteSession(int id);
}

class SleepLogService implements SleepLogDataSource {
  SleepLogService._();

  static final SleepLogService instance = SleepLogService._();

  static const _tableName = 'sleep_sessions';

  Future<void> _ensureTable() async {
    await DriftDbService.instance.driftDb.customStatement('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sleep_at INTEGER NOT NULL,
        wake_at INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<List<SleepEntry>> fetchRecentSessions({int limit = 60}) async {
    await _ensureTable();
    final results = await DriftDbService.instance.driftDb.customSelect(
      'SELECT id, sleep_at, wake_at, duration_minutes FROM $_tableName ORDER BY sleep_at DESC LIMIT ?;',
      variables: [Variable.withInt(limit)],
    ).get();

    return results
        .map((row) => SleepEntry.fromMap(row.data))
        .toList(growable: false);
  }

  @override
  Future<int> insertSession({
    required DateTime sleepAt,
    required DateTime wakeAt,
    required int durationMinutes,
  }) async {
    await _ensureTable();
    return DriftDbService.instance.driftDb.customInsert(
      'INSERT INTO $_tableName (sleep_at, wake_at, duration_minutes) VALUES (?, ?, ?);',
      variables: [
        Variable.withInt(sleepAt.millisecondsSinceEpoch),
        Variable.withInt(wakeAt.millisecondsSinceEpoch),
        Variable.withInt(durationMinutes),
      ],
      updates: {_tableName},
    );
  }

  @override
  Future<void> deleteSession(int id) async {
    await _ensureTable();
    await DriftDbService.instance.driftDb.customStatement(
      'DELETE FROM $_tableName WHERE id = ?;',
      [id],
    );
  }
}
