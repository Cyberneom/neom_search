import 'package:get/get.dart';

import 'package:neom_commons/core/utils/constants/app_route_constants.dart';

import 'search/ui/app_search_page.dart';


class SearchRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRouteConstants.search,
      page: () => const AppSearchPage(),
    ),
  ];

}
