/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/enums/item_position.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_date_time.dart';
import 'package:mindful/core/extensions/ext_duration.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/extensions/ext_widget.dart';
import 'package:mindful/providers/bedtime/sleep_sessions_provider.dart';
import 'package:mindful/ui/common/content_section_header.dart';
import 'package:mindful/ui/common/default_list_tile.dart';
import 'package:mindful/ui/common/rounded_container.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:mindful/ui/dialogs/modal_bottom_sheet.dart';
import 'package:mindful/ui/screens/home/bedtime/sleep_duration_chart.dart';
import 'package:mindful/ui/screens/home/bedtime/sleep_log_sheet.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SleepLogSection extends ConsumerWidget {
  const SleepLogSection({super.key});

  void _openSleepSheet(BuildContext context) {
    showDefaultBottomSheet(
      context: context,
      initialSize: 0.6,
      sliverBody: const SleepLogSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sleepSessionsProvider);
    final summary = ref.watch(weeklySleepSummaryProvider);
    final selectedDay = ref.watch(selectedSleepDayProvider);

    final chartDays = summary.weeklyDurations.keys.toList()..sort();

    if (chartDays.isNotEmpty && !chartDays.contains(selectedDay)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedSleepDayProvider.notifier).state = chartDays.last;
      });
    }

    final selectedDuration = summary.weeklyDurations[selectedDay] ?? Duration.zero;

    return MultiSliver(
      children: [
        ContentSectionHeader(title: context.locale.sleep_log_section_title)
            .sliver,
        StyledText(
          context.locale.sleep_log_section_info,
          isSubtitle: true,
        ).sliver,
        12.vSliverBox,
        if (summary.weeklyDurations.isNotEmpty)
          RoundedContainer(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StyledText(
                  context.locale.sleep_log_average_duration_label,
                  isSubtitle: true,
                ),
                4.vBox,
                StyledText(
                  summary.averageDuration.toTimeFull(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ).sliver,
        12.vSliverBox,
        if (chartDays.isNotEmpty)
          RoundedContainer(
            child: SleepDurationChart(
              durations: summary.weeklyDurations,
              selectedDay: selectedDay,
              onDaySelected: (day) =>
                  ref.read(selectedSleepDayProvider.notifier).state = day,
            ),
          ).sliver,
        if (chartDays.isNotEmpty)
          RoundedContainer(
            padding: const EdgeInsets.all(12),
            child: StyledText(
              selectedDuration > Duration.zero
                  ? context.locale.sleep_log_selected_day_label(
                      selectedDuration.toTimeFull(context,
                          replaceCommaWithAnd: true),
                      selectedDay.dateString(context),
                    )
                  : context.locale.sleep_log_selected_day_empty(
                      selectedDay.dateString(context),
                    ),
            ),
          ).sliver,
        12.vSliverBox,
        DefaultListTile(
          position: ItemPosition.top,
          leadingIcon: FluentIcons.weather_moon_20_regular,
          titleText: context.locale.sleep_log_add_button,
          subtitleText: context.locale.sleep_log_add_button_subtitle,
          onPressed: () => _openSleepSheet(context),
          isPrimary: true,
        ).sliver,
        sessionsAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return RoundedContainer(
                padding: const EdgeInsets.all(16),
                child: StyledText(
                  context.locale.sleep_log_empty_message,
                  isSubtitle: true,
                ),
              ).sliver;
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index.isOdd) {
                    return 8.vBox;
                  }

                  final session = sessions[index ~/ 2];
                  final duration =
                      Duration(minutes: session.durationMinutes).toTimeFull(
                    context,
                    replaceCommaWithAnd: true,
                  );

                  return RoundedContainer(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(FluentIcons.weather_moon_24_filled),
                        12.hBox,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StyledText(
                                session.sleepAt.dateString(context),
                                fontWeight: FontWeight.w600,
                              ),
                              4.vBox,
                              StyledText(
                                '${session.sleepAt.timeString(context)} — ${session.wakeAt.timeString(context)}',
                                isSubtitle: true,
                              ),
                              8.vBox,
                              StyledText(
                                context.locale
                                    .sleep_entry_duration_label(duration),
                                isSubtitle: true,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip:
                              context.locale.sleep_entry_remove_button_tooltip,
                          icon: const Icon(FluentIcons.delete_20_regular),
                          onPressed: () async {
                            await ref
                                .read(sleepSessionsProvider.notifier)
                                .removeSession(session.id);
                            context.showSnackAlert(context
                                .locale.sleep_entry_delete_confirm_snack);
                          },
                        ),
                      ],
                    ),
                  );
                },
                childCount: (sessions.length * 2) - 1,
              ),
            );
          },
          error: (error, _) => RoundedContainer(
            padding: const EdgeInsets.all(16),
            child: StyledText(error.toString(), isSubtitle: true),
          ).sliver,
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}
