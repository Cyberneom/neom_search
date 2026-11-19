import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/ui/deferred_loader.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_search/data/translations/search_de_translations.dart';
import 'package:neom_search/data/translations/search_en_translations.dart';
import 'package:neom_search/data/translations/search_es_translations.dart';
import 'package:neom_search/data/translations/search_fr_translations.dart';
import 'package:neom_search/search_routes.dart';
import 'package:neom_search/ui/app_items/item_search_controller.dart';
import 'package:neom_search/ui/app_search_controller.dart';
import 'package:neom_search/utils/constants/search_constants.dart';
import 'package:neom_search/utils/constants/search_translation_constants.dart';
import 'package:sint/sint.dart';

void main() {
  group('SearchRoutes and SearchConstants', () {
    test('registers search and itemSearch routes with unique leading-slash paths', () {
      final names = SearchRoutes.routes.map((page) => page.name).toList();
      expect(names, <String>[
        AppRouteConstants.search,
        AppRouteConstants.itemSearch,
      ]);
      expect(names.toSet().length, names.length);

      for (final name in names) {
        expect(name.startsWith('/'), isTrue);
      }
      expect(AppRouteConstants.search, '/search');
      expect(AppRouteConstants.itemSearch, '/item/search');
    });

    test('configures DeferredLoader builders and expected transitions', () {
      final byName = <String, SintPage<dynamic>>{
        for (final route in SearchRoutes.routes) route.name: route,
      };

      expect(byName[AppRouteConstants.search]?.page(), isA<DeferredLoader>());
      expect(byName[AppRouteConstants.itemSearch]?.page(), isA<DeferredLoader>());
      expect(byName[AppRouteConstants.itemSearch]?.transition, Transition.zoom);
    });

    test('SearchConstants.itemsQty defines positive default page size', () {
      expect(SearchConstants.itemsQty, 4);
      expect(SearchConstants.itemsQty, greaterThan(0));
    });
  });

  group('Search translations parity', () {
    const locales = <String, Map<String, String>>{
      'en': SearchEnTranslations.values,
      'es': SearchEsTranslations.values,
      'fr': SearchFrTranslations.values,
      'de': SearchDeTranslations.values,
    };

    test('all four locales define matching non-empty keys without raw-key fallback', () {
      final baselineKeys = SearchEnTranslations.values.keys.toSet();
      expect(
        baselineKeys,
        <String>{
          SearchTranslationConstants.favoriteSongs,
          SearchTranslationConstants.itemSearch,
          SearchTranslationConstants.searchInApp,
          SearchTranslationConstants.searchResults,
          SearchTranslationConstants.searchedText,
        },
      );

      for (final entry in locales.entries) {
        expect(
          entry.value.keys.toSet(),
          equals(baselineKeys),
          reason: 'Locale "${entry.key}" keys do not match baseline',
        );
        for (final kv in entry.value.entries) {
          expect(kv.value.trim(), isNotEmpty, reason: '${entry.key}:${kv.key}');
          expect(kv.value, isNot(kv.key), reason: '${entry.key}:${kv.key}');
        }
      }
    });
  });

  group('AppSearchController.sanitizeSearchQuery', () {
    test('preserves normal ASCII, accented, and punctuation queries while collapsing whitespace', () {
      expect(AppSearchController.sanitizeSearchQuery(''), '');
      expect(AppSearchController.sanitizeSearchQuery('   \t\n  '), '');
      expect(
        AppSearchController.sanitizeSearchQuery('  Música   acústica\t\nCDMX  '),
        'Música acústica CDMX',
      );
      expect(
        AppSearchController.sanitizeSearchQuery('Peña-Müller & Café (432Hz)!'),
        'Peña-Müller & Café (432Hz)!',
      );
    });

    test('strips ASCII controls, zero-width chars, BOM, and BiDi overrides', () {
      const dirty = 'jazz\x00\x07\u200B\u200E\u202E\u2066\uFEFFrock\u2028blues';
      expect(AppSearchController.sanitizeSearchQuery(dirty), 'jazz rock blues');
    });

    test('strips closed and truncated LLM thought, tool_call, and internal reasoning blocks', () {
      expect(
        AppSearchController.sanitizeSearchQuery(
          '<|channel>thought secret plan<channel|> guitar',
        ),
        'guitar',
      );
      expect(
        AppSearchController.sanitizeSearchQuery(
          'drums <|turn>thought unclosed trailing thought',
        ),
        'drums',
      );
      expect(
        AppSearchController.sanitizeSearchQuery(
          '<|tool_call>{"name":"x"}<tool_call|> piano <|tool_call>truncated',
        ),
        'piano',
      );
      expect(
        AppSearchController.sanitizeSearchQuery(
          '<think>hidden</think><memory_recall>m</memory_recall>'
          '[BIOCHIP]ctx[/BIOCHIP][AUTO_MEMORY]val[/AUTO_MEMORY]'
          '[SYSTEM_CONTEXT] bass <|eot|>',
        ),
        'bass',
      );
    });

    test('rewrites closing content boundary tag safely', () {
      expect(
        AppSearchController.sanitizeSearchQuery('hello </content> world'),
        'hello [content_end] world',
      );
      expect(
        AppSearchController.sanitizeSearchQuery('a < / CONTENT > b'),
        'a [content_end] b',
      );
    });

    test('enforces maxChars limit and protects UTF-16 surrogate pairs at truncation boundary', () {
      expect(AppSearchController.sanitizeSearchQuery('hello', maxChars: 0), '');
      expect(AppSearchController.sanitizeSearchQuery('hello', maxChars: -5), '');

      final longQuery = 'x' * 250;
      expect(
        AppSearchController.sanitizeSearchQuery(longQuery).length,
        AppSearchController.maxSearchQueryChars,
      );

      // 'abcd' (4 code units) + '🎸' (2 UTF-16 code units): maxChars=5 lands on high surrogate
      final truncatedSurrogate = AppSearchController.sanitizeSearchQuery(
        'abcd🎸ef',
        maxChars: 5,
      );
      expect(truncatedSurrogate, 'abcd');

      // Trims trailing space introduced right before truncation cut
      expect(
        AppSearchController.sanitizeSearchQuery('rock jazz', maxChars: 5),
        'rock',
      );
    });

    test('ItemSearchController.sanitizeSearchQuery delegates to AppSearchController', () {
      const sample = '  <think>x</think> Canción\u200B  Nueva  ';
      expect(
        ItemSearchController.sanitizeSearchQuery(sample),
        AppSearchController.sanitizeSearchQuery(sample),
      );
      expect(ItemSearchController.sanitizeSearchQuery(sample), 'Canción Nueva');
    });
  });
}
