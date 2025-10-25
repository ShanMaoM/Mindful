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
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/extensions/ext_widget.dart';
import 'package:mindful/providers/restrictions/bedtime_provider.dart';
import 'package:mindful/providers/system/parental_controls_provider.dart';
import 'package:mindful/ui/common/default_list_tile.dart';
import 'package:mindful/ui/common/content_section_header.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:mindful/ui/common/sliver_tabs_bottom_padding.dart';
import 'package:mindful/ui/screens/home/bedtime/bedtime_schedule_card.dart';
import 'package:mindful/ui/screens/home/bedtime/bedtime_quick_actions.dart';
import 'package:mindful/ui/screens/home/bedtime/sleep_log_section.dart';

class TabBedtime extends ConsumerWidget {
  const TabBedtime({super.key});

  void _setScheduleStatus(
    WidgetRef ref,
    BuildContext context,
    bool shouldStart,
  ) async {
    final state = ref.read(bedtimeScheduleProvider);

    // If none of the days is selected
    if (!state.scheduleDays.contains(true)) {
      context.showSnackAlert(
        context.locale.bedtime_no_days_selected_snack_alert,
      );
      return;
    }

    // If the total duration is less than 30 minutes
    if (state.scheduleDurationInMins < 30) {
      context.showSnackAlert(
        context.locale.bedtime_minimum_duration_snack_alert,
      );
      return;
    }

    // If no distracting apps selected
    if (shouldStart && state.distractingApps.isEmpty) {
      context.showSnackAlert(
        context.locale.minimum_distracting_apps_snack_alert,
      );
      return;
    }

    /// If restricted by invincible mode
    final isInvincibleRestricted = ref.read(parentalControlsProvider
            .select((v) => v.isInvincibleModeOn && v.includeBedtimeSchedule)) &&
        !ref.read(parentalControlsProvider.notifier).isBetweenInvincibleWindow;

    /// If time now is between bedtime schedule
    final isBetweenSchedule =
        ref.read(bedtimeScheduleProvider.notifier).isBetweenSchedule;

    if (isInvincibleRestricted && state.isScheduleOn && isBetweenSchedule) {
      context.showSnackAlert(context.locale.invincible_mode_snack_alert);
      return;
    }

    ref
        .read(bedtimeScheduleProvider.notifier)
        .switchBedtimeSchedule(shouldStart);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isScheduleOn =
        ref.watch(bedtimeScheduleProvider.select((v) => v.isScheduleOn));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        /// Information about bedtime
        StyledText(context.locale.bedtime_tab_info).sliver,

        ContentSectionHeader(title: context.locale.schedule_tile_title).sliver,

        8.vSliverBox,

        /// Card with start and end time for schedule
        /// also schedule days
        const BedtimeScheduleCard().sliver,

        /// Bedtime schedule status toggler
        DefaultListTile(
          position: ItemPosition.bottom,
          isPrimary: true,
          switchValue: isScheduleOn,
          leadingIcon: FluentIcons.sleep_20_regular,
          titleText: context.locale.schedule_tile_title,
          subtitleText: context.locale.schedule_tile_subtitle,
          onPressed: () => _setScheduleStatus(ref, context, !isScheduleOn),
        ).sliver,

        8.vSliverBox,

        /// Actions related to bedtime
        const BedtimeQuickActions(),

        const SleepLogSection(),

        const SliverTabsBottomPadding()
      ],
    );
  }
}
