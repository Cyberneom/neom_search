import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:sint/sint.dart';

import '../../utils/constants/search_translation_constants.dart';
import 'item_search_controller.dart';

class AppBarItemSearch extends StatelessWidget implements PreferredSizeWidget {

  final ItemSearchController itemSearchController;
  const AppBarItemSearch(this.itemSearchController, {super.key});
  
  @override
  Size get preferredSize => AppTheme.appBarHeight;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TextField(
        controller: itemSearchController.searchParamController,
        maxLines: 1,
        onChanged: (param) async => {await itemSearchController.setSearchParam(param.trim())},
        decoration: InputDecoration(
          suffixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.all(10),
          hintText: SearchTranslationConstants.searchInApp.tr,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
        ),
      ),
      backgroundColor: AppColor.appBar,
      elevation: 5,
    );
  }

}
