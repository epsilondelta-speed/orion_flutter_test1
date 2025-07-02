import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'orion_flutter.dart';
import 'orion_network_tracker.dart';

class OrionManualTracker {
  static final Map<String, _ManualScreenMetrics> _screenMetrics = {};
  static final List<String> _screenHistoryStack = [];

  /// 🔄 Start tracking a screen manually
  static void startTracking(String screenName) {
    debugPrint("🚀 [Orion] startTracking() called for: $screenName");

    if (_screenMetrics.containsKey(screenName)) {
      debugPrint("⚠️ [Orion] Already tracking screen: $screenName. Skipping.");
      return;
    }

    // 📚 Push to screen history
    _screenHistoryStack.add(screenName);
    debugPrint("📚 [Orion] Pushed $screenName to screen history");

    // Set current screen context for network tracking
    OrionNetworkTracker.setCurrentScreen(screenName);
    debugPrint("📍 OrionManualTracker: currentScreenName set to $screenName");

    // Start stopwatch and TTID/TTFD tracking
    final metrics = _ManualScreenMetrics(screenName);
    _screenMetrics[screenName] = metrics;
    metrics.begin();

    debugPrint("✅ [Orion] Started tracking screen: $screenName");
  }

  /// ✅ Finalize tracking and send beacon
  static void finalizeScreen(String screenName) {
    debugPrint("📥 [Orion] finalizeScreen() called for: $screenName");

    final metrics = _screenMetrics.remove(screenName);

    // 📚 Pop from screen history (only if it matches the top)
    if (_screenHistoryStack.isNotEmpty && _screenHistoryStack.last == screenName) {
      _screenHistoryStack.removeLast();
      debugPrint("📚 [Orion] Popped $screenName from screen history");
    }

    if (metrics == null) {
      debugPrint("⚠️ [Orion] No tracking data found for: $screenName. Skipping send.");
      return;
    }

    metrics.send();
    debugPrint("📤 [Orion] Sent metrics for screen: $screenName");
  }

  /// 📦 Peek the previous screen from stack (for back navigation)
  static String? getLastTrackedScreen() {
    if (_screenHistoryStack.length >= 2) {
      return _screenHistoryStack[_screenHistoryStack.length - 2];
    } else {
      debugPrint("⚠️ [Orion] No previous screen in history stack");
      return null;
    }
  }

  static bool hasTracked(String screenName) {
    final exists = _screenMetrics.containsKey(screenName);
    debugPrint("🔍 [Orion] hasTracked($screenName): $exists");
    return exists;
  }
}

class _ManualScreenMetrics {
  final String screenName;
  final Stopwatch _stopwatch = Stopwatch();
  int _ttid = -1;
  bool _ttfdCaptured = false;

  _ManualScreenMetrics(this.screenName);

  void begin() {
    _stopwatch.start();
    debugPrint("⏱️ [Orion] Stopwatch started for $screenName");

    // TTID: after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ttid = _stopwatch.elapsedMilliseconds;
      debugPrint("📏 [$screenName] TTID: $_ttid ms");
    });

    // TTFD and frame data
    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      if (_ttfdCaptured) return;
      _ttfdCaptured = true;

      Future.delayed(const Duration(milliseconds: 500), () {
        final ttfd = _stopwatch.elapsedMilliseconds;
        final janky = _mockJankyFrames();
        final frozen = _mockFrozenFrames();

        _ttfdFinal = ttfd;
        _jankyFinal = janky;
        _frozenFinal = frozen;

        debugPrint("📏 [$screenName] TTFD: $ttfd ms | Janky: $janky | Frozen: $frozen");
      });
    });
  }

  int _ttfdFinal = -1;
  int _jankyFinal = 0;
  int _frozenFinal = 0;

  void send() {
    final networkData = OrionNetworkTracker.consumeRequestsForScreen(screenName);

    debugPrint("📦 [Orion] Preparing beacon for $screenName with ${networkData.length} network entries");

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
