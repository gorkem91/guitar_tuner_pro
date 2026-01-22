import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const GuitarTunerApp());
}

class GuitarString {
  final String name;
  final double frequency;
  final int index;
  GuitarString(this.name, this.frequency, this.index);
}

final List<GuitarString> leftStrings = [
  GuitarString("E", 82.41, 0),
  GuitarString("A", 110.00, 1),
  GuitarString("D", 146.83, 2),
];

final List<GuitarString> rightStrings = [
  GuitarString("G", 196.00, 3),
  GuitarString("B", 246.94, 4),
  GuitarString("e", 329.63, 5),
];

final List<GuitarString> allStrings = [...leftStrings, ...rightStrings];

class GuitarTunerApp extends StatelessWidget {
  const GuitarTunerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pro Tuner',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const TunerScreen(),
    );
  }
}

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> with WidgetsBindingObserver {
  final _audioRecorder = FlutterAudioCapture();
  final _nativeDetector = NativePitchDetector(); 
  
  double currentFreq = 0.0;
  bool isAutoMode = true;
  GuitarString targetString = leftStrings[0];
  
  bool isListening = false;
  String statusMessage = "Başlatılıyor...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
    _forceStartAudio(); // başlamıyorsa da zorla 
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _forceStartAudio();
    }
  }

  Future<void> _forceStartAudio() async {
    print("--- SES MOTORU BAŞLATILIYOR ---");
    
    PermissionStatus status = await Permission.microphone.status;
    print("Mevcut İzin Durumu: $status");

    if (status.isDenied || status.isRestricted) {
      print("İzin isteniyor...");
      status = await Permission.microphone.request();
    }

    
    if (status.isPermanentlyDenied) {
      setState(() {
        statusMessage = "İzin reddedildi! Ayarlardan açmalısın.";
      });
      print("Kalıcı red! Ayarlara yönlendiriliyor...");
      openAppSettings(); 
      return;
    }
    if (!status.isGranted) {
      setState(() {
        statusMessage = "Mikrofon izni gerekli!";
      });
      return;
    }

    if (!isListening) {
      try {
        await _audioRecorder.start(
          _listener, 
          onError, 
          sampleRate: 44100, 
          bufferSize: 3000
        );
        setState(() {
          isListening = true;
          statusMessage = "Dinleniyor...";
        });
        print("KAYIT BAŞLADI!");
      } catch (e) {
        print("Kayıt Hatası: $e");
        setState(() {
          statusMessage = "Hata: Ses kartı başlatılamadı.";
        });
      }
    }
  }

  void _listener(dynamic obj) {
    var buffer = Float64List.fromList(obj.cast<double>());
    double pitch = _nativeDetector.getPitch(buffer);

    if (pitch > 60 && pitch < 700) {
       _handleNewFrequency(pitch);
    }
  }

  void onError(Object e) {
    print("Mikrofon Hatası: $e");
  }

  void _handleNewFrequency(double freq) {
    if (!mounted) return;
    
    if (isAutoMode) {
      GuitarString closest = allStrings.first;
      double minDiff = double.infinity;
      for (var s in allStrings) {
        double diff = (s.frequency - freq).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closest = s;
        }
      }
      setState(() {
        targetString = closest;
        currentFreq = freq;
        statusMessage = "Frekans: ${freq.toStringAsFixed(1)} Hz";
      });
    } else {
      setState(() {
        currentFreq = freq;
         statusMessage = "Frekans: ${freq.toStringAsFixed(1)} Hz";
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioRecorder.stop();
    super.dispose();
  }

  void _selectStringManual(GuitarString s) {
    setState(() {
      isAutoMode = false;
      targetString = s;
    });
  }

  void _switchToAuto() {
    setState(() {
      isAutoMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    double diff = currentFreq - targetString.frequency;
    bool isTuned = diff.abs() < 1.5; 

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.8,
                      child: Image.asset(
                        'assets/x.png', 
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.0, -1.1), 
                        errorBuilder: (c,e,s) => const Center(child: Text("Görsel Yok: assets/x.png")),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.3), const Color(0xFF121212)],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter
                        ),
                      ),
                    ),
                  ),
                  Positioned(left: 20, top: 40, bottom: 40,
                    child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                      children: leftStrings.map((s) => _buildPegButton(s)).toList()),
                  ),
                  Positioned(right: 20, top: 40, bottom: 40,
                    child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                      children: rightStrings.reversed.map((s) => _buildPegButton(s)).toList()),
                  ),
                  Positioned(top: 20,
                    child: GestureDetector(onTap: _switchToAuto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isAutoMode ? const Color(0xFF00FF88) : Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: isAutoMode ? const Color(0xFF00FF88) : Colors.grey, width: 2),
                          boxShadow: isAutoMode ? [BoxShadow(color: const Color(0xFF00FF88).withOpacity(0.4), blurRadius: 15)] : []
                        ),
                        child: Text("AUTO MODE", style: TextStyle(color: isAutoMode ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // ALT 
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 200, width: double.infinity,
                      child: CustomPaint(
                        painter: TunerGaugePainter(diff: diff, isTuned: isTuned),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Text(
                              targetString.name,
                              style: TextStyle(
                                fontSize: 90, fontWeight: FontWeight.bold, 
                                color: isTuned ? const Color(0xFF00FF88) : Colors.white,
                                shadows: [Shadow(blurRadius: isTuned ? 40 : 0, color: isTuned ? const Color(0xFF00FF88) : Colors.transparent)]
                              ),
                            ),
                            Text(
                              isTuned ? "PERFECT" : (diff < 0 ? "Too Low" : "Too High"),
                              style: TextStyle(
                                fontSize: 20, color: isTuned ? const Color(0xFF00FF88) : const Color(0xFFFF4D4D),
                                fontWeight: FontWeight.w500, letterSpacing: 2
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // DURUM MESAJI
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Text(
                        statusMessage, // Burası sürekli güncellenecek
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPegButton(GuitarString s) {
    bool isActive = (!isAutoMode && targetString.name == s.name) || (isAutoMode && targetString.name == s.name);
    return GestureDetector(
      onTap: () => _selectStringManual(s),
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? const Color(0xFF00FF88).withOpacity(0.2) : Colors.black45,
          border: Border.all(color: isActive ? const Color(0xFF00FF88) : Colors.white24, width: isActive ? 2 : 1),
          boxShadow: isActive ? [BoxShadow(color: const Color(0xFF00FF88).withOpacity(0.3), blurRadius: 20, spreadRadius: 5)] : []
        ),
        alignment: Alignment.center,
        child: Text(s.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF00FF88) : Colors.white70)),
      ),
    );
  }
}

class TunerGaugePainter extends CustomPainter {
  final double diff; final bool isTuned;
  TunerGaugePainter({required this.diff, required this.isTuned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.9);
    final radius = size.height * 0.9;
    
    final paintArc = Paint()..color = Colors.white10..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 10.0;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi, false, paintArc);

    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy - radius + 20), Paint()..color = isTuned ? const Color(0xFF00FF88) : Colors.white24..strokeWidth = 4..strokeCap = StrokeCap.round);

    double sensitivity = 0.08;
    double val = (diff.abs() > 300) ? -20 : diff; 
    double angle = -math.pi / 2 + (val * sensitivity);
    angle = angle.clamp(-math.pi + 0.1, -0.1);

    final paintNeedle = Paint()..color = isTuned ? const Color(0xFF00FF88) : const Color(0xFFFF4D4D)..strokeWidth = 6..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final needleEnd = Offset(center.dx + (radius - 10) * math.cos(angle), center.dy + (radius - 10) * math.sin(angle));
    canvas.drawLine(center, needleEnd, paintNeedle);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NativePitchDetector {
  double getPitch(Float64List samples) {
    int sampleRate = 44100;
    int n = samples.length;
    double rms = 0;
    for (var x in samples) rms += x * x;
    rms = math.sqrt(rms / n);
    if (rms < 0.02) return 0.0; 

    int minLag = (sampleRate / 700).floor(); 
    int maxLag = (sampleRate / 60).floor(); 
    double maxCorr = -1.0;
    int bestLag = -1;

    for (int lag = minLag; lag <= maxLag; lag++) {
      double sum = 0;
      for (int i = 0; i < n - lag; i++) {
        sum += samples[i] * samples[i + lag];
      }
      double avg = sum / (n - lag);
      if (avg > maxCorr) {
        maxCorr = avg;
        bestLag = lag;
      }
    }
    if (bestLag > 0 && maxCorr > 0.5) { 
       return sampleRate / bestLag;
    }
    return 0.0;
  }
}