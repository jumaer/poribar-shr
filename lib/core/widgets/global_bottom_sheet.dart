import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlobalBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        final systemBottom = MediaQuery.of(ctx).viewPadding.bottom > 0
            ? MediaQuery.of(ctx).viewPadding.bottom
            : MediaQuery.of(ctx).padding.bottom;
        final dynamicBottomPadding = viewInsets > 0
            ? 16.0
            : (systemBottom > 0 ? systemBottom + 16.0 : 28.0);
        final screenHeight = MediaQuery.of(ctx).size.height;
        final maxHeight = (screenHeight - viewInsets) * 0.92;

        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            decoration: const BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppColors.iosDivider),
                left: BorderSide(color: AppColors.iosDivider),
                right: BorderSide(color: AppColors.iosDivider),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, dynamicBottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.iosDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (title != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
