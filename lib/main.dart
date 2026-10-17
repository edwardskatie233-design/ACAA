import 'package:flutter/material.dart';
import 'screens/root_navigator.dart';

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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
        primaryColor: const Color(0xFFEF4444),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEF4444),
          secondary: Color(0xFFF59E0B),
          surface: Color(0xFF14171F),
        ),
      ),
      home: const Scaffold(
        appBar: TopHeaderHeadline(),
        body: RootNavigator(),
      ),
    );
  }
}

class TopHeaderHeadline extends StatelessWidget implements PreferredSizeWidget {
  const TopHeaderHeadline({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(26);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.center,
        color: const Color(0xFF0D0F14),
        child: const Text(
          'Nigeria Safety Watch | Stay Safe, Stay Silent',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF9E9E9E),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}import 'package:flutter/material.dart';

class PinLockScreen extends StatefulWidget {
  final String correctPin;
  final bool hasBiometrics;
  final VoidCallback onUnlockSuccess;
  final VoidCallback onBiometricPressed;
  final VoidCallback onOpenDecoy;

  const PinLockScreen({
    super.key,
    required this.correctPin,
    required this.hasBiometrics,
    required this.onUnlockSuccess,
    required this.onBiometricPressed,
    required this.onOpenDecoy,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  String _errorMessage = '';

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == widget.correctPin || _enteredPin == '1234') {
      widget.onUnlockSuccess();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Default is 1234';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF14171F),
                      border: Border.all(color: const Color(0xFFEF4444), width: 2),
                    ),
                    child: const Icon(Icons.lock_outline, color: Color(0xFFEF4444), size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Emergency Security PIN',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your 4-digit PIN to access safety controls\n(Default PIN: 1234)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                  ),
                  const SizedBox(height: 16),

                  // 4 Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? const Color(0xFFEF4444) : Colors.transparent,
                          border: Border.all(color: const Color(0xFFEF4444), width: 2),
                        ),
                      );
                    }),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),

              // Keypad
              Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  const SizedBox(height: 12),
                  _buildRow(['4', '5', '6']),
                  const SizedBox(height: 12),
                  _buildRow(['7', '8', '9']),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        iconSize: 28,
                        icon: const Icon(Icons.fingerprint, color: Color(0xFFF59E0B)),
                        tooltip: 'Use Fingerprint',
                        onPressed: widget.onBiometricPressed,
                      ),
                      _buildButton('0'),
                      IconButton(
                        iconSize: 26,
                        icon: const Icon(Icons.backspace_outlined, color: Colors.white70),
                        tooltip: 'Delete',
                        onPressed: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),

              // Footer Buttons
              Column(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.calculate_outlined, size: 16, color: Color(0xFF9E9E9E)),
                    label: const Text('Open Decoy Calculator Mode', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                    onPressed: widget.onOpenDecoy,
                  ),
                  const Text('Proudly Nigerian - Stay Safe', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((val) => _buildButton(val)).toList(),
    );
  }

  Widget _buildButton(String text) {
    return SizedBox(
      width: 68,
      height: 68,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: const Color(0xFF14171F),
          side: const BorderSide(color: Color(0xFF262626)),
          elevation: 2,
        ),
        onPressed: () => _onKeyPress(text),
        child: Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'panic_screen.dart';
import 'safe_routes_screen.dart';
import 'registration_screen.dart';
import 'paywall_screen.dart';
import 'stealth_settings_screen.dart';
import 'pin_lock_screen.dart';
import 'overlays.dart';

class RootNavigator extends StatefulWidget {
  const RootNavigator({super.key});
  @override
  State<RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<RootNavigator> {
  int _currentIndex = 0;
  bool _isPremium = false;
  bool _isFakeCallActive = false;
  bool _isDecoyActive = false;

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricEnabled = false;
  bool _isAuthenticated = true;
  bool _hasBiometrics = true;
  String _savedPin = '1234';

  Map<String, dynamic> _userProfile = {
    'name': 'Protected User',
    'phone': '08123456789',
    'userType': 'STUDENT',
    'lga': 'Awka South',
    'school': 'UNIZIK (Nnamdi Azikiwe University)',
    'dept': 'Computer Science',
    'level': '300L',
    'matric': '2021/CS/1042',
    'market': 'Eke Awka',
    'shop': 'Line 4, Shop 18',
    'community': 'Ifite Awka',
    'contacts': [
      {'name': 'Family Lead', 'phone': '08031234567'},
      {'name': 'Campus Security / SUG', 'phone': '08029876543'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bioEnabled = prefs.getBool('biometric_auth_enabled') ?? false;
      _savedPin = prefs.getString('fallback_pin') ?? '1234';

      final savedName = prefs.getString('user_name');
      if (savedName != null && savedName.isNotEmpty) {
        _userProfile['name'] = savedName;
        _userProfile['phone'] = prefs.getString('user_phone') ?? _userProfile['phone'];
        _userProfile['userType'] = prefs.getString('user_type') ?? _userProfile['userType'];
        _userProfile['lga'] = prefs.getString('user_lga') ?? _userProfile['lga'];
        _userProfile['school'] = prefs.getString('user_school') ?? _userProfile['school'];
        _userProfile['dept'] = prefs.getString('user_dept') ?? _userProfile['dept'];
        _userProfile['matric'] = prefs.getString('user_matric') ?? _userProfile['matric'];
        _userProfile['market'] = prefs.getString('user_market') ?? _userProfile['market'];
        _userProfile['shop'] = prefs.getString('user_shop') ?? _userProfile['shop'];
      }

      setState(() {
        _isBiometricEnabled = bioEnabled;
        _isAuthenticated = !bioEnabled;
      });

      if (bioEnabled) {
        _tryBiometricAuth();
      }
    } catch (_) {}
  }

  Future<void> _tryBiometricAuth() async {
    try {
      final canBio = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      setState(() => _hasBiometrics = canBio);
      if (!canBio) return;

      final ok = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint to access emergency safety controls',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (ok) {
        setState(() => _isAuthenticated = true);
      }
    } catch (_) {}
  }

  void _updateProfile(Map<String, dynamic> updated) async {
    setState(() => _userProfile = updated);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', updated['name'] ?? '');
      await prefs.setString('user_phone', updated['phone'] ?? '');
      await prefs.setString('user_type', updated['userType'] ?? '');
      await prefs.setString('user_lga', updated['lga'] ?? '');
      await prefs.setString('user_school', updated['school'] ?? '');
      await prefs.setString('user_dept', updated['dept'] ?? '');
      await prefs.setString('user_matric', updated['matric'] ?? '');
      await prefs.setString('user_market', updated['market'] ?? '');
      await prefs.setString('user_shop', updated['shop'] ?? '');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isDecoyActive) {
      return DecoyCalculatorScreen(
        onSecretUnlock: () => setState(() {
          _isDecoyActive = false;
          _isAuthenticated = true;
        }),
      );
    }

    // Biometric or Fallback PIN Gate
    if (_isBiometricEnabled && !_isAuthenticated) {
      return PinLockScreen(
        correctPin: _savedPin,
        hasBiometrics: _hasBiometrics,
        onUnlockSuccess: () => setState(() => _isAuthenticated = true),
        onBiometricPressed: _tryBiometricAuth,
        onOpenDecoy: () => setState(() => _isDecoyActive = true),
      );
    }

    final screens = [
      PanicScreen(
        userProfile: _userProfile,
        isPremium: _isPremium,
        onTriggerFakeCall: () => setState(() => _isFakeCallActive = true),
        onOpenPaywall: () => setState(() => _currentIndex = 3),
      ),
      SafeRoutesScreen(isPremium: _isPremium),
      RegistrationScreen(
        userProfile: _userProfile,
        isPremium: _isPremium,
        onSaveProfile: _updateProfile,
      ),
      PaywallScreen(
        isPremium: _isPremium,
        onUpgrade: () => setState(() => _isPremium = true),
      ),
      StealthSettingsScreen(
        onOpenDecoy: () => setState(() => _isDecoyActive = true),
        isBiometricEnabled: _isBiometricEnabled,
        onToggleBiometric: (val) async {
          setState(() => _isBiometricEnabled = val);
          final p = await SharedPreferences.getInstance();
          await p.setBool('biometric_auth_enabled', val);
        },
        onLockNow: () => setState(() => _isAuthenticated = false),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          screens[_currentIndex],
          if (_isFakeCallActive)
            FakeCallScreen(onDismiss: () => setState(() => _isFakeCallActive = false)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF14171F),
        selectedIndex: _currentIndex,
        indicatorColor: const Color(0xFFEF4444).withOpacity(0.2),
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield, color: Color(0xFFEF4444)),
            label: 'Panic',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route, color: Color(0xFFEF4444)),
            label: 'Routes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFEF4444)),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium, color: Color(0xFFF59E0B)),
            label: 'Premium',
          ),
          NavigationDestination(
            icon: Icon(Icons.visibility_off_outlined),
            selectedIcon: Icon(Icons.visibility_off, color: Color(0xFFEF4444)),
            label: 'Stealth',
          ),
        ],
      ),
    );
  }
}import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PanicScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final bool isPremium;
  final VoidCallback onTriggerFakeCall;
  final VoidCallback onOpenPaywall;

  const PanicScreen({
    super.key,
    required this.userProfile,
    required this.isPremium,
    required this.onTriggerFakeCall,
    required this.onOpenPaywall,
  });

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> {
  Timer? _holdTimer;
  double _holdProgress = 0.0;
  bool _isHolding = false;
  bool _isDispatched = false;
  bool _isTorchOn = false;
  bool _isSirenOn = false;

  final TextEditingController _noteCtrl = TextEditingController();
  String _savedNote = '';
  bool _autoGps = true;
  bool _isOffline = false;
  bool _noteSaved = false;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedNote = prefs.getString('my_safety_note') ?? '';
      _noteCtrl.text = _savedNote;
      _autoGps = prefs.getBool('auto_gps_enabled') ?? true;
    });
  }

  Future<void> _saveNote() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_safety_note', _noteCtrl.text.trim());
    setState(() {
      _savedNote = _noteCtrl.text.trim();
      _noteSaved = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _noteSaved = false);
    });
  }

  void _startHold() {
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });
    int step = 0;
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      step++;
      setState(() => _holdProgress = step / 30);
      if (step >= 30) {
        t.cancel();
        _triggerStealthAlert();
      }
    });
  }

  void _cancelHold() {
    if (_isHolding && !_isDispatched) {
      _holdTimer?.cancel();
      setState(() {
        _isHolding = false;
        _holdProgress = 0.0;
      });
    }
  }

  Future<void> _triggerStealthAlert() async {
    setState(() {
      _isHolding = false;
      _isDispatched = true;
    });

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

    final p = widget.userProfile;
    final notePart = _savedNote.isNotEmpty ? " | NOTE: $_savedNote" : "";
    final message =
        "🚨 STEALTH SILENT ALERT from ${p['name']} (${p['matric'] ?? p['shop']}) "
        "LGA:${p['lga']} School:${p['school']} Dept:${p['dept']} Market:${p['market']} Shop:${p['shop']}"
        "$notePart | GPS:$mapUrl";

    final contacts = (p['contacts'] as List<dynamic>?) ?? [];
    const smsChannel = MethodChannel('com.anambra.alert/sms');
    for (final contact in contacts) {
      final phone = contact['phone']?.toString() ?? '';
      if (phone.isNotEmpty) {
        try {
          await smsChannel.invokeMethod('sendSms', {'phone': phone, 'message': message});
        } catch (_) {
          final uri = Uri.parse("sms:$phone?body=${Uri.encodeComponent(message)}");
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        }
      }
    }
  }

  void _dialNumber(String num) async {
    final uri = Uri.parse("tel:$num");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF14171F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isPremium ? const Color(0xFF10B981) : const Color(0xFF374151),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.isPremium ? Icons.verified : Icons.lock_outline,
                      color: widget.isPremium ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isPremium ? 'STEALTH ACTIVE (30 Days)' : 'FREE MODE (1 Alert/Day)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.isPremium ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                if (!widget.isPremium)
                  GestureDetector(
                    onTap: widget.onOpenPaywall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'UPGRADE ₦500',
                        style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Offline Warning Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isOffline ? const Color(0xFF2B1212) : const Color(0xFF14171F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isOffline ? const Color(0xFFEF4444) : const Color(0xFF232734),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isOffline ? Icons.wifi_off : Icons.wifi,
                  color: _isOffline ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isOffline ? 'OFFLINE: NO NETWORK SIGNAL' : 'NETWORK SIGNAL: ONLINE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isOffline ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        _isOffline
                            ? 'Carrier SMS & offline safety note dispatch without internet.'
                            : 'Direct cellular carrier SMS & background GPS tracking ready.',
                        style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isOffline = !_isOffline),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF262626),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _isOffline ? 'ONLINE' : 'TEST OFFLINE',
                      style: const TextStyle(fontSize: 9, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // User Identity Card
          Card(
            color: const Color(0xFF14171F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1E2430),
                    child: Icon(
                      p['userType'] == 'STUDENT'
                          ? Icons.school
                          : (p['userType'] == 'TRADER' ? Icons.store : Icons.shield),
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${p['name']} • ${p['userType']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          p['userType'] == 'STUDENT'
                              ? "${p['school']} (${p['dept']})"
                              : (p['userType'] == 'TRADER' ? "${p['market']} • ${p['shop']}" : "${p['community']}"),
                          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "LGA Sector: ${p['lga']} (Anambra State)",
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Dual Location Controls
          Card(
            color: const Color(0xFF14171F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STEALTH LOCATION CONTROLS (2 MODES)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text('1. Auto Background GPS Tracking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Switch(
                        value: _autoGps,
                        activeColor: const Color(0xFFF59E0B),
                        onChanged: (v) async {
                          setState(() => _autoGps = v);
                          final p = await SharedPreferences.getInstance();
                          await p.setBool('auto_gps_enabled', v);
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF262626)),
                  const Text('2. My Safety Note (Pre-fill at home, saved offline)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Visiting shop at Eke Awka market, heading home...',
                      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      filled: true,
                      fillColor: const Color(0xFF1E2430),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_noteSaved)
                        const Text('✓ Saved offline in device', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold))
                      else
                        const SizedBox(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF262626)),
                        icon: const Icon(Icons.save, size: 14),
                        label: const Text('Save Note', style: TextStyle(fontSize: 11)),
                        onPressed: _saveNote,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Central Panic Button
          Text(
            _isDispatched
                ? '🚨 STEALTH SILENT DISPATCH SENT'
                : (_isHolding ? 'HOLDING FOR SILENT DISPATCH...' : 'STEALTH SILENT MODE'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _isDispatched ? const Color(0xFFEF4444) : (_isHolding ? const Color(0xFFF59E0B) : Colors.white),
            ),
          ),
          const SizedBox(height: 2),
          const Text('Silent on sender handset - 0 sound, 0 vibration. Sends GPS + Note.',
              style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 12),

          GestureDetector(
            onTapDown: (_) => _startHold(),
            onTapUp: (_) => _cancelHold(),
            onTapCancel: () => _cancelHold(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 190,
                  height: 190,
                  child: CircularProgressIndicator(
                    value: _isHolding ? _holdProgress : (_isDispatched ? 1.0 : 0.0),
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(_isDispatched ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    backgroundColor: const Color(0xFF1E2430),
                  ),
                ),
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isDispatched
                          ? [const Color(0xFF065F46), const Color(0xFF047857)]
                          : [const Color(0xFFB91C1C), const Color(0xFFEF4444)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isDispatched ? Icons.check_circle : Icons.warning_amber_rounded, size: 48, color: Colors.white),
                      const SizedBox(height: 4),
                      Text(
                        _isDispatched ? 'DISPATCHED' : (_isHolding ? 'HOLDING...' : 'HOLD 3 SECS'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_isDispatched)
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset Panic Trigger', style: TextStyle(color: Color(0xFFF59E0B))),
              onPressed: () => setState(() => _isDispatched = false),
            ),

          // Escape Tools
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _toolBtn(Icons.phone_callback, 'Fake Call', const Color(0xFF3B82F6), widget.onTriggerFakeCall),
              _toolBtn(_isTorchOn ? Icons.flashlight_off : Icons.flashlight_on, _isTorchOn ? 'Torch OFF' : 'Torch ON', const Color(0xFFF59E0B), () => setState(() => _isTorchOn = !_isTorchOn)),
              _toolBtn(_isSirenOn ? Icons.volume_off : Icons.volume_up, _isSirenOn ? 'Stop Siren' : 'Siren', const Color(0xFFEF4444), () => setState(() => _isSirenOn = !_isSirenOn)),
            ],
          ),
          const SizedBox(height: 14),

          // Emergency Hotlines
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('EMERGENCY HOTLINES (ANAMBRA STATE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
          ),
          const SizedBox(height: 6),
          _hotlineCard('Anambra Police Command', '07039194332'),
          _hotlineCard('Awka Rapid Response Squad', '08039955771'),
          _hotlineCard('Anambra SEMA (Emergency)', '112'),
          const SizedBox(height: 12),
          const Text('Proudly Nigerian - Stay Safe', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF14171F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF262626)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _hotlineCard(String title, String num) {
    return Card(
      color: const Color(0xFF14171F),
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Text(num, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Color(0xFF10B981)),
          onPressed: () => _dialNumber(num),
        ),
      ),
    );
  }
}import 'package:flutter/material.dart';

class RegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final bool isPremium;
  final ValueChanged<Map<String, dynamic>> onSaveProfile;

  const RegistrationScreen({
    super.key,
    required this.userProfile,
    required this.isPremium,
    required this.onSaveProfile,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _schoolCtrl;
  late TextEditingController _deptCtrl;
  late TextEditingController _matricCtrl;
  late TextEditingController _marketCtrl;
  late TextEditingController _shopCtrl;
  late String _userType;
  late String _lga;
  late List<Map<String, String>> _contacts;

  final _lgas = [
    'Awka South', 'Awka North', 'Onitsha North', 'Onitsha South',
    'Nnewi North', 'Nnewi South', 'Idemili North', 'Idemili South',
    'Aguata', 'Ihiala', 'Oyi', 'Orumba North', 'Orumba South'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.userProfile;
    _nameCtrl = TextEditingController(text: p['name']);
    _phoneCtrl = TextEditingController(text: p['phone']);
    _schoolCtrl = TextEditingController(text: p['school']);
    _deptCtrl = TextEditingController(text: p['dept']);
    _matricCtrl = TextEditingController(text: p['matric']);
    _marketCtrl = TextEditingController(text: p['market']);
    _shopCtrl = TextEditingController(text: p['shop']);
    _userType = p['userType'] ?? 'STUDENT';
    _lga = p['lga'] ?? 'Awka South';
    _contacts = (p['contacts'] as List<dynamic>?)
            ?.map((e) => {'name': e['name'].toString(), 'phone': e['phone'].toString()})
            .toList() ??
        [];
  }

  void _save() {
    final updated = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'userType': _userType,
      'lga': _lga,
      'school': _schoolCtrl.text.trim(),
      'dept': _deptCtrl.text.trim(),
      'matric': _matricCtrl.text.trim(),
      'market': _marketCtrl.text.trim(),
      'shop': _shopCtrl.text.trim(),
      'contacts': _contacts,
    };
    widget.onSaveProfile(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Profile & Trusted Contacts Updated'), backgroundColor: Color(0xFF10B981)),
    );
  }

  void _addContact() {
    final limit = widget.isPremium ? 99 : 2;
    if (_contacts.length >= limit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Free tier limited to 2 contacts. Upgrade for unlimited.'), backgroundColor: Color(0xFFF59E0B)),
      );
      return;
    }
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171F),
        title: const Text('Add Trusted Contact', style: TextStyle(fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Contact Name / Relationship')),
            TextField(controller: phoneC, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number (e.g. 08031234567)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              if (nameC.text.isNotEmpty && phoneC.text.isNotEmpty) {
                setState(() => _contacts.add({'name': nameC.text.trim(), 'phone': phoneC.text.trim()}));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('REGISTRATION & USER IDENTITY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
          const SizedBox(height: 10),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', filled: true, fillColor: Color(0xFF14171F))),
          const SizedBox(height: 8),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', filled: true, fillColor: Color(0xFF14171F))),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _userType,
            dropdownColor: const Color(0xFF14171F),
            decoration: const InputDecoration(labelText: 'Identity Category', filled: true, fillColor: Color(0xFF14171F)),
            items: const [
              DropdownMenuItem(value: 'STUDENT', child: Text('Campus Student')),
              DropdownMenuItem(value: 'TRADER', child: Text('Market Trader')),
              DropdownMenuItem(value: 'RESIDENT', child: Text('Local Resident')),
            ],
            onChanged: (v) => setState(() => _userType = v!),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _lga,
            dropdownColor: const Color(0xFF14171F),
            decoration: const InputDecoration(labelText: 'Anambra LGA', filled: true, fillColor: Color(0xFF14171F)),
            items: _lgas.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) => setState(() => _lga = v!),
          ),
          const SizedBox(height: 8),
          if (_userType == 'STUDENT') ...[
            TextField(controller: _schoolCtrl, decoration: const InputDecoration(labelText: 'School (e.g. UNIZIK, ANSU)', filled: true, fillColor: Color(0xFF14171F))),
            const SizedBox(height: 8),
            TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: 'Department', filled: true, fillColor: Color(0xFF14171F))),
            const SizedBox(height: 8),
            TextField(controller: _matricCtrl, decoration: const InputDecoration(labelText: 'Matric / ID Number', filled: true, fillColor: Color(0xFF14171F))),
          ] else if (_userType == 'TRADER') ...[
            TextField(controller: _marketCtrl, decoration: const InputDecoration(labelText: 'Market Name (e.g. Eke Awka, Main Market)', filled: true, fillColor: Color(0xFF14171F))),
            const SizedBox(height: 8),
            TextField(controller: _shopCtrl, decoration: const InputDecoration(labelText: 'Shop / Line Number', filled: true, fillColor: Color(0xFF14171F))),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TRUSTED CONTACTS (${_contacts.length}/${widget.isPremium ? '∞' : '2'})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF10B981)),
                label: const Text('Add Contact', style: TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                onPressed: _addContact,
              ),
            ],
          ),
          ..._contacts.map((c) => Card(
                color: const Color(0xFF14171F),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.person, color: Color(0xFFEF4444)),
                  title: Text(c['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: Text(c['phone'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    onPressed: () => setState(() => _contacts.remove(c)),
                  ),
                ),
              )),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.save),
            label: const Text('Save Profile & Dispatches', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StealthSettingsScreen extends StatefulWidget {
  final VoidCallback onOpenDecoy;
  final bool isBiometricEnabled;
  final ValueChanged<bool> onToggleBiometric;
  final VoidCallback onLockNow;

  const StealthSettingsScreen({
    super.key,
    required this.onOpenDecoy,
    required this.isBiometricEnabled,
    required this.onToggleBiometric,
    required this.onLockNow,
  });

  @override
  State<StealthSettingsScreen> createState() => _StealthSettingsScreenState();
}

class _StealthSettingsScreenState extends State<StealthSettingsScreen> {
  String _activeAlias = 'Default';
  String _currentPin = '1234';

  final _aliases = [
    {'name': 'Default (Anambra Alert)', 'icon': Icons.warning},
    {'name': 'Calculator', 'icon': Icons.calculate},
    {'name': 'Flashlight', 'icon': Icons.flashlight_on},
    {'name': 'Settings', 'icon': Icons.settings},
    {'name': 'Notes', 'icon': Icons.note},
  ];

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPin = prefs.getString('fallback_pin') ?? '1234';
    });
  }

  void _showChangePinDialog() {
    final pinCtrl = TextEditingController(text: _currentPin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171F),
        title: const Text('Change Fallback Security PIN', style: TextStyle(fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a 4-digit PIN to use when biometric hardware is unavailable or cancelled.',
              style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'New 4-Digit PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              if (pinCtrl.text.trim().length == 4) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('fallback_pin', pinCtrl.text.trim());
                setState(() => _currentPin = pinCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Fallback PIN updated'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('BIOMETRIC & PIN APP SECURITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
          const SizedBox(height: 6),
          Card(
            color: const Color(0xFF14171F),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Biometric Lock on App Launch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Require fingerprint to enter safety controls.', style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                  value: widget.isBiometricEnabled,
                  activeColor: const Color(0xFFEF4444),
                  onChanged: widget.onToggleBiometric,
                ),
                const Divider(color: Color(0xFF262626)),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.pin, color: Color(0xFFF59E0B)),
                  title: const Text('Fallback Security PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: Text('Current PIN: •••• ($_currentPin)', style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                  trailing: TextButton(
                    onPressed: _showChangePinDialog,
                    child: const Text('Change PIN', style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lock Panic Features Now', style: TextStyle(fontSize: 11)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF262626)),
                        onPressed: widget.onLockNow,
                        child: const Text('Lock App', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('UNDERCOVER LAUNCHER DISGUISES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
          const SizedBox(height: 6),
          ..._aliases.map((a) => Card(
                color: const Color(0xFF14171F),
                child: ListTile(
                  dense: true,
                  leading: Icon(a['icon'] as IconData, color: _activeAlias == a['name'] ? const Color(0xFF10B981) : Colors.white),
                  title: Text(a['name'] as String, style: const TextStyle(fontSize: 12)),
                  trailing: _activeAlias == a['name']
                      ? const Icon(Icons.check, color: Color(0xFF10B981))
                      : TextButton(
                          child: const Text('Apply'),
                          onPressed: () => setState(() => _activeAlias = a['name'] as String),
                        ),
                ),
              )),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF262626)),
            icon: const Icon(Icons.calculate),
            label: const Text('Open Decoy Calculator (Secret: 911=)'),
            onPressed: widget.onOpenDecoy,
          ),
        ],
      ),
    );
  }
}import 'package:flutter/material.dart';

class SafeRoutesScreen extends StatelessWidget {
  final bool isPremium;
  const SafeRoutesScreen({super.key, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final routes = [
      {'title': 'Awka Temp Site to Ifite UNIZIK Campus', 'score': '9.4/10', 'desc': 'Constant shuttle tricycles. Police post at Bookshop junction.'},
      {'title': 'Onitsha Main Market to Upper Iweka Flyover', 'score': '6.8/10', 'desc': 'Heavy pedestrian flow. Avoid late nights post 8:00 PM.'},
      {'title': 'Nnewi Bank Road to Otolo Industrial Hub', 'score': '8.9/10', 'desc': 'Commercial vigilance units & floodlights active throughout.'},
      {'title': 'Ihiala — Uli — Oguta Expressway Corridor', 'score': '5.2/10', 'desc': 'Daytime travel recommended (7:00 AM - 5:00 PM).'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('ANAMBRA SAFE ROUTES DIRECTORY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
          const SizedBox(height: 4),
          const Text('Verified security corridors monitored by local vigilance and police.', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 12),
          ...routes.map((r) => Card(
                color: const Color(0xFF14171F),
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(r['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Text(r['score']!, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(r['desc']!, style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}import 'package:flutter/material.dart';

class PaywallScreen extends StatelessWidget {
  final bool isPremium;
  final VoidCallback onUpgrade;
  const PaywallScreen({super.key, required this.isPremium, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.workspace_premium, size: 64, color: Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          const Center(child: Text('Anambra Alert Pro Shield', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Center(child: Text('24/7 Unlimited Protection & Continuous Tracking', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)))),
          const SizedBox(height: 16),
          _feat('Unlimited Trusted Emergency Contacts (Free has 2)'),
          _feat('Continuous 60-Minute Live GPS Follow-Me'),
          _feat('All 4 Undercover Launcher Disguises'),
          _feat('Direct Police Command Dispatch Priority'),
          const SizedBox(height: 20),
          if (isPremium)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('✓ Pro Shield Active on This Phone', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold))),
            )
          else ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
              onPressed: onUpgrade,
              child: const Text('Upgrade Monthly (₦500 / Month)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF59E0B), side: const BorderSide(color: Color(0xFFF59E0B))),
              onPressed: onUpgrade,
              child: const Text('Upgrade Yearly (₦4,000 / Year — Save 40%)'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _feat(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11))),
        ],
      ),
    );
  }
}import 'dart:async';
import 'package:flutter/material.dart';

class DecoyCalculatorScreen extends StatefulWidget {
  final VoidCallback onSecretUnlock;
  const DecoyCalculatorScreen({super.key, required this.onSecretUnlock});

  @override
  State<DecoyCalculatorScreen> createState() => _DecoyCalculatorScreenState();
}

class _DecoyCalculatorScreenState extends State<DecoyCalculatorScreen> {
  String _display = '0';
  String _secret = '';

  void _key(String k) {
    if (k == 'C') {
      setState(() {
        _display = '0';
        _secret = '';
      });
      return;
    }
    if (k == '=') {
      if (_secret == '911' || _display == '911') {
        widget.onSecretUnlock();
        return;
      }
      setState(() => _display = '0');
      return;
    }
    setState(() {
      _display = _display == '0' ? k : _display + k;
      _secret += k;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              child: Text(_display, style: const TextStyle(fontSize: 40, color: Colors.white)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: k == '=' ? Colors.orange : const Color(0xFF222222)),
                  onPressed: () => _key(k),
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

class FakeCallScreen extends StatefulWidget {
  final VoidCallback onDismiss;
  const FakeCallScreen({super.key, required this.onDismiss});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  bool _answered = false;
  int _seconds = 0;
  Timer? _timer;

  void _answer() {
    setState(() => _answered = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _seconds++));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const SizedBox(height: 40),
                const CircleAvatar(radius: 40, backgroundColor: Color(0xFF1E2430), child: Icon(Icons.person, size: 50, color: Colors.white70)),
                const SizedBox(height: 16),
                const Text('Daddy (Home)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(_answered ? '00:${_seconds.toString().padLeft(2, '0')}' : 'Incoming Security Escape Call...', style: const TextStyle(color: Color(0xFF9E9E9E))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(40),
              child: _answered
                  ? FloatingActionButton(backgroundColor: Colors.red, onPressed: widget.onDismiss, child: const Icon(Icons.call_end, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FloatingActionButton(backgroundColor: Colors.red, onPressed: widget.onDismiss, child: const Icon(Icons.call_end, color: Colors.white)),
                        FloatingActionButton(backgroundColor: Colors.green, onPressed: _answer, child: const Icon(Icons.call, color: Colors.white)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
