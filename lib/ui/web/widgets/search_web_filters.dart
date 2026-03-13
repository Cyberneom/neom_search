import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/web/web_hover_card.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/utils/enums/search_type.dart';
import 'package:sint/sint.dart';

class SearchWebFilters extends StatelessWidget {

  final SearchType activeFilter;
  final int profileCount;
  final int releaseCount;
  final int mediaCount;
  final ValueChanged<SearchType> onFilterChanged;

  const SearchWebFilters({
    super.key,
    required this.activeFilter,
    required this.profileCount,
    required this.releaseCount,
    required this.mediaCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Filters',
              style: TextStyle(
                color: AppColor.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _FilterItem(
            label: AppTranslationConstants.all.tr,
            count: profileCount + releaseCount + mediaCount,
            isActive: activeFilter == SearchType.any,
            onTap: () => onFilterChanged(SearchType.any),
          ),
          _FilterItem(
            label: AppTranslationConstants.profiles.tr,
            count: profileCount,
            isActive: activeFilter == SearchType.profiles,
            onTap: () => onFilterChanged(SearchType.profiles),
          ),
          _FilterItem(
            label: AppTranslationConstants.releases.tr,
            count: releaseCount,
            isActive: activeFilter == SearchType.releaseItems,
            onTap: () => onFilterChanged(SearchType.releaseItems),
          ),
          _FilterItem(
            label: AppTranslationConstants.audioLibrary.tr,
            count: mediaCount,
            isActive: activeFilter == SearchType.mediaItems,
            onTap: () => onFilterChanged(SearchType.mediaItems),
          ),
        ],
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterItem({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: WebHoverCard(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: isActive ? AppColor.bondiBlue75 : AppColor.bondiBlue.withAlpha(18),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        builder: (isHovered) => Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColor.textSecondary,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withAlpha(30) : AppColor.surfaceDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: AppColor.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
