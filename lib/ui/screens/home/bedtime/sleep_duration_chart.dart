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
import 'package:mindful/core/enums/usage_type.dart';
import 'package:mindful/models/usage_model.dart';
import 'package:mindful/ui/common/default_bar_chart.dart';

class SleepDurationChart extends StatelessWidget {
  const SleepDurationChart({
    super.key,
    required this.durations,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final Map<DateTime, Duration> durations;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final mappedUsage = durations.map(
      (key, value) => MapEntry(
        key,
        UsageModel(screenTime: value.inSeconds),
      ),
    );

    return DefaultBarChart(
      usageType: UsageType.screenUsage,
      selectedDay: selectedDay,
      data: mappedUsage,
      onDayBarTap: onDaySelected,
    );
  }
}
