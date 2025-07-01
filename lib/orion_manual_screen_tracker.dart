import 'package:flutter/material.dart';
import 'dart:developer';
import 'orion_flutter.dart';
import 'orion_network_tracker.dart';

/// Manual screen tracker for apps that use custom navigation (e.g., go_router, deep links).
/// Allows you to explicitly track when screens start and finish.
class OrionManualTracker {
  static final Map<String, _ScreenMetrics> _screenMetrics = {};

  /// Call this when navigating **away** from a screen.
  static void finalizeScreen(String screenName) {
    final metrics = _screenMetrics.remove(screenName);
    metrics?.send();
  }

  /// Call this when navigating **to** a new screen.
  static void startTracking(String screenName) {
    final metrics = _ScreenMetrics(screenName);
    _screenMetrics[screenName] = metrics;
    metrics.begin();
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

    // Capture TTID: first frame render complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ttid = _stopwatch.elapsedMilliseconds;
      debugPrint("📏 [$screenName] TTID: $_ttid ms");
    });

    // Capture TTFD, Janky, Frozen after layout stabilizes
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
    debugPrint("📦 Sending screen metrics for $screenName with ${networkData.length} requests");

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
