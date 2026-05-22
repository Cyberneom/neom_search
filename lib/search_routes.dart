import 'package:neom_core/ui/deferred_loader.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'ui/app_items/item_search_page.dart' deferred as itemSearch;
import 'ui/app_search_page.dart' deferred as appSearch;

class SearchRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.search,
      page: () => DeferredLoader(appSearch.loadLibrary, () => appSearch.AppSearchPage()),
    ),
    SintPage(
      name: AppRouteConstants.itemSearch,
      page: () => DeferredLoader(itemSearch.loadLibrary, () => itemSearch.ItemSearchPage()),
      transition: Transition.zoom,
    ),
  ];

}
