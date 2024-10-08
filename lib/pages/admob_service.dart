import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';



///https://stackoverflow.com/questions/50972863/admob-banner-how-to-show-only-on-home
///
class AdmobService {
  static BannerAd _bannerAd;
  //static InterstitialAd _interstitialAd;

  static BannerAd get bannerAd => _bannerAd;
  static String get bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-8047662979700/68640827'
      : 'ca-app-pub-394025642544/2934716';

  static initialize() {
    if (MobileAds.instance == null) {
      print("initialize:AdMob");
      MobileAds.instance.initialize();
    }
  }

  static BannerAd createBannerAd() {
    BannerAd ad = new BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.largeBanner,
      request: AdRequest(),
      //listener: null,
      listener: AdListener(
        onAdLoaded: (Ad ad) => print('Ad loaded.'),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('Ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => print('Ad opened.'),
        onAdClosed: (Ad ad) => print('Ad closed.'),
        onApplicationExit: (Ad ad) => print('Left application.'),
      ),
    );

    return ad;
  }

  static BannerAd createBannerAdSmall() {
    BannerAd ad = new BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      //listener: null,
      listener: AdListener(
        onAdLoaded: (Ad ad) => print('Ad loaded.'),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('Ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => print('Ad opened.'),
        onAdClosed: (Ad ad) => print('Ad closed.'),
        onApplicationExit: (Ad ad) => print('Left application.'),
      ),
    );

    return ad;
  }

  static void showBannerAd() {
    if (_bannerAd != null) {
      return;
    }
    _bannerAd = createBannerAd();
    _bannerAd..load();
  }

  void disposeAds() {
    print("disposeAds");
    if (_bannerAd != null) {
      _bannerAd?.dispose();
    }
  }

  // static InterstitialAd _createInterstitialAd() {
  //   return InterstitialAd(
  //     adUnitId: iOSInterstitialAdUnitID,
  //     request: AdRequest(),
  //     listener: AdListener(
  //         onAdLoaded: (Ad ad) => {_interstitialAd.show()},
  //         onAdFailedToLoad: (Ad ad, LoadAdError error) {
  //           print('Ad failed to load: $error');
  //         },
  //         onAdOpened: (Ad ad) => print('Ad opened.'),
  //         onAdClosed: (Ad ad) => {_interstitialAd.dispose()},
  //         onApplicationExit: (Ad ad) => {_interstitialAd.dispose()}),
  //   );
  // }
  //
  // static void showInterstitialAd() {
  //   _interstitialAd?.dispose();
  //   _interstitialAd = null;
  //
  //   if (_interstitialAd == null) _interstitialAd = _createInterstitialAd();
  //
  //   _interstitialAd.load();
  // }
}
