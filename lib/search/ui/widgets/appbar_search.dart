import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';




import '../app_search_controller.dart';


class AppBarSearch extends StatelessWidget implements PreferredSizeWidget {

  final AppSearchController appSearchController;
  const AppBarSearch(this.appSearchController, {super.key});
  
  @override
  Size get preferredSize => AppTheme.appBarHeight;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TextField(
        maxLines: 1,
        onChanged: (param) => appSearchController.setSearchParam(param.trim()),
        decoration: InputDecoration(
          suffixIcon: const Icon(CupertinoIcons.search),
          contentPadding: const EdgeInsets.all(10),
          hintText: (AppTranslationConstants.search+appSearchController.searchType.name.capitalize).tr,
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
