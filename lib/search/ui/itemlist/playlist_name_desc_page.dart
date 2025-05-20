import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_hero_tag_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'app_media_item_search_controller.dart';

class PlaylistNameDescPage extends StatelessWidget {
  const PlaylistNameDescPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppMediaItemSearchController>(
      id: AppPageIdConstants.playlistNameDesc,
      builder: (_) {
         return Scaffold(
           backgroundColor: AppColor.main50,
           body: _.isLoading.value ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
            child: Container(
             height: MediaQuery.of(context).size.height,
              decoration: AppTheme.appBoxDecoration,
              child: Column(
                children: <Widget>[
                  AppTheme.heightSpace50,
                  HeaderIntro(subtitle: AppTranslationConstants.createEventNameDesc.tr),
                  AppTheme.heightSpace20,
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top:20),
                    child: TextFormField(
                      controller: _.nameController,
                      onChanged:(text) => _.setItemlistName() ,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: AppTranslationConstants.itemlistTitle.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top:20),
                    child: TextFormField(
                      minLines: 1,
                      maxLines: 2,
                      controller: _.descController,
                      onChanged:(text) => _.setItemlistDesc() ,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: AppTranslationConstants.itemlistDesc.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  AppTheme.heightSpace10,
                  GestureDetector(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image, size: 20,),
                        AppTheme.widthSpace5,
                        Text(_.postUploadController.mediaFile.value.path.isEmpty
                            ? AppTranslationConstants.addItemlistImg.tr
                            : AppTranslationConstants.changeImage.tr,
                          style: const TextStyle(color: Colors.white70,),
                        ),
                      ],
                    ),
                    onTap: () => _.addItemlistImage()
                  ),
                  AppTheme.heightSpace20,
                  _.postUploadController.mediaFile.value.path.isEmpty ? const SizedBox.shrink():
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.file(File(_.postUploadController.mediaFile.value.path),height: 175, width: 175,),
                      FloatingActionButton(
                        heroTag: AppHeroTagConstants.clearImg,
                        backgroundColor: Theme.of(context).primaryColorLight,
                        onPressed: () => _.clearItemlistImage(),
                        elevation: 10,
                        child: Icon(Icons.close,
                            color: AppColor.white80,
                            size: 15),
                      ),
                  ]),
                  Container(
                    width: AppTheme.fullWidth(context) * 0.5,
                    height: AppTheme.fullHeight(context) * 0.06,
                    margin: EdgeInsets.symmetric(vertical: AppTheme.fullWidth(context) * 0.05),
                    child: TextButton(
                      style: TextButton.styleFrom(
                      backgroundColor: AppColor.bondiBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      onPressed: () async => {
                        if(!_.isButtonDisabled.value) {
                          await _.createItemlist(),
                        }
                      },
                      child: Text(AppTranslationConstants.createItemlist.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15
                        ),
                      ),
                    ),
                  ),
                ],
              ),
             ),
          ),
         );
      }
    );
  }

}
