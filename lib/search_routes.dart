import 'package:sint/sint.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'ui/app_items/item_search_page.dart';
import 'ui/app_search_page.dart';

class SearchRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.search,
      page: () => const AppSearchPage(),
    ),
    SintPage(
      name: AppRouteConstants.itemSearch,
      page: () => const ItemSearchPage(),
      transition: Transition.zoom,
    ),
  ];

}
