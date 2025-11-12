import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/env.dart';

/// AdMob 배너 광고 위젯
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  /// 광고 로드
  void _loadAd() {
    // TODO(ongi): Premium 사용자는 광고 표시 안 함
    // final isPremium = ref.read(isPremiumProvider);
    // if (isPremium) return;

    final adUnitId = Platform.isAndroid
        ? Env.admobBannerIdAndroid
        : Env.admobBannerIdIos;

    if (adUnitId.isEmpty) {
      // 테스트용 광고 ID (개발 중 사용)
      final testAdUnitId = Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Android 테스트
          : 'ca-app-pub-3940256099942544/2934735716'; // iOS 테스트

      _bannerAd = BannerAd(
        adUnitId: testAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            setState(() => _isAdLoaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            print('광고 로드 실패: $error');
            ad.dispose();
          },
        ),
      );

      _bannerAd?.load();
    } else {
      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            setState(() => _isAdLoaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            print('광고 로드 실패: $error');
            ad.dispose();
          },
        ),
      );

      _bannerAd?.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO(ongi): Premium 체크 후 광고 숨김
    // final isPremium = ref.watch(isPremiumProvider);
    // if (isPremium) return const SizedBox.shrink();

    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox(
        height: 50, // 광고 높이만큼 공간 확보
      );
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

