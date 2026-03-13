import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/utils/enums/search_type.dart';
import 'package:sint/sint.dart';

import '../../app_search_controller.dart';
import '../../widgets/search_widgets.dart';

class SearchWebResults extends StatelessWidget {

  final AppSearchController controller;
  final SearchType activeFilter;

  const SearchWebResults({
    super.key,
    required this.controller,
    required this.activeFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final showProfiles = (activeFilter == SearchType.any || activeFilter == SearchType.profiles)
          && controller.sortedProfileLocation.value.isNotEmpty;
      final showReleases = (activeFilter == SearchType.any || activeFilter == SearchType.releaseItems)
          && controller.filteredReleaseItems.isNotEmpty;
      final showMedia = (activeFilter == SearchType.any || activeFilter == SearchType.mediaItems)
          && controller.filteredMediaItems.isNotEmpty;

      if (!showProfiles && !showReleases && !showMedia) {
        return Center(
          child: Text(
            AppTranslationConstants.noResults.tr,
            style: TextStyle(color: AppColor.textMuted, fontSize: 15),
          ),
        );
      }

      return CustomScrollView(
        slivers: [
          if (showProfiles) ...[
            _buildSectionHeader(
              controller.hasUserPosition
                  ? AppTranslationConstants.nearProfiles.tr
                  : AppTranslationConstants.profiles.tr,
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final profile = controller.sortedProfileLocation.value.values.elementAt(index);
                  return buildMateTile(profile, context);
                },
                childCount: controller.getChildTypeCount(
                  controller.sortedProfileLocation.value.length,
                  SearchType.profiles,
                ),
              ),
            ),
          ],
          if (showReleases) ...[
            _buildSectionHeader(AppTranslationConstants.releases.tr),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = controller.filteredReleaseItems.values.elementAt(index);
                  return buildReleaseItemTile(context, item);
                },
                childCount: controller.getChildTypeCount(
                  controller.filteredReleaseItems.length,
                  SearchType.releaseItems,
                ),
              ),
            ),
          ],
          if (showMedia) ...[
            _buildSectionHeader(AppTranslationConstants.audioLibrary.tr),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = controller.filteredMediaItems.values.elementAt(index);
                  return buildMediaItemTile(context, item);
                },
                childCount: controller.getChildTypeCount(
                  controller.filteredMediaItems.length,
                  SearchType.mediaItems,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColor.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
