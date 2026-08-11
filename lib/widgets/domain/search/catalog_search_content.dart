import 'package:flutter/material.dart';
import 'package:sakuramedia/features/actors/data/dto/actor_list_item_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/search/presentation/providers/catalog_search_state.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/domain/actors/actor_summary_grid.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_summary_grid.dart';
import 'package:sakuramedia/widgets/base/navigation/app_tab_bar.dart';
import 'package:sakuramedia/widgets/domain/search/catalog_search_field.dart';
import 'package:sakuramedia/widgets/domain/search/catalog_search_stream_status_card.dart';

class CatalogSearchContent extends StatelessWidget {
  const CatalogSearchContent({
    super.key,
    required this.state,
    required this.textController,
    required this.tabController,
    required this.useOnlineSearch,
    required this.onOnlineSearchToggle,
    this.useFuzzySearch = false,
    this.onFuzzySearchToggle,
    this.useKeywordSearch = false,
    this.onKeywordSearchToggle,
    required this.onSubmitSearch,
    required this.onTabSelected,
    required this.onMovieTap,
    this.onMovieMenuRequest,
    required this.onActorTap,
    required this.onMovieSubscriptionTap,
    required this.onActorSubscriptionTap,
    this.onFallbackToOnlineSearch,
    this.onLoadMoreFuzzy,
    this.tagSearchMovieType = 0,
    this.onTagSearchMovieTypeChanged,
    this.tagSearchAutoImport = false,
    this.onTagSearchAutoImportChanged,
  });

  final CatalogSearchState state;
  final TextEditingController textController;
  final TabController tabController;
  final bool useOnlineSearch;
  final ValueChanged<bool> onOnlineSearchToggle;

  /// 模糊搜索开关：默认关闭，与在线搜索并列展示在搜索框右侧。
  final bool useFuzzySearch;
  final ValueChanged<bool>? onFuzzySearchToggle;

  /// 关键词搜索开关。
  final bool useKeywordSearch;
  final ValueChanged<bool>? onKeywordSearchToggle;
  final VoidCallback onSubmitSearch;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<MovieListItemDto> onMovieTap;
  final void Function(MovieListItemDto movie, Offset globalPosition)?
  onMovieMenuRequest;
  final ValueChanged<ActorListItemDto> onActorTap;
  final ValueChanged<MovieListItemDto> onMovieSubscriptionTap;
  final ValueChanged<ActorListItemDto> onActorSubscriptionTap;
  final VoidCallback? onFallbackToOnlineSearch;

  /// 模糊搜索翻页：滚动到底时触发加载下一页。
  final VoidCallback? onLoadMoreFuzzy;

  /// 标签搜索：影片类型（0=一般 / 1=有码 / 2=无码欧美）。
  final int tagSearchMovieType;
  final ValueChanged<int>? onTagSearchMovieTypeChanged;

  /// 标签搜索：搜索后是否自动导入落库。
  final bool tagSearchAutoImport;
  final ValueChanged<bool>? onTagSearchAutoImportChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surfaceElevated,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200) {
            onLoadMoreFuzzy?.call();
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CatalogSearchField(
                  key: const Key('catalog-search-page-field'),
                  fieldKey: const Key('catalog-search-page-input'),
                  searchButtonKey: const Key('catalog-search-page-submit'),
                  onlineToggleKey: const Key(
                    'catalog-search-page-online-toggle',
                  ),
                  fuzzyToggleKey: const Key('catalog-search-page-fuzzy-toggle'),
                  controller: textController,
                  hintText: state.activeKind == CatalogSearchKind.tags
                      ? '如 HDTV、可播放、高畫質'
                      : '如 SSNI-888、三上悠亚',
                  showOnlineToggle: true,
                  isOnlineSearchEnabled: useOnlineSearch,
                  onOnlineSearchToggle: onOnlineSearchToggle,
                  showFuzzyToggle: onFuzzySearchToggle != null,
                  isFuzzySearchEnabled: useFuzzySearch,
                  onFuzzySearchToggle: onFuzzySearchToggle,
                  showKeywordToggle: onKeywordSearchToggle != null,
                  isKeywordSearchEnabled: useKeywordSearch,
                  onKeywordSearchToggle: onKeywordSearchToggle,
                  onSubmitted: (_) => onSubmitSearch(),
                  onSearchTap: onSubmitSearch,
                ),
                if (state.streamStatus != null) ...[
                  SizedBox(height: context.appSpacing.md),
                  CatalogSearchStreamStatusCard(status: state.streamStatus!),
                ],
                SizedBox(height: context.appSpacing.xs),
                AppTabBar(
                  controller: tabController,
                  onTap: onTabSelected,
                  tabs: const [
                    Tab(text: '影片'),
                    Tab(text: '女优'),
                    Tab(text: '标签'),
                  ],
                ),
                if (state.activeKind == CatalogSearchKind.tags) ...[
                  SizedBox(height: context.appSpacing.sm),
                  _TagSearchOptionsBar(
                    movieType: tagSearchMovieType,
                    onMovieTypeChanged: onTagSearchMovieTypeChanged,
                    autoImport: tagSearchAutoImport,
                    onAutoImportChanged: onTagSearchAutoImportChanged,
                  ),
                ],
                SizedBox(height: context.appSpacing.lg),
              ],
            ),
          ),
          if (state.useFuzzySearch && state.fuzzySearchTotal != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: context.appSpacing.sm),
                child: Text(
                  '共 ${state.fuzzySearchTotal} 部',
                  key: const Key('catalog-search-fuzzy-total'),
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    weight: AppTextWeight.regular,
                    tone: AppTextTone.muted,
                  ),
                ),
              ),
            ),
          _buildBodySliver(context),
          if (state.isLoadingMoreFuzzy)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildBodySliver(BuildContext context) {
    if (state.query.isEmpty && !state.isLoading) {
      return const SliverToBoxAdapter(
        child: AppEmptyState(message: '输入关键词开始搜索'),
      );
    }

    if (state.errorMessage != null) {
      return SliverToBoxAdapter(
        child: AppEmptyState(
          message: state.errorMessage!,
          onRetry: onSubmitSearch,
          retryKey: const Key('catalog-search-retry'),
        ),
      );
    }

    if (state.isLoading) {
      return const SliverToBoxAdapter(child: _CatalogSearchLoadingIndicator());
    }

    switch (state.activeKind) {
      case CatalogSearchKind.movies:
        if (!state.isOnlineSearchActive &&
            state.movieResults.isEmpty &&
            onFallbackToOnlineSearch != null) {
          return SliverToBoxAdapter(
            child: _CatalogSearchOnlineFallback(
              onPressed: onFallbackToOnlineSearch!,
            ),
          );
        }
        return MovieSummarySliver(
          items: state.movieResults,
          isLoading: false,
          emptyMessage:
              state.isOnlineSearchActive
                  ? '在线源未找到该番号或未成功入库'
                  : '本地库中没有匹配该番号的影片。',
          onMovieTap: onMovieTap,
          onMovieMenuRequest: onMovieMenuRequest,
          onMovieSubscriptionTap: onMovieSubscriptionTap,
          isMovieSubscriptionUpdating:
              (movie) => state.isMovieSubscriptionUpdating(movie.movieNumber),
        );
      case CatalogSearchKind.actors:
        return ActorSummarySliver(
          items: state.actorResults,
          isLoading: false,
          emptyMessage: '在线源未找到匹配女优',
          onActorTap: onActorTap,
          onActorSubscriptionTap: onActorSubscriptionTap,
          isActorSubscriptionUpdating:
              (actor) => state.isActorSubscriptionUpdating(actor.id),
        );
      case CatalogSearchKind.tags:
        return MovieSummarySliver(
          items: state.tagResults,
          isLoading: false,
          emptyMessage:
              state.isOnlineSearchActive
                  ? '在线源未找到匹配该标签的影片'
                  : '标签下暂无影片',
          onMovieTap: onMovieTap,
          onMovieMenuRequest: onMovieMenuRequest,
          onMovieSubscriptionTap: onMovieSubscriptionTap,
          isMovieSubscriptionUpdating:
              (movie) => state.isMovieSubscriptionUpdating(movie.movieNumber),
        );
    }
  }
}

class _CatalogSearchLoadingIndicator extends StatelessWidget {
  const _CatalogSearchLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 240,
      child: Center(
        child: SizedBox(
          key: Key('catalog-search-loading-indicator'),
          width: 24,
          height: 24,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _CatalogSearchOnlineFallback extends StatelessWidget {
  const _CatalogSearchOnlineFallback({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore,
              size: context.appComponentTokens.iconSize4xl,
              color: resolveAppTextToneColor(context, AppTextTone.secondary),
            ),
            SizedBox(height: spacing.md),
            Text(
              '本地库未找到匹配影片',
              textAlign: TextAlign.center,
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s14,
                weight: AppTextWeight.regular,
                tone: AppTextTone.secondary,
              ),
            ),
            SizedBox(height: spacing.lg),
            AppButton(
              key: const Key('catalog-search-online-fallback'),
              variant: AppButtonVariant.primary,
              label: '从外部数据源获取',
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _TagSearchOptionsBar extends StatelessWidget {
  const _TagSearchOptionsBar({
    required this.movieType,
    required this.onMovieTypeChanged,
    required this.autoImport,
    required this.onAutoImportChanged,
  });

  final int movieType;
  final ValueChanged<int>? onMovieTypeChanged;
  final bool autoImport;
  final ValueChanged<bool>? onAutoImportChanged;

  static const List<(String, int)> _movieTypeOptions = [
    ('一般', 0),
    ('有码', 1),
    ('无码/欧美', 2),
  ];

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final labelStyle = resolveAppTextStyle(
      context,
      size: AppTextSize.s12,
      weight: AppTextWeight.regular,
      tone: AppTextTone.secondary,
    );
    return Wrap(
      spacing: spacing.md,
      runSpacing: spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('影片类型', style: labelStyle),
        for (final option in _movieTypeOptions)
          AppTextButton(
            key: Key('tag-search-movie-type-${option.$2}'),
            label: option.$1,
            size: AppTextButtonSize.xSmall,
            isSelected: movieType == option.$2,
            onPressed:
                onMovieTypeChanged != null
                    ? () => onMovieTypeChanged!(option.$2)
                    : null,
          ),
        SizedBox(width: spacing.xs),
        Text('自动导入', style: labelStyle),
        AppTextButton(
          key: const Key('tag-search-auto-import'),
          label: '搜索后导入',
          size: AppTextButtonSize.xSmall,
          isSelected: autoImport,
          onPressed:
              onAutoImportChanged != null
                  ? () => onAutoImportChanged!(!autoImport)
                  : null,
        ),
      ],
    );
  }
}
