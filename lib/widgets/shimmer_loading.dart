import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerLoading extends StatelessWidget {
  final int itemCount;
  final double height;
  final double? width;
  final BorderRadius borderRadius;
  
  const ShimmerLoading({
    super.key,
    this.itemCount = 3,
    this.height = 100,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: borderRadius,
            ),
          );
        },
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: AppTheme.radiusM,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Container(
                      height: 10,
                      width: 100,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(height: 10, width: double.infinity, color: Colors.grey.shade300),
          const SizedBox(height: AppTheme.spacingS),
          Container(height: 10, width: 200, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}