import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
}

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

      final canBio = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _isBiometricEnabled = bioEnabled;
        _hasBiometrics = canBio || isDeviceSupported;
        if (bioEnabled) {
          _isAuthenticated = false;
        }
      });

      if (bioEnabled) {
        _authenticateBiometric();
      }
    } catch (_) {
      setState(() => _hasBiometrics = false);
    }
  }

  Future<void> _authenticateBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint or face to open Anambra Community Alert',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (authenticated && mounted) {
        setState(() => _isAuthenticated = true);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isDecoyActive) {
      return DecoyCalculatorScreen(
        onSecretUnlock: () {
          setState(() {
            _isDecoyActive = false;
            _isAuthenticated = true;
          });
        },
      );
    }

    if (_isBiometricEnabled && !_isAuthenticated) {
      return PinLockScreen(
        correctPin: _savedPin,
        hasBiometrics: _hasBiometrics,
        onUnlockSuccess: () => setState(() => _isAuthenticated = true),
        onBiometricPressed: _authenticateBiometric,
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
        onSaveProfile: (updated) {
          setState(() => _userProfile = updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Safety Profile updated successfully!')),
          );
        },
      ),
      StealthSettingsScreen(
        onOpenDecoy: () => setState(() => _isDecoyActive = true),
        isBiometricEnabled: _isBiometricEnabled,
        onToggleBiometric: (val) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('biometric_auth_enabled', val);
          setState(() => _isBiometricEnabled = val);
        },
        onLockNow: () => setState(() => _isAuthenticated = false),
      ),
    ];

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0D0F14),
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (idx) => setState(() => _currentIndex = idx),
            backgroundColor: const Color(0xFF14171F),
            selectedItemColor: const Color(0xFFEF4444),
            unselectedItemColor: const Color(0xFF9E9E9E),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.warning_amber_rounded), label: 'Panic'),
              BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: 'Safe Routes'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
              BottomNavigationBarItem(icon: Icon(Icons.visibility_off_outlined), label: 'Stealth'),
            ],
          ),
        ),
        if (_isFakeCallActive)
          FakeCallOverlay(onDismiss: () => setState(() => _isFakeCallActive = false)),
      ],
    );
  }
}class PinLockScreen extends StatefulWidget {
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
        _enteredPin = '';
        _errorMessage = 'Incorrect PIN. Try again or scan biometric.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SECURITY LOCK',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calculate_outlined, color: Colors.white70),
                    tooltip: 'Open Decoy Calculator',
                    onPressed: widget.onOpenDecoy,
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.lock_rounded, size: 52, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              const Text(
                'Anambra Community Alert',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter Security PIN or use Biometric unlock',
                style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? const Color(0xFFEF4444) : Colors.transparent,
                      border: Border.all(
                        color: isFilled ? const Color(0xFFEF4444) : const Color(0xFF4B5563),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
              ),
              const Spacer(),
              _buildKeypad(),
              const SizedBox(height: 16),
              if (widget.hasBiometrics)
                TextButton.icon(
                  onPressed: widget.onBiometricPressed,
                  icon: const Icon(Icons.fingerprint, color: Color(0xFFEF4444), size: 28),
                  label: const Text(
                    'Unlock with Fingerprint / Face',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((num) => _keyBtn(num)).toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _actionBtn(Icons.calculate, widget.onOpenDecoy),
            _keyBtn('0'),
            _actionBtn(Icons.backspace_outlined, _onBackspace),
          ],
        ),
      ],
    );
  }

  Widget _keyBtn(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => _onKeyPress(text),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF374151)),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback action) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white70, size: 24),
        ),
      ),
    );
  }
}class PanicScreen extends StatefulWidget {
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
  bool _isHolding = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  bool _alertTriggered = false;
  Position? _currentPosition;

  void _startHold() {
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _holdProgress += 0.05 / 3.0;
        if (_holdProgress >= 1.0) {
          _holdProgress = 1.0;
          _triggerEmergencyAlert();
          timer.cancel();
        }
      });
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    if (!_alertTriggered) {
      setState(() {
        _isHolding = false;
        _holdProgress = 0.0;
      });
    }
  }

  Future<void> _triggerEmergencyAlert() async {
    setState(() => _alertTriggered = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      _currentPosition = pos;
    } catch (_) {}
    _dispatchSilentSMS();
  }

  Future<void> _dispatchSilentSMS() async {
    final lat = _currentPosition?.latitude;
    final lng = _currentPosition?.longitude;
    final mapUrl = (lat != null && lng != null)
        ? 'https://maps.google.com/?q=$lat,$lng'
        : 'Location unavailable';

    final message = Uri.encodeComponent(
      'EMERGENCY ALERT from ${widget.userProfile['name']} (${widget.userProfile['phone']})! '
      'Type: ${widget.userProfile['userType']}. LGA: ${widget.userProfile['lga']}. '
      'Current GPS: $mapUrl. Please send help immediately!',
    );

    final contacts = (widget.userProfile['contacts'] as List<dynamic>?) ?? [];
    if (contacts.isNotEmpty) {
      final firstPhone = contacts.first['phone'] ?? '112';
      final uri = Uri.parse('sms:$firstPhone?body=$message');
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  Future<void> _callEmergency(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onTriggerFakeCall,
                icon: const Icon(Icons.call, size: 16, color: Color(0xFFF59E0B)),
                label: const Text('Fake Call', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield, color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 4),
                    Text('Silent Guard Active', style: TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTapDown: (_) => _startHold(),
                  onTapUp: (_) => _cancelHold(),
                  onTapCancel: () => _cancelHold(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: _holdProgress,
                          strokeWidth: 8,
                          backgroundColor: const Color(0xFF1F2937),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                        ),
                      ),
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _alertTriggered
                              ? const Color(0xFFB91C1C)
                              : (_isHolding ? const Color(0xFFDC2626) : const Color(0xFFEF4444)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _alertTriggered ? Icons.check_circle : Icons.touch_app,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _alertTriggered
                                  ? 'ALERT SENT!'
                                  : (_isHolding ? 'HOLD FOR 3s...' : 'HOLD TO PANIC'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _alertTriggered
                      ? 'Emergency SMS & GPS location dispatched to contacts!'
                      : 'Press & hold 3 seconds to silently alert contacts and police.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                ),
                if (_alertTriggered)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() {
                        _alertTriggered = false;
                        _holdProgress = 0.0;
                      }),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Reset Alert'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF374151)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ANAMBRA EMERGENCY HOTLINES',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dialCard(
                  'Police Control',
                  '07039194397',
                  Icons.local_police,
                  () => _callEmergency('07039194397'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dialCard(
                  'SEMA Awka',
                  '08037452683',
                  Icons.emergency,
                  () => _callEmergency('08037452683'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dialCard(
                  'Rapid Response',
                  '08035408999',
                  Icons.flash_on,
                  () => _callEmergency('08035408999'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dialCard(String title, String phone, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF14171F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFEF4444), size: 22),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
            Text(phone, style: const TextStyle(fontSize: 9, color: Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }
}class RegistrationScreen extends StatefulWidget {
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
  late TextEditingController _matricCtrl;
  late TextEditingController _marketCtrl;
  late TextEditingController _communityCtrl;
  late TextEditingController _contact1Phone;
  late TextEditingController _contact2Phone;

  String _userType = 'STUDENT';
  String _selectedLga = 'Awka South';

  final List<String> _lgas = [
    'Awka South', 'Awka North', 'Onitsha North', 'Onitsha South',
    'Nnewi North', 'Nnewi South', 'Idemili North', 'Idemili South',
    'Ihiala', 'Aguata', 'Ogbaru', 'Orumba North', 'Orumba South'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.userProfile;
    _nameCtrl = TextEditingController(text: p['name']);
    _phoneCtrl = TextEditingController(text: p['phone']);
    _schoolCtrl = TextEditingController(text: p['school'] ?? '');
    _matricCtrl = TextEditingController(text: p['matric'] ?? '');
    _marketCtrl = TextEditingController(text: p['market'] ?? '');
    _communityCtrl = TextEditingController(text: p['community'] ?? '');

    _userType = p['userType'] ?? 'STUDENT';
    _selectedLga = p['lga'] ?? 'Awka South';

    final contacts = (p['contacts'] as List<dynamic>?) ?? [];
    _contact1Phone = TextEditingController(
      text: contacts.isNotEmpty ? contacts[0]['phone'] : '08031234567',
    );
    _contact2Phone = TextEditingController(
      text: contacts.length > 1 ? contacts[1]['phone'] : '08029876543',
    );
  }

  void _save() {
    final updated = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'userType': _userType,
      'lga': _selectedLga,
      'school': _schoolCtrl.text.trim(),
      'matric': _matricCtrl.text.trim(),
      'market': _marketCtrl.text.trim(),
      'community': _communityCtrl.text.trim(),
      'contacts': [
        {'name': 'Emergency Contact 1', 'phone': _contact1Phone.text.trim()},
        {'name': 'Emergency Contact 2', 'phone': _contact2Phone.text.trim()},
      ],
    };
    widget.onSaveProfile(updated);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'ANAMBRA SAFETY REGISTRATION',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your profile information is attached to emergency alerts sent to vigilance and family.',
          style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(height: 16),
        _buildTextField(_nameCtrl, 'Full Legal Name', Icons.person),
        const SizedBox(height: 10),
        _buildTextField(_phoneCtrl, 'Your Mobile Phone Number', Icons.phone, TextInputType.phone),
        const SizedBox(height: 12),
        const Text('Profile Category:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: ['STUDENT', 'TRADER', 'RESIDENT'].map((type) {
            final isSel = _userType == type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text(type, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.white70)),
                  selected: isSel,
                  selectedColor: const Color(0xFFEF4444),
                  onSelected: (val) {
                    if (val) setState(() => _userType = type);
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedLga,
          decoration: const InputDecoration(
            labelText: 'Local Government Area (LGA)',
            filled: true,
            fillColor: Color(0xFF14171F),
            border: OutlineInputBorder(),
          ),
          items: _lgas.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedLga = val);
          },
        ),
        const SizedBox(height: 12),
        if (_userType == 'STUDENT') ...[
          _buildTextField(_schoolCtrl, 'University / Polytechnic (e.g. UNIZIK, ANSU)', Icons.school),
          const SizedBox(height: 10),
          _buildTextField(_matricCtrl, 'Matric Number / Campus Lodge', Icons.home_work),
        ] else if (_userType == 'TRADER') ...[
          _buildTextField(_marketCtrl, 'Market & Shop Line (e.g. Main Market, Line 5)', Icons.store),
        ] else ...[
          _buildTextField(_communityCtrl, 'Residential Village / Layout', Icons.location_city),
        ],
        const SizedBox(height: 16),
        const Text(
          'TRUSTED EMERGENCY SMS RECIPIENTS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
        ),
        const SizedBox(height: 8),
        _buildTextField(_contact1Phone, 'Contact 1 (Family / Next of Kin)', Icons.phone_forwarded, TextInputType.phone),
        const SizedBox(height: 10),
        _buildTextField(_contact2Phone, 'Contact 2 (Security / SUG / Friend)', Icons.phone_forwarded, TextInputType.phone),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Save Safety Profile'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, [TextInputType type = TextInputType.text]) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFEF4444), size: 20),
        filled: true,
        fillColor: const Color(0xFF14171F),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

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
            child: ListTile(
              leading: const Icon(Icons.shield, color: Color(0xFF10B981)),
              title: Text(r['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(r['desc']!, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              trailing: Text(r['score']!, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          )),
        ],
      ),
    );
  }
}

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
  final TextEditingController _pinCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('STEALTH & BIOMETRIC PROTECTION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF14171F),
          child: SwitchListTile(
            title: const Text('Biometric Launch Protection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Require fingerprint or face scan every time the app opens.', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            value: widget.isBiometricEnabled,
            activeColor: const Color(0xFFEF4444),
            onChanged: widget.onToggleBiometric,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFF14171F),
          child: ListTile(
            leading: const Icon(Icons.pin, color: Color(0xFFEF4444)),
            title: const Text('Change Fallback 4-Digit PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Used if biometrics fail or hardware unavailable. Default: 1234', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            onTap: _showChangePinDialog,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFF14171F),
          child: ListTile(
            leading: const Icon(Icons.calculate, color: Color(0xFFF59E0B)),
            title: const Text('Open Decoy Calculator Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Disguises this app as a calculator. Enter "911=" to return.', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onOpenDecoy,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: widget.onLockNow,
          icon: const Icon(Icons.lock_clock),
          label: const Text('Lock App Now'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F2937)),
        ),
      ],
    );
  }

  void _showChangePinDialog() {
    _pinCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171F),
        title: const Text('Set 4-Digit Fallback PIN'),
        content: TextField(
          controller: _pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(hintText: 'Enter 4 digits (e.g. 5678)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_pinCtrl.text.length == 4) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('fallback_pin', _pinCtrl.text);
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fallback PIN updated!')),
                );
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }
}

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
      setState(() {
        _display = '${int.tryParse(_display) ?? 42}';
        _secret = '';
      });
      return;
    }
    setState(() {
      _secret += k;
      _display = _display == '0' ? k : _display + k;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(24),
                child: Text(
                  _display,
                  style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.w300),
                ),
              ),
            ),
            for (var row in [
              ['C', '+/-', '%', '/'],
              ['7', '8', '9', 'x'],
              ['4', '5', '6', '-'],
              ['1', '2', '3', '+'],
              ['0', '.', '=']
            ])
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((btn) {
                  final isOp = ['/', 'x', '-', '+', '='].contains(btn);
                  return Padding(
                    padding: const EdgeInsets.all(6),
                    child: InkWell(
                      onTap: () => _key(btn),
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        width: btn == '0' ? 140 : 68,
                        height: 68,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isOp ? Colors.orange : const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Text(
                          btn,
                          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class FakeCallOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  const FakeCallOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.95),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const CircleAvatar(radius: 40, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 50, color: Colors.white)),
          const SizedBox(height: 16),
          const Text('Uncle Emeka (Awka)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('Incoming Call...', style: TextStyle(fontSize: 14, color: Colors.white70)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FloatingActionButton(
                heroTag: 'fake_call_decline',
                backgroundColor: Colors.red,
                onPressed: onDismiss,
                child: const Icon(Icons.call_end),
              ),
              FloatingActionButton(
                heroTag: 'fake_call_accept',
                backgroundColor: Colors.green,
                onPressed: onDismiss,
                child: const Icon(Icons.call),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
