

import 'package:neom_core/domain/model/app_media_item.dart';

abstract class ItemSearchService {

  Future<void> setSearchParam(String text);
  Future<void> searchItems();
  void getAppMediaItemDetails(AppMediaItem appMediaItem);

}
