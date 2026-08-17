import 'package:flutter/material.dart';
import '../navigation/navigation_tree.dart';
import '../theme/app_colors.dart';
import '../view_functions/offline_markdown.dart';
import '../utils/markdown_utils.dart';
import '../view_functions/common_functions.dart';

class TextCarouselModalContent extends StatefulWidget {
  final TextCarouselNode node;
  final ScrollController scrollController;

  const TextCarouselModalContent({
    super.key,
    required this.node,
    required this.scrollController,
  });

  @override
  State<TextCarouselModalContent> createState() => _TextCarouselModalContentState();
}

class _TextCarouselModalContentState extends State<TextCarouselModalContent> {
  late PageController _pageController;
  late ValueNotifier<int> _currentIndexNotifier;

  @override
  void initState() {
    super.initState();
    _currentIndexNotifier = ValueNotifier<int>(widget.node.initialIndex);
    _pageController = PageController(initialPage: widget.node.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 16),
          child: Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.brandColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        if (widget.node.texts.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ValueListenableBuilder<int>(
              valueListenable: _currentIndexNotifier,
              builder: (context, currentIndex, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.node.texts.length, (dotIndex) {
                    final active = dotIndex == currentIndex;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 8 : 6,
                      height: active ? 8 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? AppColors.brandColor
                            : AppColors.brandColor.withValues(alpha: 0.3),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              _currentIndexNotifier.value = index;
            },
            itemCount: widget.node.texts.length,
            itemBuilder: (context, index) {
              final textData = widget.node.texts[index];

              return ValueListenableBuilder<int>(
                valueListenable: _currentIndexNotifier,
                builder: (context, currentIndex, child) {
                  final isCurrentPage = index == currentIndex;

                  return ListView(
                    key: ValueKey(index),
                    primary: false,
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 20 + bottomPadding,
                    ),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (textData.icon != null) ...[
                                  Icon(textData.icon,
                                      color: AppColors.brandColor, size: 24),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    textData.title.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          buildFeedbackButton(context, color: Colors.white),
                        ],
                      ),
                      const SizedBox(height: 16),
                      child!,
                    ],
                  );
                },
                child: OfflineMarkdown(
                  data: MarkdownUtils.cleanModalContent(
                    textData.content,
                    textData.title,
                  ),
                  cragId: widget.node.cragId,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
