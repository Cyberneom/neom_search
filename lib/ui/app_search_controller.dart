import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/use_cases/mate_service.dart';
import 'package:neom_core/domain/use_cases/search_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/search_type.dart';
import 'package:neom_core/utils/position_utilities.dart';


class AppSearchController extends GetxController implements SearchService {

  final userServiceImpl = Get.find<UserService>();
  MateService? mateServiceImpl;
  ScrollController scrollController = ScrollController();

  final RxBool _isLoading = true.obs;
  final RxMap<String, AppProfile> _filteredProfiles = <String, AppProfile>{}.obs;

  RxString searchParam = "".obs;

  Map<String, AppMediaItem> mediaItems = {};
  Map<String, AppReleaseItem> releaseItems = {};
  RxMap<String, AppMediaItem> filteredMediaItems = <String, AppMediaItem>{}.obs;
  RxMap<String, AppReleaseItem> filteredReleaseItems = <String, AppReleaseItem>{}.obs;

  Rx<SplayTreeMap<double, AppProfile>> sortedProfileLocation = SplayTreeMap<double, AppProfile>().obs;

  SearchType searchType = SearchType.profiles;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.i("Search Controller Init");

    try {
      final args = Get.arguments;
      if(args is List && args.isNotEmpty) {

        final firstArg = args[0];
        if(firstArg is SearchType) {
          searchType = firstArg;
        }
      }

      if(searchType == SearchType.profiles || searchType == SearchType.any) {
        mateServiceImpl = Get.find<MateService>();
      }

      loadSearchInfo();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void onReady() {
    super.onReady();

    try {

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  Future<void> loadSearchInfo() async {
    AppConfig.logger.i("Search Type: $searchType");

    switch(searchType) {
      case SearchType.profiles:
        await loadProfiles();
        break;
      case SearchType.bands:
        break;
      case SearchType.events:
        break;
      case SearchType.mediaItems:
        await loadMediaItems();
      case SearchType.releaseItems:
        await loadReleaseItems();
      case SearchType.any:
        await loadMediaItems();
        await loadProfiles();
        await loadReleaseItems();
        break;
    }

    setSearchParam("");

    _isLoading.value = false;
    // update([AppPageIdConstants.search]);
  }

  @override
  void setSearchParam(String param, {bool onlyByName = false}) {
    AppConfig.logger.t("Search Param: $param, Only By Name: $onlyByName");

    searchParam.value = TextUtilities.normalizeString(param);

    switch(searchType) {
      case SearchType.profiles:
        filterProfiles(onlyByName: onlyByName);
        sortByLocation();
        break;
      case SearchType.bands:
        break;
      case SearchType.events:
        break;
      case SearchType.mediaItems:
        filterMediaItems();
      case SearchType.releaseItems:
        filterReleaseItems();
      case SearchType.any:
        filterProfiles(onlyByName: onlyByName);
        filterMediaItems();
        filterReleaseItems();
        sortByLocation();
        break;
    }

    update([AppPageIdConstants.search]);
  }

  void filterProfiles({bool onlyByName = false}) {
    _filteredProfiles.value = searchParam.isEmpty ? mateServiceImpl?.totalProfiles ?? {}
        : onlyByName ? AppUtilities.filterByName(mateServiceImpl?.totalProfiles ?? {}, searchParam.value)
        : AppUtilities.filterByNameOrInstrument(mateServiceImpl?.totalProfiles ?? {}, searchParam.value);
  }

  void filterMediaItems() {
    filteredMediaItems.value = searchParam.isEmpty
        ? mediaItems : Map.fromEntries(
        mediaItems.entries.where((entry) => entry.value.name.toLowerCase().contains(searchParam.value.toLowerCase())
            || entry.value.artist.toLowerCase().contains(searchParam.value.toLowerCase())));
  }

  void filterReleaseItems() {
    filteredReleaseItems.value = searchParam.isEmpty
        ? releaseItems : Map.fromEntries(
        releaseItems.entries.where((entry) =>
        entry.value.name.toLowerCase().contains(searchParam.value.toLowerCase())
            || entry.value.ownerName.toLowerCase().contains(searchParam.value.toLowerCase())));
  }

  @override
  Future<void> loadProfiles({bool includeSelf = false}) async {
    AppConfig.logger.d("Loading Profiles");
    try {

      if(mateServiceImpl?.profiles.isEmpty ?? true) {
        await mateServiceImpl?.loadProfiles(includeSelf: includeSelf);
      }
      _filteredProfiles.value.addAll(mateServiceImpl?.followingProfiles ?? {});
      _filteredProfiles.value.addAll(mateServiceImpl?.followerProfiles ?? {});
      _filteredProfiles.value.addAll(mateServiceImpl?.mates ?? {});
      _filteredProfiles.value.addAll(mateServiceImpl?.profiles ?? {});
      AppConfig.logger.d("Filtered Profiles ${_filteredProfiles.value.length}");
      sortByLocation();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }


    _isLoading.value = false;
    update([AppPageIdConstants.search]);
  }

  @override
  Future<void> loadMediaItems() async {
    AppConfig.logger.d("Loading Media Items");

    try {
      mediaItems = await AppMediaItemFirestore().fetchAll();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  Future<void> loadReleaseItems() async {
    AppConfig.logger.d("Loading Release Items");

    try {
      releaseItems = await AppReleaseItemFirestore().retrieveAll();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void sortByLocation() {
    sortedProfileLocation.value.clear();
    _filteredProfiles.value.forEach((key, mate) {
      double distanceBetweenProfiles = PositionUtilities.distanceBetweenPositions(
          userServiceImpl.profile.position!,
          mate.position!);

      distanceBetweenProfiles = distanceBetweenProfiles + Random().nextDouble();
      sortedProfileLocation.value[distanceBetweenProfiles] = mate;
    });

    AppConfig.logger.t("Sortered Profiles ${sortedProfileLocation.value.length}");
  }

  @override
  bool get isLoading => _isLoading.value;

  @override
  Map<String, AppProfile> get filteredProfiles => _filteredProfiles.value;

}
