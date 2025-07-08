

import 'package:neom_core/domain/model/app_media_item.dart';

abstract class AppMediaItemSearchService {

  Future<void> setSearchParam(String text);
  Future<void> searchAppMediaItem();
  void getAppMediaItemDetails(AppMediaItem appMediaItem);

}
