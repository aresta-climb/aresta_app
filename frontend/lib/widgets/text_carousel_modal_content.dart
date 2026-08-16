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
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.node.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemCount: widget.node.texts.length,
      itemBuilder: (context, index) {
        final textData = widget.node.texts[index];
        final isCurrentPage = index == _currentIndex;
        
        return ListView(
          controller: isCurrentPage ? widget.scrollController : null,
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: 20 + bottomPadding,
          ),
          children: [
            Column(
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.brandColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (textData.icon != null) ...[
                            Icon(textData.icon, color: AppColors.brandColor, size: 24),
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
                if (widget.node.texts.length > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.node.texts.length, (dotIndex) {
                      final active = dotIndex == _currentIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 8 : 6,
                        height: active ? 8 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? AppColors.brandColor : AppColors.brandColor.withValues(alpha: 0.3),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final content = MarkdownUtils.cleanModalContent(
                  textData.content,
                  textData.title,
                );
                return OfflineMarkdown(
                  data: content,
                  cragId: widget.node.cragId,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
