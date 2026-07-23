import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ad_constants.dart';
import '../../presentation/bloc/economy/economy_bloc.dart';

/// Bottom banner — tries [AdConstants.bannerIds] 1-by-1 until one loads.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  int _loadGen = 0;

  @override
  void initState() {
    super.initState();
    _loadBannerWaterfall();
  }

  void _loadBannerWaterfall() {
    final ids = AdConstants.bannerIds;
    if (ids.isEmpty) return;
    final gen = ++_loadGen;
    _tryBannerAt(0, ids, gen);
  }

  void _tryBannerAt(int index, List<String> ids, int gen) {
    if (!mounted || gen != _loadGen) return;
    if (index >= ids.length) {
      if (mounted) setState(() => _loaded = false);
      return;
    }

    final banner = BannerAd(
      adUnitId: ids[index],
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || gen != _loadGen) {
            ad.dispose();
            return;
          }
          // First success — stop waterfall (no further IDs).
          setState(() {
            _bannerAd = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted || gen != _loadGen) return;
          _tryBannerAt(index + 1, ids, gen);
        },
      ),
    );
    banner.load();
  }

  @override
  void dispose() {
    _loadGen++;
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EconomyBloc, EconomyBlocState>(
      buildWhen: (prev, curr) =>
          prev.economy.noAdsPurchased != curr.economy.noAdsPurchased,
      builder: (context, state) {
        if (state.economy.noAdsPurchased) return const SizedBox.shrink();
        final ad = _bannerAd;
        if (!_loaded || ad == null) {
          return SizedBox(
            width: double.infinity,
            height: AdSize.banner.height.toDouble(),
          );
        }
        return SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        );
      },
    );
  }
}
