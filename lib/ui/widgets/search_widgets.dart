import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/ui/widgets/giglist/giglist_preview_sheet.dart';
import 'package:neom_commons/ui/widgets/images/neom_image_card.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/external_utilities.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/api/app_accounts.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/app_hive_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:neom_core/utils/enums/external_media_source.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:sint/sint.dart';

import '../app_items/item_search_controller.dart';

/// Builds a single profile tile for search results.
/// Navigates to mateDetails route when tapped.
Widget buildMateTile(AppProfile mate, BuildContext context) {
  return mate.name.isNotEmpty && mate.isActive
      ? GestureDetector(
    child: ListTile(
      onTap: () => mate.id.isNotEmpty
          ? Sint.toNamed(AppRouteConstants.matePath(mate.id), arguments: mate.id)
          : {},
      leading: platformCircleAvatar(
        imageUrl: mate.photoUrl.isNotEmpty ? mate.photoUrl : AppProperties.getAppLogoUrl(),
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
        Sint.toNamed(AppFlavour.getMainItemDetailsRoute(appMediaItem.id), arguments: [appMediaItem]);
      }
      Sint.find<AppHiveService>().addQuery(appMediaItem.name);
    },
  );
}

/// Builds a release item tile for search results.
/// Routes to item details when tapped (or adds to Repertoire in Gigmeout itemSearch).
ListTile buildReleaseItemTile(BuildContext context, AppReleaseItem releaseItem) {
  final isGigmeout = AppConfig.instance.appInUse == AppInUse.g;
  return ListTile(
    contentPadding: const EdgeInsets.only(left: 15.0, right: 8.0),
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
    trailing: isGigmeout
        ? IconButton(
            tooltip: 'Agregar a Mi Repertorio',
            icon: Icon(Icons.playlist_add_circle_outlined, color: AppColor.getMain()),
            onPressed: () => showAddSongToRepertoireDialog(
              context,
              releaseItem: releaseItem,
            ),
          )
        : null,
    onTap: () {
      if (isGigmeout && Sint.isRegistered<ItemSearchController>()) {
        final ctrl = Sint.find<ItemSearchController>();
        if (ctrl.itemlist.id.isNotEmpty) {
          showAddSongToRepertoireDialog(
            context,
            releaseItem: releaseItem,
            preselectedList: ctrl.itemlist,
          );
          return;
        }
      }
      Sint.toNamed(AppFlavour.getMainItemDetailsRoute(releaseItem.id), arguments: [releaseItem]);
      if (Sint.isRegistered<AppHiveService>()) {
        Sint.find<AppHiveService>().addQuery(releaseItem.name);
      }
    },
  );
}

/// Builds an external item tile for search results (e.g., YouTube Music in Gigmeout, Google Books in EMXI).
ListTile buildExternalItemTile(BuildContext context, ExternalItem externalItem) {
  final isYoutubeSong = AppConfig.instance.appInUse == AppInUse.g &&
      (externalItem.source == ExternalSource.youtube ||
          externalItem.permaUrl.contains('youtube') ||
          externalItem.url.isEmpty);

  return ListTile(
    contentPadding: const EdgeInsets.only(left: 15.0, right: 8.0),
    title: Text(TextUtilities.getMediaName(externalItem.name),
      style: const TextStyle(fontWeight: FontWeight.w500,),
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Row(
      children: [
        if (isYoutubeSong) ...[
          const Icon(Icons.play_circle_outline, size: 14, color: Colors.redAccent),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            isYoutubeSong
                ? '${TextUtilities.getArtistName(externalItem.ownerName)} · YouTube Music'
                : TextUtilities.getArtistName(externalItem.ownerName),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    isThreeLine: false,
    leading: NeomImageCard(
      placeholderImage: const AssetImage(AppAssets.mainItemCover),
      imageUrl: externalItem.imgUrl
    ),
    trailing: isYoutubeSong
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Preview 30s (YouTube Music)',
                icon: const Icon(Icons.ondemand_video_rounded, size: 20, color: Colors.redAccent),
                onPressed: () {
                  Itemlist? preselected;
                  if (Sint.isRegistered<ItemSearchController>()) {
                    final ctrl = Sint.find<ItemSearchController>();
                    if (ctrl.itemlist.id.isNotEmpty &&
                        ctrl.itemlist.type == ItemlistType.giglist) {
                      preselected = ctrl.itemlist;
                    }
                  }
                  GiglistPreviewSheet.show(
                    context,
                    item: externalItem,
                    onAddToGiglist: () => showAddSongToRepertoireDialog(
                      context,
                      externalItem: externalItem,
                      preselectedList: preselected,
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Agregar a Giglist (Repertorio)',
                icon: Icon(Icons.playlist_add_circle_outlined, color: AppColor.getMain()),
                onPressed: () => showAddSongToRepertoireDialog(
                  context,
                  externalItem: externalItem,
                ),
              ),
            ],
          )
        : null,
    onTap: () {
      if (Sint.isRegistered<AppHiveService>()) {
        Sint.find<AppHiveService>().addQuery(externalItem.name);
      }
      if (isYoutubeSong) {
        Itemlist? preselected;
        if (Sint.isRegistered<ItemSearchController>()) {
          final ctrl = Sint.find<ItemSearchController>();
          if (ctrl.itemlist.id.isNotEmpty &&
              ctrl.itemlist.type == ItemlistType.giglist) {
            preselected = ctrl.itemlist;
          }
        }
        showAddSongToRepertoireDialog(
          context,
          externalItem: externalItem,
          preselectedList: preselected,
        );
        return;
      }
      Sint.toNamed(AppFlavour.getMainItemDetailsRoute(externalItem.id), arguments: [externalItem]);
    },
  );
}

Future<bool> showAddSongToRepertoireDialog(
  BuildContext context, {
  ExternalItem? externalItem,
  AppReleaseItem? releaseItem,
  Itemlist? preselectedList,
}) async {
  if (!AppConfig.instance.canPersistUserActivity) {
    AuthGuard.protect(
      context,
      () => showAddSongToRepertoireDialog(
        context,
        externalItem: externalItem,
        releaseItem: releaseItem,
        preselectedList: preselectedList,
      ),
    );
    return false;
  }

  final userService = Sint.find<UserService>();
  final profile = userService.profile;
  final itemlistRepo = ItemlistFirestore();

  Map<String, Itemlist> userLists = Map<String, Itemlist>.from(profile.itemlists ?? {});
  if (userLists.isEmpty && profile.id.isNotEmpty) {
    userLists = await itemlistRepo.getByOwnerId(profile.id);
    profile.itemlists = Map<String, Itemlist>.from(userLists);
  }

  final bool isExternalYoutube = externalItem != null;
  // External YouTube Music songs MUST belong strictly to Giglists
  // (`ItemlistType.giglist`), never to Gigmeout streaming Playlists.
  final modifiableLists = userLists.values.where((l) {
    if (!l.isModifiable) return false;
    if (isExternalYoutube) return l.type == ItemlistType.giglist;
    return l.type == ItemlistType.giglist || l.type == ItemlistType.playlist;
  }).toList();

  if (modifiableLists.isEmpty) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final defaultList = Itemlist(
      name: 'Mi Giglist',
      description: 'Canciones de mi repertorio (YouTube Music) para conectar con Songmates',
      ownerId: profile.id,
      ownerName: profile.name,
      type: ItemlistType.giglist,
      public: true,
      externalItems: [],
      createdTime: now,
      modifiedTime: now,
    );
    final newId = await itemlistRepo.insert(defaultList);
    if (newId.isNotEmpty) {
      defaultList.id = newId;
      modifiableLists.add(defaultList);
      profile.itemlists ??= {};
      profile.itemlists![newId] = defaultList;
    }
  }

  if (modifiableLists.isEmpty || !context.mounted) {
    AppUtilities.showSnackBar(
      title: 'Repertorio',
      message: 'No se pudo preparar tu lista de repertorio. Intenta de nuevo.',
    );
    return false;
  }

  String selectedListId = (preselectedList != null &&
          preselectedList.id.isNotEmpty &&
          modifiableLists.any((l) => l.id == preselectedList.id))
      ? preselectedList.id
      : modifiableLists.first.id;
  int masteryState = AppItemState.readyToPlay.value; // 5 by default for repertoire

  final songTitle = externalItem?.name ?? releaseItem?.name ?? '';
  final songArtist = externalItem?.ownerName ?? releaseItem?.ownerName ?? '';
  final songImg = externalItem?.imgUrl ?? releaseItem?.imgUrl ?? '';
  final ytUrl = externalItem?.permaUrl ?? '';

  final labels = <int, String>{
    1: '1 · La escuché / Me interesa',
    2: '2 · Aprendiéndola',
    3: '3 · En práctica / Ensayo',
    4: '4 · Lista para tocar en vivo',
    5: '5 · Dominada al 100% (Songmate Match)',
  };

  final added = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColor.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      bool saving = false;
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: songImg.isNotEmpty
                            ? platformNetworkImage(
                                imageUrl: songImg,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 52,
                                height: 52,
                                color: AppColor.getMain().withValues(alpha: 0.3),
                                child: const Icon(Icons.music_note, color: Colors.white70),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              songTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              songArtist,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (externalItem != null)
                        TextButton.icon(
                          onPressed: () => GiglistPreviewSheet.show(
                            ctx,
                            item: externalItem,
                          ),
                          icon: const Icon(Icons.ondemand_video_rounded, size: 16, color: Colors.redAccent),
                          label: const Text('Preview 30s', style: TextStyle(color: Colors.redAccent)),
                        )
                      else if (ytUrl.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => ExternalUtilities.launchURL(ytUrl, sameTab: false),
                          icon: const Icon(Icons.open_in_new, size: 16, color: Colors.redAccent),
                          label: const Text('YouTube', style: TextStyle(color: Colors.redAccent)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Nivel de dominio en tu repertorio',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: masteryState,
                    dropdownColor: AppColor.surfaceCard,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColor.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: labels.entries
                        .map((e) => DropdownMenuItem<int>(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (v) => setSheetState(() => masteryState = v ?? 5),
                  ),
                  if (modifiableLists.length > 1) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Lista / Repertorio destino',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedListId,
                      dropdownColor: AppColor.surfaceCard,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColor.surfaceCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: modifiableLists
                          .map((l) => DropdownMenuItem<String>(
                                value: l.id,
                                child: Text('${l.name} (${l.allItems.length})'),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedListId = v ?? selectedListId),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.getMain(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              setSheetState(() => saving = true);
                              bool ok = false;
                              String savedItemId = '';
                              if (externalItem != null) {
                                externalItem.state = masteryState;
                                ok = await itemlistRepo.addExternalItem(selectedListId, externalItem);
                                savedItemId = externalItem.id;
                                if (ok) {
                                  final target = profile.itemlists?[selectedListId];
                                  if (target != null) {
                                    target.externalItems ??= [];
                                    target.externalItems!.removeWhere((x) => x.id == externalItem.id);
                                    target.externalItems!.add(externalItem);
                                  }
                                }
                              } else if (releaseItem != null) {
                                releaseItem.state = masteryState;
                                ok = await itemlistRepo.addReleaseItem(selectedListId, releaseItem);
                                savedItemId = releaseItem.id;
                                if (ok) {
                                  final target = profile.itemlists?[selectedListId];
                                  if (target != null) {
                                    target.appReleaseItems ??= [];
                                    target.appReleaseItems!.removeWhere((x) => x.id == releaseItem.id);
                                    target.appReleaseItems!.add(releaseItem);
                                  }
                                }
                              }
                              if (ok && savedItemId.isNotEmpty && profile.id.isNotEmpty) {
                                profile.favoriteItems ??= [];
                                if (!profile.favoriteItems!.contains(savedItemId)) {
                                  profile.favoriteItems!.add(savedItemId);
                                }
                                try {
                                  await AppProfiles.repository.addFavoriteItem(profile.id, savedItemId);
                                } catch (_) {}
                              }
                              if (ctx.mounted) Navigator.of(ctx).pop(ok);
                            },
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.library_add_check_rounded),
                      label: Text(
                        saving ? 'Guardando...' : 'Agregar a Mi Repertorio',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (added == true) {
    AppUtilities.showSnackBar(
      title: 'Repertorio actualizado',
      message: '"$songTitle" ya forma parte de tu repertorio para conectar con Songmates.',
    );
    return true;
  }
  return false;
}
