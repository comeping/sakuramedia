import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/search/data/catalog_search_stream_stats.dart';
import 'package:sakuramedia/features/tags/data/tag_search_tag_dto.dart';

/// 标签 JavDB 搜索 SSE 流的事件更新。
///
/// `POST /tags/search/javdb/stream` 返回的每个 SSE 事件被映射为此对象，
/// 前端 provider 按其更新搜索状态。事件语义对齐后端文档。
class TagSearchStreamUpdate {
  const TagSearchStreamUpdate({
    required this.stage,
    required this.message,
    this.current,
    this.total,
    this.results = const <MovieListItemDto>[],
    this.foundTags = const <TagSearchTagDto>[],
    this.success,
    this.reason,
    this.stats,
  });

  /// 事件阶段标识（search_started / tag_found / movie_found / importing / completed 等）。
  final String stage;

  /// 面向用户的进度文案。
  final String message;

  /// 当前进度序号（落库阶段）。
  final int? current;

  /// 总数（候选影片数 / 落库总数）。
  final int? total;

  /// 搜索结果影片列表（completed 事件携带）。
  final List<MovieListItemDto> results;

  /// 搜索到的标签候选（tag_found 事件携带）。
  final List<TagSearchTagDto> foundTags;

  /// 搜索 / 落库是否成功（仅 completed 事件有效）。
  final bool? success;

  /// 失败原因（仅 completed 事件 success=false 时有效，如 tag_not_found）。
  final String? reason;

  /// import / upsert 阶段的统计信息。
  final CatalogSearchStreamStats? stats;

  /// 是否已完成。
  bool get isComplete => stage == 'completed';
}

