import 'package:get/get.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';
import 'search/ui/app_search_page.dart';
import 'search/ui/itemlist/app_media_item_search_page.dart';
import 'search/ui/itemlist/playlist_name_desc_page.dart';


class SearchRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRouteConstants.search,
      page: () => const AppSearchPage(),
    ),
    GetPage(
      name: AppRouteConstants.itemSearch,
      page: () => const AppMediaItemSearchPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.playlistSearch,
      page: () => const AppMediaItemSearchPage(),
      transition: Transition.zoom,
    ),
    GetPage(
        name: AppRouteConstants.playlistNameDesc,
        page: () => const PlaylistNameDescPage(),
        transition: Transition.leftToRight
    ),
  ];

}
