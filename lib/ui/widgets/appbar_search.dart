import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';

import '../app_search_controller.dart';

class AppBarSearch extends StatelessWidget implements PreferredSizeWidget {

  final AppSearchController appSearchController;
  const AppBarSearch(this.appSearchController, {super.key});
  
  @override
  Size get preferredSize => AppTheme.appBarHeight;

  @override
  Widget build(BuildContext context) {
    String type = appSearchController.searchType.name;
    String capitalizedType = type.substring(0, 1).toUpperCase() + type.substring(1);

    return AppBar(
      title: TextField(
        maxLines: 1,
        onChanged: (param) => appSearchController.setSearchParam(param.trim()),
        decoration: InputDecoration(
          suffixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.all(10),
          hintText: (AppTranslationConstants.search+capitalizedType).tr,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(12.0),
            ),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
        ),
      ),
      backgroundColor: AppColor.appBar,
    );
  }

}
