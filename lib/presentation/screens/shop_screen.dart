import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../bloc/economy/economy_bloc.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_status_bar.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EconomyBloc, EconomyBlocState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                TopStatusBar(
                  coins: state.economy.coins,
                  lives: state.economy.lives,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    children: [
                      Text(AppStrings.shop, style: AppTextStyles.heading(context)),
                      const SizedBox(height: AppDimensions.paddingL),
                      _CoinBundle(
                        coins: 500,
                        price: '\$0.99',
                        onBuy: () => _stubPurchase(context, 500),
                      ),
                      _CoinBundle(
                        coins: 2000,
                        price: '\$2.99',
                        badge: AppStrings.bestValue,
                        onBuy: () => _stubPurchase(context, 2000),
                      ),
                      _CoinBundle(
                        coins: 5000,
                        price: '\$6.99',
                        onBuy: () => _stubPurchase(context, 5000),
                      ),
                      const SizedBox(height: AppDimensions.paddingL),
                      _ShopItem(
                        title: AppStrings.boosterPack,
                        subtitle: '5× Hint, 3× Magnet, 3× Magic Wand',
                        price: '200 coins',
                        onTap: () {
                          if (state.economy.coins >= 200) {
                            context.read<EconomyBloc>().add(const SpendCoins(200));
                            final b = state.economy.boosters;
                            context.read<EconomyBloc>().add(UpdateBoosters(
                                  b.copyWith(
                                    hint: b.hint + 5,
                                    magnet: b.magnet + 3,
                                    magicWand: b.magicWand + 3,
                                  ),
                                ));
                          }
                        },
                      ),
                      _ShopItem(
                        title: AppStrings.removeAds,
                        subtitle: state.economy.noAdsPurchased
                            ? AppStrings.noAdsPurchased
                            : 'One-time purchase (stub)',
                        price: '\$4.99',
                        onTap: () {
                          context.read<EconomyBloc>().add(const PurchaseNoAds());
                        },
                      ),
                      _ShopItem(
                        title: AppStrings.freeReward,
                        subtitle: 'Daily free coins',
                        price: 'FREE',
                        onTap: () {
                          context.read<EconomyBloc>().add(const EarnCoins(25));
                        },
                      ),
                    ],
                  ),
                ),
                const BottomNavBar(currentIndex: 1),
              ],
            ),
          ),
        );
      },
    );
  }

  void _stubPurchase(BuildContext context, int coins) {
    context.read<EconomyBloc>().add(EarnCoins(coins));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Stub IAP: +$coins coins')),
    );
  }
}

class _CoinBundle extends StatelessWidget {
  const _CoinBundle({
    required this.coins,
    required this.price,
    required this.onBuy,
    this.badge,
  });

  final int coins;
  final String price;
  final VoidCallback onBuy;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          const Icon(Icons.monetization_on, color: AppColors.accentGold, size: 32),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$coins ${AppStrings.coins}', style: AppTextStyles.subheading(context)),
                if (badge != null)
                  Text(badge!, style: AppTextStyles.caption(context).copyWith(color: AppColors.accentGreen)),
              ],
            ),
          ),
          ElevatedButton(onPressed: onBuy, child: Text(price)),
        ],
      ),
    );
  }
}

class _ShopItem extends StatelessWidget {
  const _ShopItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.subheading(context)),
                Text(subtitle, style: AppTextStyles.caption(context)),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: Text(price)),
        ],
      ),
    );
  }
}
