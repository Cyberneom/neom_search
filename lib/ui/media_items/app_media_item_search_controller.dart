import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/band.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_google_books/google_books/data/api_services/google_books_api.dart';
import 'package:neom_google_books/google_books/domain/model/google_book.dart';
import 'package:neom_google_books/google_books/utils/google_book_mapper.dart';

import '../../domain/use_cases/app_media_item_search_service.dart';

class AppMediaItemSearchController extends GetxController implements AppMediaItemSearchService   {

  final userController = Get.find<UserController>();

  TextEditingController searchParamController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();

  final RxBool isLoading = true.obs;
  final RxMap<String, AppMediaItem> appMediaItems = <String, AppMediaItem>{}.obs;
  final RxMap<String, AppReleaseItem> appReleaseItems = <String, AppReleaseItem>{}.obs;
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

      profile = userController.profile;
      band = userController.band;
      ownerType = userController.itemlistOwner;
      itemlist.ownerType = ownerType;
      if(ownerType == OwnerType.profile) {
        itemlists.value = profile.itemlists ?? {};
      } else {
        itemlists.value = band.itemlists ?? {};
      }

      if(Get.arguments != null) {
        if(Get.arguments[0] is MediaSearchType) {
          searchType = Get.arguments[0] as MediaSearchType;
          if(Get.arguments.length == 2) {
            switch(searchType) {
              case(MediaSearchType.song):
                itemlist =  Get.arguments[1] as Itemlist;
                break;
              case(MediaSearchType.playlist):
                await initSearchParam(Get.arguments[1] as String);
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


  void clear() {
    appMediaItems.value.clear();
    appReleaseItems.value.clear();
  }

  Future<void> initSearchParam(String text) async {
    AppConfig.logger.d("initSearchParam");

    searchParam.value = text;
    searchParamController.text = text;

    try {
      await searchAppMediaItem();
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
      await searchAppMediaItem();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    update([AppPageIdConstants.mediaItemSearch]);
  }


  @override
  Future<void> searchAppMediaItem() async {
    AppConfig.logger.d("searchAppMediaItem");

    AppConfig.logger.d(searchParam);
    clear();
    try {
      switch(searchType) {
        case(MediaSearchType.song):

          if(AppConfig.instance.appInUse != AppInUse.e) {

            if(appMediaItems.isEmpty) {
              appMediaItems.value.addAll(await AppMediaItemFirestore().fetchAll(excludeTypes: [MediaItemType.pdf, MediaItemType.neomPreset]));
            }
            if(appReleaseItems.isEmpty) appReleaseItems.value = await AppReleaseItemFirestore().retrieveAll();

            for (var value in appReleaseItems.value.values) {
              appMediaItems[value.id] = AppMediaItemMapper.fromAppReleaseItem(value);
            }
          }

          appMediaItems.value.removeWhere((key, item) => !item.name.toLowerCase().contains(searchParam.value.toLowerCase())
              && !item.artist.toLowerCase().contains(searchParam.value.toLowerCase()));

          switch(AppConfig.instance.appInUse){
            case AppInUse.g:
              ///VERIFY IF IS A GOOD STRATEGY TO USE SEARCH ON SPOTIFY OR IF ITS JUST NOISE
              // Map<String, AppMediaItem> spotifySongs = await SpotifySearch.searchSongs(searchParam.value);
              // appMediaItems.addAll(spotifySongs);
              break;
            case AppInUse.e:
              break;
            case AppInUse.c:
            default:
              break;
          }

          AppConfig.logger.d("${appMediaItems.length} appMediaItems retrieved");
          break;
        case(MediaSearchType.playlist):
          ///NOT IN USE
          // itemlists.value = await NeomSpotifyController().searchPlaylists(searchParam.value);
          AppConfig.logger.d("${itemlists.length} playlists retrieved");
          break;

        case(MediaSearchType.book):
          if(appReleaseItems.isEmpty) {
            appReleaseItems.value = await AppReleaseItemFirestore().retrieveAll();
          }
          for (var value in appReleaseItems.value.values) {
            if(value.name.toLowerCase().contains(searchParam.value)
                || (value.ownerName.toLowerCase().contains(searchParam.value))) {
              appMediaItems[value.id] = AppMediaItemMapper.fromAppReleaseItem(value, itemType: MediaItemType.pdf);
            }
          }

          List<GoogleBook> googleBooks = await GoogleBooksAPI.searchBooks(searchParam.value);
          for (var googleBook in googleBooks) {
            AppMediaItem book = GoogleBookMapper.toAppMediaItem(googleBook);
            appMediaItems[book.id] = book;
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
    Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [appMediaItem]);
  }

  Map<String, AppMediaItem> loadItemsFromPlaylist(Itemlist itemlist){
    Map<String, AppMediaItem> gItems = {};

    itemlist.appMediaItems?.forEach((gItem) {
      AppConfig.logger.d(gItem.name);
      gItems[gItem.id] = gItem;
    });

    return gItems;
  }

}
