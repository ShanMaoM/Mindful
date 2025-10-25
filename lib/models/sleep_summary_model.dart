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
class SleepSummary {
  final Map<DateTime, Duration> weeklyDurations;
  final Duration averageDuration;
  final bool isLoading;

  const SleepSummary({
    required this.weeklyDurations,
    this.averageDuration = Duration.zero,
    this.isLoading = false,
  });

  const SleepSummary.empty({this.isLoading = false})
      : weeklyDurations = const {},
        averageDuration = Duration.zero;
}
