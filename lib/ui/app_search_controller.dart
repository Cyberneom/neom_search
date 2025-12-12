import 'dart:async';
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

import '../utils/constants/search_constants.dart';


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

  Rxn<SearchType> moreResultsType = Rxn<SearchType>();
  RxInt moreResultsQty = 0.obs;

  Timer? _debounce;

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
    _isLoading.value = true; // Asegura que empiece cargando

    try {
      // OPTIMIZACIÓN 1: Carga Paralela
      // Ejecutamos todo simultáneamente.
      List<Future> tasks = [];

      switch(searchType) {
        case SearchType.profiles:
          tasks.add(loadProfiles());
          break;
        case SearchType.mediaItems:
          tasks.add(loadMediaItems());
          break;
        case SearchType.releaseItems:
          tasks.add(loadReleaseItems());
          break;
        case SearchType.any:
        // Disparamos las 3 peticiones a la vez
          tasks.add(loadMediaItems());
          tasks.add(loadProfiles());
          tasks.add(loadReleaseItems());
          break;
        default:
          break;
      }

      // Esperamos a que el bloque paralelo termine
      await Future.wait(tasks);

      setSearchParam("");

    } catch (e) {
      AppConfig.logger.e("Error loading search info: $e");
    } finally {
      _isLoading.value = false; // Se apaga el loading pase lo que pase
    }

  }

  @override
  void setSearchParam(String param, {bool onlyByName = false}) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    AppConfig.logger.t("Search Param: $param, Only By Name: $onlyByName");

    _debounce = Timer(const Duration(milliseconds: 300), () {

      searchParam.value = TextUtilities.normalizeString(param);
      AppConfig.logger.t("Filtering for: ${searchParam.value}");

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
          break; // Faltaba break aquí
        case SearchType.releaseItems:
          filterReleaseItems();
          break; // Faltaba break aquí
        case SearchType.any:
          filterProfiles(onlyByName: onlyByName);
          filterMediaItems();
          filterReleaseItems();
          sortByLocation();
          break;
      }

      update([AppPageIdConstants.search]);
    });

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
            || entry.value.ownerName.toLowerCase().contains(searchParam.value.toLowerCase())));
  }

  void filterReleaseItems() {
    filteredReleaseItems.value = searchParam.isEmpty
        ? releaseItems : Map.fromEntries(
        releaseItems.entries.where((entry) {

          final item = entry.value;
          final lowerSearch = searchParam.value.toLowerCase();
          final lowerItemName= entry.value.name.toLowerCase();

          bool nameMatch = lowerItemName.contains(lowerSearch);
          bool ownerMatch = item.ownerName.toLowerCase().contains(lowerSearch);
          bool categoryMatch = item.categories.any((cate) => cate.toLowerCase().contains(lowerSearch));

          return nameMatch || ownerMatch || categoryMatch;
        }
    ));
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
    AppConfig.logger.t("Sorting Profiles by Location");

    if(_filteredProfiles.isEmpty) {
      sortedProfileLocation.value.clear();
      return;
    }

    // Cacheamos la posición del usuario para no acceder al getter en cada iteración del loop
    final userPos = userServiceImpl.profile.position;
    if(userPos == null) return;

    Map<double, AppProfile> tempMap = {};

    _filteredProfiles.value.forEach((key, mate) {
        if (mate.position != null) {
          double distance = PositionUtilities.distanceBetweenPositions(userPos, mate.position!);
          // Evitar colisiones de claves en el TreeMap
          distance = distance + (Random().nextDouble() * 0.01);
          tempMap[distance] = mate;
        }
      });

      sortedProfileLocation.value = SplayTreeMap.from(tempMap);
      AppConfig.logger.t("Sorted Profiles: ${sortedProfileLocation.value.length}");
  }

  @override
  bool get isLoading => _isLoading.value;

  @override
  Map<String, AppProfile> get filteredProfiles => _filteredProfiles.value;

  void showMoreResults(SearchType type, {int qty = 10}) {
    if (moreResultsType.value == type) {
      moreResultsQty.value += qty; // Aumentamos la cantidad a mostrar
    } else {
      // Si es una categoría nueva, reseteamos la cantidad y cambiamos el tipo
      moreResultsType.value = type;
      moreResultsQty.value = qty;
    }
  }

  int getChildTypeCount(int length, SearchType type) {
    AppConfig.logger.d("Getting child count for type $type with length $length");

    int count = length;

    if(length > SearchConstants.itemsQty) {
      AppConfig.logger.t("Length $length is greater than itemsQty ${SearchConstants.itemsQty}");
      if(moreResultsType.value == type) {
        AppConfig.logger.t("More results type matches current type: ${moreResultsType.value}");
        if(length > SearchConstants.itemsQty + moreResultsQty.value) {
          count = SearchConstants.itemsQty + moreResultsQty.value;
        } else {
          count = length;
        }
      } else {
        count = SearchConstants.itemsQty;
      }
    }

    return count;
  }

}
