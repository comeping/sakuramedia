import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/network/api_exception.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/tags/data/tags_api.dart';

import '../../../support/fake_http_client_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStore sessionStore;
  late ApiClient apiClient;
  late TagsApi tagsApi;
  late FakeHttpClientAdapter adapter;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-03-08T10:00:00Z'),
    );
    apiClient = ApiClient(sessionStore: sessionStore);
    tagsApi = TagsApi(apiClient: apiClient);
    adapter = FakeHttpClientAdapter();
    apiClient.rawDio.httpClientAdapter = adapter;
    apiClient.rawRefreshDio.httpClientAdapter = adapter;
  });

  tearDown(() {
    apiClient.dispose();
  });

  test('getTags sends default sort and parses tag list', () async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      statusCode: 200,
      body: <Map<String, dynamic>>[
        <String, dynamic>{'tag_id': 5, 'name': '巨乳', 'movie_count': 1280},
        <String, dynamic>{'tag_id': 8, 'name': '单体作品', 'movie_count': 940},
      ],
    );

    final tags = await tagsApi.getTags();

    final request = adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.path, '/tags');
    expect(request.uri.queryParameters['sort'], 'movie_count:desc');
    expect(request.uri.queryParameters.containsKey('query'), isFalse);
    expect(tags, hasLength(2));
    expect(tags.first.tagId, 5);
    expect(tags.first.name, '巨乳');
    expect(tags.first.movieCount, 1280);
  });

  test('getTags sends trimmed query and custom sort when provided', () async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      statusCode: 200,
      body: const <Map<String, dynamic>>[],
    );

    await tagsApi.getTags(query: '  巨乳  ', sort: 'name:asc');

    final request = adapter.requests.single;
    expect(request.uri.queryParameters['query'], '巨乳');
    expect(request.uri.queryParameters['sort'], 'name:asc');
  });

  test('getTags omits blank query', () async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      statusCode: 200,
      body: const <Map<String, dynamic>>[],
    );

    await tagsApi.getTags(query: '   ');

    final request = adapter.requests.single;
    expect(request.uri.queryParameters.containsKey('query'), isFalse);
  });

  test('getTags converts backend error to ApiException', () async {
    adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      statusCode: 422,
      body: <String, dynamic>{
        'error': <String, dynamic>{
          'code': 'invalid_tag_filter',
          'message': '非法筛选',
        },
      },
    );

    expect(
      () => tagsApi.getTags(sort: 'bad:order'),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.error?.code,
          'error.code',
          'invalid_tag_filter',
        ),
      ),
    );
  });

  group('searchJavdbTagsStream', () {
    test('sends correct POST body and parses search-only SSE stream', () async {
      adapter.enqueueSse(
        method: 'POST',
        path: '/tags/search/javdb/stream',
        chunks: <String>[
          'event: search_started\n'
              'data: {"tag_name":"HDTV","movie_type":0,"auto_import":false}\n'
              '\n',
          'event: tag_found\n'
              'data: {"tags":[{"javdb_id":"335","name":"HDTV","category_id":"category","category_name":"類別","movie_type":0}],"total":1}\n'
              '\n',
          'event: movie_found\n'
              'data: {"movies":[{"javdb_id":"abc123","movie_number":"RD-1366","title":"影片A","cover_image":null,"release_date":"2026-08-01"}],"total":1}\n'
              '\n',
          'event: completed\n'
              'data: {"success":true,"movies":[{"javdb_id":"abc123","movie_number":"RD-1366","title":"影片A","cover_image":null,"release_date":"2026-08-01"}],"stats":{"total":1}}\n'
              '\n',
        ],
      );

      final events = await tagsApi
          .searchJavdbTagsStream(tagName: 'HDTV')
          .toList();

      // 验证请求体
      final request = adapter.requests.firstWhere(
        (r) => r.path == '/tags/search/javdb/stream',
      );
      expect(request.method, 'POST');
      final body = request.body as Map<String, dynamic>;
      expect(body['tag_name'], 'HDTV');
      expect(body['movie_type'], 0);
      expect(body['auto_import'], isFalse);

      // 验证事件流
      expect(events, hasLength(4));
      expect(events[0].stage, 'search_started');
      expect(events[1].stage, 'tag_found');
      expect(events[1].foundTags.single.name, 'HDTV');
      expect(events[2].stage, 'movie_found');
      expect(events[2].total, 1);
      expect(events[3].stage, 'completed');
      expect(events[3].success, isTrue);
      expect(events[3].results.single.movieNumber, 'RD-1366');
    });

    test('sends auto_import and movie_type in body', () async {
      adapter.enqueueSse(
        method: 'POST',
        path: '/tags/search/javdb/stream',
        chunks: <String>[
          'event: completed\n'
              'data: {"success":true,"movies":[]}\n\n',
        ],
      );

      await tagsApi
          .searchJavdbTagsStream(
            tagName: '可播放',
            movieType: 1,
            autoImport: true,
          )
          .drain<void>();

      final request = adapter.requests.firstWhere(
        (r) => r.path == '/tags/search/javdb/stream',
      );
      final body = request.body as Map<String, dynamic>;
      expect(body['tag_name'], '可播放');
      expect(body['movie_type'], 1);
      expect(body['auto_import'], isTrue);
    });
  });
}
