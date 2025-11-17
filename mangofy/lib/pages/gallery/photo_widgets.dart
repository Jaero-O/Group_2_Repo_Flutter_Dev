import 'package:flutter/material.dart';

/// A reusable grid item widget for displaying a generic photo placeholder.
class PhotoGridItemPlaceholder extends StatelessWidget {
  final double iconSize;
  final double borderRadius;

  const PhotoGridItemPlaceholder({
    super.key,
    this.iconSize = 40,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.photo,
        color: Colors.grey,
        size: iconSize,
      ),
    );
  }
}

/// A reusable widget to display a grid of photo placeholders.
class PhotoGridPlaceholder extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double borderRadius;
  final double iconSize;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;

  const PhotoGridPlaceholder({
    super.key,
    required this.itemCount,
    this.crossAxisCount = 4,
    this.crossAxisSpacing = 4,
    this.mainAxisSpacing = 4,
    this.borderRadius = 8,
    this.iconSize = 40,
    this.shrinkWrap = false,
    this.physics,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return PhotoGridItemPlaceholder(
          iconSize: iconSize,
          borderRadius: borderRadius,
        );
      },
    );
  }
}