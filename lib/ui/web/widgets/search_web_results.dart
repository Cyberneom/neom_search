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

      final totalProfiles = controller.sortedProfileLocation.value.length;
      final shownProfiles = controller.getChildTypeCount(totalProfiles, SearchType.profiles);
      final remainingProfiles = totalProfiles - shownProfiles;

      final totalReleases = controller.filteredReleaseItems.length;
      final shownReleases = controller.getChildTypeCount(totalReleases, SearchType.releaseItems);
      final remainingReleases = totalReleases - shownReleases;

      final totalMedia = controller.filteredMediaItems.length;
      final shownMedia = controller.getChildTypeCount(totalMedia, SearchType.mediaItems);
      final remainingMedia = totalMedia - shownMedia;

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
                childCount: shownProfiles,
              ),
            ),
            if (remainingProfiles > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => controller.showMoreResults(SearchType.profiles),
                    child: Text(
                      "${AppTranslationConstants.showMore.tr} ($remainingProfiles)",
                      style: const TextStyle(color: Colors.white70),
                    ),
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
                childCount: shownReleases,
              ),
            ),
            if (remainingReleases > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => controller.showMoreResults(SearchType.releaseItems),
                    child: Text(
                      "${AppTranslationConstants.showMore.tr} ($remainingReleases)",
                      style: const TextStyle(color: Colors.white70),
                    ),
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
                childCount: shownMedia,
              ),
            ),
            if (remainingMedia > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => controller.showMoreResults(SearchType.mediaItems),
                    child: Text(
                      "${AppTranslationConstants.showMore.tr} ($remainingMedia)",
                      style: const TextStyle(color: Colors.white70),
                    ),
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
