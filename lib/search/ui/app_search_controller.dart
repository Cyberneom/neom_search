import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_commons/core/data/implementations/mate_controller.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/domain/use_cases/search_service.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/search_type.dart';

class AppSearchController extends GetxController implements SearchService {

  final userController = Get.find<UserController>();
  MateController mateController = Get.put(MateController());
  ScrollController scrollController = ScrollController();

  final RxBool isLoading = true.obs;
  final RxString searchParam = "".obs;

  final RxMap<String, AppProfile> filteredProfiles = <String, AppProfile>{}.obs;

  Map<String, AppMediaItem> mediaItems = {};
  Map<String, AppReleaseItem> releaseItems = {};
  final RxMap<String, AppMediaItem> filteredMediaItems = <String, AppMediaItem>{}.obs;
  final RxMap<String, AppReleaseItem> filteredReleaseItems = <String, AppReleaseItem>{}.obs;

  final Rx<SplayTreeMap<double, AppProfile>> sortedProfileLocation = SplayTreeMap<double, AppProfile>().obs;

  SearchType searchType = SearchType.profiles;

  @override
  void onInit() {
    super.onInit();
    AppUtilities.logger.i("Search Controller Init");

    try {
      final args = Get.arguments;
      if(args is List && args.isNotEmpty) {

        final firstArg = args[0];
        if(firstArg is SearchType) {
          searchType = firstArg;
        }

      }

      loadSearchInfo();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  void onReady() {
    super.onReady();
    try {

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.search]);
  }

  Future<void> loadSearchInfo() async {

    AppUtilities.logger.i("Search Type: $searchType");

    switch(searchType) {
      case SearchType.profiles:
        await loadProfiles();
        break;
      case SearchType.bands:
        break;
      case SearchType.events:
        break;
      case SearchType.items:
        await loadItems();
      case SearchType.any:
        await loadProfiles();
        loadItems();
        break;
    }

    setSearchParam("");
  }

  @override
  void setSearchParam(String param, {bool onlyByName = false}) {
    searchParam.value = param;
    filteredProfiles.value = searchParam.isEmpty ? mateController.totalProfiles
        : onlyByName ? mateController.filterByName(searchParam.value)
        : mateController.filterByNameOrInstrument(searchParam.value);
    // Actualizamos el filtrado de media items:
    filteredMediaItems.value = searchParam.isEmpty
        ? mediaItems
        : Map.fromEntries(
        mediaItems.entries.where((entry) => entry.value.name.toLowerCase().contains(searchParam.value.toLowerCase())
            || entry.value.artist.toLowerCase().contains(searchParam.value.toLowerCase())
        )
    );

    filteredReleaseItems.value = searchParam.isEmpty
        ? releaseItems
        : Map.fromEntries(
        releaseItems.entries.where((entry) =>
            entry.value.name.toLowerCase().contains(searchParam.value.toLowerCase())
                || entry.value.ownerName.toLowerCase().contains(searchParam.value.toLowerCase())
        )
    );


    sortByLocation();
    update([AppPageIdConstants.search]);
  }

  @override
  Future<void> loadProfiles({bool includeSelf = false}) async {
    AppUtilities.logger.d("Loading Profiles");
    try {
      await mateController.loadProfiles(includeSelf: includeSelf);
      filteredProfiles.value.addAll(mateController.followingProfiles);
      filteredProfiles.value.addAll(mateController.followerProfiles);
      filteredProfiles.value.addAll(mateController.mates);
      filteredProfiles.value.addAll(mateController.profiles);
      sortByLocation();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }


    isLoading.value = false;
    update([AppPageIdConstants.search]);
  }

  @override
  Future<void> loadItems() async {
    AppUtilities.logger.d("Loading Items");

    try {
      mediaItems = await AppMediaItemFirestore().fetchAll();
      releaseItems = await AppReleaseItemFirestore().retrieveAll();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.search]);
  }

  @override
  void sortByLocation() {
    sortedProfileLocation.value.clear();
    filteredProfiles.value.forEach((key, mate) {
      double distanceBetweenProfiles = AppUtilities.distanceBetweenPositions(
          userController.profile.position!,
          mate.position!);

      distanceBetweenProfiles = distanceBetweenProfiles + Random().nextDouble();
      sortedProfileLocation.value[distanceBetweenProfiles] = mate;
    });

    AppUtilities.logger.d("Filtered Profiles ${filteredProfiles.value.length}");
    AppUtilities.logger.d("Sortered Profiles ${sortedProfileLocation.value.length}");
    update([AppPageIdConstants.search]);
  }

}
