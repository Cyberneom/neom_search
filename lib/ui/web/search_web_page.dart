import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/web/web_keyboard_manager.dart';
import 'package:neom_core/utils/enums/search_type.dart';
import 'package:sint/sint.dart';

import '../app_search_controller.dart';
import 'widgets/search_web_bar.dart';
import 'widgets/search_web_filters.dart';
import 'widgets/search_web_results.dart';

class SearchWebPage extends StatefulWidget {

  final AppSearchController controller;

  const SearchWebPage({super.key, required this.controller});

  @override
  State<SearchWebPage> createState() => _SearchWebPageState();
}

class _SearchWebPageState extends State<SearchWebPage> {

  late SearchType _activeFilter;
  final _searchFocusNode = FocusNode();

  static const _filterCycle = [
    SearchType.any,
    SearchType.profiles,
    SearchType.releaseItems,
    SearchType.mediaItems,
  ];

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.controller.searchType;
  }

  void _cycleFilter() {
    final currentIdx = _filterCycle.indexOf(_activeFilter);
    final nextIdx = (currentIdx + 1) % _filterCycle.length;
    setState(() => _activeFilter = _filterCycle[nextIdx]);
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebKeyboardManager(
      pageId: 'search',
      pageShortcuts: {
        const SingleActivator(LogicalKeyboardKey.slash): () => _searchFocusNode.requestFocus(),
        const SingleActivator(LogicalKeyboardKey.tab): () => _cycleFilter(),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_searchFocusNode.hasFocus) {
            _searchFocusNode.unfocus();
          } else {
            Sint.back();
          }
        },
      },
      child: Scaffold(
      backgroundColor: AppFlavour.getBackgroundColor(),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: Obx(() => widget.controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SearchWebBar(controller: widget.controller, focusNode: _searchFocusNode),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Filters sidebar
                            SizedBox(
                              width: 240,
                              child: Obx(() => SearchWebFilters(
                                activeFilter: _activeFilter,
                                profileCount: widget.controller.sortedProfileLocation.value.length,
                                releaseCount: widget.controller.filteredReleaseItems.length,
                                mediaCount: widget.controller.filteredMediaItems.length,
                                onFilterChanged: (type) => setState(() => _activeFilter = type),
                              )),
                            ),
                            VerticalDivider(width: 1, color: AppColor.borderSubtle),
                            // Results
                            Expanded(
                              child: SearchWebResults(
                                controller: widget.controller,
                                activeFilter: _activeFilter,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
      ),
    );
  }
}
