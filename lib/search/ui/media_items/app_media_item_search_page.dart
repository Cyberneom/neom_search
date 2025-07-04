import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/core/domain/model/app_media_item.dart';




import '../widgets/search_widgets.dart';
import 'app_media_item_search_controller.dart';
import 'appbar_item_search.dart';

class AppMediaItemSearchPage extends StatelessWidget {
  const AppMediaItemSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppMediaItemSearchController>(
        id: AppPageIdConstants.mediaItemSearch,
        init: AppMediaItemSearchController(),
        builder: (_) => Scaffold(
          appBar: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: AppBarItemSearch(_)),
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: _.isLoading.value ? const Center(child: CircularProgressIndicator())
            : Obx(()=> ListView.builder(
              padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
              itemCount: _.appMediaItems.length,
              itemBuilder: (context, index) {
                AppMediaItem appMediaItem = _.appMediaItems.values.elementAt(index);
                return buildMediaItemTile(context, appMediaItem, query: _.searchParam.value, itemlist: _.itemlist);
              },
            )),
          ),
        )
    );
  }
}
