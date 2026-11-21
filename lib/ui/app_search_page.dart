import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/web_content_wrapper.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/utils/enums/search_type.dart';
import 'package:sint/sint.dart';

import 'app_search_controller.dart';
import 'web/search_web_page.dart';
import 'widgets/appbar_search.dart';
import 'widgets/search_widgets.dart';

class AppSearchPage extends StatelessWidget {

  const AppSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<AppSearchController>(
      id: AppPageIdConstants.search,
      init: Sint.isRegistered<AppSearchController>() ? Sint.find<AppSearchController>() : AppSearchController(),
      autoRemove: false,
      builder: (controller) {
        if (MediaQuery.sizeOf(context).width > 900) {
          return SearchWebPage(controller: controller);
        }
        return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBarSearch(controller)
      ),
      backgroundColor: AppFlavour.getBackgroundColor(),
      body: WebContentWrapper(
        maxWidth: 750,
        padding: EdgeInsets.zero,
        child: Obx(() {
          final activeFilter = controller.selectedFilter.value;
          final showProfiles = (activeFilter == SearchType.any || activeFilter == SearchType.profiles)
              && controller.sortedProfileLocation.value.isNotEmpty;
          final showCollectives = (activeFilter == SearchType.any || activeFilter == SearchType.collectives)
              && controller.filteredCollectives.isNotEmpty;
          final showReleases = (activeFilter == SearchType.any || activeFilter == SearchType.releaseItems)
              && controller.filteredReleaseItems.isNotEmpty;
          final showMedia = (activeFilter == SearchType.any || activeFilter == SearchType.mediaItems)
              && controller.filteredMediaItems.isNotEmpty;

          final totalProfiles = controller.sortedProfileLocation.value.length;
          final shownProfiles = controller.getChildTypeCount(totalProfiles, SearchType.profiles);
          final remainingProfiles = totalProfiles - shownProfiles;

          final totalCollectives = controller.filteredCollectives.length;
          final shownCollectives = controller.getChildTypeCount(totalCollectives, SearchType.collectives);
          final remainingCollectives = totalCollectives - shownCollectives;

          final totalReleases = controller.filteredReleaseItems.length;
          final shownReleases = controller.getChildTypeCount(totalReleases, SearchType.releaseItems);
          final remainingReleases = totalReleases - shownReleases;

          final totalMedia = controller.filteredMediaItems.length;
          final shownMedia = controller.getChildTypeCount(totalMedia, SearchType.mediaItems);
          final remainingMedia = totalMedia - shownMedia;

          final showBandsChip = AppFlavour.showBands() || totalCollectives > 0;

          return Container(
        decoration: AppTheme.appBoxDecoration,
        child: controller.isLoading ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    _buildFilterChip(
                      label: AppTranslationConstants.all.tr,
                      selected: activeFilter == SearchType.any,
                      onSelected: () => controller.setFilter(SearchType.any),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: '${AppTranslationConstants.profiles.tr}${totalProfiles > 0 ? ' ($totalProfiles)' : ''}',
                      selected: activeFilter == SearchType.profiles,
                      onSelected: () => controller.setFilter(SearchType.profiles),
                    ),
                    if (showBandsChip) ...[
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: '${AppTranslationConstants.collectives.tr}${totalCollectives > 0 ? ' ($totalCollectives)' : ''}',
                        selected: activeFilter == SearchType.collectives,
                        onSelected: () => controller.setFilter(SearchType.collectives),
                      ),
                    ],
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: '${AppTranslationConstants.releases.tr}${totalReleases > 0 ? ' ($totalReleases)' : ''}',
                      selected: activeFilter == SearchType.releaseItems,
                      onSelected: () => controller.setFilter(SearchType.releaseItems),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: '${AppTranslationConstants.audioLibrary.tr}${totalMedia > 0 ? ' ($totalMedia)' : ''}',
                      selected: activeFilter == SearchType.mediaItems,
                      onSelected: () => controller.setFilter(SearchType.mediaItems),
                    ),
                  ],
                ),
              ),
            ),
            if (!showProfiles && !showCollectives && !showReleases && !showMedia)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    AppTranslationConstants.noResults.tr,
                    style: TextStyle(color: AppColor.textMuted, fontSize: 15),
                  ),
                ),
              ),
            if(showProfiles)
              _buildSliverSectionHeader(context,
                controller.hasUserPosition
                    ? AppTranslationConstants.nearProfiles.tr
                    : AppTranslationConstants.profiles.tr,
              ),
            if(showProfiles)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final profile = controller.sortedProfileLocation.value.values.elementAt(index);
                  return buildMateTile(profile, context);
                },
                childCount: shownProfiles
              ),
            ),
            if(showProfiles && remainingProfiles > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => controller.showMoreResults(SearchType.profiles),
                    child: Text("${AppTranslationConstants.showMore.tr} ($remainingProfiles)",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            if(showCollectives)
              _buildSliverSectionHeader(context, AppTranslationConstants.collectives.tr),
            if(showCollectives)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final collective = controller.filteredCollectives.values.elementAt(index);
                    return buildCollectiveTile(context, collective);
                  },
                  childCount: shownCollectives,
                ),
              ),
            if(showCollectives && remainingCollectives > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => controller.showMoreResults(SearchType.collectives),
                    child: Text("${AppTranslationConstants.showMore.tr} ($remainingCollectives)",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            if(showReleases)
              _buildSliverSectionHeader(context, AppTranslationConstants.releases.tr),
            if(showReleases)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                      (context, index) {
                  final item = controller.filteredReleaseItems.values.elementAt(index);
                  return buildReleaseItemTile(context, item);
                  },
                  childCount: shownReleases
              ),
            ),
            if(showReleases && remainingReleases > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => controller.showMoreResults(SearchType.releaseItems),
                    child: Text("${AppTranslationConstants.showMore.tr} ($remainingReleases)",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            // Sección de Media
            if(showMedia)
              _buildSliverSectionHeader(context, AppTranslationConstants.audioLibrary.tr),
            if(showMedia)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item = controller.filteredMediaItems.values.elementAt(index);
                  return buildMediaItemTile(context, item); // Tu widget existente
                },
                childCount: shownMedia
              ),
            ),
            if(showMedia && remainingMedia > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => controller.showMoreResults(SearchType.mediaItems),
                    child: Text("${AppTranslationConstants.showMore.tr} ($remainingMedia)",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            // Espacio final para que no quede pegado abajo
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        )
        );
      }),),);},
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: selected,
      selectedColor: AppColor.bondiBlue75,
      backgroundColor: AppColor.surfaceCard,
      side: BorderSide(color: selected ? AppColor.bondiBlue : AppColor.borderSubtle),
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onSelected(),
    );
  }

  // Helper simple para títulos de sección (Opcional)
  Widget _buildSliverSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ),
    );
  }

}
