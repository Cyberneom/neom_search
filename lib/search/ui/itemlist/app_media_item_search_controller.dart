import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/api_services/google_books/google_books_api.dart';
import 'package:neom_commons/core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/domain/model/band.dart';
import 'package:neom_commons/core/domain/model/google_book.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';
import 'package:neom_commons/core/utils/enums/itemlist_type.dart';
import 'package:neom_commons/core/utils/enums/media_item_type.dart';
import 'package:neom_commons/core/utils/enums/owner_type.dart';
import 'package:neom_commons/core/utils/enums/spotify_search_type.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
import 'package:neom_events/events/ui/event_details_controller.dart';
import 'package:neom_itemlists/itemlists/ui/app_media_item/app_media_item_controller.dart';
import 'package:neom_posts/posts/ui/upload/post_upload_controller.dart';

import '../../domain/use_cases/app_media_item_search_search_service.dart';

class AppMediaItemSearchController extends GetxController implements AppMediaItemSearchService   {
  
  final userController = Get.find<UserController>();
  final postUploadController = Get.put(PostUploadController());

  TextEditingController searchParamController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();

  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;
  final RxMap<String, AppMediaItem> appMediaItems = <String, AppMediaItem>{}.obs;
  final RxMap<String, AppReleaseItem> appReleaseItems = <String, AppReleaseItem>{}.obs;
  final RxMap<String, Itemlist> itemlists = <String, Itemlist>{}.obs;
  final RxList<AppMediaItem> addedItems = <AppMediaItem>[].obs;
  final RxString searchParam = "".obs;
  final RxString itemlistId = "".obs;
  final RxInt appItemState = 0.obs;
  final RxBool existsInItemlist = false.obs;
  final RxBool wasAdded = false.obs;

  AppProfile profile = AppProfile();
  Band band = Band();
  OwnerType ownerType = OwnerType.profile;
  Itemlist itemlist = Itemlist();
  AppMediaItem appMediaItem = AppMediaItem();
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
      AppUtilities.logger.e(e.toString());
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
    AppUtilities.logger.d("initSearchParam");

    searchParam.value = text;
    searchParamController.text = text;

    try {
      await searchAppMediaItem();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.mediaItemSearch]);
  }


  @override
  Future<void> setSearchParam(String text) async {
    AppUtilities.logger.d("Set SearchParam: $text");

    searchParam.value = text;
    try {
      await searchAppMediaItem();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    update([AppPageIdConstants.mediaItemSearch]);
  }


  @override
  Future<void> searchAppMediaItem() async {
    AppUtilities.logger.d("searchAppMediaItem");

    AppUtilities.logger.d(searchParam);
    clear();
    try {
      switch(searchType) {
        case(MediaSearchType.song):

          if(AppFlavour.appInUse != AppInUse.e) {

            if(appMediaItems.isEmpty) {
              appMediaItems.value.addAll(await AppMediaItemFirestore().fetchAll(excludeTypes: [MediaItemType.pdf, MediaItemType.neomPreset]));
            }
            if(appReleaseItems.isEmpty) appReleaseItems.value = await AppReleaseItemFirestore().retrieveAll();

            for (var value in appReleaseItems.value.values) {
              appMediaItems[value.id] = AppMediaItem.fromAppReleaseItem(value);
            }
          }

          appMediaItems.value.removeWhere((key, item) => !item.name.toLowerCase().contains(searchParam.value.toLowerCase())
              && !item.artist.toLowerCase().contains(searchParam.value.toLowerCase()));

          switch(AppFlavour.appInUse){
            case AppInUse.g:
              ///VERIFY IF IS A GOOD STRATEGY TO USE SEARCH ON SPOTIFY OR IF ITS JUST NOISE
              // Map<String, AppMediaItem> spotifySongs = await SpotifySearch.searchSongs(searchParam.value);
              // appMediaItems.addAll(spotifySongs);
              break;
            case AppInUse.e:
              break;
            case AppInUse.c:
              break;
          }

          AppUtilities.logger.d("${appMediaItems.length} appMediaItems retrieved");
          break;
        case(MediaSearchType.playlist):
          ///NOT IN USE
          // itemlists.value = await NeomSpotifyController().searchPlaylists(searchParam.value);
          AppUtilities.logger.d("${itemlists.length} playlists retrieved");
          break;

        case(MediaSearchType.book):
          if(appReleaseItems.isEmpty) {
            appReleaseItems.value = await AppReleaseItemFirestore().retrieveAll();
          }
          for (var value in appReleaseItems.value.values) {
            if(value.name.toLowerCase().contains(searchParam.value)
                || (value.ownerName.toLowerCase().contains(searchParam.value))) {
              appMediaItems[value.id] = AppMediaItem.fromAppReleaseItem(value, itemType: MediaItemType.pdf);
            }
          }

          List<GoogleBook> googleBooks = await GoogleBooksApi.searchBooks(searchParam.value);
          for (var googleBook in googleBooks) {
            AppMediaItem book = AppMediaItem.fromGoogleBook(googleBook);
            appMediaItems[book.id] = book;
          }
          break;
        default:
          break;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.mediaItemSearch]);
  }


  void handleItemlistItems(AppMediaItem appMediaItem, AppItemState appItemState) {
    AppUtilities.logger.d("handleItemlistItems");

    try {
      if (addedItems.contains(appMediaItem) && appMediaItem.state == appItemState.value) {
        AppUtilities.logger.d("Removing item with name ${appMediaItem.name} from itemlist");
        setItemState(appMediaItem.id, AppItemState.noState );
        addedItems.remove(appMediaItem);
      } else {
        AppUtilities.logger.d("Adding item with name ${appMediaItem.name} to itemlist");
        addedItems.add(appMediaItem);
        setItemState(appMediaItem.id, appItemState);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.playlistSong]);
  }

  void setItemState(String itemId, AppItemState newState){
    AppUtilities.logger.d("Setting new itemState $newState");
    update([AppPageIdConstants.itemlistItem, AppPageIdConstants.appMediaItem, AppPageIdConstants.playlistSong]);
  }

  @override
  void getAppMediaItemDetails(AppMediaItem appMediaItem) {
    AppUtilities.logger.d("Sending appMediaItem with title ${appMediaItem.name} to item controller");

    ///DEPRECATED - VERIFY IF CORRECT
    // PageRouteBuilder(
    //   pageBuilder: (_, __, ___) => MediaPlayerPage(appMediaItem: appMediaItem), opaque: false,
    // );
    Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [appMediaItem]);

    ///DEPRECATED
    // NeomPlayerInvoke.init(
    //   appMediaItems: [appMediaItem],
    //   index: 0, isOffline: false,
    // );
    // Get.back();
    // Get.toNamed(AppFlavour.getItemDetailsRoute(), arguments: [appMediaItem, itemlist.id]);

  }


  @override
  void getItemListDetails(Itemlist playlist) {
    AppUtilities.logger.d("Going to itemlist with name ${playlist.name}");

    if(itemlist.name != playlist.name) {
      addedItems.clear();
    }
    itemlist = playlist;
    //items = loadItemsFromPlaylist(playlist);
    nameController.text = playlist.name;
    descController.text = playlist.description;
    Get.toNamed(AppRouteConstants.playlistItems);
  }

  Map<String, AppMediaItem> loadItemsFromPlaylist(Itemlist itemlist){
    Map<String, AppMediaItem> gItems = {};

    itemlist.appMediaItems?.forEach((gItem) {
      AppUtilities.logger.d(gItem.name);
      gItems[gItem.id] = gItem;
    });

    return gItems;
  }


  void setItemlistName() {
    AppUtilities.logger.d("setItemlistName");
    itemlist.name = nameController.text.trim();
    update([AppPageIdConstants.playlistNameDesc]);
  }


  void setItemlistDesc() {
    AppUtilities.logger.d("setItemlistDesc");
    itemlist.description = descController.text.trim();
    update([AppPageIdConstants.playlistNameDesc]);
  }


  void addItemlistImage() async {
    AppUtilities.logger.d("addItemlistImage");
    try {
      await postUploadController.handleImage();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.playlistNameDesc]);
  }


  void clearItemlistImage() async {
    AppUtilities.logger.d("clearItemlistImage");
    try {
      postUploadController.clearMedia();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.playlistNameDesc]);
  }


  bool validateNameDesc(){
    return nameController.text.isEmpty ? false :
    descController.text.isEmpty ? false : true;
  }

  Future<void> createItemlist() async {
    isButtonDisabled.value = true;
    isLoading.value = true;
    update([AppPageIdConstants.playlistNameDesc]);
    itemlist.appMediaItems = addedItems;

    try {
      if(postUploadController.mediaFile.value.path.isNotEmpty) {
        String itemlistImgUrl = await postUploadController.handleUploadImage(UploadImageType.itemlist);
        if(itemlistImgUrl.isNotEmpty) {
          itemlist.imgUrl = itemlistImgUrl;
        }
      }

      String itemlistId = "";
      if(itemlist.ownerType == OwnerType.profile) {
        itemlist.ownerId = profile.id;
        itemlist.ownerName = profile.name;
      } else if(itemlist.ownerType == OwnerType.band) {
        itemlist.ownerId = band.id;
        itemlist.ownerName = band.name;
      }

      itemlistId = await ItemlistFirestore().insert(itemlist);

      AppUtilities.logger.d("Itemlist inserted with id $itemlistId");

      if(itemlistId.isNotEmpty) {
        itemlist.id = itemlistId;

        if(ownerType == OwnerType.profile) {
          userController.profile.itemlists![itemlist.id] = itemlist;

          List<String> appMediaItemsIds = itemlist.appMediaItems!.map((e) => e.id).toList();
          if(await ProfileFirestore().addFavoriteItems(profile.id, appMediaItemsIds)) {
            for (var itemId in appMediaItemsIds) {
              if (userController.profile.favoriteItems != null) {
                AppUtilities.logger.d("Adding item to global state items for profile from userController");
                userController.profile.favoriteItems!.add(itemId);
              }
            }
          }
        } else if(ownerType == OwnerType.band) {
          userController.band.itemlists![itemlist.id] = itemlist;
        }

        for (AppMediaItem appMediaItem in itemlist.appMediaItems ?? []) {
          AppMediaItemFirestore().existsOrInsert(appMediaItem);
        }

        AppUtilities.logger.d("Items added successfully from Itemlist");
      }
      isButtonDisabled.value = false;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    if(ownerType == OwnerType.profile) {
      Get.offAllNamed(AppRouteConstants.home);
    } else if(ownerType == OwnerType.band) {
      Get.offAllNamed(AppRouteConstants.home);
    }

    update();
  }

  void setAppItemState(AppItemState newState){
    AppUtilities.logger.d("Setting new appItemState $newState");
    appItemState.value = newState.value;
    update([AppPageIdConstants.appItemDetails]);
  }

  void setSelectedItemlist(String selectedItemlist){
    AppUtilities.logger.d("Setting selectedItemlist $selectedItemlist");
    itemlistId.value  = selectedItemlist;
    existsInItemlist.value = itemAlreadyInList();
    update([AppPageIdConstants.appItemDetails]);
  }


  Future<void> addItemlistItem(BuildContext context, {int fanItemState = 0, bool goHome = true}) async {
    AppUtilities.logger.t("addItemlistItem ${appMediaItem.id}");

    
    if(existsInItemlist.value) {
      AppUtilities.showSnackBar(message: '"${appMediaItem.name}" ${AppTranslationConstants.isAlreadyInPlaylist.tr} ${itemlist.name}');
    } else if(!isButtonDisabled.value) {
      isButtonDisabled.value = true;
      isLoading.value = true;
      update([AppPageIdConstants.appItemDetails]);
      AppUtilities.logger.i("AppMediaItem ${appMediaItem.name} would be added as $appItemState for Itemlist $itemlistId");

      try {

        if(fanItemState > 0) appItemState.value = fanItemState;
        if(itemlistId.isEmpty) itemlistId.value = itemlists.values.first.id;

        AppMediaItemController appMediaItemController;
        if (Get.isRegistered<AppMediaItemController>()) {
          appMediaItemController = Get.find<AppMediaItemController>();
        } else {
          appMediaItemController = Get.put(AppMediaItemController());
        }

        AppMediaItemFirestore().existsOrInsert(appMediaItem);

        if(!existsInItemlist.value) {
          appMediaItem.state = appItemState.value;
          if(await appMediaItemController.addItemToItemlist(appMediaItem, itemlistId.value)){
            AppUtilities.logger.d("Setting existsInItemlist and wasAdded true");
            existsInItemlist.value = true;
            wasAdded.value = true;
          }
        }

      } catch (e) {
        AppUtilities.logger.d(e.toString());
      }

      update([AppPageIdConstants.itemlistItem,
        AppPageIdConstants.itemlist,
        AppPageIdConstants.appItemDetails,
        AppPageIdConstants.profile]);

      try {
        if(ownerType == OwnerType.profile) {
          if(Get.isRegistered<EventDetailsController>()) {
            Get.find<EventDetailsController>().addToMatchedItems(appMediaItem);
            Navigator.pop(context);
          } else {
            if(goHome) {
              Get.offAllNamed(AppRouteConstants.home);
            } else {
              Navigator.pop(context);
            }
          }
        } else {
          if(goHome) {
            Get.offAllNamed(AppRouteConstants.home);
          } else {
            Navigator.pop(context);
          }
        }

        AppUtilities.showSnackBar(
          message: '"${appMediaItem.name}" ${AppTranslationConstants.wasAddedToItemList.tr}.'
        );
      } catch (e) {
        Get.offAllNamed(AppRouteConstants.home);
        Get.toNamed(AppRouteConstants.listItems);
      }
    }

  }

  bool itemAlreadyInList() {
    AppUtilities.logger.d("Verifying if item already exists in itemlists");
    bool itemAlreadyInList = false;

    itemlists.forEach((key, iList) {
      for (AppMediaItem item in iList.appMediaItems ?? []) {
        if (item.id == appMediaItem.id) {
          itemAlreadyInList = true;
          appMediaItem.state = item.state;
          itemlistId.value = iList.id;
        }
      }
    });

    AppUtilities.logger.d("Item already exists in itemlists: $itemAlreadyInList");
    return itemAlreadyInList;
  }

  Future<Itemlist> createBasicItemlist() async {
    Itemlist newItemlist = Itemlist.createBasic(AppTranslationConstants.myFirstPlaylist.tr, AppTranslationConstants.myFirstPlaylistDesc.tr,
        profile.id, profile.name, ItemlistType.playlist);

    String listId = await ItemlistFirestore().insert(newItemlist);
    newItemlist.id = listId;

    return newItemlist;
  }

}
