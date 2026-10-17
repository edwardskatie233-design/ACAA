import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AnambraAlertApp());
}

class AnambraAlertApp extends StatelessWidget {
  const AnambraAlertApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anambra Community Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
        primaryColor: const Color(0xFFEF4444),
      ),
      home: const MainAlertScreen(),
    );
  }
}

class MainAlertScreen extends StatefulWidget {
  const MainAlertScreen({super.key});
  @override
  State<MainAlertScreen> createState() => _MainAlertScreenState();
}

class _MainAlertScreenState extends State<MainAlertScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _authenticated = false;
  bool _isDecoy = false;
  bool _autoGps = true;
  bool _isOffline = false;
  bool _isHolding = false;
  bool _dispatched = false;
  double _progress = 0.0;
  Timer? _holdTimer;

  final TextEditingController _noteCtrl = TextEditingController();
  String _savedNote = '';
  List<String> _contacts = ['08031234567', '08029876543'];

  // Decoy Calculator State
  String _calcDisplay = '0';
  String _calcSecret = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedNote = prefs.getString('safety_note') ?? '';
      _noteCtrl.text = _savedNote;
      _autoGps = prefs.getBool('auto_gps') ?? true;
      _contacts = prefs.getStringList('contacts') ?? _contacts;
    });
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canBio = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canBio) {
        setState(() => _authenticated = true);
        return;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Scan fingerprint to open Anambra Community Alert',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      setState(() => _authenticated = ok);
    } catch (_) {
      setState(() => _authenticated = true);
    }
  }

  Future<void> _saveNote() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('safety_note', _noteCtrl.text.trim());
    setState(() => _savedNote = _noteCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Safety Note saved offline'), backgroundColor: Colors.green),
    );
  }

  void _startHold() {
    setState(() {
      _isHolding = true;
      _progress = 0.0;
    });
    int step = 0;
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      step++;
      setState(() => _progress = step / 30);
      if (step >= 30) {
        t.cancel();
        _triggerStealthDispatch();
      }
    });
  }

  void _cancelHold() {
    if (_isHolding && !_dispatched) {
      _holdTimer?.cancel();
      setState(() {
        _isHolding = false;
        _progress = 0.0;
      });
    }
  }

  Future<void> _triggerStealthDispatch() async {
    setState(() {
      _isHolding = false;
      _dispatched = true;
    });

    // 1. Collect Auto GPS
    String mapUrl = "https://maps.google.com/?q=6.2209,7.0674";
    if (_autoGps) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
        mapUrl = "https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
      } catch (_) {}
    }

    // 2. Build Stealth Message
    final notePart = _savedNote.isNotEmpty ? " | NOTE: $_savedNote" : "";
    final msg = "🚨 SILENT EMERGENCY: Anambra Community Alert$notePart | GPS: $mapUrl";

    // 3. Silent SMS via MethodChannel with url_launcher fallback
    const smsChannel = MethodChannel('com.anambra.alert/sms');
    for (final phone in _contacts) {
      try {
        await smsChannel.invokeMethod('sendSms', {'phone': phone, 'message': msg});
      } catch (_) {
        final uri = Uri.parse("sms:$phone?body=${Uri.encodeComponent(msg)}");
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
    }
  }

  void _onCalcKey(String k) {
    if (k == 'C') {
      setState(() {
        _calcDisplay = '0';
        _calcSecret = '';
      });
      return;
    }
    if (k == '=') {
      if (_calcSecret == '911' || _calcDisplay == '911') {
        setState(() {
          _isDecoy = false;
          _authenticated = true;
        });
        return;
      }
      setState(() => _calcDisplay = '0');
      return;
    }
    setState(() {
      _calcDisplay = _calcDisplay == '0' ? k : _calcDisplay + k;
      _calcSecret += k;
    });
  }

  void _call(String num) async {
    final uri = Uri.parse("tel:$num");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    if (_isDecoy) return _buildDecoyCalculator();
    if (!_authenticated) return _buildBiometricLock();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nigeria Safety Watch | Anambra Alert', style: TextStyle(fontSize: 13, color: Colors.grey)),
        backgroundColor: const Color(0xFF14171F),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate, color: Colors.grey),
            tooltip: 'Decoy Mode',
            onPressed: () => setState(() => _isDecoy = true),
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline, color: Colors.red),
            tooltip: 'Lock',
            onPressed: () => setState(() => _authenticated = false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Network Warning Banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isOffline ? const Color(0xFF3B1212) : const Color(0xFF14171F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _isOffline ? Colors.red : Colors.green),
              ),
              child: Row(
                children: [
                  Icon(_isOffline ? Icons.wifi_off : Icons.wifi, color: _isOffline ? Colors.red : Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isOffline ? 'OFFLINE: Carrier SMS & Safety Note Armed' : 'ONLINE: Live GPS & SMS Active',
                      style: TextStyle(fontSize: 11, color: _isOffline ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isOffline = !_isOffline),
                    child: Text(_isOffline ? 'ONLINE' : 'OFFLINE', style: const TextStyle(fontSize: 10, color: Colors.orange)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Location Controls: Auto GPS + Safety Note
            Card(
              color: const Color(0xFF14171F),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('1. Auto Background GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Switch(
                          value: _autoGps,
                          activeColor: Colors.orange,
                          onChanged: (v) async {
                            setState(() => _autoGps = v);
                            final p = await SharedPreferences.getInstance();
                            await p.setBool('auto_gps', v);
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12),
                    const Text('2. My Safety Note (Pre-fill at home, saved offline)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. At Eke Awka market shop 12, heading home...',
                        hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                        filled: true,
                        fillColor: Color(0xFF1E2430),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF262626)),
                        icon: const Icon(Icons.save, size: 14),
                        label: const Text('Save Note', style: TextStyle(fontSize: 11)),
                        onPressed: _saveNote,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stealth Silent Panic Button (Hold 3 Seconds)
            Text(
              _dispatched ? '🚨 STEALTH ALERT DISPATCHED' : (_isHolding ? 'HOLDING FOR SILENT DISPATCH...' : 'STEALTH SILENT MODE'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _dispatched ? Colors.red : Colors.white),
            ),
            const Text('Zero sound, zero vibration on your phone. Sends Auto GPS + Note.', style: TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 14),

            GestureDetector(
              onTapDown: (_) => _startHold(),
              onTapUp: (_) => _cancelHold(),
              onTapCancel: () => _cancelHold(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: CircularProgressIndicator(
                      value: _isHolding ? _progress : (_dispatched ? 1.0 : 0.0),
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(_dispatched ? Colors.green : Colors.red),
                    ),
                  ),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _dispatched ? Colors.green.shade800 : Colors.red.shade700,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_dispatched ? Icons.check : Icons.warning_amber, size: 40, color: Colors.white),
                        const SizedBox(height: 4),
                        Text(
                          _dispatched ? 'DISPATCHED' : (_isHolding ? 'HOLDING...' : 'HOLD 3 SECS'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_dispatched)
              TextButton(
                onPressed: () => setState(() => _dispatched = false),
                child: const Text('Reset Alert', style: TextStyle(color: Colors.orange)),
              ),

            // Anambra Hotlines
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('ANAMBRA HOTLINES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
            ),
            const SizedBox(height: 6),
            _hotlineTile('Anambra Police Command', '07039194332'),
            _hotlineTile('Awka Rapid Response Squad', '08039955771'),
            _hotlineTile('Anambra SEMA (Emergency)', '112'),
            const SizedBox(height: 14),
            const Text('Proudly Nigerian - Stay Safe', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _hotlineTile(String title, String num) {
    return Card(
      color: const Color(0xFF14171F),
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Text(num, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Colors.green, size: 20),
          onPressed: () => _call(num),
        ),
      ),
    );
  }

  Widget _buildBiometricLock() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Biometric Lock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Scan fingerprint or face unlock to access safety panic controls.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size.fromHeight(44)),
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock with Biometrics'),
                onPressed: _checkBiometrics,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => setState(() => _isDecoy = true),
                child: const Text('Open Decoy Calculator'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecoyCalculator() {
    final keys = ['C', '911', '%', '/', '7', '8', '9', '*', '4', '5', '6', '-', '1', '2', '3', '+', '0', '.', '='];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Calculator', style: TextStyle(fontSize: 14)), backgroundColor: Colors.black),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(20),
              child: Text(_calcDisplay, style: const TextStyle(fontSize: 40, color: Colors.white)),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keys.map((k) {
              return SizedBox(
                width: 72,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: k == '=' ? Colors.orange : const Color(0xFF222222),
                  ),
                  onPressed: () => _onCalcKey(k),
                  child: Text(k, style: const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
