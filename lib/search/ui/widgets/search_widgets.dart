import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/profile_type.dart';
import 'package:neom_commons/core/utils/enums/verification_level.dart';
import 'package:neom_itemlists/itemlists/ui/widgets/app_item_widgets.dart';

import '../app_search_controller.dart';

List<Widget> buildMateTiles(List<AppProfile> mates, BuildContext context) {
  return mates.map((mate) {
    // Puedes reutilizar la lógica de buildMateSearchList para crear cada ListTile
    return mate.name.isNotEmpty && mate.isActive
        ? GestureDetector(
      child: ListTile(
        onTap: () => mate.id.isNotEmpty
            ? Get.toNamed(AppRouteConstants.mateDetails, arguments: mate.id)
            : {},
        leading: CachedNetworkImage(
          imageUrl: mate.photoUrl.isNotEmpty
              ? mate.photoUrl
              : AppFlavour.getAppLogoUrl(),
          placeholder: (context, url) => const CircleAvatar(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) {
            AppUtilities.logger.w("Error loading image: $error");
            return CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(AppFlavour.getAppLogoUrl()),
            );
          },
          imageBuilder: (context, imageProvider) => CircleAvatar(
            backgroundImage: imageProvider,
          ),
        ),
        title: Row(
          children: [
            Text(mate.name.capitalize),
            AppTheme.widthSpace5,
            if (mate.verificationLevel != VerificationLevel.none)
              AppFlavour.getVerificationIcon(mate.verificationLevel, size: 18)
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if(mate.mainFeature != ProfileType.general.name) Row(
              children: [
                Icon(AppFlavour.getAppItemIcon(), color: Colors.blueGrey, size: 15),
                AppTheme.widthSpace5,
                Text(mate.mainFeature.tr.capitalize),
              ],
            ),
            Row(
              children: [
                if (mate.address.isNotEmpty)
                  const Icon(Icons.location_on, color: Colors.blueGrey, size: 15),
                if (mate.address.isNotEmpty) AppTheme.widthSpace5,
                if (mate.address.isNotEmpty)
                  SizedBox(
                    width: AppTheme.fullWidth(context) * 0.66,
                    child: Text(mate.address.split(',').first),
                  ),
              ],
            ),
          ],
        ),
      ),
      onLongPress: () {},
    )
        : const SizedBox.shrink();
  }).toList();
}

List<Widget> buildMediaTiles(AppSearchController controller, BuildContext context) {
  return controller.filteredMediaItems.value.values.map((mediaItem) {
    return createCoolMediaItemTile(context, mediaItem);
  }).toList();
}

List<Widget> buildReleaseTiles(AppSearchController controller, BuildContext context) {
  return controller.filteredReleaseItems.value.values.map((releaseItem) {
    AppMediaItem converted = AppMediaItem.fromAppReleaseItem(releaseItem);
    return createMediaItemTile(context, converted);
  }).toList();
}
