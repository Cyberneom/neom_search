import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:sint/sint.dart';

import '../../app_search_controller.dart';

class SearchWebBar extends StatelessWidget {

  final AppSearchController controller;
  final FocusNode? focusNode;

  const SearchWebBar({super.key, required this.controller, this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: TextField(
        focusNode: focusNode,
        onChanged: (value) => controller.setSearchParam(value),
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: AppTranslationConstants.search.tr,
          hintStyle: TextStyle(color: AppColor.textMuted),
          prefixIcon: Icon(Icons.search, color: AppColor.textSecondary),
          filled: true,
          fillColor: AppColor.surfaceDim,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
