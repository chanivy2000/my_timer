import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const StopwatchScreen(),
    );
  }
}

// ================= Data Models =================
class ColorItem {
  final String name;
  final Color color;
  bool isUnlocked;
  ColorItem({required this.name, required this.color, this.isUnlocked = false});
}

class TimeFormatItem {
  final String id;
  final String label;
  final String example;
  bool isUnlocked;
  TimeFormatItem({required this.id, required this.label, required this.example, this.isUnlocked = false});
}

class LapRecord {
  final int index;
  final String totalTime;
  final String lapTime;
  LapRecord({required this.index, required this.totalTime, required this.lapTime});
}

class WordPair {
  final String id;
  final String english;
  final String chinese;
  WordPair({required this.id, required this.english, required this.chinese});
}

enum NumberStyle { stroke, solid, classic }

// ================= Main Stopwatch Screen =================
class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _displayTime = "00:00.00";

  bool _isCountdownMode = false;
  int _countdownTotalMs = 0;
  int _countdownRemainingMs = 0;

  Color _bgColor = Colors.black;
  Color _textColor = Colors.white;
  String _currentFormatId = "m:s.ms";
  NumberStyle _numberStyle = NumberStyle.stroke;

  final List<LapRecord> _laps = [];
  int _lastLapMilliseconds = 0;
  final bool _unlimitedLaps = false;

  bool _showTranslationMode = false;
  bool _isEnglishShowing = true;
  int _currentWordIndex = 0;
  Timer? _wordTimer;


  final List<WordPair> _words = [
    WordPair(id: '1', english: "Focus", chinese: "專注"),
    WordPair(id: '2', english: "Persist", chinese: "堅持"),
    WordPair(id: '3', english: "Study", chinese: "學習"),
  ];

  final List<ColorItem> _colorLibrary = [
    ColorItem(name: 'Classic Black', color: Colors.black, isUnlocked: true),
    ColorItem(name: 'White Wood', color: const Color(0xFFF5F5F5), isUnlocked: true),
    ColorItem(name: 'Grey Walnut', color: const Color(0xFF8D7B68)),
    ColorItem(name: 'Light Oak', color: const Color(0xFFB0A8B9)),
    ColorItem(name: 'Yellow Pine', color: const Color(0xFFD4A373)),
    ColorItem(name: 'Cocoa Cream', color: const Color(0xFFC9A78D)),
    ColorItem(name: 'Black Wood', color: const Color(0xFF2C2C2C)),
    ColorItem(name: 'Red Oak', color: const Color(0xFF7B3F3F)),
  ];

  final List<TimeFormatItem> _formatLibrary = [
    TimeFormatItem(id: "h:m", label: "h:m", example: "Hour:Minute", isUnlocked: true),
    TimeFormatItem(id: "m:s", label: "m:s", example: "Minute:Second", isUnlocked: true),
    TimeFormatItem(id: "m:s.ms", label: "m:s.ms", example: "Minute:Second.Ms", isUnlocked: true),
    TimeFormatItem(id: "s.ms", label: "s.ms", example: "Second.Ms", isUnlocked: true),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _wordTimer?.cancel();
    super.dispose();
  }

  Color get _iconColor => _bgColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white54;
  Color get _strokeColor => _bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  Future<void> _notifyFinish() async {
  }

  Future<bool> _showAdConfirm(String title, String content) async {
    if (!mounted) return false;
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Watch Ad")),
        ],
      ),
    );
    if (confirm != true) return false;
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  void _toggleStopwatch() {
    setState(() {
      if (_isCountdownMode) {
        _toggleCountdown();
      } else {
        _toggleCountUp();
      }
    });
  }

  void _toggleCountUp() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
      _wordTimer?.cancel();
    } else {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() => _displayTime = _formatTime(_stopwatch.elapsedMilliseconds));
      });
      if (_showTranslationMode && _words.isNotEmpty) _startWordRotation();
    }
  }

  void _toggleCountdown() {
    if (_countdownTotalMs == 0) {
      _showSetTimeDialog();
      return;
    }
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _wordTimer?.cancel();
      setState(() {});
    } else {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _countdownRemainingMs -= 100;
          if (_countdownRemainingMs <= 0) {
            _countdownRemainingMs = 0;
            _timer?.cancel();
            _wordTimer?.cancel();
            _notifyFinish();
            _showTimeUpDialog();
          }
          _displayTime = _formatTime(_countdownRemainingMs);
        });
      });
      if (_showTranslationMode && _words.isNotEmpty) _startWordRotation();
    }
  }

  void _showTimeUpDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Text("⏰ Time's Up!",
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ),
        content: const Text("Your countdown has finished.",
            style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: Colors.greenAccent, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  void _startWordRotation() {
    _wordTimer?.cancel();
    _wordTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        if (_words.isNotEmpty) {
          _currentWordIndex = (_currentWordIndex + 1) % _words.length;
          _isEnglishShowing = true;
        }
      });
    });
  }

  void _resetStopwatch() {
    setState(() {
      if (_isCountdownMode) {
        _timer?.cancel();
        _wordTimer?.cancel();
        _countdownRemainingMs = _countdownTotalMs;
        _displayTime = _formatTime(_countdownRemainingMs);
      } else {
        _stopwatch.stop();
        _stopwatch.reset();
        _timer?.cancel();
        _wordTimer?.cancel();
        _displayTime = _formatTime(0);
        _lastLapMilliseconds = 0;
      }
      _laps.clear();
    });
  }

  void _recordLap() {
    if (!_stopwatch.isRunning) return;

    if (!_unlimitedLaps && _laps.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lap limit reached (10). Watch an ad to unlock unlimited laps."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    int currentMs = _stopwatch.elapsedMilliseconds;
    int lapMs = currentMs - _lastLapMilliseconds;
    setState(() {
      _laps.add(LapRecord(
        index: _laps.length + 1,
        totalTime: _formatTime(currentMs),
        lapTime: _formatTime(lapMs),
      ));
      _lastLapMilliseconds = currentMs;
    });
  }

  String _formatTime(int milliseconds) {
    if (milliseconds < 0) milliseconds = 0;
    int totalSeconds = (milliseconds / 1000).truncate();
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    int tenths = ((milliseconds % 1000) / 100).truncate();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    switch (_currentFormatId) {
      case "h:m":
        return "${twoDigits(hours)}:${twoDigits(minutes)}";
      case "m:s":
        return "${twoDigits(minutes)}:${twoDigits(seconds)}";
      case "m:s.ms":
        return "${twoDigits(minutes)}:${twoDigits(seconds)}.${twoDigits(tenths)}";
      case "s.ms":
        return "${twoDigits(seconds)}.${twoDigits(tenths)}";
      default:
        return "${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
  }

  void _goToWordManager() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => WordManagerScreen(initialWords: _words)));
    setState(() {});
  }

  void _cycleNumberStyle() {
    setState(() {
      switch (_numberStyle) {
        case NumberStyle.stroke:
          _numberStyle = NumberStyle.solid;
          break;
        case NumberStyle.solid:
          _numberStyle = NumberStyle.classic;
          break;
        case NumberStyle.classic:
          _numberStyle = NumberStyle.stroke;
          break;
      }
    });
  }

  IconData _numberStyleIcon() {
    switch (_numberStyle) {
      case NumberStyle.stroke:
        return Icons.blur_on;
      case NumberStyle.solid:
        return Icons.format_bold;
      case NumberStyle.classic:
        return Icons.linear_scale;
    }
  }

  void _randomUnlockColor() async {
    List<ColorItem> lockedColors = _colorLibrary.where((c) => !c.isUnlocked).toList();
    if (lockedColors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All colors unlocked!")));
      return;
    }
    bool adWatched = await _showAdConfirm("Watch Ad", "Watch a short ad to unlock a random color!");
    if (adWatched && mounted) {
      Random random = Random();
      ColorItem unlockedColor = lockedColors[random.nextInt(lockedColors.length)];
      setState(() {
        unlockedColor.isUnlocked = true;
        _bgColor = unlockedColor.color;
        _textColor = unlockedColor.color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Unlocked: ${unlockedColor.name}!")));
    }
  }

  bool get _isRunning =>
      _isCountdownMode ? (_timer != null && _timer!.isActive) : _stopwatch.isRunning;

  @override
  Widget build(BuildContext context) {
    WordPair? currentWord = _words.isNotEmpty ? _words[_currentWordIndex % _words.length] : null;

    return Scaffold(
      body: Container(
        color: _bgColor,
        child: Stack(
          children: [
            // ✅ Full-height column, no Spacer, timer takes remaining space
            Column(
              children: [
                // ===== Timer: takes ALL remaining space =====
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 60, 8, 6),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _strokeColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _strokeColor.withValues(alpha: 0.3), width: 3),
                        boxShadow: [
                          BoxShadow(color: _strokeColor.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: _buildNumber(_displayTime),
                        ),
                      ),
                    ),
                  ),
                ),
                // ===== Vocab word (if enabled) =====
                if (_showTranslationMode && currentWord != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isEnglishShowing = !_isEnglishShowing),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                                color: _strokeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(15)),
                            child: Column(
                              children: [
                                Text(
                                  _isEnglishShowing ? currentWord.english : currentWord.chinese,
                                  style: TextStyle(fontSize: 26, color: _strokeColor, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isEnglishShowing ? "Tap to see Chinese" : "Tap to see English",
                                  style: TextStyle(color: _strokeColor.withValues(alpha: 0.5), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.skip_next, color: _iconColor, size: 28),
                          onPressed: () => setState(() {
                            if (_words.isNotEmpty) {
                              _currentWordIndex = (_currentWordIndex + 1) % _words.length;
                              _isEnglishShowing = true;
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                // ===== Controls row =====
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: Row(
                    children: [
                      if (_laps.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Last Lap",
                                style: TextStyle(color: _strokeColor.withValues(alpha: 0.5), fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              _laps.last.lapTime,
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontFamily: 'monospace',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _resetStopwatch,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                              color: _strokeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(30)),
                          child: Text("Reset", style: TextStyle(color: _strokeColor, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _recordLap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(30)),
                          child: const Text("Lap", style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _toggleStopwatch,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isRunning ? Colors.redAccent : Colors.greenAccent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _isRunning ? "Pause" : "Start",
                            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ===== Lap history: compact single-row strip =====
                if (_laps.isNotEmpty)
                  Container(
                    height: 48,
                    color: Colors.black38,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.vertical,
                      itemCount: _laps.length,
                      itemBuilder: (context, index) {
                        final lap = _laps.reversed.toList()[index];
                        return SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: _strokeColor.withValues(alpha: 0.2),
                                child: Text(
                                  "${lap.index}",
                                  style: TextStyle(
                                      color: _strokeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Total: ${lap.totalTime}",
                                  style: TextStyle(
                                    color: _strokeColor,
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                "Lap: ${lap.lapTime}",
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                // ===== Ad banner =====
                
              ],
            ),
            // ===== Top toolbar =====
            Positioned(
              top: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(_isCountdownMode ? Icons.hourglass_bottom : Icons.hourglass_top,
                            color: _iconColor),
                        onPressed: () {
                          setState(() {
                            _timer?.cancel();
                            _wordTimer?.cancel();
                            _stopwatch.stop();
                            _stopwatch.reset();
                            if (!_isCountdownMode) {
                              if (_countdownTotalMs == 0) {
                                _showSetTimeDialog();
                                return;
                              } else {
                                _isCountdownMode = true;
                                _countdownRemainingMs = _countdownTotalMs;
                                _displayTime = _formatTime(_countdownRemainingMs);
                              }
                            } else {
                              _isCountdownMode = false;
                              _displayTime = _formatTime(0);
                            }
                          });
                        },
                      ),
                      if (_isCountdownMode)
                        IconButton(icon: Icon(Icons.timer, color: _iconColor), onPressed: _showSetTimeDialog),
                      IconButton(
                        icon: Icon(Icons.menu_book,
                            color: _showTranslationMode ? Colors.blueAccent : _iconColor),
                        onPressed: () {
                          setState(() {
                            _showTranslationMode = !_showTranslationMode;
                            if (_showTranslationMode && _isRunning && _words.isNotEmpty) {
                              _startWordRotation();
                            } else {
                              _wordTimer?.cancel();
                            }
                          });
                        },
                      ),
                      IconButton(
                          icon: Icon(Icons.list_alt, color: _iconColor), onPressed: _goToWordManager),
                      IconButton(icon: Icon(Icons.palette, color: _iconColor), onPressed: _showColorLibrary),
                      IconButton(
                        icon: Icon(Icons.schedule, color: _iconColor),
                        onPressed: _showTimeFormatSettings,
                        tooltip: "Time Format",
                      ),
                      IconButton(
                        icon: Icon(_numberStyleIcon(), color: _iconColor),
                        onPressed: _cycleNumberStyle,
                        tooltip: "Number Style: ${_numberStyle.name}",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumber(String text) {
    switch (_numberStyle) {
      case NumberStyle.stroke:
        return Text(
          text,
          style: TextStyle(
            fontSize: 200,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            fontFeatures: const [FontFeature.tabularFigures()],
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5.0
              ..color = _strokeColor,
          ),
        );
      case NumberStyle.solid:
        return Text(
          text,
          style: TextStyle(
            fontSize: 200,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            fontFeatures: const [FontFeature.tabularFigures()],
            color: _strokeColor,
          ),
        );
      case NumberStyle.classic:
        return Text(
          text,
          style: TextStyle(
            fontSize: 200,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
            fontFeatures: const [FontFeature.tabularFigures()],
            color: _strokeColor.withValues(alpha: 0.85),
            letterSpacing: 4,
            shadows: [Shadow(color: _strokeColor.withValues(alpha: 0.6), blurRadius: 12)],
          ),
        );
    }
  }

  void _showSetTimeDialog() {
    int hours = 0, minutes = 5, seconds = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Set Countdown Time", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTimeRow("Hours", hours, (v) => setDialogState(() => hours = v), 0, 23),
                _buildTimeRow("Minutes", minutes, (v) => setDialogState(() => minutes = v), 0, 59),
                _buildTimeRow("Seconds", seconds, (v) => setDialogState(() => seconds = v), 0, 59),
                const SizedBox(height: 16),
                Text(
                  "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 22,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  setState(() {
                    _countdownTotalMs = (hours * 3600 + minutes * 60 + seconds) * 1000;
                    _countdownRemainingMs = _countdownTotalMs;
                    _displayTime = _formatTime(_countdownTotalMs);
                    _isCountdownMode = true;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text("Set", style: TextStyle(color: Colors.greenAccent)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeRow(String label, int value, ValueChanged<int> onChanged, int min, int max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.white70))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Container(
            width: 50,
            alignment: Alignment.center,
            child: Text(
              value.toString().padLeft(2, '0'),
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white54),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  void _showColorLibrary() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Color Library",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Watch an ad to unlock a random color.",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colorLibrary.map((item) {
                    return GestureDetector(
                      onTap: () {
                        if (item.isUnlocked) {
                          setState(() {
                            _bgColor = item.color;
                            _textColor = item.color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
                          });
                          setModalState(() {});
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Locked! Watch an ad below."),
                                duration: Duration(seconds: 2)),
                          );
                        }
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: item.isUnlocked ? item.color : Colors.grey[700],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Center(
                          child: item.isUnlocked
                              ? const Icon(Icons.check, color: Colors.white70, size: 18)
                              : const Icon(Icons.lock, color: Colors.white54, size: 22),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _randomUnlockColor();
                    },
                    icon: const Icon(Icons.video_library),
                    label: const Text("Watch Ad, Unlock Random Color"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTimeFormatSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Time Format",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._formatLibrary.map((item) {
                  final isSelected = _currentFormatId == item.id;
                  return ListTile(
                    title: Text("${item.label}  (${item.example})",
                        style: const TextStyle(color: Colors.white)),
                    trailing: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.greenAccent : Colors.white54,
                    ),
                    onTap: () {
                      setState(() {
                        _currentFormatId = item.id;
                        if (_isCountdownMode) {
                          _displayTime = _formatTime(_countdownRemainingMs);
                        } else {
                          _displayTime = _formatTime(_stopwatch.elapsedMilliseconds);
                        }
                      });
                      setModalState(() {});
                    },
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ================= Word Manager Screen =================
class WordManagerScreen extends StatefulWidget {
  final List<WordPair> initialWords;
  const WordManagerScreen({super.key, required this.initialWords});

  @override
  State<WordManagerScreen> createState() => _WordManagerScreenState();
}

class _WordManagerScreenState extends State<WordManagerScreen> {
  late List<WordPair> _words;
  int _freeAddsToday = 1;
  bool _isUnlimited = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _words = List.from(widget.initialWords);
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  List<WordPair> get _filteredWords {
    if (_searchQuery.isEmpty) return _words;
    final q = _searchQuery.toLowerCase();
    return _words
        .where((w) => w.english.toLowerCase().contains(q) || w.chinese.contains(q))
        .toList();
  }

  void _onAddWordPressed() {
    if (_isUnlimited) {
      _showAddWordDialog();
      return;
    }
    if (_freeAddsToday > 0) {
      setState(() => _freeAddsToday--);
      _showAddWordDialog();
      return;
    }
    _showPaymentDialog();
  }

  void _showAddWordDialog() {
    final TextEditingController engController = TextEditingController();
    final TextEditingController chiController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add Word", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: engController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "English",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: chiController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Chinese translation",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (engController.text.isNotEmpty && chiController.text.isNotEmpty) {
                setState(() => _words.add(WordPair(
                    id: _generateId(),
                    english: engController.text,
                    chinese: chiController.text)));
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Daily Free Limit Reached", style: TextStyle(color: Colors.white)),
        content: const Text("HK\$8 to permanently unlock unlimited words.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Future.delayed(const Duration(seconds: 1));
              setState(() => _isUnlimited = true);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment successful!")));
            },
            child: const Text("Pay HK\$8", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("My Words", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isUnlimited ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isUnlimited ? "✨ Unlimited" : "Free: $_freeAddsToday/1",
                  style: TextStyle(
                    color: _isUnlimited ? Colors.greenAccent : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search words...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _filteredWords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_outlined, size: 80, color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 16),
                        Text(
                          _words.isEmpty ? "No words yet" : "No results found",
                          style: const TextStyle(color: Colors.white38, fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _words.isEmpty ? "Tap the + button to add your first word" : "Try a different keyword",
                          style: const TextStyle(color: Colors.white24, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _filteredWords.length,
                    itemBuilder: (context, index) {
                      final word = _filteredWords[index];
                      final realIndex = _words.indexWhere((w) => w.id == word.id);
                      return Dismissible(
                        key: ValueKey(word.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.only(right: 24),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          setState(() => _words.removeWhere((w) => w.id == word.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Deleted \"${word.english}\"")),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    "${realIndex + 1}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      word.english,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      word.chinese,
                                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 18),
                                  onPressed: () {
                                    setState(() => _words.removeWhere((w) => w.id == word.id));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddWordPressed,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_isUnlimited ? "Add Word" : "Add Word ($_freeAddsToday)"),
      ),
    );
  }
}