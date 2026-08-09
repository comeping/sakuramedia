/// JavDB 标签搜索结果中的标签候选。
///
/// 同名标签可能跨 category 出现多个，每个候选含 JavDB 侧的分类与影片类型信息，
/// 对应 SSE `tag_found` 事件 `tags` 数组中的每一项。
class TagSearchTagDto {
  const TagSearchTagDto({
    required this.javdbId,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.movieType,
  });

  final String javdbId;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final int? movieType;

  factory TagSearchTagDto.fromJson(Map<String, dynamic> json) {
    return TagSearchTagDto(
      javdbId: json['javdb_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      movieType: json['movie_type'] as int?,
    );
  }
}

