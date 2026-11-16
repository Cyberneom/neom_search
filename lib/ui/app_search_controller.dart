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
  static const int maxSearchQueryChars = 160;
  static final RegExp _unsafeSearchControls = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B\u200C\u200E\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  static final RegExp _gemma4ThoughtClosed = RegExp(
    r'<\|(?:channel|turn)>\s*thought\b[\s\S]*?<(?:channel|turn)\|>'
    r'|<\|tool_call>[\s\S]*?<tool_call\|>',
    caseSensitive: false,
  );
  static final RegExp _gemma4ThoughtTruncated = RegExp(
    r'<\|(?:channel|turn)>\s*thought\b[\s\S]*$'
    r'|<\|tool_call>[\s\S]*$',
    caseSensitive: false,
  );
  static final RegExp _internalReasoningBlock = RegExp(
    r'<\s*(think|thought|memory_recall|auto_memory|system_context)\b[^>]*>[\s\S]*?(?:<\s*/\s*\1\s*>|$)'
    r'|\[\s*(BIOCHIP|MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT)\b[^\]]*\][\s\S]*?\[\s*/\s*\2\s*\]',
    caseSensitive: false,
  );
  static final RegExp _sentinelBracketBlock = RegExp(
    r'\[\s*/?\s*(?:BIOCHIP|MEMORY_RECALL|AUTO_MEMORY|SYSTEM_CONTEXT)\b[^\]]*\]',
    caseSensitive: false,
  );
  static final RegExp _turnTokens = RegExp(
    r'(?:<\|/?(?:turn|channel|eot|im_start|im_end|tool_call)[^>]*\|?>|<(?:turn|channel|tool_call)\|>)',
    caseSensitive: false,
  );
  static final RegExp _closingContentBoundary = RegExp(
    r'<\s*/\s*content\s*>',
    caseSensitive: false,
  );

  static String sanitizeSearchQuery(
    String raw, {
    int maxChars = maxSearchQueryChars,
  }) {
    if (!maxChars.toDouble().isFinite || maxChars <= 0) return '';
    var cleaned = raw
        .replaceAll(_gemma4ThoughtClosed, ' ')
        .replaceAll(_gemma4ThoughtTruncated, ' ')
        .replaceAll(_internalReasoningBlock, ' ')
        .replaceAll(_sentinelBracketBlock, ' ')
        .replaceAll(_turnTokens, ' ')
        .replaceAll(_closingContentBoundary, '[content_end]')
        .replaceAll(_unsafeSearchControls, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length <= maxChars) return cleaned;
    var end = maxChars;
    final cu = cleaned.codeUnitAt(end - 1);
    if (cu >= 0xD800 && cu <= 0xDBFF) {
      end -= 1;
    }
    if (end <= 0) return '';
    return cleaned.substring(0, end).trimRight();
  }

  UserService? _userServiceImpl;
  UserService? get _userService {
    if (_userServiceImpl != null) return _userServiceImpl;
    if (Sint.isRegistered<UserService>()) {
      _userServiceImpl = Sint.find<UserService>();
    }
    return _userServiceImpl;
  }

  UserService get userServiceImpl => _userService!;

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
  Timer? _initialQueryTimer;
  bool _isClosed = false;

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
      final args = Sint.arguments;
      if (args is List && args.isNotEmpty) {
        final firstArg = args[0];
        if (firstArg is SearchType) {
          searchType = firstArg;
        }
      } else if (args is SearchType) {
        searchType = args;
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
      final normalized =
          (typeAliases[typeParam.toLowerCase()] ?? typeParam).toLowerCase();
      final parsed = SearchType.values.where(
        (e) => e.name.toLowerCase() == normalized,
      ).firstOrNull;
      if (parsed != null) searchType = parsed;
    }

    final qParam = Sint.queryParam('q') ?? Sint.queryParam('buscar');
    final safeQuery = qParam != null ? sanitizeSearchQuery(qParam) : '';
    if (safeQuery.isNotEmpty) {
      // Defer to allow loadSearchInfo to complete first; cancelable on close
      _initialQueryTimer?.cancel();
      _initialQueryTimer = Timer(const Duration(milliseconds: 500), () {
        if (_isClosed) return;
        setSearchParam(safeQuery);
      });
    }
  }

  @override
  void onClose() {
    _isClosed = true;
    _debounce?.cancel();
    _initialQueryTimer?.cancel();
    try {
      scrollController.dispose();
    } catch (_) {}
    _isLoading.close();
    _filteredProfiles.close();
    searchParam.close();
    filteredMediaItems.close();
    filteredReleaseItems.close();
    sortedProfileLocation.close();
    moreResultsType.close();
    moreResultsQty.close();
    super.onClose();
  }

  Future<void> loadSearchInfo() async {
    AppConfig.logger.i("Search Type: $searchType");
    if (!_isClosed) _isLoading.value = true;

    try {
      // Always load profiles, releases and media items concurrently
      // so switching category filters / tabs on web or mobile responds immediately
      await Future.wait([
        loadProfiles(),
        loadMediaItems(),
        loadReleaseItems(),
      ]);

      if (!_isClosed) setSearchParam("");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_search', operation: 'loadSearchInfo');
    } finally {
      if (!_isClosed) {
        _isLoading.value = false;
        update([AppPageIdConstants.search]);
      }
    }
  }

  @override
  void setSearchParam(String param, {bool onlyByName = false}) {
    if (_isClosed) return;
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    AppConfig.logger.t("Search Param: $param, Only By Name: $onlyByName");

    final sanitizedParam = sanitizeSearchQuery(param);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_isClosed) return;
      searchParam.value = TextUtilities.normalizeString(sanitizedParam);
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
    final search = TextUtilities.normalizeString(searchParam.value).toLowerCase();
    filteredMediaItems.value = searchParam.isEmpty
        ? mediaItems
        : Map.fromEntries(
            mediaItems.entries.where((entry) {
              final name = TextUtilities.normalizeString(entry.value.name).toLowerCase();
              final owner = TextUtilities.normalizeString(entry.value.ownerName).toLowerCase();
              return name.contains(search) || owner.contains(search);
            }),
          );
  }

  void filterReleaseItems() {
    final search = TextUtilities.normalizeString(searchParam.value).toLowerCase();
    filteredReleaseItems.value = searchParam.isEmpty
        ? releaseItems
        : Map.fromEntries(
            releaseItems.entries.where((entry) {
              final item = entry.value;
              final name = TextUtilities.normalizeString(item.name).toLowerCase();
              final owner = TextUtilities.normalizeString(item.ownerName).toLowerCase();
              final categoryMatch = item.categories.any((cate) =>
                  TextUtilities.normalizeString(cate).toLowerCase().contains(search));

              return name.contains(search) || owner.contains(search) || categoryMatch;
            }),
          );
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
    final userPos = _userService?.profile.position;
    final hasFiniteUserPos = userPos != null &&
        userPos.latitude.isFinite &&
        userPos.longitude.isFinite;

    final Map<double, AppProfile> tempMap = {};
    final Set<String> placedKeys = <String>{};
    double maxDistance = 0.0;

    if (hasFiniteUserPos) {
      // Ordenar por distancia al usuario
      _filteredProfiles.value.forEach((key, mate) {
        final matePos = mate.position;
        if (matePos != null &&
            matePos.latitude.isFinite &&
            matePos.longitude.isFinite) {
          double distance = PositionUtilities.distanceBetweenPositions(
            userPos,
            matePos,
          );
          if (!distance.isFinite || distance < 0) return;
          // Evitar colisiones de claves en el TreeMap
          distance = distance + (Random().nextDouble() * 0.01);
          while (tempMap.containsKey(distance)) {
            distance += 0.0001;
          }
          tempMap[distance] = mate;
          placedKeys.add(key);
          if (distance > maxDistance) {
            maxDistance = distance;
          }
        }
      });
    }

    // Fallback: perfiles sin posición válida (o sin geolocación del usuario)
    // Los agregamos al final con claves altas para que queden después de los ordenados
    if (tempMap.length < _filteredProfiles.length) {
      double fallbackKey = (tempMap.isEmpty ? 0.0 : maxDistance) + 1000.0;
      // Ordenar alfabéticamente los que no tienen posición o cuando no hay geolocación
      final remaining = _filteredProfiles.value.entries
          .where((e) => !placedKeys.contains(e.key))
          .toList();
      remaining.sort(
        (a, b) => a.value.name.toLowerCase().compareTo(b.value.name.toLowerCase()),
      );
      for (final entry in remaining) {
        if (!tempMap.containsValue(entry.value)) {
          tempMap[fallbackKey] = entry.value;
          fallbackKey += 1.0;
        }
      }
    }

    sortedProfileLocation.value = SplayTreeMap.from(tempMap);
    AppConfig.logger.t("Sorted Profiles: ${sortedProfileLocation.value.length}");
  }

  /// Whether the user has geolocation available (profiles sorted by distance)
  bool get hasUserPosition => _userService?.profile.position != null;

  @override
  bool get isLoading => _isLoading.value;

  @override
  Map<String, AppProfile> get filteredProfiles => _filteredProfiles.value;

  void showMoreResults(SearchType type, {int qty = 10}) {
    final safeQty = qty.toDouble().isFinite ? qty.clamp(1, 200) : 10;
    if (moreResultsType.value == type) {
      final next = moreResultsQty.value + safeQty;
      moreResultsQty.value = next > 10000 ? 10000 : next;
    } else {
      // Si es una categoría nueva, reseteamos la cantidad y cambiamos el tipo
      moreResultsType.value = type;
      moreResultsQty.value = safeQty;
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
