import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/collective.dart';
import 'package:neom_core/domain/model/collective_member.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/genre.dart';
import 'package:neom_core/domain/model/instrument.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/repository/itemlist_repository.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/mate_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_core/utils/enums/search_type.dart';
import 'package:neom_search/ui/app_search_controller.dart';
import 'package:neom_search/ui/web/widgets/search_web_filters.dart';
import 'package:neom_search/ui/widgets/search_widgets.dart';
import 'package:sint/sint.dart';

class _FakeFirebaseUser extends Fake implements fba.User {}

class _FakeLoginService extends Fake implements LoginService {
  @override
  AuthStatus getAuthStatus() => AuthStatus.loggedIn;

  @override
  fba.User get fbaUser => _FakeFirebaseUser();
}

class _FakeUserService extends Fake implements UserService {
  _FakeUserService({
    AppProfile? profile,
    Collective? collective,
    OwnerType itemlistOwnerType = OwnerType.profile,
  }) : _profile = profile ?? AppProfile(id: 'prof-1', name: 'Alice'),
       _collective = collective ?? Collective(id: 'band-1', name: 'Los Rayos'),
       _itemlistOwnerType = itemlistOwnerType;

  final AppUser _user = AppUser(id: 'u1', email: 'alice@example.com');
  AppProfile _profile;
  Collective _collective;
  OwnerType _itemlistOwnerType;

  @override
  AppUser get user => _user;

  @override
  AppProfile get profile => _profile;

  @override
  set profile(AppProfile value) => _profile = value;

  @override
  Collective get collective => _collective;

  @override
  set collective(Collective value) => _collective = value;

  @override
  OwnerType get itemlistOwnerType => _itemlistOwnerType;

  @override
  set itemlistOwnerType(OwnerType value) => _itemlistOwnerType = value;
}

class _FakeMateService extends Fake implements MateService {
  @override
  final Map<String, AppProfile> totalProfiles = {};
  @override
  final Map<String, AppProfile> profiles = {};
  @override
  final Map<String, AppProfile> mates = {};
  @override
  final Map<String, AppProfile> followingProfiles = {};
  @override
  final Map<String, AppProfile> followerProfiles = {};

  @override
  Future<void> loadProfiles({bool includeSelf = false, bool loadAll = false}) async {}
}

class _FakeItemlistRepo extends Fake implements ItemlistRepository {
  final Map<String, Itemlist> store = {};
  final List<Itemlist> inserted = [];
  final List<({String listId, ExternalItem item})> addedExternal = [];
  OwnerType? lastFetchedOwnerType;
  String? lastFetchedOwnerId;

  @override
  Future<Map<String, Itemlist>> fetchAll({
    bool onlyPublic = false,
    int maxLength = 50,
    String ownerId = '',
    String excludeFromProfileId = '',
    OwnerType ownerType = OwnerType.profile,
    ItemlistType? itemlistType,
    bool includeAllOwnerTypes = false,
  }) async {
    lastFetchedOwnerId = ownerId;
    lastFetchedOwnerType = ownerType;
    return Map<String, Itemlist>.fromEntries(
      store.entries.where((e) {
        final l = e.value;
        if (ownerId.isNotEmpty && l.ownerId != ownerId) return false;
        if (!includeAllOwnerTypes && l.ownerType != ownerType) return false;
        if (itemlistType != null && l.type != itemlistType) return false;
        return true;
      }),
    );
  }

  @override
  Future<String> insert(Itemlist itemlist) async {
    final id = 'created-${inserted.length + 1}';
    itemlist.id = id;
    inserted.add(itemlist);
    store[id] = itemlist;
    return id;
  }

  @override
  Future<bool> addExternalItem(String itemlistId, ExternalItem item) async {
    addedExternal.add((listId: itemlistId, item: item));
    return true;
  }
}

class _TestableSearchController extends AppSearchController {
  _TestableSearchController(this.stubCollectives);

  final Map<String, Collective> stubCollectives;

  @override
  Future<void> loadCollectives() async {
    collectives = Map<String, Collective>.from(stubCollectives);
    filterCollectives();
  }

  @override
  Future<void> loadMediaItems() async {}

  @override
  Future<void> loadReleaseItems() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppInUse prevApp;
  late bool prevGuest;

  setUp(() {
    prevApp = AppConfig.instance.appInUse;
    prevGuest = AppConfig.instance.isGuestMode;
    AppConfig.instance.appInUse = AppInUse.g;
    AppConfig.instance.isGuestMode = false;
    Sint.reset();
    Sint.testMode = true;
    Sint.put<LoginService>(_FakeLoginService());
  });

  tearDown(() {
    Sint.reset();
    Sint.testMode = false;
    AppConfig.instance.appInUse = prevApp;
    AppConfig.instance.isGuestMode = prevGuest;
  });

  group('resolveRepertoireTargetOwner & collective repertoire dialog', () {
    test('resolves collective owner from preselectedList or userService context', () {
      final userService = _FakeUserService(
        profile: AppProfile(id: 'p1', name: 'Solo'),
        collective: Collective(id: 'band-1', name: 'Los Rayos'),
        itemlistOwnerType: OwnerType.profile,
      );

      final bandList = Itemlist(
        id: 'gl-1',
        name: 'Band Giglist',
        ownerId: 'band-2',
        ownerName: 'Fuego Sur',
        ownerType: OwnerType.collective,
        type: ItemlistType.giglist,
      );

      final fromList = resolveRepertoireTargetOwner(
        userService: userService,
        preselectedList: bandList,
      );
      expect(fromList.ownerType, OwnerType.collective);
      expect(fromList.ownerId, 'band-2');
      expect(fromList.ownerName, 'Fuego Sur');

      userService.itemlistOwnerType = OwnerType.collective;
      final fromService = resolveRepertoireTargetOwner(userService: userService);
      expect(fromService.ownerType, OwnerType.collective);
      expect(fromService.ownerId, 'band-1');
      expect(fromService.ownerName, 'Los Rayos');

      userService.itemlistOwnerType = OwnerType.profile;
      final fallback = resolveRepertoireTargetOwner(userService: userService);
      expect(fallback.ownerType, OwnerType.profile);
      expect(fallback.ownerId, 'p1');
    });

    testWidgets('showAddSongToRepertoireDialog saves to collective Giglist without touching profile.favoriteItems', (tester) async {
      final profile = AppProfile(
        id: 'p1',
        name: 'Alice',
        favoriteItems: <String>[],
        itemlists: {
          'prof-gl': Itemlist(
            id: 'prof-gl',
            name: 'Mi Giglist',
            ownerId: 'p1',
            ownerName: 'Alice',
            ownerType: OwnerType.profile,
            type: ItemlistType.giglist,
          ),
        },
      );
      final band = Collective(id: 'band-1', name: 'Los Rayos');
      final bandGiglist = Itemlist(
        id: 'band-gl',
        name: 'Setlist Band',
        ownerId: 'band-1',
        ownerName: 'Los Rayos',
        ownerType: OwnerType.collective,
        type: ItemlistType.giglist,
        externalItems: [],
      );
      final repo = _FakeItemlistRepo()..store['band-gl'] = bandGiglist;
      final userService = _FakeUserService(
        profile: profile,
        collective: band,
        itemlistOwnerType: OwnerType.collective,
      );
      Sint.put<UserService>(userService);

      final song = ExternalItem(
        id: 'yt-song-1',
        name: 'Persiana Americana',
        ownerName: 'Soda Stereo',
      );

      bool? dialogResult;
      await tester.pumpWidget(
        SintMaterialApp(
          initialRoute: '/test',
          sintPages: [
            SintPage(
              name: '/test',
              page: () => Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () async {
                      dialogResult = await showAddSongToRepertoireDialog(
                        ctx,
                        externalItem: song,
                        preselectedList: bandGiglist,
                        itemlistRepository: repo,
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(repo.lastFetchedOwnerType, OwnerType.collective);
      expect(repo.lastFetchedOwnerId, 'band-1');

      await tester.tap(find.text('Agregar a Los Rayos'));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(dialogResult, isTrue);
      expect(repo.addedExternal.length, 1);
      expect(repo.addedExternal.first.listId, 'band-gl');
      expect(userService.collective.itemlists?['band-gl']?.externalItems?.any((e) => e.id == 'yt-song-1'), isTrue);
      // MUST NOT pollute personal profile favorites or personal lists
      expect(profile.favoriteItems, isEmpty);
      expect(profile.itemlists?['prof-gl']?.externalItems ?? const [], isEmpty);
    });

    testWidgets('showAddSongToRepertoireDialog creates new collective Giglist with collective ownerType when band has none', (tester) async {
      final profile = AppProfile(id: 'p1', name: 'Alice', favoriteItems: <String>[]);
      final band = Collective(id: 'band-77', name: 'Noche Azul');
      final repo = _FakeItemlistRepo();
      final userService = _FakeUserService(
        profile: profile,
        collective: band,
        itemlistOwnerType: OwnerType.collective,
      );
      Sint.put<UserService>(userService);

      final song = ExternalItem(id: 'yt-song-2', name: 'Lamento Boliviano', ownerName: 'Enanitos Verdes');

      await tester.pumpWidget(
        SintMaterialApp(
          initialRoute: '/test',
          sintPages: [
            SintPage(
              name: '/test',
              page: () => Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => showAddSongToRepertoireDialog(
                      ctx,
                      externalItem: song,
                      itemlistRepository: repo,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(repo.inserted.length, 1);
      final created = repo.inserted.first;
      expect(created.ownerType, OwnerType.collective);
      expect(created.ownerId, 'band-77');
      expect(created.ownerName, 'Noche Azul');
      expect(created.type, ItemlistType.giglist);
      expect(userService.collective.itemlists?.containsKey(created.id), isTrue);

      await tester.tap(find.text('Agregar a Noche Azul'));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(repo.addedExternal.single.listId, created.id);
      expect(profile.favoriteItems, isEmpty);
    });
  });

  group('AppSearchController Band/Collective search', () {
    test('filters collectives by name, description, genres, and member names/instruments', () async {
      Sint.put<UserService>(_FakeUserService());
      Sint.put<MateService>(_FakeMateService());

      final band1 = Collective(
        id: 'c1',
        name: 'Café Cósmico',
        description: 'Rock psicodélico en vivo',
        isActive: true,
      )
        ..genres = {'Indie Rock': Genre(name: 'Indie Rock')}
        ..members = {
          'm1': CollectiveMember(
            id: 'm1',
            name: 'Martín López',
            profileId: 'p-m1',
            instrument: Instrument(name: 'Batería'),
          ),
        };

      final band2 = Collective(
        id: 'c2',
        name: 'Jazz Quartet',
        description: 'Improvisación nocturna',
        isActive: true,
      )
        ..genres = {'Jazz': Genre(name: 'Jazz')}
        ..members = {
          'm2': CollectiveMember(
            id: 'm2',
            name: 'Elena Ruiz',
            profileId: 'p-m2',
            instrument: Instrument(name: 'Saxofón'),
          ),
        };

      final inactiveBand = Collective(
        id: 'c3',
        name: 'Old Band',
        isActive: false,
      );

      final ctrl = _TestableSearchController({
        'c1': band1,
        'c2': band2,
        'c3': inactiveBand,
      });
      addTearDown(ctrl.onClose);

      await ctrl.loadSearchInfo();
      expect(ctrl.filteredCollectives.keys, unorderedEquals(['c1', 'c2']));

      // Match by name (accent-insensitive)
      ctrl.searchParam.value = 'cafe';
      ctrl.filterCollectives();
      expect(ctrl.filteredCollectives.keys, ['c1']);

      // Match by description
      ctrl.searchParam.value = 'improvisacion';
      ctrl.filterCollectives();
      expect(ctrl.filteredCollectives.keys, ['c2']);

      // Match by genre
      ctrl.searchParam.value = 'indie';
      ctrl.filterCollectives();
      expect(ctrl.filteredCollectives.keys, ['c1']);

      // Match by member name
      ctrl.searchParam.value = 'elena';
      ctrl.filterCollectives();
      expect(ctrl.filteredCollectives.keys, ['c2']);

      // Match by member instrument
      ctrl.searchParam.value = 'bateria';
      ctrl.filterCollectives();
      expect(ctrl.filteredCollectives.keys, ['c1']);

      // Deep-link Spanish alias 'bandas'
      SintTestMode.setTestQueryParameters({'tipo': 'bandas'});
      ctrl.onReady();
      expect(ctrl.searchType, SearchType.collectives);
      expect(ctrl.selectedFilter.value, SearchType.collectives);
    });

    testWidgets('SearchWebFilters shows collectives filter and totals', (tester) async {
      final tapped = <SearchType>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchWebFilters(
              activeFilter: SearchType.any,
              profileCount: 2,
              collectiveCount: 4,
              releaseCount: 1,
              mediaCount: 0,
              onFilterChanged: tapped.add,
            ),
          ),
        ),
      );

      // Total = 2 + 4 + 1 + 0 = 7
      expect(find.text('7'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.text('4'));
      await tester.pump();
      expect(tapped, [SearchType.collectives]);
    });
  });
}
