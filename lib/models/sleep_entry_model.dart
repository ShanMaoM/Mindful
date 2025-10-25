/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/foundation.dart';

@immutable
class SleepEntry {
  final int id;
  final DateTime sleepAt;
  final DateTime wakeAt;
  final int durationMinutes;

  const SleepEntry({
    required this.id,
    required this.sleepAt,
    required this.wakeAt,
    required this.durationMinutes,
  });

  SleepEntry copyWith({
    int? id,
    DateTime? sleepAt,
    DateTime? wakeAt,
    int? durationMinutes,
  }) {
    return SleepEntry(
      id: id ?? this.id,
      sleepAt: sleepAt ?? this.sleepAt,
      wakeAt: wakeAt ?? this.wakeAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  static SleepEntry fromMap(Map<String, Object?> map) {
    return SleepEntry(
      id: map['id'] as int,
      sleepAt: DateTime.fromMillisecondsSinceEpoch(map['sleep_at'] as int),
      wakeAt: DateTime.fromMillisecondsSinceEpoch(map['wake_at'] as int),
      durationMinutes: map['duration_minutes'] as int,
    );
  }
}
