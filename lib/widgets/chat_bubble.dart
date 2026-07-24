import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/date_utils.dart';
import '../models/message_model.dart';

/// Burbuja de mensaje limpia estilo fintech.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showTail = true,
  });

  final MessageModel message;
  final bool isMine;
  final bool showTail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: Text(
            message.text,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final bg = isMine
        ? (isDark ? AppColors.bubbleMineDark : AppColors.bubbleMineLight)
        : (isDark ? AppColors.bubbleOtherDark : AppColors.bubbleOtherLight);

    final fg = isMine
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    final timeColor = isMine
        ? Colors.white.withValues(alpha: 0.75)
        : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isMine ? AppSpacing.huge : 0,
            right: isMine ? 0 : AppSpacing.huge,
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : (showTail ? 4 : 18)),
              bottomRight: Radius.circular(isMine ? (showTail ? 4 : 18) : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                PicaflorDateUtils.timeOnly(message.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: timeColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Separador de día en el hilo del chat.
class ChatDaySeparator extends StatelessWidget {
  const ChatDaySeparator({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xxs + 2,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightBorder.withValues(alpha: 0.6),
            borderRadius: AppSpacing.pillRadius,
          ),
          child: Text(
            PicaflorDateUtils.daySeparator(date),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
