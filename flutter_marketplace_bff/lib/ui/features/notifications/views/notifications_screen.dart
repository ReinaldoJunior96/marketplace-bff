import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../domain/models/app_notification.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/animations/fade_slide_in.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/illustration.dart';
import '../../../core/widgets/state_message.dart';
import '../view_models/notifications_view_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.viewModel});

  final NotificationsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final gutter = math.max(
      AppSpacing.lg,
      (MediaQuery.sizeOf(context).width - 720) / 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final notifications = viewModel.notifications;
          return RefreshIndicator(
            onRefresh: viewModel.poll,
            child: !viewModel.loaded
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      FadeSlideIn(
                        child: StateMessage(
                          illustration: AppIllustration.emptyNotifications,
                          title: 'Nenhuma notificação ainda',
                          message:
                              'Faça um pedido: o aviso chega aqui quando o '
                              'notification-service processar o evento.',
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      AppSpacing.sm,
                      gutter,
                      AppSpacing.xl,
                    ),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) => FadeSlideIn(
                      key: ValueKey(notifications[index].id),
                      delay: AppMotion.stagger * math.min(index, 8),
                      child: _NotificationTile(
                        notification: notifications[index],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.peach,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const FaIcon(
                FontAwesomeIcons.solidBell,
                size: 18,
                color: AppColors.terracotta,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        formatRelative(notification.sentAt),
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.mocha,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.mocha,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
