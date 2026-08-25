import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
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
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/position_utilities.dart';
import 'package:sint/sint.dart';

import '../utils/constants/search_constants.dart';


class AppSearchController extends SintController implements SearchService {

  final userServiceImpl = Sint.find<UserService>();
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

  MateService? get _mateService {
    if (mateServiceImpl != null) return mateServiceImpl;
    if (Sint.isRegistered<MateService>()) {
      mateServiceImpl = Sint.find<MateService>();
    }
    return mateServiceImpl;
  }

  final Map<String, AppProfile> _allProfilesCache = {};

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.d("Search Controller Init");

    try {
      scrollController = ScrollController();
      final args = Sint.arguments;
      if(args is List && args.isNotEmpty) {
        final firstArg = args[0];
        if(firstArg is SearchType) {
          searchType = firstArg;
        }
      }

      loadSearchInfo();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_search', operation: 'onInit');
    }
  }

  @override
  void onReady() {
    super.onReady();
    AppConfig.logger.i("Search Controller Ready");

    // URL query params for web deep links
    // Supports both EN and ES param names: type/tipo, q/buscar
    final typeParam = Sint.queryParam('type') ?? Sint.queryParam('tipo');

    // Type aliases: ES → enum name
    const typeAliases = <String, String>{
      'perfiles': 'profiles', 'colectivos': 'collectives', 'eventos': 'events',
      'canciones': 'mediaItems', 'musica': 'mediaItems',
      'lanzamientos': 'releaseItems', 'libros': 'releaseItems', 'todos': 'any', 'todo': 'any',
    };

    if (typeParam != null) {
      final normalized = typeAliases[typeParam.toLowerCase()] ?? typeParam.toLowerCase();
      final parsed = SearchType.values.where(
        (e) => e.name.toLowerCase() == normalized,
      ).firstOrNull;
      if (parsed != null) searchType = parsed;
    }

    final qParam = Sint.queryParam('q') ?? Sint.queryParam('buscar');
    if (qParam != null && qParam.isNotEmpty) {
      // Defer to allow loadSearchInfo to complete first
      Future.delayed(const Duration(milliseconds: 500), () {
        setSearchParam(qParam);
      });
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    try {
      scrollController.dispose();
    } catch (_) {}
    super.onClose();
  }

  Future<void> loadSearchInfo() async {
    AppConfig.logger.i("Search Type: $searchType");
    _isLoading.value = true;

    try {
      // Always load profiles, releases and media items concurrently
      // so switching category filters / tabs on web or mobile responds immediately
      await Future.wait([
        loadProfiles(),
        loadMediaItems(),
        loadReleaseItems(),
      ]);

      setSearchParam("");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_search', operation: 'loadSearchInfo');
    } finally {
      _isLoading.value = false;
      update([AppPageIdConstants.search]);
    }
  }

  @override
  void setSearchParam(String param, {bool onlyByName = false}) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    AppConfig.logger.t("Search Param: $param, Only By Name: $onlyByName");

    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchParam.value = TextUtilities.normalizeString(param);
      AppConfig.logger.t("Filtering for: ${searchParam.value}");

      // Filter all categories so count badges and tabs are always in sync
      filterProfiles(onlyByName: onlyByName);
      filterMediaItems();
      filterReleaseItems();
      sortByLocation();

      update([AppPageIdConstants.search]);
    });
  }

  void filterProfiles({bool onlyByName = false}) {
    final ms = _mateService;
    final Map<String, AppProfile> allProfiles = {};
    if (ms != null) {
      allProfiles.addAll(ms.totalProfiles);
      allProfiles.addAll(ms.profiles);
      allProfiles.addAll(ms.mates);
      allProfiles.addAll(ms.followingProfiles);
      allProfiles.addAll(ms.followerProfiles);
    }
    allProfiles.addAll(_allProfilesCache);

    final Map<String, AppProfile> candidates = searchParam.isEmpty
        ? allProfiles
        : onlyByName
            ? AppUtilities.filterByName(allProfiles, searchParam.value)
            : AppUtilities.filterByNameOrInstrument(allProfiles, searchParam.value);

    final filtered = Map<String, AppProfile>.fromEntries(
      candidates.entries.where((entry) {
        final profile = entry.value;
        final email = profile.email.toLowerCase().trim();
        if (email.endsWith('@emxi.org') || 
            email.endsWith('@gigmeout.com') || 
            email.endsWith('@cyberneom.xyz')) {
          return false;
        }
        return true;
      })
    );

    _filteredProfiles.value = filtered;
    AppConfig.logger.t("Filtered Profiles: ${_filteredProfiles.value.length}");
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
      final ms = _mateService;
      if (ms != null) {
        if (ms.profiles.isEmpty && ms.totalProfiles.isEmpty) {
          await ms.loadProfiles(includeSelf: includeSelf, loadAll: true);
        }
        _allProfilesCache.addAll(ms.totalProfiles);
        _allProfilesCache.addAll(ms.profiles);
        _allProfilesCache.addAll(ms.mates);
        _allProfilesCache.addAll(ms.followingProfiles);
        _allProfilesCache.addAll(ms.followerProfiles);
      }

      filterProfiles();
      sortByLocation();
      AppConfig.logger.d("Filtered Profiles ${_filteredProfiles.value.length}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_search', operation: 'loadProfiles');
    }
  }

  @override
  Future<void> loadMediaItems() async {
    AppConfig.logger.d("Loading Media Items");
    try {
      mediaItems = await AppMediaItemFirestore().fetchAll();
      filterMediaItems();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_search', operation: 'loadMediaItems');
    }
  }

  @override
  Future<void> loadReleaseItems() async {
    AppConfig.logger.d("Loading Release Items");
    try {
      releaseItems = await AppReleaseItemFirestore().retrieveAll();
      filterReleaseItems();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_search', operation: 'loadReleaseItems');
    }
  }

  @override
  void sortByLocation() {
    AppConfig.logger.t("Sorting ${_filteredProfiles.length} Profiles by Location");

    if(_filteredProfiles.isEmpty) {
      sortedProfileLocation.value.clear();
      return;
    }

    // Cacheamos la posición del usuario para no acceder al getter en cada iteración del loop
    final userPos = userServiceImpl.profile.position;

    Map<double, AppProfile> tempMap = {};

    if(userPos != null) {
      // Ordenar por distancia al usuario
      _filteredProfiles.value.forEach((key, mate) {
        if (mate.position != null) {
          double distance = PositionUtilities.distanceBetweenPositions(userPos, mate.position!);
          // Evitar colisiones de claves en el TreeMap
          distance = distance + (Random().nextDouble() * 0.01);
          tempMap[distance] = mate;
        }
      });
    }

    // Fallback: perfiles sin posición (o sin geolocación del usuario)
    // Los agregamos al final con claves altas para que queden después de los ordenados
    if(tempMap.length < _filteredProfiles.length) {
      double fallbackKey = (tempMap.isEmpty ? 0 : tempMap.keys.last) + 1000;
      // Ordenar alfabéticamente los que no tienen posición o cuando no hay geolocación
      final remaining = userPos != null
          ? _filteredProfiles.value.entries.where((e) => e.value.position == null).toList()
          : _filteredProfiles.value.entries.toList();
      remaining.sort((a, b) => a.value.name.toLowerCase().compareTo(b.value.name.toLowerCase()));
      for (final entry in remaining) {
        if(!tempMap.containsValue(entry.value)) {
          tempMap[fallbackKey] = entry.value;
          fallbackKey += 1;
        }
      }
    }

    sortedProfileLocation.value = SplayTreeMap.from(tempMap);
    AppConfig.logger.t("Sorted Profiles: ${sortedProfileLocation.value.length}");
  }

  /// Whether the user has geolocation available (profiles sorted by distance)
  bool get hasUserPosition => userServiceImpl.profile.position != null;

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
      AppConfig.logger.t("Length $length for ${type.name} is greater than itemsQty ${SearchConstants.itemsQty}");
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
