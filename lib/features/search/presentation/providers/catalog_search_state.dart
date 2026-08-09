import 'package:flutter/foundation.dart';
import 'package:sakuramedia/features/actors/data/dto/actor_list_item_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/search/presentation/catalog_search_stream_status.dart';

enum CatalogSearchKind { movies, actors }

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
    this.updatingMovieNumbers = const <String>{},
    this.updatingActorIds = const <int>{},
    this.hasBootstrapped = false,
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
  final Set<String> updatingMovieNumbers;
  final Set<int> updatingActorIds;
  final bool hasBootstrapped;

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
    Object? errorMessage = _sentinel,
    Object? streamStatus = _sentinel,
    List<MovieListItemDto>? movieResults,
    List<ActorListItemDto>? actorResults,
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
      updatingMovieNumbers: Set<String>.unmodifiable(
        updatingMovieNumbers ?? this.updatingMovieNumbers,
      ),
      updatingActorIds: Set<int>.unmodifiable(
        updatingActorIds ?? this.updatingActorIds,
      ),
      hasBootstrapped: hasBootstrapped ?? this.hasBootstrapped,
    );
  }
}

const Object _sentinel = Object();
