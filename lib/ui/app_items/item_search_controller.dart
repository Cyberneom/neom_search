// ignore_for_file: unused_import

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/api/app_platform_api.dart';
import 'package:neom_core/data/api/app_release_items.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/collective.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/external_music_service.dart';
import 'package:neom_core/domain/use_cases/google_book_gateway_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';

import '../../domain/use_cases/app_media_item_search_service.dart';
import '../app_search_controller.dart';

class ItemSearchController extends SintController implements ItemSearchService {
  static String sanitizeSearchQuery(String raw) =>
      AppSearchController.sanitizeSearchQuery(raw);

  UserService? _userServiceImpl;
  UserService? get _userService {
    if (_userServiceImpl != null) return _userServiceImpl;
    if (Sint.isRegistered<UserService>()) {
      _userServiceImpl = Sint.find<UserService>();
    }
    return _userServiceImpl;
  }

  UserService get userServiceImpl => _userService!;

  TextEditingController searchParamController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();

  final RxBool isLoading = true.obs;
  final RxMap<String, AppMediaItem> totalMediaItems = <String, AppMediaItem>{}.obs;
  final RxMap<String, AppReleaseItem> totalReleaseItems = <String, AppReleaseItem>{}.obs;
  ///DEPRECATED
  // final RxMap<String, AppMediaItem> foundMediaItems = <String, AppMediaItem>{}.obs;
  // final RxMap<String, AppReleaseItem> foundReleaseItems = <String, AppReleaseItem>{}.obs;
  final RxMap<String, ExternalItem> foundExternalItems = <String, ExternalItem>{}.obs;
  final RxMap<String, dynamic> foundItems = <String, dynamic>{}.obs;

  final RxMap<String, Itemlist> itemlists = <String, Itemlist>{}.obs;
  final RxList<AppMediaItem> addedItems = <AppMediaItem>[].obs;
  final RxString searchParam = "".obs;

  AppProfile profile = AppProfile();
  Collective collective = Collective();
  OwnerType ownerType = OwnerType.profile;
  Itemlist itemlist = Itemlist();
  MediaSearchType searchType = MediaSearchType.song;
  Timer? _searchDebounce;
  bool _isClosed = false;

  @override
  void onInit() async {
    super.onInit();
    try {
      final us = _userService;
      if (us != null) {
        profile = us.profile;
        collective = us.collective;
        ownerType = us.itemlistOwnerType;
      }
      itemlist.ownerType = ownerType;
      if (ownerType == OwnerType.profile) {
        itemlists.value = profile.itemlists ?? {};
      } else {
        itemlists.value = collective.itemlists ?? {};
      }

      final args = Sint.arguments;
      if (args is List && args.isNotEmpty) {
        final firstArg = args[0];
        if (firstArg is MediaSearchType) {
          searchType = firstArg;
          if (args.length >= 2) {
            switch (searchType) {
              case MediaSearchType.song:
              case MediaSearchType.book:
                if (args[1] is Itemlist) {
                  itemlist = args[1] as Itemlist;
                }
                break;
              case MediaSearchType.playlist:
                if (args[1] is String) {
                  await initSearchParam(args[1] as String);
                }
                break;
              default:
                break;
            }
          }
        } else if (firstArg is Itemlist) {
          itemlist = firstArg;
          searchType = _getMediaSearchType(itemlist.type);
        }
      } else if (args is MediaSearchType) {
        searchType = args;
      } else if (args is Itemlist) {
        itemlist = args;
        searchType = _getMediaSearchType(itemlist.type);
      } else if (itemlist.type != ItemlistType.playlist) {
        searchType = _getMediaSearchType(itemlist.type);
      }

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_search', operation: 'onInit');
    }
  }

  static MediaSearchType _getMediaSearchType(ItemlistType itemlistType) {
    switch(itemlistType) {
      case ItemlistType.playlist:
      case ItemlistType.single:
      case ItemlistType.ep:
      case ItemlistType.album:
      case ItemlistType.demo:
      case ItemlistType.radioStation:
      case ItemlistType.giglist:
        return MediaSearchType.song;
      case ItemlistType.podcast:
        return MediaSearchType.podcast;
      case ItemlistType.readlist:
      case ItemlistType.publication:
        return MediaSearchType.book;
      case ItemlistType.audiobook:
        return MediaSearchType.audiobook;
      case ItemlistType.meditation:
        return MediaSearchType.meditation;
      case ItemlistType.gallery:
        return MediaSearchType.song;
    }
  }

  @override
  void onReady() async {
    super.onReady();
    if (_isClosed) return;
    isLoading.value = false;
    update([AppPageIdConstants.mediaItemSearch]);
  }


  void clearFoundItems() {
    foundExternalItems.value.clear();
    foundItems.value.clear();
  }

  Future<void> initSearchParam(String text) async {
    if (_isClosed) return;
    AppConfig.logger.d("initSearchParam");
    final cleanText = sanitizeSearchQuery(text);

    searchParam.value = cleanText;
    searchParamController.text = cleanText;

    try {
      await searchItems();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_search', operation: 'initSearchParam');
    }

    if (!_isClosed) {
      update([AppPageIdConstants.mediaItemSearch]);
    }
  }


  void debouncedSetSearchParam(
    String text, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    if (_isClosed) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      if (_isClosed) return;
      unawaited(setSearchParam(text));
    });
  }

  @override
  Future<void> setSearchParam(String text) async {
    if (_isClosed) return;
    _searchDebounce?.cancel();
    final cleanText = sanitizeSearchQuery(text);
    AppConfig.logger.d("Set SearchParam: $cleanText");

    searchParam.value = cleanText;
    try {
      await searchItems();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_search', operation: 'setSearchParam');
    }

    if (!_isClosed) {
      update([AppPageIdConstants.mediaItemSearch]);
    }
  }


  @override
  Future<void> searchItems() async {
    AppConfig.logger.d("Searching $searchType with param: ${searchParam.value}");
    clearFoundItems();
    try {
      switch(searchType) {
        case(MediaSearchType.song):
          final needle = searchParam.value.trim().toLowerCase();
          if (needle.isEmpty) break;

          if (!AppPlatformApi.isEnabled && totalMediaItems.isEmpty) {
            totalMediaItems.value.addAll(await AppMediaItemFirestore().fetchAll(excludeTypes: [MediaItemType.pdf, MediaItemType.neomPreset]));
          }

          if (AppConfig.instance.appInUse != AppInUse.e) {
            if (totalReleaseItems.isEmpty) {
              totalReleaseItems.value = await AppReleaseItems.repository.retrieveAll();
            }
            for (final release in totalReleaseItems.value.values) {
              if (release.name.toLowerCase().contains(needle) ||
                  release.ownerName.toLowerCase().contains(needle)) {
                foundItems[release.id] = release;
              }
            }
          }

          for (var value in totalMediaItems.value.values) {
            if(value.name.toLowerCase().contains(needle)
                || (value.ownerName.toLowerCase().contains(needle))) {
              foundItems[value.id] = value;
            }
          }

          switch(AppConfig.instance.appInUse) {
            case AppInUse.g:
              if (needle.length >= 2 && Sint.isRegistered<ExternalMusicService>()) {
                final ytSongs = await Sint.find<ExternalMusicService>().searchSongs(searchParam.value.trim());
                for (final song in ytSongs) {
                  if (song.id.isNotEmpty) {
                    foundExternalItems[song.id] = song;
                    foundItems.putIfAbsent(song.id, () => song);
                  }
                }
              }
              break;
            default:
              break;
          }

          AppConfig.logger.d("${foundItems.length} songs retrieved (catalog + YouTube)");
          break;
        case(MediaSearchType.playlist):
          ///NOT IN USE
          // itemlists.value = await NeomSpotifyController().searchPlaylists(searchParam.value);
          AppConfig.logger.d("${itemlists.length} playlists retrieved");
          break;

        case(MediaSearchType.book):
          if(totalReleaseItems.isEmpty) {
            totalReleaseItems.value = await AppReleaseItems.repository.retrieveAll();
          }

          final lowerQuery = searchParam.value.toLowerCase();
          for (var value in totalReleaseItems.value.values) {
            if(value.name.toLowerCase().contains(lowerQuery)
                || (value.ownerName.toLowerCase().contains(lowerQuery))) {
              foundItems[value.id] = value;
            }
          }

          if (Sint.isRegistered<GoogleBookGatewayService>()) {
            foundExternalItems.value = await Sint.find<GoogleBookGatewayService>().searchBooksAsExternalItem(searchParam.value);
          }

          for (var value in foundExternalItems.value.values) {
            if(value.name.toLowerCase().contains(lowerQuery)
                || (value.ownerName.toLowerCase().contains(lowerQuery))) {
              foundItems[value.id] = value;
            }
          }
          break;

        case(MediaSearchType.audiobook):
          if (totalReleaseItems.isEmpty) {
            totalReleaseItems.value = await AppReleaseItemFirestore().retrieveAll();
          }
          if (totalMediaItems.isEmpty) {
            totalMediaItems.value.addAll(await AppMediaItemFirestore().fetchAll());
          }

          final lowerQueryAudiobook = TextUtilities.normalizeString(searchParam.value).toLowerCase();
          for (var value in totalReleaseItems.value.values) {
            if (value.mediaType == MediaItemType.audiobook || value.type == ReleaseType.chapter) {
              final name = TextUtilities.normalizeString(value.name).toLowerCase();
              final owner = TextUtilities.normalizeString(value.ownerName).toLowerCase();
              if (name.contains(lowerQueryAudiobook) || owner.contains(lowerQueryAudiobook)) {
                foundItems[value.id] = value;
              }
            }
          }
          for (var value in totalMediaItems.value.values) {
            if (value.type == MediaItemType.audiobook) {
              final name = TextUtilities.normalizeString(value.name).toLowerCase();
              final owner = TextUtilities.normalizeString(value.ownerName).toLowerCase();
              if (name.contains(lowerQueryAudiobook) || owner.contains(lowerQueryAudiobook)) {
                foundItems[value.id] = value;
              }
            }
          }
          break;

        case(MediaSearchType.podcast):
          if (totalMediaItems.isEmpty) {
            totalMediaItems.value.addAll(await AppMediaItemFirestore().fetchAll());
          }
          if (totalReleaseItems.isEmpty) {
            totalReleaseItems.value = await AppReleaseItemFirestore().retrieveAll();
          }

          final lowerQueryPodcast = TextUtilities.normalizeString(searchParam.value).toLowerCase();
          for (var value in totalMediaItems.value.values) {
            if (value.type == MediaItemType.podcast) {
              final name = TextUtilities.normalizeString(value.name).toLowerCase();
              final owner = TextUtilities.normalizeString(value.ownerName).toLowerCase();
              if (name.contains(lowerQueryPodcast) || owner.contains(lowerQueryPodcast)) {
                foundItems[value.id] = value;
              }
            }
          }
          for (var value in totalReleaseItems.value.values) {
            if (value.mediaType == MediaItemType.podcast || value.type == ReleaseType.episode) {
              final name = TextUtilities.normalizeString(value.name).toLowerCase();
              final owner = TextUtilities.normalizeString(value.ownerName).toLowerCase();
              if (name.contains(lowerQueryPodcast) || owner.contains(lowerQueryPodcast)) {
                foundItems[value.id] = value;
              }
            }
          }
          break;
        default:
          break;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_search', operation: 'searchItems');
    }

    if (!_isClosed) {
      update([AppPageIdConstants.mediaItemSearch]);
    }
  }

  @override
  void getAppMediaItemDetails(AppMediaItem appMediaItem) {
    AppConfig.logger.d("Sending appMediaItem with title ${appMediaItem.name} to item controller");
    AppUtilities.gotoItemDetails(appMediaItem);
  }

  @override
  void onClose() {
    _isClosed = true;
    _searchDebounce?.cancel();
    searchParamController.dispose();
    nameController.dispose();
    descController.dispose();
    isLoading.close();
    totalMediaItems.close();
    totalReleaseItems.close();
    foundExternalItems.close();
    foundItems.close();
    itemlists.close();
    addedItems.close();
    searchParam.close();
    super.onClose();
  }

}
