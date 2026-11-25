import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/product_image_model.dart';

/// Full-screen image viewer with pinch-to-zoom up to 400% (M-DS-04).
/// Allows vintage shoppers to closely inspect fabric texture, labels, and defects.
class FullScreenZoomViewer extends StatefulWidget {
  final List<ProductImageModel> images;
  final int initialIndex;
  final String? title;

  const FullScreenZoomViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.title,
  });

  @override
  State<FullScreenZoomViewer> createState() => _FullScreenZoomViewerState();
}

class _FullScreenZoomViewerState extends State<FullScreenZoomViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(
      0,
      widget.images.isNotEmpty ? widget.images.length - 1 : 0,
    );
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            'Không có hình ảnh để hiển thị.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final currentImage = widget.images[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF141312),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Zoomable PageView
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _resetZoom();
                });
              },
              itemBuilder: (context, index) {
                final img = widget.images[index];
                return InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 1.0,
                  maxScale: 4.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Center(
                    child: Image.network(
                      img.imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryTerracotta,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white54,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Không tải được hình ảnh',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Top Bar Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null)
                            Text(
                              widget.title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            'Ảnh ${_currentIndex + 1} / ${widget.images.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.restart_alt_rounded,
                        color: Colors.white70,
                      ),
                      tooltip: 'Đặt lại phóng to',
                      onPressed: _resetZoom,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Bar Overlay (Defect notes & Thumbnail carousel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(
                  top: 16,
                  bottom: 20,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentImage.imageType == 'DEFECT_CLOSEUP' ||
                        currentImage.defectNote != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2214),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.starGold),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.starGold,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentImage.defectNote != null &&
                                        currentImage.defectNote!.isNotEmpty
                                    ? currentImage.defectNote!
                                    : 'Ảnh chụp cận cảnh vết khuyết điểm hoặc sờn mòn tự nhiên.',
                                style: const TextStyle(
                                  color: AppColors.creamBadgeBg,
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.images.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, idx) {
                          final thumb = widget.images[idx];
                          final isSelected = idx == _currentIndex;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                idx,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.creamBadgeBg
                                      : Colors.white24,
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.starGold
                                              .withValues(alpha: 0.35),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  thumb.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey[850],
                                        child: const Icon(
                                          Icons.broken_image_rounded,
                                          size: 18,
                                          color: Colors.white30,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
