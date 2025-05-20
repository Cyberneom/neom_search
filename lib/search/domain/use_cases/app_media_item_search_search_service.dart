import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';

///AppMediaItems Seach Controller
///Right now its looking at internal (AppFlavour.appInUse) and Spotify.
///Youtube in consideration.
abstract class AppMediaItemSearchService {

  Future<void> setSearchParam(String text);
  Future<void> searchAppMediaItem();
  void getAppMediaItemDetails(AppMediaItem appMediaItem);
  void getItemListDetails(Itemlist itemList);

}
