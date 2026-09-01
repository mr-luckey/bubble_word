import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/bloc/economy/economy_bloc.dart';
import '../../presentation/widgets/ads/banner_ad_slot.dart';
import '../config/ads_config.dart';
import '../di/injection.dart';
import '../services/ads_service.dart';

/// Bottom banner for one named placement. Collapses on no-fill / no ads.
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({
    super.key,
    this.placement = AdsPlacements.home,
  });

  final String placement;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EconomyBloc, EconomyBlocState>(
      buildWhen: (prev, curr) =>
          prev.economy.noAdsPurchased != curr.economy.noAdsPurchased,
      builder: (context, state) {
        if (state.economy.noAdsPurchased) return const SizedBox.shrink();
        if (!getIt.isRegistered<AdsService>()) return const SizedBox.shrink();
        return BannerAdSlot(
          ads: getIt<AdsService>(),
          placement: placement,
        );
      },
    );
  }
}
