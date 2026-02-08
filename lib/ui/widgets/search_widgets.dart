import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/images/neom_image_card.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/use_cases/app_hive_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:sint/sint.dart';

/// Builds a single profile tile for search results.
/// Navigates to mateDetails route when tapped.
Widget buildMateTile(AppProfile mate, BuildContext context) {
  return mate.name.isNotEmpty && mate.isActive
      ? GestureDetector(
    child: ListTile(
      onTap: () => mate.id.isNotEmpty
          ? Sint.toNamed(AppRouteConstants.mateDetails, arguments: mate.id)
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
  ) : const SizedBox.shrink();
}

/// Builds a media item tile for search results.
/// Routes to audio player for playable media, or item details for others.
ListTile buildMediaItemTile(BuildContext context, AppMediaItem appMediaItem) {
  return ListTile(
    contentPadding: const EdgeInsets.only(left: 15.0,),
    title: Text(TextUtilities.getMediaName(appMediaItem.name),
      style: const TextStyle(fontWeight: FontWeight.w500,),
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(TextUtilities.getArtistName(appMediaItem.ownerName),
      overflow: TextOverflow.ellipsis,
    ),
    isThreeLine: false,
    leading: NeomImageCard(
        placeholderImage: const AssetImage(AppAssets.mainItemCover),
        imageUrl: appMediaItem.imgUrl
    ),
    onTap: () {
      if(appMediaItem.type == MediaItemType.song
          || appMediaItem.type == MediaItemType.podcast
          || appMediaItem.type == MediaItemType.audiobook) {
        Sint.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [appMediaItem]);
      } else {
        Sint.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [appMediaItem]);
      }
      Sint.find<AppHiveService>().addQuery(appMediaItem.name);
    },
  );
}

/// Builds a release item tile for search results.
/// Routes to item details when tapped.
ListTile buildReleaseItemTile(BuildContext context, AppReleaseItem releaseItem) {
  return ListTile(
    contentPadding: const EdgeInsets.only(left: 15.0,),
    title: Text(TextUtilities.getMediaName(releaseItem.name),
      style: const TextStyle(fontWeight: FontWeight.w500,),
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(TextUtilities.getArtistName(releaseItem.ownerName),
      overflow: TextOverflow.ellipsis,
    ),
    isThreeLine: false,
    leading: NeomImageCard(
        placeholderImage: const AssetImage(AppAssets.mainItemCover),
        imageUrl: releaseItem.imgUrl
    ),
    onTap: () {
      Sint.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [releaseItem]);
      Sint.find<AppHiveService>().addQuery(releaseItem.name);
    },
  );
}

/// Builds an external item tile for search results (e.g., Google Books).
/// Routes to item details when tapped.
ListTile buildExternalItemTile(BuildContext context, ExternalItem externalItem) {
  return ListTile(
    contentPadding: const EdgeInsets.only(left: 15.0,),
    title: Text(TextUtilities.getMediaName(externalItem.name),
      style: const TextStyle(fontWeight: FontWeight.w500,),
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(TextUtilities.getArtistName(externalItem.ownerName),
      overflow: TextOverflow.ellipsis,
    ),
    isThreeLine: false,
    leading: NeomImageCard(
      placeholderImage: const AssetImage(AppAssets.mainItemCover),
      imageUrl: externalItem.imgUrl
    ),
    onTap: () {
      Sint.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [externalItem]);
      Sint.find<AppHiveService>().addQuery(externalItem.name);
    },
  );
}
