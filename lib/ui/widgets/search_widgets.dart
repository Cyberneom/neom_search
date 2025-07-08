import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/neom_image_card.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:neom_core/utils/enums/verification_level.dart';

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
              : AppProperties.getAppLogoUrl(),
          placeholder: (context, url) => const CircleAvatar(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) {
            AppConfig.logger.w("Error loading image: $error");
            return CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(AppProperties.getAppLogoUrl()),
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
    return buildMediaItemTile(context, mediaItem);
  }).toList();
}

List<Widget> buildReleaseTiles(AppSearchController controller, BuildContext context) {
  return controller.filteredReleaseItems.value.values.map((releaseItem) {
    AppMediaItem convertedMediaItem = AppMediaItemMapper.fromAppReleaseItem(releaseItem);
    return buildMediaItemTile(context, convertedMediaItem);
  }).toList();
}

ListTile buildMediaItemTile(BuildContext context, AppMediaItem appMediaItem,
    {Itemlist? itemlist, String query = ''}) {

  return ListTile(
    contentPadding: const EdgeInsets.only(left: 15.0,),
    title: Text(appMediaItem.name,
      style: const TextStyle(fontWeight: FontWeight.w500,),
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(TextUtilities.getArtistName(appMediaItem.artist),
      overflow: TextOverflow.ellipsis,
    ),
    isThreeLine: false,
    leading: NeomImageCard(
        placeholderImage: const AssetImage(AppAssets.audioPlayerCover),
        imageUrl: appMediaItem.imgUrl
    ),
    onTap: () {
      if(appMediaItem.type == MediaItemType.song) {
        Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [appMediaItem]);
      } else {
        Get.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [appMediaItem]);
      }
      AppHiveController().addQuery(appMediaItem.name);
    },
  );
}
