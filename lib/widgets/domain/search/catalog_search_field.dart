import 'package:flutter/material.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/forms/app_text_field.dart';

class CatalogSearchField extends StatelessWidget {
  const CatalogSearchField({
    super.key,
    this.fieldKey,
    this.searchButtonKey,
    this.imageSearchButtonKey,
    this.onlineToggleKey,
    this.fuzzyToggleKey,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.onSearchTap,
    this.onImageSearchTap,
    this.showImageSearchButton = false,
    this.showOnlineToggle = false,
    this.isOnlineSearchEnabled = false,
    this.onOnlineSearchToggle,
    this.showFuzzyToggle = false,
    this.isFuzzySearchEnabled = false,
    this.onFuzzySearchToggle,
    /// 关键词搜索开关：模糊搜索 + 联网时用关键词搜 javdb（不过滤番号）。
    this.showKeywordToggle = false,
    this.isKeywordSearchEnabled = false,
    this.onKeywordSearchToggle,
    this.fillColor,
  });

  final Key? fieldKey;
  final Key? searchButtonKey;
  final Key? imageSearchButtonKey;
  final Key? onlineToggleKey;
  final Key? fuzzyToggleKey;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onSearchTap;
  final VoidCallback? onImageSearchTap;
  final bool showImageSearchButton;
  final bool showOnlineToggle;
  final bool isOnlineSearchEnabled;
  final ValueChanged<bool>? onOnlineSearchToggle;

  /// 模糊搜索开关：开启后按标题 / 中文标题 / 番号做宽泛子串匹配，跳过番号解析
  /// 与女优搜索流程，固定展示影片结果。
  final bool showFuzzyToggle;
  final bool isFuzzySearchEnabled;
  final ValueChanged<bool>? onFuzzySearchToggle;

  /// 关键词搜索开关：开启后模糊搜索 + 联网时发关键词到 javdb。
  final bool showKeywordToggle;
  final bool isKeywordSearchEnabled;
  final ValueChanged<bool>? onKeywordSearchToggle;

  /// 覆盖默认的填充色；用于把搜索框放到比 `surfaceMuted` 更暗的面板（如侧边栏）上时提升对比。
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      fieldKey: fieldKey,
      controller: controller,
      hintText: hintText,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: onSubmitted,
      fillColor: fillColor,
      suffix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showImageSearchButton)
            AppIconButton(
              key: imageSearchButtonKey,
              iconColor: context.appTextPalette.primary,
              icon: const Icon(Icons.image_search_outlined),
              onPressed: onImageSearchTap,
            ),
          if (showOnlineToggle)
            AppIconButton(
              key: onlineToggleKey,
              icon: const Icon(Icons.public_rounded),
              isSelected: isOnlineSearchEnabled,
              onPressed:
                  onOnlineSearchToggle == null
                      ? null
                      : () => onOnlineSearchToggle!(!isOnlineSearchEnabled),
            ),
          if (showFuzzyToggle)
            AppIconButton(
              key: fuzzyToggleKey,
              tooltip: '模糊搜索',
              icon: const Icon(Icons.manage_search_rounded),
              isSelected: isFuzzySearchEnabled,
              onPressed:
                  onFuzzySearchToggle == null
                      ? null
                      : () => onFuzzySearchToggle!(!isFuzzySearchEnabled),
            ),
          if (showKeywordToggle)
            AppIconButton(
              key: const Key('catalog-search-page-keyword-toggle'),
              tooltip: '关键词搜索',
              icon: const Icon(Icons.vpn_key_rounded),
              isSelected: isKeywordSearchEnabled,
              onPressed:
                  onKeywordSearchToggle == null
                      ? null
                      : () => onKeywordSearchToggle!(!isKeywordSearchEnabled),
            ),
          AppIconButton(
            key: searchButtonKey,
            iconColor: context.appTextPalette.primary,
            icon: const Icon(Icons.search_rounded),
            onPressed: onSearchTap,
          ),
        ],
      ),
    );
  }
}
