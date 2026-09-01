import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/services/ads_service.dart';

/// One on-screen banner placement. Collapses on no-fill. Disposes on leave.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({
    super.key,
    required this.ads,
    required this.placement,
    this.size,
    this.padding = const EdgeInsets.only(top: 8),
  });

  final AdsService ads;
  final String placement;
  final AdSize? size;
  final EdgeInsets padding;

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    widget.ads.addResumeListener(_onAdsResumed);
    _load();
  }

  @override
  void didUpdateWidget(covariant BannerAdSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement != widget.placement ||
        oldWidget.ads != widget.ads) {
      oldWidget.ads.removeResumeListener(_onAdsResumed);
      widget.ads.addResumeListener(_onAdsResumed);
      _ad?.dispose();
      _ad = null;
      _loaded = false;
      _load();
    }
  }

  void _onAdsResumed() {
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    final size = widget.size ?? AdSize.banner;
    final ad = await widget.ads.loadBanner(
      placement: widget.placement,
      size: size,
    );
    _loading = false;
    if (!mounted) {
      ad?.dispose();
      return;
    }
    setState(() {
      _ad = ad;
      _loaded = ad != null;
    });
  }

  @override
  void dispose() {
    widget.ads.removeResumeListener(_onAdsResumed);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: widget.padding,
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
