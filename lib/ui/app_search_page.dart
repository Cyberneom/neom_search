import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/utils/enums/search_type.dart';

import '../utils/constants/search_constants.dart';
import 'app_search_controller.dart';
import 'widgets/appbar_search.dart';
import 'widgets/search_widgets.dart';

class AppSearchPage extends StatelessWidget {

  const AppSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<AppSearchController>(
      id: AppPageIdConstants.search,
      init: AppSearchController(),
      builder: (controller) => Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBarSearch(controller)
      ),
      backgroundColor: AppFlavour.getBackgroundColor(),
      body: Obx(() => Container(
        decoration: AppTheme.appBoxDecoration,
        child: controller.isLoading ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
          slivers: [
            if(controller.sortedProfileLocation.value.isNotEmpty)
              _buildSliverSectionHeader(context, AppTranslationConstants.nearProfiles.tr),
            if(controller.sortedProfileLocation.value.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final profile = controller.sortedProfileLocation.value.values.elementAt(index);
                  return buildMateTile(profile, context);
                },
                childCount: controller.getChildTypeCount(controller.sortedProfileLocation.value.length, SearchType.profiles)
              ),
            ),
            if(controller.sortedProfileLocation.value.length > SearchConstants.itemsQty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => controller.showMoreResults(SearchType.profiles),
                    child: Text("${AppTranslationConstants.showMore.tr}"
                        " (${controller.sortedProfileLocation.value.length - SearchConstants.itemsQty
                        - ((controller.moreResultsType.value == SearchType.profiles) ? controller.moreResultsQty.value : 0)
                    })",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            if(controller.filteredReleaseItems.isNotEmpty)
              _buildSliverSectionHeader(context, AppTranslationConstants.releases.tr),
            if(controller.filteredReleaseItems.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                      (context, index) {
                  final item = controller.filteredReleaseItems.values.elementAt(index);
                  return buildReleaseItemTile(context, item);
                  },
                  childCount: controller.getChildTypeCount(controller.filteredReleaseItems.length, SearchType.releaseItems)
              ),
            ),
            if(controller.filteredReleaseItems.value.length > SearchConstants.itemsQty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => controller.showMoreResults(SearchType.releaseItems),
                    child: Text("${AppTranslationConstants.showMore.tr}"
                        " (${controller.filteredReleaseItems.value.length - SearchConstants.itemsQty -
                        ((controller.moreResultsType.value == SearchType.releaseItems) ? controller.moreResultsQty.value : 0)
                      })",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            // Sección de Media
            if(controller.filteredMediaItems.isNotEmpty)
              _buildSliverSectionHeader(context, AppTranslationConstants.audioLibrary.tr),
            if(controller.filteredMediaItems.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item = controller.filteredMediaItems.values.elementAt(index);
                  return buildMediaItemTile(context, item); // Tu widget existente
                },
                childCount: controller.getChildTypeCount(controller.filteredMediaItems.length, SearchType.mediaItems)
              ),
            ),
            if(controller.filteredMediaItems.value.length > SearchConstants.itemsQty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => controller.showMoreResults(SearchType.mediaItems),
                    child: Text("${AppTranslationConstants.showMore.tr}"
                        " (${controller.filteredMediaItems.value.length - SearchConstants.itemsQty -
                      ((controller.moreResultsType.value == SearchType.mediaItems) ? controller.moreResultsQty.value : 0)
                    })",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            // Espacio final para que no quede pegado abajo
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        )
        ///DEPRECATED
        ///   : ListView(
        /// children: buildCombinedSearchList(controller, context)
        )
      ),)
    );
  }

  // Helper simple para títulos de sección (Opcional)
  Widget _buildSliverSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ),
    );
  }

  ///DEPRECATED
  // List<Widget> buildCombinedSearchList(AppSearchController controller, BuildContext context) {
  //   List<Widget> combined = [];
  //   combined.addAll(buildMateTiles(controller.sortedProfileLocation.value.values.toList(), context));
  //   combined.addAll(buildReleaseTiles(controller, context));
  //   combined.addAll(buildMediaTiles(controller, context));
  //   return combined;
  // }

}
