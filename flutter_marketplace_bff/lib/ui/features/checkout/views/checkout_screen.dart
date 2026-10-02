import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/animations/circular_reveal_route.dart';
import '../../../core/animations/fade_slide_in.dart';
import '../../../core/app_scope.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../view_models/checkout_view_model.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  CheckoutViewModel? _viewModel;
  late int _itemCount;
  late int _totalInCents;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) return;
    final scope = AppScope.of(context);
    // Guarda o resumo: o carrinho é esvaziado quando o pedido é criado.
    _itemCount = scope.cart.itemCount;
    _totalInCents = scope.cart.totalInCents;
    _viewModel = CheckoutViewModel(
      cart: scope.cart,
      orderRepository: scope.orderRepository,
    )..addListener(_onStateChanged);
  }

  void _onStateChanged() {
    final state = _viewModel!.state;
    if (state is! CheckoutSuccess || !mounted) return;
    HapticFeedback.heavyImpact();
    Navigator.of(context).pushReplacement(
      CircularRevealRoute<void>(
        center: Alignment.bottomCenter,
        builder: (_) => OrderConfirmationScreen(
          order: state.order,
          correlationId: state.correlationId,
          totalInCents: state.totalInCents,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel!;
    final textTheme = Theme.of(context).textTheme;
    final gutter = math.max(
      AppSpacing.lg,
      (MediaQuery.sizeOf(context).width - 560) / 2,
    );

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final state = viewModel.state;

        return PopScope(
          canPop: !viewModel.isProcessing,
          child: Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: const Text('Pagamento'),
                  backgroundColor: AppColors.cream,
                  surfaceTintColor: Colors.transparent,
                ),
                body: ListView(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.sm,
                    gutter,
                    AppSpacing.xl,
                  ),
                  children: [
                    const FadeSlideIn(child: _FakeCreditCard()),
                    const SizedBox(height: AppSpacing.xl),
                    FadeSlideIn(
                      delay: AppMotion.stagger * 2,
                      child: Text('Resumo', style: textTheme.titleLarge),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      delay: AppMotion.stagger * 3,
                      child: _OrderSummary(
                        itemCount: _itemCount,
                        totalInCents: _totalInCents,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FadeSlideIn(
                      delay: AppMotion.stagger * 4,
                      child: const _DemoNotice(),
                    ),
                    if (state is CheckoutFailure) ...[
                      const SizedBox(height: AppSpacing.lg),
                      FadeSlideIn(
                        child: _FailureNotice(message: state.message),
                      ),
                    ],
                  ],
                ),
                bottomNavigationBar: _PayBar(
                  totalInCents: _totalInCents,
                  retry: state is CheckoutFailure,
                  onPay: viewModel.isProcessing ? null : viewModel.pay,
                ),
              ),
              _ProcessingOverlay(
                step: switch (state) {
                  CheckoutProcessing(:final step) => step,
                  _ => null,
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Cartão ilustrativo — o pagamento é simulado.
class _FakeCreditCard extends StatelessWidget {
  const _FakeCreditCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const onCard = AppColors.cream;

    return Semantics(
      label: 'Cartão de demonstração final 4242',
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: AspectRatio(
          aspectRatio: 1.6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.terracotta,
                  Color(0xFFC57A5C),
                  AppColors.clay,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.terracotta.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Stack(
                children: [
                  Positioned(
                    right: -50,
                    top: -60,
                    child: _CardCircle(size: 200, alpha: 0.12),
                  ),
                  Positioned(
                    left: -40,
                    bottom: -90,
                    child: _CardCircle(size: 220, alpha: 0.08),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.leaf,
                                size: 18,
                                color: onCard,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'TerraShop Card',
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: onCard,
                                  ),
                                ),
                              ),
                              const FaIcon(
                                FontAwesomeIcons.wifi,
                                size: 16,
                                color: onCard,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            width: 42,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.sand,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FittedBox(
                            child: Text(
                              '••••  ••••  ••••  4242',
                              style: textTheme.headlineSmall?.copyWith(
                                color: onCard,
                                letterSpacing: 2,
                                fontFamily: 'DMSans',
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'CLIENTE TERRASHOP',
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: onCard,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Text(
                                '12/30',
                                style: textTheme.labelMedium?.copyWith(
                                  color: onCard,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              const FaIcon(
                                FontAwesomeIcons.ccVisa,
                                size: 30,
                                color: onCard,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardCircle extends StatelessWidget {
  const _CardCircle({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.itemCount, required this.totalInCents});

  final int itemCount;
  final int totalInCents;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.mocha);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _SummaryRow(
              icon: FontAwesomeIcons.boxOpen,
              label: itemCount == 1 ? '1 item' : '$itemCount itens',
              value: formatBrl(totalInCents),
              style: muted,
            ),
            const SizedBox(height: AppSpacing.md),
            _SummaryRow(
              icon: FontAwesomeIcons.truckFast,
              label: 'Entrega',
              value: 'Grátis',
              style: muted,
            ),
            const Divider(height: AppSpacing.xl, color: AppColors.stone),
            Row(
              children: [
                Expanded(child: Text('Total', style: textTheme.titleLarge)),
                Text(
                  formatBrl(totalInCents),
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.terracotta,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.style,
  });

  final FaIconData icon;
  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: AppColors.mocha),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaIcon(
            FontAwesomeIcons.circleInfo,
            size: 16,
            color: AppColors.olive,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Pagamento de demonstração: nada é cobrado. O pedido é criado de '
              'verdade no BFF e você acompanha os serviços reagindo na próxima '
              'tela.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.espresso, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureNotice extends StatelessWidget {
  const _FailureNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.triangleExclamation,
            size: 16,
            color: AppColors.terracotta,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Não foi possível concluir: $message Seu carrinho foi mantido.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayBar extends StatelessWidget {
  const _PayBar({
    required this.totalInCents,
    required this.retry,
    required this.onPay,
  });

  final int totalInCents;
  final bool retry;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.linen,
        border: Border(top: BorderSide(color: AppColors.stone)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: onPay,
            icon: const FaIcon(FontAwesomeIcons.lock, size: 16),
            label: Text(
              retry ? 'Tentar novamente' : 'Pagar ${formatBrl(totalInCents)}',
            ),
          ),
        ),
      ),
    );
  }
}

/// Véu com as etapas do pagamento enquanto ele é processado.
class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.step});

  final PaymentStep? step;

  static const _labels = {
    PaymentStep.validatingCard: 'Validando cartão',
    PaymentStep.authorizingPayment: 'Autorizando pagamento',
    PaymentStep.creatingOrder: 'Criando pedido no BFF',
  };

  @override
  Widget build(BuildContext context) {
    final step = this.step;
    final textTheme = Theme.of(context).textTheme;

    return IgnorePointer(
      ignoring: step == null,
      child: AnimatedOpacity(
        opacity: step == null ? 0 : 1,
        duration: AppMotion.fast,
        child: ColoredBox(
          color: AppColors.espresso.withValues(alpha: 0.45),
          child: Center(
            child: AnimatedScale(
              scale: step == null ? 0.9 : 1,
              duration: AppMotion.medium,
              curve: Curves.easeOutBack,
              child: Material(
                color: AppColors.linen,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Processando', style: textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.lg),
                      for (final candidate in PaymentStep.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _StepRow(
                            label: _labels[candidate]!,
                            status: step == null
                                ? _StepStatus.pending
                                : candidate.index < step.index
                                ? _StepStatus.done
                                : candidate == step
                                ? _StepStatus.active
                                : _StepStatus.pending,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _StepStatus { pending, active, done }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.status});

  final String label;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: 24,
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: switch (status) {
              _StepStatus.done => const CircleAvatar(
                key: ValueKey('done'),
                backgroundColor: AppColors.olive,
                child: FaIcon(
                  FontAwesomeIcons.check,
                  size: 11,
                  color: Colors.white,
                ),
              ),
              _StepStatus.active => const Padding(
                key: ValueKey('active'),
                padding: EdgeInsets.all(3),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              _StepStatus.pending => Container(
                key: const ValueKey('pending'),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.stone, width: 2),
                ),
              ),
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: status == _StepStatus.pending
                  ? AppColors.mocha
                  : AppColors.espresso,
              fontWeight: status == _StepStatus.active
                  ? FontWeight.w700
                  : FontWeight.w400,
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
