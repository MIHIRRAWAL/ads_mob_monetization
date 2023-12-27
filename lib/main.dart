import 'dart:io' show Platform;
import 'package:ads_mob_monetization/core/ads_id_holder.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/dummy_json.dart';
import 'core/dummy_json_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

const int maxFailedLoadAttempts = 3;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BannerAd? _bannerAd;
  BannerAd? _bottomBannerAd;
  InterstitialAd? _interstitialAd;
  int _numBannerAdLoadAttempt = 0;
  late NewsDummyJson dummyData;
  bool _inlineBannerAd = false;

  @override
  void initState() {
    super.initState();
    MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
        testDeviceIds: [
          Platform.isAndroid ? AdIdhelper.androidAppId : AdIdhelper.iosAppId
        ]));
    dummyData = NewsDummyJson.fromJson(newsDummyList);
    _createInlineBannerAd();
    _createBottomBannerAd();
    _createInterstitialAd();
  }

  void _createInlineBannerAd() {
    _bannerAd = BannerAd(
      size: AdSize.mediumRectangle,
      adUnitId: AdIdhelper.bannerAd,
      request: request,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _inlineBannerAd = true;
          });
        },
        onAdFailedToLoad: (error, ad) {
          debugPrint('bannerad failed to load: $error.');
          _numBannerAdLoadAttempt += 1;
          _bannerAd = null;
          if (_numBannerAdLoadAttempt < maxFailedLoadAttempts) {
            _createInlineBannerAd();
          }
        },
      ),
    );
    _bannerAd?.load();
  }

  void _createBottomBannerAd() {
    _bottomBannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: AdIdhelper.bannerAd,
      request: request,
      listener: BannerAdListener(
        onAdLoaded: (_) {},
        onAdFailedToLoad: (error, ad) {
          debugPrint('bannerad failed to load: $error.');
          _numBannerAdLoadAttempt += 1;
          _bottomBannerAd = null;
          if (_numBannerAdLoadAttempt < maxFailedLoadAttempts) {
            _createBottomBannerAd();
          }
        },
      ),
    );
    _bottomBannerAd?.load();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdIdhelper.interstitialAd,
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _createInterstitialAd();
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _bannerAd?.dispose();
    _bottomBannerAd?.dispose();
    _interstitialAd?.dispose();
  }

  AdRequest request = const AdRequest(
    keywords: <String>['foo', 'bar'],
    contentUrl: 'http://foo.com/bar.html',
    nonPersonalizedAds: true,
  );

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (BuildContext context) {
        return SafeArea(
          child: Scaffold(
              bottomNavigationBar: Container(
                decoration:
                    const BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    spreadRadius: 2,
                    blurRadius: 2,
                  )
                ]),
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                width: _bannerAd!.size.width.toDouble(),
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AdWidget(ad: _bottomBannerAd!),
                ),
              ),
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: Colors.blue,
                title: const Text(
                  'AdMob Plugin example app',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              body: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                    itemCount:
                        dummyData.articles.length - (_inlineBannerAd ? 1 : 0),
                    itemBuilder: (cxt, i) {
                      if (_inlineBannerAd && i == 3) {
                        return Container(
                          padding: const EdgeInsets.only(bottom: 10, top: 10),
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(
                            ad: _bannerAd!,
                          ),
                        );
                      } else {}
                      return GestureDetector(
                        onTap: () {
                          _showInterstitialAd();
                        },
                        child: AbsorbPointer(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              elevation: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 150,
                                    decoration: const BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            topRight: Radius.circular(10))),
                                    width: MediaQuery.of(context).size.width,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 220,
                                          child: Text(
                                            dummyData.articles[i].title,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                          width: 260,
                                          child: Text(
                                            dummyData.articles[i].description,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
              )),
        );
      }),
    );
  }
}
