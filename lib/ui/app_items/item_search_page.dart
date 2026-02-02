import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/external_item.dart';

import '../widgets/search_widgets.dart';
import 'appbar_item_search.dart';
import 'item_search_controller.dart';

class ItemSearchPage extends StatelessWidget {
  const ItemSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<ItemSearchController>(
        id: AppPageIdConstants.mediaItemSearch,
        init: ItemSearchController(),
        builder: (controller) => Scaffold(
          appBar: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: AppBarItemSearch(controller)),
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: controller.isLoading.value ? const Center(child: CircularProgressIndicator())
            : Obx(()=> ListView.builder(
              padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
              itemCount: controller.foundItems.length,
              itemBuilder: (context, index) {
                dynamic foundItem = controller.foundItems.values.elementAt(index);
                Widget tile = const SizedBox.shrink();
                if(foundItem is AppReleaseItem) {
                  tile = buildReleaseItemTile(context, foundItem);
                } else if(foundItem is AppMediaItem) {
                  tile = buildMediaItemTile(context, foundItem);
                } else if(foundItem is ExternalItem) {
                  tile = buildExternalItemTile(context, foundItem);
                }
                return tile;
              },
            )),
          ),
        )
    );
  }
}
