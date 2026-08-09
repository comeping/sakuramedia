import 'package:flutter/material.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/listing/movie_filter_state.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/forms/app_text_field.dart';

/// 影片筛选的所有 section（关键词 / 状态 / 合集类型 / 番号来源 / 年份 / 排序）的纵向 Column。
///
/// 桌面 `AppListHeader` 的就地浮层 panel 和移动 `MobileMovieFilterDrawer` 都用它，
/// 避免双份维护。底栏/重置按钮由调用方自己附加。
class MovieFilterSectionGroup extends StatelessWidget {
  const MovieFilterSectionGroup({
    super.key,
    required this.filterState,
    required this.onChanged,
    this.yearOptions = const <MovieFilterYearOption>[],
    this.isYearOptionsLoading = false,
    this.yearOptionsErrorMessage,
    this.onYearOptionsRetry,
  });

  final MovieFilterState filterState;
  final ValueChanged<MovieFilterState> onChanged;
  final List<MovieFilterYearOption> yearOptions;
  final bool isYearOptionsLoading;
  final String? yearOptionsErrorMessage;
  final VoidCallback? onYearOptionsRetry;

  bool get _shouldShowYearSection =>
      yearOptions.isNotEmpty ||
      isYearOptionsLoading ||
      yearOptionsErrorMessage != null ||
      filterState.year != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MovieKeywordFilterSection(
          keyword: filterState.keyword,
          onSubmitted:
              (value) => onChanged(filterState.copyWith(keyword: value)),
        ),
        SizedBox(height: context.appSpacing.lg),
        MovieFilterChoiceSection<MovieStatusFilter>(
          title: '状态筛选',
          options: MovieStatusFilter.values,
          selectedValue: filterState.status,
          labelBuilder: (value) => value.label,
          onSelected: (value) => onChanged(filterState.copyWith(status: value)),
        ),
        SizedBox(height: context.appSpacing.lg),
        MovieFilterChoiceSection<MovieCollectionTypeFilter>(
          title: '合集类型',
          options: MovieCollectionTypeFilter.values,
          selectedValue: filterState.collectionType,
          labelBuilder: (value) => value.label,
          onSelected:
              (value) => onChanged(filterState.copyWith(collectionType: value)),
        ),
        SizedBox(height: context.appSpacing.lg),
        MovieFilterChoiceSection<MovieNumberSourceFilter>(
          title: '番号来源',
          options: MovieNumberSourceFilter.values,
          selectedValue: filterState.numberSource,
          labelBuilder: (value) => value.label,
          onSelected:
              (value) => onChanged(filterState.copyWith(numberSource: value)),
        ),
        if (_shouldShowYearSection) ...[
          SizedBox(height: context.appSpacing.lg),
          MovieYearFilterSection(
            options: yearOptions,
            selectedYear: filterState.year,
            isLoading: isYearOptionsLoading,
            errorMessage: yearOptionsErrorMessage,
            onRetry: onYearOptionsRetry,
            onSelected: (value) => onChanged(filterState.copyWith(year: value)),
          ),
        ],
        SizedBox(height: context.appSpacing.lg),
        MovieSortSection(
          filterState: filterState,
          onSortFieldChanged:
              (value) => onChanged(filterState.copyWith(sortField: value)),
          onSortDirectionChanged:
              (value) => onChanged(filterState.copyWith(sortDirection: value)),
        ),
      ],
    );
  }
}

/// 关键词模糊搜索：对标题 / 中文标题 / 番号做子串匹配（后端 `q` 参数）。
///
/// 提交后立即生效，与其它筛选项按 AND 关系组合；清空关键词并提交即可回退到
/// 默认列表语义。用 [TextEditingController] 承载草稿，外部 `keyword`（如重置）
/// 变化时才回写文本，避免打字过程中被外部状态覆盖。
class MovieKeywordFilterSection extends StatefulWidget {
  const MovieKeywordFilterSection({
    super.key,
    required this.keyword,
    required this.onSubmitted,
  });

  final String keyword;
  final ValueChanged<String> onSubmitted;

  @override
  State<MovieKeywordFilterSection> createState() =>
      _MovieKeywordFilterSectionState();
}

class _MovieKeywordFilterSectionState
    extends State<MovieKeywordFilterSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.keyword);
  }

  @override
  void didUpdateWidget(covariant MovieKeywordFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.keyword != oldWidget.keyword &&
        widget.keyword != _controller.text) {
      _controller.text = widget.keyword;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => widget.onSubmitted(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '关键词搜索',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.regular,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: context.appSpacing.sm),
        AppTextField(
          fieldKey: const Key('movie-filter-keyword-field'),
          controller: _controller,
          hintText: '按标题 / 中文标题 / 番号搜索',
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) => _submit(),
          suffix: AppIconButton(
            key: const Key('movie-filter-keyword-submit'),
            icon: const Icon(Icons.search_rounded),
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

class MovieFilterChoiceSection<T> extends StatelessWidget {
  const MovieFilterChoiceSection({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onSelected,
    this.optionKeyBuilder,
  });

  final String title;
  final List<T> options;
  final T selectedValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  /// 给每个选项 chip 生成稳定 Key（测试锚点）。语义对齐
  /// `RankingFilterChoiceSection.optionKeyBuilder`；不传则不挂 Key。
  final Key Function(T value)? optionKeyBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.regular,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: context.appSpacing.sm),
        Wrap(
          spacing: context.appSpacing.sm,
          runSpacing: context.appSpacing.sm,
          children: options
              .map(
                (value) => AppTextButton(
                  key: optionKeyBuilder?.call(value),
                  label: labelBuilder(value),
                  size: AppTextButtonSize.xSmall,
                  isSelected: value == selectedValue,
                  onPressed: () => onSelected(value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class MovieYearFilterSection extends StatelessWidget {
  const MovieYearFilterSection({
    super.key,
    required this.options,
    required this.selectedYear,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onSelected,
  });

  final List<MovieFilterYearOption> options;
  final int? selectedYear;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '发行年份',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.regular,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: context.appSpacing.sm),
        if (isLoading)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: context.appSpacing.sm),
              Text(
                '年份加载中',
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s12,
                  weight: AppTextWeight.regular,
                  tone: AppTextTone.muted,
                ),
              ),
            ],
          )
        else if (errorMessage != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errorMessage!,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s12,
                  weight: AppTextWeight.regular,
                  tone: AppTextTone.muted,
                ),
              ),
              SizedBox(width: context.appSpacing.sm),
              AppTextButton(
                label: '重试',
                size: AppTextButtonSize.xSmall,
                onPressed: onRetry,
              ),
            ],
          )
        else
          Wrap(
            spacing: context.appSpacing.sm,
            runSpacing: context.appSpacing.sm,
            children: [
              AppTextButton(
                label: '全部年份',
                size: AppTextButtonSize.xSmall,
                isSelected: selectedYear == null,
                onPressed: () => onSelected(null),
              ),
              for (final option in options)
                AppTextButton(
                  label: option.label,
                  size: AppTextButtonSize.xSmall,
                  isSelected: option.year == selectedYear,
                  onPressed: () => onSelected(option.year),
                ),
            ],
          ),
      ],
    );
  }
}

class MovieSortSection extends StatelessWidget {
  const MovieSortSection({
    super.key,
    required this.filterState,
    required this.onSortFieldChanged,
    required this.onSortDirectionChanged,
  });

  final MovieFilterState filterState;
  final ValueChanged<MovieSortField> onSortFieldChanged;
  final ValueChanged<SortDirection> onSortDirectionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '排序方式',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.regular,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: context.appSpacing.sm),
        Wrap(
          spacing: context.appSpacing.sm,
          runSpacing: context.appSpacing.sm,
          children: MovieSortField.values
              .map(
                (value) => AppTextButton(
                  label: value.label,
                  size: AppTextButtonSize.xSmall,
                  isSelected: value == filterState.sortField,
                  onPressed: () => onSortFieldChanged(value),
                ),
              )
              .toList(growable: false),
        ),
        SizedBox(height: context.appSpacing.md),
        Wrap(
          spacing: context.appSpacing.sm,
          children: SortDirection.values
              .map(
                (value) => AppTextButton(
                  label: value.label,
                  size: AppTextButtonSize.xSmall,
                  isSelected: value == filterState.sortDirection,
                  onPressed: () => onSortDirectionChanged(value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}
