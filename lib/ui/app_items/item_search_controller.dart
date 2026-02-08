// ignore_for_file: unused_import

import 'package:flutter/cupertino.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/band.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/google_book_gateway_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:sint/sint.dart';

import '../../domain/use_cases/app_media_item_search_service.dart';

class ItemSearchController extends SintController implements ItemSearchService {

  final userServiceImpl = Sint.find<UserService>();

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
  Band band = Band();
  OwnerType ownerType = OwnerType.profile;
  Itemlist itemlist = Itemlist();
  MediaSearchType searchType = MediaSearchType.song;

  @override
  void onInit() async {
    super.onInit();
    try {

      profile = userServiceImpl.profile;
      band = userServiceImpl.band;
      ownerType = userServiceImpl.itemlistOwnerType;
      itemlist.ownerType = ownerType;
      if(ownerType == OwnerType.profile) {
        itemlists.value = profile.itemlists ?? {};
      } else {
        itemlists.value = band.itemlists ?? {};
      }

      if(Sint.arguments != null) {
        if(Sint.arguments[0] is MediaSearchType) {
          searchType = Sint.arguments[0] as MediaSearchType;
          if(Sint.arguments.length == 2) {
            switch(searchType) {
              case(MediaSearchType.song):
              case(MediaSearchType.book):
                itemlist =  Sint.arguments[1] as Itemlist;
                break;
              case(MediaSearchType.playlist):
                await initSearchParam(Sint.arguments[1] as String);
                break;
              default:
                break;
            }
          }
        }
      }

      switch(itemlist.type) {
        case ItemlistType.readlist:
          searchType = MediaSearchType.book;
        case ItemlistType.playlist:
        case ItemlistType.podcast:
          searchType = MediaSearchType.song;
        default:
          searchType = MediaSearchType.song;
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  void onReady() async {
    super.onReady();
    isLoading.value = false;
    update([AppPageIdConstants.mediaItemSearch]);
  }


  void clearFoundItems() {
    foundExternalItems.value.clear();
    foundItems.value.clear();
  }

  Future<void> initSearchParam(String text) async {
    AppConfig.logger.d("initSearchParam");

    searchParam.value = text;
    searchParamController.text = text;

    try {
      await searchItems();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.mediaItemSearch]);
  }


  @override
  Future<void> setSearchParam(String text) async {
    AppConfig.logger.d("Set SearchParam: $text");

    searchParam.value = text;
    try {
      await searchItems();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.mediaItemSearch]);
  }


  @override
  Future<void> searchItems() async {
    AppConfig.logger.d("Searching $searchType with param: ${searchParam.value}");
    clearFoundItems();
    try {
      switch(searchType) {
        case(MediaSearchType.song):

          if(totalMediaItems.isEmpty) {
            totalMediaItems.value.addAll(await AppMediaItemFirestore().fetchAll(excludeTypes: [MediaItemType.pdf, MediaItemType.neomPreset]));
          }

          if(AppConfig.instance.appInUse != AppInUse.e) {
            if(totalReleaseItems.isEmpty) totalReleaseItems.value = await AppReleaseItemFirestore().retrieveAll();
          }

          for (var value in totalMediaItems.value.values) {
            if(value.name.toLowerCase().contains(searchParam.value.toLowerCase())
                || (value.ownerName.toLowerCase().contains(searchParam.value.toLowerCase()))) {
              foundItems[value.id] = value;
            }
          }

          switch(AppConfig.instance.appInUse) {
            case AppInUse.g:
              ///VERIFY IF IS A GOOD STRATEGY TO USE SEARCH ON SPOTIFY OR IF ITS JUST NOISE
              // Map<String, AppMediaItem> spotifySongs = await SpotifySearch.searchSongs(searchParam.value);
              // appMediaItems.addAll(spotifySongs);
              break;
            default:
              break;
          }

          AppConfig.logger.d("${foundItems.length} appMediaItems retrieved");
          break;
        case(MediaSearchType.playlist):
          ///NOT IN USE
          // itemlists.value = await NeomSpotifyController().searchPlaylists(searchParam.value);
          AppConfig.logger.d("${itemlists.length} playlists retrieved");
          break;

        case(MediaSearchType.book):
          if(totalReleaseItems.isEmpty) {
            totalReleaseItems.value = await AppReleaseItemFirestore().retrieveAll();
          }

          for (var value in totalReleaseItems.value.values) {
            if(value.name.toLowerCase().contains(searchParam.value.toLowerCase())
                || (value.ownerName.toLowerCase().contains(searchParam.value.toLowerCase()))) {
              foundItems[value.id] = value;
            }
          }

          foundExternalItems.value = await Sint.find<GoogleBookGatewayService>().searchBooksAsExternalItem(searchParam.value);

          for (var value in foundExternalItems.value.values) {
            if(value.name.toLowerCase().contains(searchParam.value)
                || (value.ownerName.toLowerCase().contains(searchParam.value))) {
              foundItems[value.id] = value;
            }
          }
          break;
        default:
          break;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.mediaItemSearch]);
  }

  @override
  void getAppMediaItemDetails(AppMediaItem appMediaItem) {
    AppConfig.logger.d("Sending appMediaItem with title ${appMediaItem.name} to item controller");
    AppUtilities.gotoItemDetails(appMediaItem);
  }

}
