import 'package:neom_core/ui/deferred_loader.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'ui/app_items/item_search_page.dart' deferred as item_search;
import 'ui/app_search_page.dart' deferred as app_search;

class SearchRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.search,
      page: () => DeferredLoader(app_search.loadLibrary, () => app_search.AppSearchPage()),
    ),
    SintPage(
      name: AppRouteConstants.itemSearch,
      page: () => DeferredLoader(item_search.loadLibrary, () => item_search.ItemSearchPage()),
      transition: Transition.zoom,
    ),
  ];

}
