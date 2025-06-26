import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';

import 'app_search_controller.dart';
import 'widgets/appbar_search.dart';
import 'widgets/search_widgets.dart';

class AppSearchPage extends StatelessWidget {

  const AppSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppSearchController>(
      id: AppPageIdConstants.search,
      init: AppSearchController(),
      builder: (_) => Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBarSearch(_)
      ),
      backgroundColor: AppColor.main50,
      body: Obx(() => Container(
        decoration: AppTheme.appBoxDecoration,
        child: _.isLoading.value ? const Center(child: CircularProgressIndicator())
            : ListView(
          children: buildCombinedSearchList(_, context)
        )
      ),)
    ),
    );
  }

  List<Widget> buildCombinedSearchList(AppSearchController controller, BuildContext context) {
    List<Widget> combined = [];
    combined.addAll(buildMateTiles(controller.sortedProfileLocation.value.values.toList(), context));
    combined.addAll(buildReleaseTiles(controller, context));
    combined.addAll(buildMediaTiles(controller, context));
    return combined;
  }

}
