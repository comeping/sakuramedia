import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/network/api_sse_event.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/search/data/catalog_search_stream_stats.dart';
import 'package:sakuramedia/features/tags/data/tag_list_item_dto.dart';
import 'package:sakuramedia/features/tags/data/tag_search_stream_update.dart';
import 'package:sakuramedia/features/tags/data/tag_search_tag_dto.dart';

class TagsApi {
  const TagsApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 获取全部标签（含每标签影片数）。
  ///
  /// [query] 为标签名称模糊匹配，空白串后端会返回 422，故仅在非空时下发。
  /// [sort] 默认按影片数降序，便于优先展示热门标签。
  Future<List<TagListItemDto>> getTags({
    String? query,
    String sort = 'movie_count:desc',
  }) async {
    final queryParameters = <String, dynamic>{'sort': sort};
    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      queryParameters['query'] = trimmed;
    }

    final response = await _apiClient.getList(
      '/tags',
      queryParameters: queryParameters,
    );
    return response.map(TagListItemDto.fromJson).toList(growable: false);
  }

  /// 按标签名从 JavDB 搜索影片列表（SSE 流式响应）。
  ///
  /// [tagName] 为标签名（精确匹配，如 HDTV、可播放、高畫質）。
  /// [movieType] 影片类型：0=一般、1=有码、2=无码/欧美，默认 0。
  /// [autoImport] 为 true 时搜索完成后逐个拉详情并落库。
  ///
  /// 对应后端端点 `POST /tags/search/javdb/stream`。
  Stream<TagSearchStreamUpdate> searchJavdbTagsStream({
    required String tagName,
    int movieType = 0,
    bool autoImport = false,
  }) {
    return _apiClient
        .postSse(
          '/tags/search/javdb/stream',
          data: <String, dynamic>{
            'tag_name': tagName,
            'movie_type': movieType,
            'auto_import': autoImport,
          },
        )
        .map(_mapTagSearchStreamEvent);
  }

  TagSearchStreamUpdate _mapTagSearchStreamEvent(ApiSseEvent event) {
    final payload = event.jsonData;

    switch (event.event) {
      case 'search_started':
        return const TagSearchStreamUpdate(
          stage: 'search_started',
          message: '正在从 JavDB 搜索标签',
        );
      case 'tag_found':
        return TagSearchStreamUpdate(
          stage: 'tag_found',
          message: '已找到标签，正在拉取标签下影片',
          total: payload['total'] as int?,
          foundTags: _parseTagSearchTags(payload['tags']),
        );
      case 'movie_found':
        return TagSearchStreamUpdate(
          stage: 'movie_found',
          message: '已获取标签下候选影片',
          total: payload['total'] as int?,
        );
      case 'upsert_started':
        return TagSearchStreamUpdate(
          stage: 'upsert_started',
          message: '正在入库标签下影片',
          total: payload['total'] as int?,
        );
      case 'movie_skipped' || 'movie_upsert_started' || 'movie_upsert_finished':
        return TagSearchStreamUpdate(
          stage: 'importing',
          message: '正在入库影片...',
          current: payload['index'] as int?,
          total: payload['total'] as int?,
        );
      case 'upsert_finished':
        return TagSearchStreamUpdate(
          stage: 'upsert_finished',
          message: '标签影片入库完成',
          stats: CatalogSearchStreamStats.fromLooseJson(payload),
        );
      case 'completed':
        return TagSearchStreamUpdate(
          stage: 'completed',
          message:
              (payload['success'] as bool? ?? false)
                  ? '标签搜索完成'
                  : '标签搜索失败',
          results: _parseMovieResults(payload['movies']),
          success: payload['success'] as bool?,
          reason: payload['reason'] as String?,
          stats:
              payload.containsKey('stats') || payload.containsKey('total')
                  ? CatalogSearchStreamStats.fromLooseJson(payload)
                  : null,
        );
      default:
        return TagSearchStreamUpdate(
          stage: event.event,
          message: '正在同步标签搜索结果',
        );
    }
  }

  List<TagSearchTagDto> _parseTagSearchTags(dynamic value) {
    if (value is! List) {
      return const <TagSearchTagDto>[];
    }
    return value
        .whereType<Object?>()
        .map((item) => TagSearchTagDto.fromJson(_toMap(item)))
        .toList(growable: false);
  }

  List<MovieListItemDto> _parseMovieResults(dynamic value) {
    if (value is! List) {
      return const <MovieListItemDto>[];
    }
    return value
        .whereType<Object?>()
        .map((item) => MovieListItemDto.fromJson(_toMap(item)))
        .toList(growable: false);
  }

  Map<String, dynamic> _toMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic data) => MapEntry(key.toString(), data),
      );
    }
    return const <String, dynamic>{};
  }
}
