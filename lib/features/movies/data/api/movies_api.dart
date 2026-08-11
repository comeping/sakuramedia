import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/network/api_sse_event.dart';
import 'package:sakuramedia/core/network/paginated_response_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/thumbnails/movie_media_thumbnail_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_review_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/series_import/movie_search_stream_update.dart';
import 'package:sakuramedia/features/movies/data/dto/player/movie_subtitle_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_collection_type_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_subscription_batch_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/parsed_movie_number_dto.dart';
import 'package:sakuramedia/features/search/data/catalog_search_stream_stats.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/listing/movie_filter_state.dart';

class MoviesApi {
  const MoviesApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PaginatedResponseDto<MovieListItemDto>> getMovies({
    MovieStatusFilter? status,
    MovieCollectionTypeFilter? collectionType,
    MovieNumberSourceFilter? numberSource,
    String? sort,
    int? actorId,
    int? year,
    List<int>? tagIds,
    TagMatchMode? tagMatch,
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (status != null) {
      queryParameters['status'] = status.apiValue;
    }
    if (collectionType != null) {
      queryParameters['collection_type'] = collectionType.apiValue;
    }
    if (numberSource != null) {
      queryParameters['number_source'] = numberSource.apiValue;
    }
    if (sort != null && sort.isNotEmpty) {
      queryParameters['sort'] = sort;
    }
    if (actorId != null) {
      queryParameters['actor_id'] = actorId;
    }
    if (year != null) {
      queryParameters['year'] = year;
    }
    if (tagIds != null && tagIds.isNotEmpty) {
      queryParameters['tag_ids'] = tagIds.join(',');
      // tag_match 仅在传 tag_ids 时生效：or 命中任一标签，and 须同时命中全部。
      if (tagMatch != null) {
        queryParameters['tag_match'] = tagMatch.apiValue;
      }
    }
    // 模糊搜索关键词：后端 `q` 参数对 title/title_zh/movie_number 做 OR 子串匹配，
    // 与其它筛选条件是 AND 关系。传纯空白会被后端拒绝（422），这里先 trim 再判空。
    final trimmedKeyword = keyword?.trim();
    if (trimmedKeyword != null && trimmedKeyword.isNotEmpty) {
      queryParameters['q'] = trimmedKeyword;
    }

    final response = await _apiClient.get(
      '/movies',
      queryParameters: queryParameters,
    );
    return PaginatedResponseDto<MovieListItemDto>.fromJson(
      response,
      MovieListItemDto.fromJson,
    );
  }

  /// 模糊搜索：按标题 / 中文标题 / 番号对关键词做 OR 子串匹配（`GET /movies?q=`）。
  ///
  /// 目录搜索页在开启「模糊搜索」时使用，跳过番号解析 + 精确/在线搜索流程，
  /// 直接把关键词交给后端做宽泛匹配；语义与影片库筛选器的 `keyword` 完全一致，
  /// 这里只是给搜索页一个语义更直白的入口。
  /// 返回 `PaginatedResponseDto` 以便调用方读取 `total`，展示"共 X 部"等分页信息。
  Future<PaginatedResponseDto<MovieListItemDto>> searchMoviesFuzzy({
    required String keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    return getMovies(
      keyword: keyword,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<PaginatedResponseDto<MovieListItemDto>> getLatestMovies({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      '/movies/latest',
      queryParameters: <String, dynamic>{'page': page, 'page_size': pageSize},
    );
    return PaginatedResponseDto<MovieListItemDto>.fromJson(
      response,
      MovieListItemDto.fromJson,
    );
  }

  Future<PaginatedResponseDto<MovieListItemDto>>
  getSubscribedActorsLatestMovies({int page = 1, int pageSize = 20}) async {
    final response = await _apiClient.get(
      '/movies/subscribed-actors/latest',
      queryParameters: <String, dynamic>{'page': page, 'page_size': pageSize},
    );
    return PaginatedResponseDto<MovieListItemDto>.fromJson(
      response,
      MovieListItemDto.fromJson,
    );
  }

  Future<PaginatedResponseDto<MovieListItemDto>> getMoviesBySeries({
    required int seriesId,
    int page = 1,
    int pageSize = 24,
  }) async {
    final response = await _apiClient.post(
      '/movies/by-series',
      data: <String, dynamic>{
        'series_id': seriesId,
        'page': page,
        'page_size': pageSize,
      },
    );
    return PaginatedResponseDto<MovieListItemDto>.fromJson(
      response,
      MovieListItemDto.fromJson,
    );
  }

  Future<MovieDetailDto> getMovieDetail({required String movieNumber}) async {
    final response = await _apiClient.get('/movies/$movieNumber');
    return MovieDetailDto.fromJson(response);
  }

  Future<MovieDetailDto> refreshMovieMetadata({
    required String movieNumber,
  }) async {
    final response = await _apiClient.post(
      '/movies/$movieNumber/metadata-refresh',
    );
    return MovieDetailDto.fromJson(response);
  }

  /// 入队翻译任务（统一 action，任务架构 Wave 4）：执行在后台 worker。
  ///
  /// 旧 `/movies/{number}/desc-translation` 端点已删，改走资源级操作唯一入口。
  /// `rerun` 是强制语义：已翻译的影片也会重译，从未记账的影片后端自动播种状态行。
  /// 连点被 mutex 顶 409（`resource_task_action_conflict`）。
  Future<void> translateMovieDescription({required int movieId}) async {
    await _applyMovieResourceTaskRerun(
      taskKey: 'movie_desc_translation',
      movieId: movieId,
    );
  }

  /// 入队互动数同步任务（统一 action）；语义同 [translateMovieDescription]。
  Future<void> syncMovieInteraction({required int movieId}) async {
    await _applyMovieResourceTaskRerun(
      taskKey: 'movie_interaction_sync',
      movieId: movieId,
    );
  }

  Future<void> _applyMovieResourceTaskRerun({
    required String taskKey,
    required int movieId,
  }) async {
    await _apiClient.post(
      '/system/resource-task-actions',
      data: <String, dynamic>{
        'task_key': taskKey,
        'action': 'rerun',
        'resource_ids': <int>[movieId],
      },
    );
  }

  Future<MovieDetailDto> recomputeMovieHeat({
    required String movieNumber,
  }) async {
    final response = await _apiClient.post(
      '/movies/$movieNumber/heat-recompute',
    );
    return MovieDetailDto.fromJson(response);
  }

  Future<List<MovieListItemDto>> getSimilarMovies({
    required String movieNumber,
    int limit = 15,
  }) async {
    final response = await _apiClient.getList(
      '/movies/$movieNumber/similar',
      queryParameters: <String, dynamic>{'limit': limit},
    );
    return response.map(MovieListItemDto.fromJson).toList(growable: false);
  }

  Future<List<MovieReviewDto>> getMovieReviews({
    required String movieNumber,
    int page = 1,
    int pageSize = 20,
    MovieReviewSort sort = MovieReviewSort.recently,
  }) async {
    final response = await _apiClient.getList(
      '/movies/$movieNumber/reviews',
      queryParameters: <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'sort': sort.apiValue,
      },
    );
    return response.map(MovieReviewDto.fromJson).toList(growable: false);
  }

  Future<MovieSubtitleListDto> getMovieSubtitles({
    required String movieNumber,
  }) async {
    final response = await _apiClient.get('/movies/$movieNumber/subtitles');
    return MovieSubtitleListDto.fromJson(response);
  }

  Future<List<MovieMediaThumbnailDto>> getMediaThumbnails({
    required int mediaId,
  }) async {
    final response = await _apiClient.getList('/media/$mediaId/thumbnails');
    return response
        .map(MovieMediaThumbnailDto.fromJson)
        .toList(growable: false);
  }

  Future<MovieMediaProgressDto> updateMediaProgress({
    required int mediaId,
    required int positionSeconds,
  }) async {
    final response = await _apiClient.put(
      '/media/$mediaId/progress',
      data: <String, dynamic>{'position_seconds': positionSeconds},
    );
    return MovieMediaProgressDto.fromJson(response);
  }

  Future<ParsedMovieNumberDto> parseMovieNumber({required String query}) async {
    final response = await _apiClient.post(
      '/movies/search/parse-number',
      data: <String, dynamic>{'query': query.trim()},
    );
    return ParsedMovieNumberDto.fromJson(response);
  }

  Future<List<MovieListItemDto>> searchLocalMovies({
    required String movieNumber,
  }) async {
    final response = await _apiClient.getList(
      '/movies/search/local',
      queryParameters: <String, dynamic>{'movie_number': movieNumber},
    );
    return response.map(MovieListItemDto.fromJson).toList(growable: false);
  }

  Future<MovieCollectionStatusDto> getMovieCollectionStatus({
    required String movieNumber,
  }) async {
    final response = await _apiClient.get(
      '/movies/$movieNumber/collection-status',
    );
    return MovieCollectionStatusDto.fromJson(response);
  }

  Future<UpdateMovieCollectionTypeResultDto> updateMovieCollectionType({
    required List<String> movieNumbers,
    required MovieCollectionType collectionType,
  }) async {
    final response = await _apiClient.patch(
      '/movies/collection-type',
      data:
          UpdateMovieCollectionTypePayload(
            movieNumbers: movieNumbers,
            collectionType: collectionType,
          ).toJson(),
    );
    return UpdateMovieCollectionTypeResultDto.fromJson(response);
  }

  Stream<MovieSearchStreamUpdate> searchOnlineMoviesStream({
    required String movieNumber,
  }) {
    return _apiClient
        .postSse(
          '/movies/search/javdb/stream',
          data: <String, dynamic>{'movie_number': movieNumber},
        )
        .map(_mapMovieSearchStreamEvent);
  }

  Stream<MovieSearchStreamUpdate> searchOnlineMoviesByKeywordStream({
    required String keyword,
  }) {
    return _apiClient
        .postSse(
          '/movies/search/javdb/keyword/stream',
          data: <String, dynamic>{'keyword': keyword},
        )
        .map(_mapMovieSearchStreamEvent);
  }

  Future<void> subscribeMovie({required String movieNumber}) {
    return _apiClient.putNoContent('/movies/$movieNumber/subscription');
  }

  Future<void> unsubscribeMovie({
    required String movieNumber,
    bool deleteMedia = false,
  }) {
    return _apiClient.deleteNoContent(
      '/movies/$movieNumber/subscription',
      queryParameters: <String, dynamic>{'delete_media': deleteMedia},
    );
  }

  Future<MovieSubscriptionBatchResultDto> batchSubscribeMovies({
    required List<String> movieNumbers,
  }) async {
    final response = await _apiClient.post(
      '/movies/subscriptions',
      data: <String, dynamic>{'movie_numbers': movieNumbers},
    );
    return MovieSubscriptionBatchResultDto.fromJson(response);
  }

  Future<MovieSubscriptionBatchResultDto> batchUnsubscribeMovies({
    required List<String> movieNumbers,
  }) async {
    final response = await _apiClient.post(
      '/movies/unsubscriptions',
      data: <String, dynamic>{'movie_numbers': movieNumbers},
    );
    return MovieSubscriptionBatchResultDto.fromJson(response);
  }

  Stream<MovieSearchStreamUpdate> importSeriesMoviesStream({
    required int seriesId,
  }) {
    return _apiClient
        .postSse(
          '/movies/series/$seriesId/javdb/import/stream',
          data: <String, dynamic>{},
        )
        .map(_mapSeriesImportStreamEvent);
  }

  MovieSearchStreamUpdate _mapSeriesImportStreamEvent(ApiSseEvent event) {
    final payload = event.jsonData;

    switch (event.event) {
      case 'search_started':
        return const MovieSearchStreamUpdate(
          stage: 'searching',
          message: '正在搜索系列...',
        );
      case 'series_found':
        return MovieSearchStreamUpdate(
          stage: 'series_matched',
          message: '已找到库内系列：${payload['series_name'] ?? ''}',
        );
      case 'javdb_series_found':
        final count = payload['videos_count'];
        final countLabel = count != null ? '，共 $count 部' : '';
        return MovieSearchStreamUpdate(
          stage: 'series_matched',
          message: '已匹配到 JAVDB 系列$countLabel',
          total: count as int?,
        );
      case 'movie_found':
        final total = payload['total'] as int?;
        return MovieSearchStreamUpdate(
          stage: 'movies_found',
          message: '已获取到 ${total ?? 0} 部影片，准备入库',
          total: total,
        );
      case 'upsert_started':
        return MovieSearchStreamUpdate(
          stage: 'importing',
          message: '正在入库影片...',
          current: 0,
          total: payload['total'] as int?,
        );
      case 'movie_skipped' || 'movie_upsert_started' || 'movie_upsert_finished':
        return MovieSearchStreamUpdate(
          stage: 'importing',
          message: '正在入库影片...',
          current: payload['index'] as int?,
          total: payload['total'] as int?,
        );
      case 'upsert_finished':
        return MovieSearchStreamUpdate(
          stage: 'import_finished',
          message: '入库完成',
          stats: CatalogSearchStreamStats.fromLooseJson(payload),
        );
      case 'completed':
        return MovieSearchStreamUpdate(
          stage: 'completed',
          message: payload['success'] as bool? ?? false ? '导入成功' : '导入失败',
          results: _parseMovieResults(payload['movies']),
          stats: CatalogSearchStreamStats.fromLooseJson(payload),
          success: payload['success'] as bool?,
          reason: payload['reason'] as String?,
        );
      default:
        return MovieSearchStreamUpdate(stage: event.event, message: '正在处理...');
    }
  }

  MovieSearchStreamUpdate _mapMovieSearchStreamEvent(ApiSseEvent event) {
    final payload = event.jsonData;

    switch (event.event) {
      case 'search_started':
        return const MovieSearchStreamUpdate(
          stage: 'search_started',
          message: '正在从外部数据源搜索影片',
        );
      case 'movie_found':
        return MovieSearchStreamUpdate(
          stage: 'movie_found',
          message: '已从在线源获取候选影片',
          total: payload['total'] as int?,
        );
      case 'upsert_started':
        return MovieSearchStreamUpdate(
          stage: 'upsert_started',
          message: '正在入库在线影片',
          total: payload['total'] as int?,
        );
      case 'upsert_finished':
        return MovieSearchStreamUpdate(
          stage: 'upsert_finished',
          message: '在线影片入库完成',
          stats: CatalogSearchStreamStats.fromLooseJson(payload),
        );
      case 'completed':
        return MovieSearchStreamUpdate(
          stage: 'completed',
          message: '在线搜索已完成',
          results: _parseMovieResults(payload['movies']),
          success: payload['success'] as bool? ?? false,
          reason: payload['reason'] as String?,
          stats:
              payload.containsKey('stats') || payload.containsKey('total')
                  ? CatalogSearchStreamStats.fromLooseJson(payload)
                  : null,
        );
      default:
        return MovieSearchStreamUpdate(
          stage: event.event,
          message: '正在同步在线影片搜索结果',
        );
    }
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
