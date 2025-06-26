
import 'package:flutter/material.dart';
import 'orion_flutter.dart';
import 'orion_network_tracker.dart';

class OrionManualTracker {
  static final Map<String, _ScreenMetrics> _activeScreens = {};

  static void trackScreen(String screenName) {
    OrionNetworkTracker.setCurrentScreen(screenName);
    debugPrint("📍 OrionManualTracker: currentScreenName set to $screenName");

    final metrics = _ScreenMetrics(screenName);
    metrics.begin();
    _activeScreens[screenName] = metrics;
  }

  static void finalizeScreen(String screenName) {
    final metrics = _activeScreens.remove(screenName);
    if (metrics != null) {
      metrics.send();
    } else {
      debugPrint("⚠️ OrionManualTracker: Tried to finalize unknown screen $screenName");
    }
  }
}

class _ScreenMetrics {
  final String screenName;
  final Stopwatch _stopwatch = Stopwatch();
  int _ttid = -1;
  bool _ttfdCaptured = false;

  _ScreenMetrics(this.screenName);

  void begin() {
    _stopwatch.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ttid = _stopwatch.elapsedMilliseconds;
      debugPrint("📏 [$screenName] TTID: $_ttid ms");
    });

    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      if (_ttfdCaptured) return;
      _ttfdCaptured = true;

      Future.delayed(const Duration(milliseconds: 500), () {
        final ttfd = _stopwatch.elapsedMilliseconds;
        final janky = _mockJankyFrames();
        final frozen = _mockFrozenFrames();

        debugPrint("📏 [$screenName] TTFD: $ttfd ms | Janky: $janky | Frozen: $frozen");

        _ttfdFinal = ttfd;
        _jankyFinal = janky;
        _frozenFinal = frozen;
      });
    });
  }

  int _ttfdFinal = -1;
  int _jankyFinal = 0;
  int _frozenFinal = 0;

  void send() {
    final networkData = OrionNetworkTracker.consumeRequestsForScreen(screenName);
    debugPrint("📦 [OrionManualTracker] Sending metrics for $screenName");

    OrionFlutter.trackFlutterScreen(
      screen: screenName,
      ttid: _ttid,
      ttfd: _ttfdFinal,
      jankyFrames: _jankyFinal,
      frozenFrames: _frozenFinal,
      network: networkData,
    );
  }

  int _mockJankyFrames() => 0;
  int _mockFrozenFrames() => 0;
}
