import 'package:flutter/foundation.dart';
import 'package:sakuramedia/features/actors/data/dto/actor_list_item_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/search/presentation/catalog_search_stream_status.dart';
import 'package:sakuramedia/features/tags/data/tag_search_tag_dto.dart';

enum CatalogSearchKind { movies, actors, tags }

@immutable
class CatalogSearchState {
  const CatalogSearchState({
    this.query = '',
    this.activeKind = CatalogSearchKind.movies,
    this.lastResolvedKind,
    this.isLoading = false,
    this.isOnlineSearchActive = false,
    this.useOnlineSearch = false,
    this.useFuzzySearch = false,
    this.errorMessage,
    this.streamStatus,
    this.movieResults = const <MovieListItemDto>[],
    this.actorResults = const <ActorListItemDto>[],
    this.tagResults = const <MovieListItemDto>[],
    this.foundTags = const <TagSearchTagDto>[],
    this.tagSearchMovieType = 0,
    this.tagSearchAutoImport = false,
    this.updatingMovieNumbers = const <String>{},
    this.updatingActorIds = const <int>{},
    this.hasBootstrapped = false,
    this.fuzzySearchTotal,
    this.fuzzySearchPage = 1,
    this.isLoadingMoreFuzzy = false,
  });

  static const CatalogSearchState initial = CatalogSearchState();

  final String query;
  final CatalogSearchKind activeKind;
  final CatalogSearchKind? lastResolvedKind;
  final bool isLoading;
  final bool isOnlineSearchActive;
  final bool useOnlineSearch;
  final bool useFuzzySearch;
  final String? errorMessage;
  final CatalogSearchStreamStatus? streamStatus;
  final List<MovieListItemDto> movieResults;
  final List<ActorListItemDto> actorResults;
  final List<MovieListItemDto> tagResults;
  final List<TagSearchTagDto> foundTags;
  final int tagSearchMovieType;
  final bool tagSearchAutoImport;
  final Set<String> updatingMovieNumbers;
  final Set<int> updatingActorIds;
  final bool hasBootstrapped;

  /// 模糊搜索结果总数，供 UI 显示"共 X 部"。null 表示未启用模糊搜索或无数据。
  final int? fuzzySearchTotal;

  /// 模糊搜索当前页码（从 1 开始），用于翻页加载更多。
  final int fuzzySearchPage;

  /// 是否正在加载更多模糊搜索结果（翻页中）。
  final bool isLoadingMoreFuzzy;

  bool isMovieSubscriptionUpdating(String movieNumber) =>
      updatingMovieNumbers.contains(movieNumber);

  bool isActorSubscriptionUpdating(int actorId) =>
      updatingActorIds.contains(actorId);

  CatalogSearchState copyWith({
    String? query,
    CatalogSearchKind? activeKind,
    Object? lastResolvedKind = _sentinel,
    bool? isLoading,
    bool? isOnlineSearchActive,
    bool? useOnlineSearch,
    bool? useFuzzySearch,
    Object? fuzzySearchTotal = _sentinel,
    int? fuzzySearchPage,
    bool? isLoadingMoreFuzzy,
    Object? errorMessage = _sentinel,
    Object? streamStatus = _sentinel,
    List<MovieListItemDto>? movieResults,
    List<ActorListItemDto>? actorResults,
    List<MovieListItemDto>? tagResults,
    List<TagSearchTagDto>? foundTags,
    int? tagSearchMovieType,
    bool? tagSearchAutoImport,
    Set<String>? updatingMovieNumbers,
    Set<int>? updatingActorIds,
    bool? hasBootstrapped,
  }) {
    return CatalogSearchState(
      query: query ?? this.query,
      activeKind: activeKind ?? this.activeKind,
      lastResolvedKind:
          identical(lastResolvedKind, _sentinel)
              ? this.lastResolvedKind
              : lastResolvedKind as CatalogSearchKind?,
      isLoading: isLoading ?? this.isLoading,
      isOnlineSearchActive: isOnlineSearchActive ?? this.isOnlineSearchActive,
      useOnlineSearch: useOnlineSearch ?? this.useOnlineSearch,
      useFuzzySearch: useFuzzySearch ?? this.useFuzzySearch,
      fuzzySearchTotal:
          identical(fuzzySearchTotal, _sentinel)
              ? this.fuzzySearchTotal
              : fuzzySearchTotal as int?,
      errorMessage:
          identical(errorMessage, _sentinel)
              ? this.errorMessage
              : errorMessage as String?,
      streamStatus:
          identical(streamStatus, _sentinel)
              ? this.streamStatus
              : streamStatus as CatalogSearchStreamStatus?,
      movieResults: List<MovieListItemDto>.unmodifiable(
        movieResults ?? this.movieResults,
      ),
      actorResults: List<ActorListItemDto>.unmodifiable(
        actorResults ?? this.actorResults,
      ),
      tagResults: List<MovieListItemDto>.unmodifiable(
        tagResults ?? this.tagResults,
      ),
      foundTags: List<TagSearchTagDto>.unmodifiable(
        foundTags ?? this.foundTags,
      ),
      tagSearchMovieType: tagSearchMovieType ?? this.tagSearchMovieType,
      tagSearchAutoImport: tagSearchAutoImport ?? this.tagSearchAutoImport,
      updatingMovieNumbers: Set<String>.unmodifiable(
        updatingMovieNumbers ?? this.updatingMovieNumbers,
      ),
      updatingActorIds: Set<int>.unmodifiable(
        updatingActorIds ?? this.updatingActorIds,
      ),
      hasBootstrapped: hasBootstrapped ?? this.hasBootstrapped,
      fuzzySearchPage: fuzzySearchPage ?? this.fuzzySearchPage,
      isLoadingMoreFuzzy: isLoadingMoreFuzzy ?? this.isLoadingMoreFuzzy,
    );
  }
}

const Object _sentinel = Object();
