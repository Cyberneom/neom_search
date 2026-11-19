import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/collective.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/google_book_gateway_service.dart';
import 'package:neom_core/domain/use_cases/mate_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:neom_core/utils/enums/search_type.dart';
import 'package:neom_search/ui/app_items/item_search_controller.dart';
import 'package:neom_search/ui/app_search_controller.dart';
import 'package:neom_search/ui/web/widgets/search_web_filters.dart';
import 'package:neom_search/utils/constants/search_constants.dart';
import 'package:sint/sint.dart';

Position _pos(double lat, double lng) {
  return Position(
    longitude: lng,
    latitude: lat,
    timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    accuracy: 5.0,
    altitude: 0.0,
    altitudeAccuracy: 1.0,
    heading: 0.0,
    headingAccuracy: 1.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
}

AppProfile _buildProfile({
  required String id,
  required String name,
  String email = 'user@example.com',
  String mainFeature = '',
  String address = '',
  Position? position,
}) {
  final p = AppProfile(
    id: id,
    name: name,
    mainFeature: mainFeature,
    address: address,
    position: position,
  );
  p.email = email;
  return p;
}

class _FakeUserService implements UserService {
  _FakeUserService({
    AppUser? user,
    AppProfile? profile,
    Collective? collective,
    OwnerType itemlistOwnerType = OwnerType.profile,
  })  : _user = user ?? AppUser(id: 'u1', email: 'me@example.com'),
        _profile = profile ?? _buildProfile(id: 'self', name: 'Self'),
        _collective = collective ?? Collective(id: 'col1', name: 'Band'),
        _itemlistOwnerType = itemlistOwnerType;

  AppUser _user;
  AppProfile _profile;
  Collective _collective;
  OwnerType _itemlistOwnerType;

  @override
  AppUser get user => _user;

  @override
  set user(AppUser value) => _user = value;

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

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeMateService implements MateService {
  _FakeMateService({
    Map<String, AppProfile>? totalProfiles,
    Map<String, AppProfile>? profiles,
    Map<String, AppProfile>? mates,
    Map<String, AppProfile>? followingProfiles,
    Map<String, AppProfile>? followerProfiles,
    this.onLoadProfiles,
  })  : totalProfiles = totalProfiles ?? <String, AppProfile>{},
        profiles = profiles ?? <String, AppProfile>{},
        mates = mates ?? <String, AppProfile>{},
        followingProfiles = followingProfiles ?? <String, AppProfile>{},
        followerProfiles = followerProfiles ?? <String, AppProfile>{};

  @override
  final Map<String, AppProfile> totalProfiles;

  @override
  final Map<String, AppProfile> profiles;

  @override
  final Map<String, AppProfile> mates;

  @override
  final Map<String, AppProfile> followingProfiles;

  @override
  final Map<String, AppProfile> followerProfiles;

  final void Function()? onLoadProfiles;
  int loadProfilesCalls = 0;

  @override
  Future<void> loadProfiles({bool includeSelf = false, bool loadAll = false}) async {
    loadProfilesCalls++;
    onLoadProfiles?.call();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeGoogleBookGatewayService implements GoogleBookGatewayService {
  _FakeGoogleBookGatewayService(this.results);

  final Map<String, ExternalItem> results;
  final List<String> queries = <String>[];

  @override
  Future<Map<String, ExternalItem>> searchBooksAsExternalItem(String param) async {
    queries.add(param);
    return results;
  }
}

/// Test double overriding only Firestore loaders so `onInit`/`loadSearchInfo`
/// run deterministically in-memory with zero Firebase calls.
class _TestableAppSearchController extends AppSearchController {
  _TestableAppSearchController({
    this.stubMediaItems = const <String, AppMediaItem>{},
    this.stubReleaseItems = const <String, AppReleaseItem>{},
  });

  final Map<String, AppMediaItem> stubMediaItems;
  final Map<String, AppReleaseItem> stubReleaseItems;

  @override
  Future<void> loadMediaItems() async {
    mediaItems = Map<String, AppMediaItem>.from(stubMediaItems);
    filterMediaItems();
  }

  @override
  Future<void> loadReleaseItems() async {
    releaseItems = Map<String, AppReleaseItem>.from(stubReleaseItems);
    filterReleaseItems();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSearchController filtering, normalization, and domain exclusions', () {
    late _TestableAppSearchController controller;
    late _FakeMateService mateService;
    late _FakeUserService userService;

    setUp(() {
      Sint.reset();
      Sint.testMode = true;

      userService = _FakeUserService(
        profile: _buildProfile(
          id: 'self',
          name: 'Current User',
          position: _pos(19.4326, -99.1332), // CDMX
        ),
      );
      mateService = _FakeMateService(
        totalProfiles: <String, AppProfile>{
          'p1': _buildProfile(
            id: 'p1',
            name: 'José Martínez',
            email: 'jose@example.com',
            mainFeature: 'Guitarra',
            address: 'Guadalajara',
            position: _pos(20.6597, -103.3496), // ~460 km
          ),
          'p2': _buildProfile(
            id: 'p2',
            name: 'Mónica Peña',
            email: 'monica@example.com',
            mainFeature: 'Violín',
            address: 'Ciudad de México',
            position: _pos(19.4350, -99.1400), // ~1 km
          ),
          'internal1': _buildProfile(
            id: 'internal1',
            name: 'Staff Emxi',
            email: 'ops@emxi.org ',
          ),
          'internal2': _buildProfile(
            id: 'internal2',
            name: 'Staff Gigmeout',
            email: 'ADMIN@GIGMEOUT.COM',
          ),
          'internal3': _buildProfile(
            id: 'internal3',
            name: 'Staff Cyberneom',
            email: 'bot@cyberneom.xyz',
          ),
        },
        mates: <String, AppProfile>{
          'p3': _buildProfile(
            id: 'p3',
            name: 'Álvaro Núñez',
            email: 'alvaro@example.com',
            mainFeature: 'Batería',
            address: 'Monterrey',
          ),
        },
      );

      Sint.put<UserService>(userService);
      Sint.put<MateService>(mateService);

      controller = _TestableAppSearchController(
        stubMediaItems: <String, AppMediaItem>{
          'm1': AppMediaItem(
            id: 'm1',
            name: 'Canción del Alba',
            ownerName: 'Belén Ortiz',
          ),
          'm2': AppMediaItem(
            id: 'm2',
            name: 'Midnight Jazz',
            ownerName: 'Miles Trio',
          ),
        },
        stubReleaseItems: <String, AppReleaseItem>{
          'r1': AppReleaseItem(
            id: 'r1',
            name: 'Crónicas de Otoño',
            ownerName: 'Sofía Méndez',
            categories: <String>['Poesía', 'Ficción'],
          ),
          'r2': AppReleaseItem(
            id: 'r2',
            name: 'Acoustic Sessions',
            ownerName: 'The Band',
            categories: <String>['Indie Rock'],
          ),
        },
      );
    });

    tearDown(() {
      controller.onClose();
      Sint.reset();
    });

    test('filterProfiles merges profile sources and always excludes internal staff domains', () {
      controller.searchParam.value = '';
      controller.filterProfiles();

      expect(controller.filteredProfiles.keys, unorderedEquals(<String>['p1', 'p2', 'p3']));
      expect(controller.filteredProfiles.containsKey('internal1'), isFalse);
      expect(controller.filteredProfiles.containsKey('internal2'), isFalse);
      expect(controller.filteredProfiles.containsKey('internal3'), isFalse);
    });

    test('filterProfiles handles accented queries and respects onlyByName flag', () {
      controller.searchParam.value = 'jose';
      controller.filterProfiles(onlyByName: true);
      expect(controller.filteredProfiles.keys, <String>['p1']);

      // onlyByName=true ignores mainFeature and address
      controller.searchParam.value = 'guitarra';
      controller.filterProfiles(onlyByName: true);
      expect(controller.filteredProfiles, isEmpty);

      // onlyByName=false matches mainFeature and address
      controller.filterProfiles(onlyByName: false);
      expect(controller.filteredProfiles.keys, <String>['p1']);

      controller.searchParam.value = 'monterrey';
      controller.filterProfiles(onlyByName: false);
      expect(controller.filteredProfiles.keys, <String>['p3']);

      // Special characters do not throw and safely yield empty match
      controller.searchParam.value = r'🎸+*?()[]^$';
      controller.filterProfiles(onlyByName: false);
      expect(controller.filteredProfiles, isEmpty);
    });

    test('filterMediaItems and filterReleaseItems normalize accents across name, owner, and categories', () async {
      await controller.loadMediaItems();
      await controller.loadReleaseItems();

      expect(controller.filteredMediaItems.length, 2);
      expect(controller.filteredReleaseItems.length, 2);

      // Accented media title
      controller.searchParam.value = 'cancion';
      controller.filterMediaItems();
      expect(controller.filteredMediaItems.keys, <String>['m1']);

      // Accented media owner
      controller.searchParam.value = 'belen';
      controller.filterMediaItems();
      expect(controller.filteredMediaItems.keys, <String>['m1']);

      // Release category match (accented)
      controller.searchParam.value = 'poesia';
      controller.filterReleaseItems();
      expect(controller.filteredReleaseItems.keys, <String>['r1']);

      // Release owner match
      controller.searchParam.value = 'sofia';
      controller.filterReleaseItems();
      expect(controller.filteredReleaseItems.keys, <String>['r1']);

      // Empty query restores full collections
      controller.searchParam.value = '';
      controller.filterMediaItems();
      controller.filterReleaseItems();
      expect(controller.filteredMediaItems.length, 2);
      expect(controller.filteredReleaseItems.length, 2);
    });

    test('sortByLocation orders nearby before distant and appends no-position profiles alphabetically', () {
      mateService.mates['p4'] = _buildProfile(
        id: 'p4',
        name: 'Beatriz WithoutPos',
        position: null,
      );
      mateService.mates['p5'] = _buildProfile(
        id: 'p5',
        name: 'Carlos NaNPos',
        position: _pos(double.nan, double.infinity),
      );

      controller.searchParam.value = '';
      controller.filterProfiles();
      controller.sortByLocation();

      expect(controller.hasUserPosition, isTrue);
      final orderedIds = controller.sortedProfileLocation.value.values.map((p) => p.id).toList();
      // p2 (~1 km) before p1 (~460 km), then non-positioned alphabetically: Beatriz, Carlos, Álvaro
      expect(orderedIds.sublist(0, 2), <String>['p2', 'p1']);
      expect(orderedIds.sublist(2), <String>['p4', 'p5', 'p3']);
    });

    test('sortByLocation falls back to alphabetical order when user has no geolocation and handles empty results', () {
      userService.profile.position = null;
      expect(controller.hasUserPosition, isFalse);

      controller.searchParam.value = '';
      controller.filterProfiles();
      controller.sortByLocation();

      final names = controller.sortedProfileLocation.value.values.map((p) => p.name).toList();
      expect(names, <String>['José Martínez', 'Mónica Peña', 'Álvaro Núñez']);

      // Empty filtered profiles clears sortedProfileLocation
      controller.searchParam.value = 'no_match_xyz';
      controller.filterProfiles();
      controller.sortByLocation();
      expect(controller.sortedProfileLocation.value, isEmpty);
    });

    test('loadProfiles triggers MateService.loadProfiles when caches are empty', () async {
      final emptyMates = _FakeMateService(
        onLoadProfiles: () {},
      );
      controller.mateServiceImpl = emptyMates;

      await controller.loadProfiles(includeSelf: true);
      expect(emptyMates.loadProfilesCalls, 1);
    });
  });

  group('AppSearchController pagination, debounce, arguments, and deep links', () {
    late _TestableAppSearchController controller;
    var isClosed = false;

    setUp(() {
      Sint.reset();
      Sint.testMode = true;
      Sint.put<UserService>(_FakeUserService());
      Sint.put<MateService>(
        _FakeMateService(
          totalProfiles: <String, AppProfile>{
            'p1': _buildProfile(id: 'p1', name: 'Carlos Santana'),
            'p2': _buildProfile(id: 'p2', name: 'Clara Schumann'),
          },
        ),
      );
      controller = _TestableAppSearchController(
        stubMediaItems: <String, AppMediaItem>{
          'm1': AppMediaItem(id: 'm1', name: 'Samba Pa Ti', ownerName: 'Carlos Santana'),
        },
      );
      isClosed = false;
    });

    tearDown(() {
      if (!isClosed) {
        controller.onClose();
      }
      Sint.reset();
    });

    test('showMoreResults and getChildTypeCount clamp bounds, accumulate, and reset across SearchType switches', () {
      // Length <= itemsQty returns exact length
      expect(controller.getChildTypeCount(0, SearchType.profiles), 0);
      expect(controller.getChildTypeCount(3, SearchType.profiles), 3);
      expect(controller.getChildTypeCount(SearchConstants.itemsQty, SearchType.profiles), 4);

      // Length > itemsQty caps at itemsQty until showMoreResults is called for that type
      expect(controller.getChildTypeCount(25, SearchType.profiles), 4);

      controller.showMoreResults(SearchType.profiles, qty: 10);
      expect(controller.moreResultsType.value, SearchType.profiles);
      expect(controller.moreResultsQty.value, 10);
      expect(controller.getChildTypeCount(25, SearchType.profiles), 14);
      expect(controller.getChildTypeCount(25, SearchType.mediaItems), 4);

      // Accumulating same type respects total length cap
      controller.showMoreResults(SearchType.profiles, qty: 20);
      expect(controller.moreResultsQty.value, 30);
      expect(controller.getChildTypeCount(25, SearchType.profiles), 25);

      // Clamps qty to [1, 200]
      controller.showMoreResults(SearchType.mediaItems, qty: 0);
      expect(controller.moreResultsType.value, SearchType.mediaItems);
      expect(controller.moreResultsQty.value, 1);

      controller.showMoreResults(SearchType.releaseItems, qty: 500);
      expect(controller.moreResultsQty.value, 200);

      // Caps cumulative total at 10000
      controller.moreResultsQty.value = 9950;
      controller.showMoreResults(SearchType.releaseItems, qty: 100);
      expect(controller.moreResultsQty.value, 10000);
    });

    test('onInit reads SearchType from direct or list arguments and finishes loading', () async {
      SintTestMode.setTestArguments(<dynamic>[SearchType.releaseItems]);
      controller.onInit();
      expect(controller.searchType, SearchType.releaseItems);

      await controller.loadSearchInfo();
      expect(controller.isLoading, isFalse);
      expect(controller.filteredMediaItems.length, 1);
    });

    test('setSearchParam debounces 300ms, cancels superseded queries, and ignores calls after onClose', () {
      fakeAsync((FakeAsync async) {
        controller.mediaItems = <String, AppMediaItem>{
          'm1': AppMediaItem(id: 'm1', name: 'Canción Solar', ownerName: 'Carlos'),
          'm2': AppMediaItem(id: 'm2', name: 'Lunar Echo', ownerName: 'Clara'),
        };

        controller.setSearchParam('lunar');
        async.elapse(const Duration(milliseconds: 150));
        // Not applied yet
        expect(controller.searchParam.value, '');

        // Superseded before 300ms elapsed
        controller.setSearchParam('  <think>hidden</think> Canción  ');
        async.elapse(const Duration(milliseconds: 200));
        expect(controller.searchParam.value, '');

        async.elapse(const Duration(milliseconds: 100));
        expect(controller.searchParam.value, 'Cancion');
        expect(controller.filteredMediaItems.keys, <String>['m1']);

        // Pending timer is cancelled cleanly on onClose, and post-close calls are no-ops
        controller.setSearchParam('lunar');
        controller.onClose();
        isClosed = true;
        async.elapse(const Duration(milliseconds: 500));
        controller.setSearchParam('ignored');
      });
    });

    test('onReady maps Spanish/English deep-link type aliases and schedules sanitized initial query', () {
      fakeAsync((FakeAsync async) {
        SintTestMode.setTestQueryParameters(<String, String?>{
          'tipo': 'canciones',
          'buscar': '<|channel>thought x<channel|>  Música  ',
        });

        controller.onReady();
        expect(controller.searchType, SearchType.mediaItems);

        // 500ms initial delay + 300ms debounce
        async.elapse(const Duration(milliseconds: 500));
        expect(controller.searchParam.value, '');
        async.elapse(const Duration(milliseconds: 300));
        expect(controller.searchParam.value, 'Musica');
      });
    });

    test('onReady maps all documented Spanish type aliases accurately', () {
      const aliasCases = <String, SearchType>{
        'perfiles': SearchType.profiles,
        'colectivos': SearchType.collectives,
        'eventos': SearchType.events,
        'musica': SearchType.mediaItems,
        'lanzamientos': SearchType.releaseItems,
        'libros': SearchType.releaseItems,
        'todos': SearchType.any,
        'todo': SearchType.any,
      };

      for (final entry in aliasCases.entries) {
        final ctrl = _TestableAppSearchController();
        SintTestMode.setTestQueryParameters(<String, String?>{'tipo': entry.key});
        ctrl.onReady();
        expect(
          ctrl.searchType,
          entry.value,
          reason: 'Alias "${entry.key}" should resolve to ${entry.value}',
        );
        ctrl.onClose();
      }
    });
  });

  group('ItemSearchController', () {
    late ItemSearchController controller;
    late _FakeUserService userService;
    late _FakeGoogleBookGatewayService googleBooks;
    var isClosed = false;

    setUp(() {
      Sint.reset();
      Sint.testMode = true;

      userService = _FakeUserService(
        profile: AppProfile(
          id: 'p1',
          name: 'Reader',
          itemlists: <String, Itemlist>{
            'pl_1': Itemlist(id: 'pl_1', name: 'Profile List'),
          },
        ),
        collective: Collective(id: 'c1', name: 'Collective')
          ..itemlists = <String, Itemlist>{
            'cl_1': Itemlist(id: 'cl_1', name: 'Collective List'),
          },
      );
      googleBooks = _FakeGoogleBookGatewayService(<String, ExternalItem>{
        'gb_1': ExternalItem(
          id: 'gb_1',
          name: 'Dune Messiah',
          ownerName: 'Frank Herbert',
        ),
        'gb_2': ExternalItem(
          id: 'gb_2',
          name: 'Unrelated Volume',
          ownerName: 'Other Author',
        ),
      });

      Sint.put<UserService>(userService);
      Sint.put<GoogleBookGatewayService>(googleBooks);

      controller = ItemSearchController();
      isClosed = false;
    });

    tearDown(() {
      if (!isClosed) {
        controller.onClose();
      }
      Sint.reset();
    });

    test('onInit selects profile vs collective itemlists and maps ItemlistType to MediaSearchType', () {
      const typeExpectations = <ItemlistType, MediaSearchType>{
        ItemlistType.playlist: MediaSearchType.song,
        ItemlistType.single: MediaSearchType.song,
        ItemlistType.ep: MediaSearchType.song,
        ItemlistType.album: MediaSearchType.song,
        ItemlistType.demo: MediaSearchType.song,
        ItemlistType.radioStation: MediaSearchType.song,
        ItemlistType.giglist: MediaSearchType.song,
        ItemlistType.gallery: MediaSearchType.song,
        ItemlistType.podcast: MediaSearchType.podcast,
        ItemlistType.readlist: MediaSearchType.book,
        ItemlistType.publication: MediaSearchType.book,
        ItemlistType.audiobook: MediaSearchType.audiobook,
        ItemlistType.meditation: MediaSearchType.meditation,
      };

      for (final entry in typeExpectations.entries) {
        final ctrl = ItemSearchController();
        SintTestMode.setTestArguments(Itemlist(id: 'l_${entry.key.name}', type: entry.key));
        ctrl.onInit();
        expect(
          ctrl.searchType,
          entry.value,
          reason: 'ItemlistType.${entry.key.name} should map to ${entry.value}',
        );
        expect(ctrl.itemlists.containsKey('pl_1'), isTrue);
        ctrl.onClose();
      }

      // Collective ownerType loads collective itemlists
      userService.itemlistOwnerType = OwnerType.collective;
      SintTestMode.setTestArguments(<dynamic>[
        MediaSearchType.book,
        Itemlist(id: 'custom_list', name: 'Reading', type: ItemlistType.readlist),
      ]);
      controller.onInit();
      expect(controller.ownerType, OwnerType.collective);
      expect(controller.itemlists.containsKey('cl_1'), isTrue);
      expect(controller.searchType, MediaSearchType.book);
      expect(controller.itemlist.id, 'custom_list');
    });

    test('searchItems filters songs, books + external Google Books, audiobooks, and podcasts without Firestore', () async {
      // Pre-populate caches so Firestore fallbacks are never invoked
      controller.totalMediaItems.addAll(<String, AppMediaItem>{
        's1': AppMediaItem(
          id: 's1',
          name: 'Starlight',
          ownerName: 'Muse',
          type: MediaItemType.song,
        ),
        'ab_m1': AppMediaItem(
          id: 'ab_m1',
          name: 'Historia Cósmica',
          ownerName: 'Carl',
          type: MediaItemType.audiobook,
        ),
        'pod_m1': AppMediaItem(
          id: 'pod_m1',
          name: 'Charlas de Música',
          ownerName: 'Anfitrión',
          type: MediaItemType.podcast,
        ),
      });
      controller.totalReleaseItems.addAll(<String, AppReleaseItem>{
        'b1': AppReleaseItem(
          id: 'b1',
          name: 'Dune Chronicles',
          ownerName: 'Herbert',
          type: ReleaseType.single,
          mediaType: MediaItemType.pdf,
        ),
        'ab_r1': AppReleaseItem(
          id: 'ab_r1',
          name: 'Capítulo Cósmico',
          ownerName: 'Narrador',
          type: ReleaseType.chapter,
          mediaType: MediaItemType.audiobook,
        ),
        'pod_r1': AppReleaseItem(
          id: 'pod_r1',
          name: 'Episodio Musical',
          ownerName: 'Locutor',
          type: ReleaseType.episode,
          mediaType: MediaItemType.podcast,
        ),
      });

      // 1. Songs
      controller.searchType = MediaSearchType.song;
      await controller.setSearchParam('starlight');
      expect(controller.foundItems.keys, <String>['s1']);

      // 2. Books (local release + external Google Books gateway)
      controller.searchType = MediaSearchType.book;
      await controller.setSearchParam('dune');
      expect(googleBooks.queries, <String>['dune']);
      expect(controller.foundItems.keys, unorderedEquals(<String>['b1', 'gb_1']));

      // 3. Audiobooks (accent-normalized across media + releases)
      controller.searchType = MediaSearchType.audiobook;
      await controller.setSearchParam('cosmico');
      expect(controller.foundItems.keys, <String>['ab_r1']);
      await controller.setSearchParam('cosmica');
      expect(controller.foundItems.keys, <String>['ab_m1']);

      // 4. Podcasts (accent-normalized across media + releases)
      controller.searchType = MediaSearchType.podcast;
      await controller.setSearchParam('musica');
      expect(controller.foundItems.keys, unorderedEquals(<String>['pod_m1', 'pod_r1']));

      // 5. Playlist clears foundItems safely
      controller.searchType = MediaSearchType.playlist;
      await controller.setSearchParam('anything');
      expect(controller.foundItems, isEmpty);
    });

    test('initSearchParam syncs sanitized text and debouncedSetSearchParam cancels rapid updates', () {
      fakeAsync((FakeAsync async) {
        controller.searchType = MediaSearchType.song;
        controller.totalMediaItems['s1'] = AppMediaItem(id: 's1', name: 'Aurora', ownerName: 'Artist');
        controller.totalReleaseItems['r1'] = AppReleaseItem(id: 'r1', name: 'Placeholder');

        controller.debouncedSetSearchParam('first');
        async.elapse(const Duration(milliseconds: 100));
        controller.debouncedSetSearchParam('  <think>x</think> aurora ');
        async.elapse(const Duration(milliseconds: 299));
        expect(controller.searchParam.value, '');

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(controller.searchParam.value, 'aurora');
        expect(controller.foundItems.keys, <String>['s1']);

        // initSearchParam updates both observable and TextEditingController
        controller.initSearchParam('  Aurora\u200B  ');
        async.flushMicrotasks();
        expect(controller.searchParam.value, 'Aurora');
        expect(controller.searchParamController.text, 'Aurora');

        // onReady clears loading flag
        controller.onReady();
        expect(controller.isLoading.value, isFalse);

        // onClose cancels debounce and blocks further updates
        controller.debouncedSetSearchParam('after_close');
        controller.onClose();
        isClosed = true;
        async.elapse(const Duration(milliseconds: 500));
        controller.debouncedSetSearchParam('ignored_after_close');
        async.elapse(const Duration(milliseconds: 500));
      });
    });
  });

  group('SearchWebFilters widget', () {
    testWidgets('displays aggregated and per-category counts and emits SearchType on tap', (
      WidgetTester tester,
    ) async {
      final selected = <SearchType>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchWebFilters(
              activeFilter: SearchType.profiles,
              profileCount: 5,
              releaseCount: 3,
              mediaCount: 0,
              onFilterChanged: selected.add,
            ),
          ),
        ),
      );

      // Total count = 5 + 3 + 0 = 8; media count = 0 so badge hidden
      expect(find.text('8'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('0'), findsNothing);

      // Tap each filter item
      await tester.tap(find.text('8'));
      await tester.tap(find.text('3'));
      await tester.pump();

      expect(selected, <SearchType>[SearchType.any, SearchType.releaseItems]);
    });
  });
}
