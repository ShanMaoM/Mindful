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
import 'package:mindful/config/hero_tags.dart';
import 'package:mindful/core/database/adapters/time_of_day_adapter.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_date_time.dart';
import 'package:mindful/core/extensions/ext_duration.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/providers/bedtime/sleep_sessions_provider.dart';
import 'package:mindful/ui/common/rounded_container.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:mindful/ui/common/time_card.dart';

class SleepLogSheet extends ConsumerStatefulWidget {
  const SleepLogSheet({super.key});

  @override
  ConsumerState<SleepLogSheet> createState() => _SleepLogSheetState();
}

class _SleepLogSheetState extends ConsumerState<SleepLogSheet> {
  late DateTime _sleepAt;
  late DateTime _wakeAt;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _wakeAt = now;
    _sleepAt = now.subtract(const Duration(hours: 8));
  }

  TimeOfDayAdapter get _sleepTime => TimeOfDayAdapter.fromDateTime(_sleepAt);
  TimeOfDayAdapter get _wakeTime => TimeOfDayAdapter.fromDateTime(_wakeAt);

  Duration get _sleepDuration => _wakeAt.difference(_sleepAt);

  Future<void> _pickSleepDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sleepAt.dateOnly,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      helpText: context.locale.sleep_entry_date_picker_title,
    );

    if (picked != null) {
      setState(() {
        _sleepAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _sleepAt.hour,
          _sleepAt.minute,
        );
        if (!_wakeAt.isAfter(_sleepAt)) {
          _wakeAt = _sleepAt.add(const Duration(hours: 7));
        }
      });
    }
  }

  Future<void> _pickWakeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _wakeAt.dateOnly,
      firstDate: _sleepAt.dateOnly,
      lastDate: DateTime.now(),
      helpText: context.locale.sleep_entry_date_picker_title,
    );

    if (picked != null) {
      setState(() {
        _wakeAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _wakeAt.hour,
          _wakeAt.minute,
        );
        if (!_wakeAt.isAfter(_sleepAt)) {
          _wakeAt = _sleepAt.add(const Duration(hours: 7));
        }
      });
    }
  }

  void _setSleepTime(TimeOfDayAdapter time) {
    setState(() {
      _sleepAt = DateTime(
        _sleepAt.year,
        _sleepAt.month,
        _sleepAt.day,
        time.hour,
        time.minute,
      );
      if (!_wakeAt.isAfter(_sleepAt)) {
        _wakeAt = _sleepAt.add(const Duration(hours: 7));
      }
    });
  }

  void _setWakeTime(TimeOfDayAdapter time) {
    setState(() {
      _wakeAt = DateTime(
        _wakeAt.year,
        _wakeAt.month,
        _wakeAt.day,
        time.hour,
        time.minute,
      );
      if (!_wakeAt.isAfter(_sleepAt)) {
        _wakeAt = _sleepAt.add(const Duration(hours: 7));
      }
    });
  }

  Future<void> _save() async {
    if (_sleepDuration.inMinutes < 30) {
      context
          .showSnackAlert(context.locale.sleep_entry_short_duration_snack_alert);
      return;
    }

    await ref.read(sleepSessionsProvider.notifier).addSession(
          sleepAt: _sleepAt,
          wakeAt: _wakeAt,
        );

    if (!mounted) return;
    Navigator.of(context).pop();
    context.showSnackAlert(context.locale.sleep_entry_saved_snack_alert);
  }

  @override
  Widget build(BuildContext context) {
    final durationText = _sleepDuration.toTimeFull(
      context,
      replaceCommaWithAnd: true,
    );

    return SliverList(
      delegate: SliverChildListDelegate(
        [
          StyledText(
            context.locale.sleep_log_add_button_subtitle,
            isSubtitle: true,
          ),
          16.vBox,
          RoundedContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StyledText(
                  context.locale.sleep_entry_sleep_label,
                  fontWeight: FontWeight.w600,
                ),
                12.vBox,
                RoundedContainer(
                  onPressed: _pickSleepDate,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StyledText(
                        context.locale.sleep_entry_date_label,
                        isSubtitle: true,
                      ),
                      4.vBox,
                      StyledText(
                        _sleepAt.dateString(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                12.vBox,
                TimeCard(
                  label: context.locale.sleep_entry_time_label,
                  heroTag: HeroTags.sleepStartTimePickerTag,
                  initialTime: _sleepTime,
                  onChange: _setSleepTime,
                ),
              ],
            ),
          ),
          16.vBox,
          RoundedContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StyledText(
                  context.locale.sleep_entry_wake_label,
                  fontWeight: FontWeight.w600,
                ),
                12.vBox,
                RoundedContainer(
                  onPressed: _pickWakeDate,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StyledText(
                        context.locale.sleep_entry_date_label,
                        isSubtitle: true,
                      ),
                      4.vBox,
                      StyledText(
                        _wakeAt.dateString(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                12.vBox,
                TimeCard(
                  label: context.locale.sleep_entry_time_label,
                  heroTag: HeroTags.sleepEndTimePickerTag,
                  initialTime: _wakeTime,
                  onChange: _setWakeTime,
                ),
              ],
            ),
          ),
          16.vBox,
          RoundedContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StyledText(
                  context.locale.sleep_entry_duration_title,
                  isSubtitle: true,
                ),
                4.vBox,
                StyledText(
                  durationText,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
          24.vBox,
          FilledButton(
            onPressed: _save,
            child: Text(context.locale.sleep_entry_save_button),
          ),
          24.vBox,
        ],
      ),
    );
  }
}
