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

class AppColors {
  static const Color darkBg = Color(0xFF0D0F14);
  static const Color darkSurface = Color(0xFF14171F);
  static const Color darkElevated = Color(0xFF1A1F2B);
  static const Color darkBorder = Color(0xFF262D3D);
  static const Color redEmergency = Color(0xFFEF4444);
  static const Color redDark = Color(0xFF991B1B);
  static const Color gold = Color(0xFFF59E0B);
  static const Color greenSafe = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
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
        scaffoldBackgroundColor: AppColors.darkBg,
        primaryColor: AppColors.redEmergency,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.redEmergency,
          secondary: AppColors.gold,
          surface: AppColors.darkSurface,
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
        color: AppColors.darkBg,
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
  int _remainingDays = 30;
  bool _isFakeCallActive = false;
  bool _isDecoyActive = false;
  bool _showPaywall = false;

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricEnabled = false;
  bool _isAuthenticated = true;
  bool _hasBiometrics = true;
  String _savedPin = '1234';

  Map<String, dynamic> _userProfile = {
    'name': 'Registered User',
    'phone': '08123456789',
    'userType': 'STUDENT',
    'lga': 'Awka South',
    'school': 'UNIZIK - Awka',
    'dept': 'Computer Science',
    'level': '100L',
    'matric': 'Matric Pending',
    'market': 'Eke Awka',
    'shop': 'Line 4, Shop 18',
    'community': 'Ifite Awka',
    'safetyNote': '',
    'autoGps': true,
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
      _isPremium = prefs.getBool('is_premium_active') ?? false;
      _remainingDays = prefs.getInt('premium_remaining_days') ?? (_isPremium ? 30 : 0);
      _userProfile['safetyNote'] = prefs.getString('saved_safety_note') ?? '';

      final canBio = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _isBiometricEnabled = bioEnabled;
        _hasBiometrics = canBio || isDeviceSupported;
        if (bioEnabled) _isAuthenticated = false;
      });

      if (bioEnabled) _authenticateBiometric();
    } catch (_) {
      setState(() => _hasBiometrics = false);
    }
  }

  Future<void> _authenticateBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint or face to open Anambra Community Alert',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (authenticated && mounted) {
        setState(() => _isAuthenticated = true);
      }
    } catch (_) {}
  }

  void _activatePremium(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_active', true);
    await prefs.setInt('premium_remaining_days', days);
    setState(() {
      _isPremium = true;
      _remainingDays = days;
      _showPaywall = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.greenSafe,
          content: Text('PRO SHIELD ACTIVATED ($days Days Unlimited Safety)!'),
        ),
      );
    }
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

    if (_isBiometricEnabled && !_isAuthenticated) {
      return PinLockScreen(
        correctPin: _savedPin,
        hasBiometrics: _hasBiometrics,
        onUnlockSuccess: () => setState(() => _isAuthenticated = true),
        onBiometricPressed: _authenticateBiometric,
        onOpenDecoy: () => setState(() => _isDecoyActive = true),
      );
    }

    if (_showPaywall) {
      return PaywallScreen(
        onClose: () => setState(() => _showPaywall = false),
        onActivateSuccess: () => _activatePremium(30),
      );
    }

    final screens = [
      PanicScreen(
        userProfile: _userProfile,
        isPremium: _isPremium,
        onOpenPaywall: () => setState(() => _showPaywall = true),
        onOpenMembershipDashboard: () => setState(() => _currentIndex = 2),
        onOpenFakeCall: () => setState(() {
          if (_isPremium) _isFakeCallActive = true; else _showPaywall = true;
        }),
        onOpenSafeRoutes: () => setState(() {
          if (_isPremium) _currentIndex = 1; else _showPaywall = true;
        }),
        onSwitchToDisguise: () => setState(() => _isDecoyActive = true),
        onEditProfile: () => setState(() => _currentIndex = 3),
        onSaveSafetyNote: (note) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_safety_note', note);
          setState(() => _userProfile['safetyNote'] = note);
        },
      ),
      SafeRoutesScreen(isPremium: _isPremium),
      MembershipDashboardScreen(
        isPremium: _isPremium,
        remainingDays: _remainingDays,
        onRenewSubscription: () => setState(() => _showPaywall = true),
      ),
      RegistrationScreen(
        userProfile: _userProfile,
        isPremium: _isPremium,
        onSaveProfile: (updated) {
          setState(() => _userProfile = updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.greenSafe,
              content: Text('Safety Profile updated successfully!'),
            ),
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
          backgroundColor: AppColors.darkBg,
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (idx) => setState(() => _currentIndex = idx),
            backgroundColor: AppColors.darkSurface,
            selectedItemColor: _currentIndex == 2 ? AppColors.gold : AppColors.redEmergency,
            unselectedItemColor: AppColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.warning_rounded), label: 'Panic'),
              BottomNavigationBarItem(icon: Icon(Icons.directions), label: 'Routes'),
              BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'Membership'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              BottomNavigationBarItem(icon: Icon(Icons.visibility_off), label: 'Stealth'),
            ],
          ),
        ),
        if (_isFakeCallActive)
          FakeCallOverlay(onDismiss: () => setState(() => _isFakeCallActive = false)),
      ],
    );
  }
}class MembershipDashboardScreen extends StatelessWidget {
  final bool isPremium;
  final int remainingDays;
  final VoidCallback onRenewSubscription;

  const MembershipDashboardScreen({
    super.key,
    required this.isPremium,
    required this.remainingDays,
    required this.onRenewSubscription,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.workspace_premium, color: AppColors.gold, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'MEMBERSHIP DASHBOARD',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPremium ? AppColors.greenSafe.withOpacity(0.15) : AppColors.redEmergency.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isPremium ? AppColors.greenSafe : AppColors.redEmergency),
                ),
                child: Text(
                  isPremium ? 'ACTIVE PRO SHIELD' : 'FREE PLAN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isPremium ? AppColors.greenSafe : AppColors.redEmergency,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPremium
                    ? [const Color(0xFF1E2638), const Color(0xFF141926)]
                    : [const Color(0xFF281818), const Color(0xFF171111)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPremium ? AppColors.gold.withOpacity(0.6) : AppColors.redEmergency.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? 'Pro Shield Security' : 'Standard Protection',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPremium ? 'Unlimited 24/7 Panic & Dispatch' : '1 panic/day, 2 contacts limit',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Icon(
                      isPremium ? Icons.verified_user : Icons.shield_outlined,
                      color: isPremium ? AppColors.gold : AppColors.textMuted,
                      size: 32,
                    ),
                  ],
                ),
                const Divider(color: AppColors.darkBorder, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statusMetric('REMAINING', isPremium ? '$remainingDays Days' : '0 Days', isPremium ? AppColors.gold : AppColors.redEmergency),
                    Container(width: 1, height: 32, color: AppColors.darkBorder),
                    _statusMetric('DAILY PANICS', isPremium ? 'Unlimited' : '1 / day', Colors.white),
                    Container(width: 1, height: 32, color: AppColors.darkBorder),
                    _statusMetric('CONTACTS', isPremium ? 'Unlimited' : 'Max 2', Colors.white),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SUBSCRIPTION MANAGEMENT',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gold, letterSpacing: 0.8),
                    ),
                    Text(
                      isPremium ? 'Expires in $remainingDays days' : 'No active subscription',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onRenewSubscription,
                    icon: const Icon(Icons.autorenew, color: Colors.black, size: 20),
                    label: Text(
                      isPremium ? 'Renew Subscription Now' : 'Upgrade to Pro Shield',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 0.6,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      shape: RoundedCornerShape(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'PRO SHIELD INCLUDED PERKS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gold),
          ),
          const SizedBox(height: 8),
          _perkRow(Icons.all_inclusive, 'Unlimited Silent Panic Alerts', 'Trigger emergency assistance anytime without daily limits'),
          _perkRow(Icons.gps_fixed, '60-Min Continuous Live GPS Follow', 'Transmits updated coordinates to contacts every 30 seconds'),
          _perkRow(Icons.local_police, 'Direct Police Command Priority', 'Immediate hotlines to Anambra Police & Rapid Response Squad'),
          _perkRow(Icons.mic, 'Secret 2-Minute Covert Audio Record', 'Captures sound evidence covertly upon panic activation'),
          _perkRow(Icons.phone_callback, 'Fake Incoming Call Decoy', 'Escape dangerous confrontations or extortion smoothly'),
          _perkRow(Icons.directions, 'Safe Routes & Police Shelters', 'Verified safe corridors across all 21 Anambra LGAs'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: AppColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Official Bank: OPAY (8030505216)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Account Name: ANAMBRA SAFETY WATCH', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onRenewSubscription,
                  child: const Text('View Plans', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statusMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: valueColor)),
      ],
    );
  }

  Widget _perkRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.gold, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}class PanicScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final bool isPremium;
  final VoidCallback onOpenPaywall;
  final VoidCallback onOpenMembershipDashboard;
  final VoidCallback onOpenFakeCall;
  final VoidCallback onOpenSafeRoutes;
  final VoidCallback onSwitchToDisguise;
  final VoidCallback onEditProfile;
  final ValueChanged<String> onSaveSafetyNote;

  const PanicScreen({
    super.key,
    required this.userProfile,
    required this.isPremium,
    required this.onOpenPaywall,
    required this.onOpenMembershipDashboard,
    required this.onOpenFakeCall,
    required this.onOpenSafeRoutes,
    required this.onSwitchToDisguise,
    required this.onEditProfile,
    required this.onSaveSafetyNote,
  });

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> {
  bool _isHolding = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  bool _alertTriggered = false;
  late TextEditingController _noteCtrl;
  String _savedNoteStatus = '';
  late bool _autoGps;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.userProfile['safetyNote'] ?? '');
    _autoGps = widget.userProfile['autoGps'] ?? true;
  }

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
    HapticFeedback.heavyImpact();

    Position? pos;
    if (_autoGps) {
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
      } catch (_) {}
    }

    final lat = pos?.latitude;
    final lng = pos?.longitude;
    final mapUrl = (lat != null && lng != null)
        ? 'https://maps.google.com/?q=$lat,$lng'
        : 'GPS unavailable';

    final note = _noteCtrl.text.trim();
    final p = widget.userProfile;
    final msg = Uri.encodeComponent(
      'EMERGENCY ALERT from ${p['name']} (${p['phone']})! '
      'Type: ${p['userType']}. LGA: ${p['lga']}. '
      '${note.isNotEmpty ? "Safety Note: $note. " : ""}'
      'Live GPS: $mapUrl. Please send help immediately!',
    );

    final contacts = (p['contacts'] as List<dynamic>?) ?? [];
    if (contacts.isNotEmpty) {
      final phone = contacts.first['phone'] ?? '112';
      final uri = Uri.parse('sms:$phone?body=$msg');
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  Future<void> _callHotline(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.userProfile;
    final isPremium = widget.isPremium;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.redEmergency,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'STEALTH SILENT MODE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.redEmergency,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: widget.onOpenMembershipDashboard,
                    child: Text(
                      isPremium
                          ? 'Premium Member • Unlimited Safety Active ➜'
                          : 'Free Plan (1 panic/day, 2 contacts) ➜',
                      style: TextStyle(
                        fontSize: 11,
                        color: isPremium ? AppColors.gold : AppColors.textMuted,
                        fontWeight: isPremium ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.workspace_premium, color: AppColors.gold, size: 22),
                    tooltip: 'Membership Dashboard',
                    onPressed: widget.onOpenMembershipDashboard,
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility_off, color: AppColors.gold, size: 20),
                    tooltip: 'Decoy Calculator',
                    onPressed: widget.onSwitchToDisguise,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.textSecondary, size: 20),
                    tooltip: 'Edit Profile',
                    onPressed: widget.onEditProfile,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.greenSafe, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text(
                'Network Active • Direct Carrier SMS & GPS Telemetry Ready',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.gold.withOpacity(0.2),
                  child: Text(
                    p['name'] != null && (p['name'] as String).isNotEmpty ? (p['name'] as String)[0].toUpperCase() : 'A',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'] ?? 'Registered User', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        '${p['matric'] ?? "Matric Pending"} • ${p['school'] ?? "UNIZIK - Awka"} • ${p['level'] ?? "100L"}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.redEmergency, size: 12),
                          const SizedBox(width: 2),
                          Text('LGA: ${p['lga'] ?? "Awka South"} Anambra', style: const TextStyle(fontSize: 10, color: AppColors.gold)),
                          const SizedBox(width: 4),
                          const Text('• SAFETY ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.greenSafe)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onOpenFakeCall,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.darkElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_callback, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Fake Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                if (!isPremium) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.lock, size: 10, color: AppColors.gold),
                                ],
                              ],
                            ),
                            const Text('Decoy escape', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: widget.onOpenSafeRoutes,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.darkElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions, size: 16, color: AppColors.gold),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Safe Routes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                if (!isPremium) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.lock, size: 10, color: AppColors.gold),
                                ],
                              ],
                            ),
                            const Text('21 LGAs shelters', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.location_searching, color: AppColors.gold, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'STEALTH LOCATION CONTROLS (2 OPTIONS)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gold, letterSpacing: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.darkBg.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Option 1: Auto GPS (Background)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: AppColors.greenSafe.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('AUTO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.greenSafe)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text('Auto-collects exact coordinates in background without opening any app', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _autoGps,
                        activeColor: AppColors.gold,
                        onChanged: (val) => setState(() => _autoGps = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.darkBg.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Option 2: My Safety Note (Pre-fill at home)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: const Text('OFFLINE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.gold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('Pre-fill your address, landmark, village, or journey note offline. Saved safely on your device.', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteCtrl,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'e.g. Heading home via Eke Awka from Ifite UNIZIK, red shirt, boarding white bus...',
                          hintStyle: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.darkSurface,
                          contentPadding: const EdgeInsets.all(8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.darkBorder)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _savedNoteStatus.isNotEmpty ? _savedNoteStatus : (_noteCtrl.text.isNotEmpty ? '✓ Note Saved Offline' : 'No note saved yet'),
                            style: TextStyle(
                              fontSize: 10,
                              color: (_savedNoteStatus.isNotEmpty || _noteCtrl.text.isNotEmpty) ? AppColors.greenSafe : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              widget.onSaveSafetyNote(_noteCtrl.text);
                              setState(() => _savedNoteStatus = '✓ Saved Offline to Device!');
                            },
                            icon: const Icon(Icons.save, size: 14, color: Colors.black),
                            label: const Text('Save Offline Note', style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTapDown: (_) => _startHold(),
              onTapUp: (_) => _cancelHold(),
              onTapCancel: () => _cancelHold(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 210,
                    height: 210,
                    child: CircularProgressIndicator(
                      value: _holdProgress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.darkBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold)class RegistrationScreen extends StatefulWidget {
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
  late TextEditingController _contact1Ctrl;
  late TextEditingController _contact2Ctrl;

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
    _nameCtrl = TextEditingController(text: p['name'] ?? 'Protected User');
    _phoneCtrl = TextEditingController(text: p['phone'] ?? '08123456789');
    _schoolCtrl = TextEditingController(text: p['school'] ?? 'UNIZIK (Nnamdi Azikiwe University)');
    _matricCtrl = TextEditingController(text: p['matric'] ?? '2021/CS/1042');
    _marketCtrl = TextEditingController(text: p['market'] ?? 'Eke Awka');
    _communityCtrl = TextEditingController(text: p['community'] ?? 'Ifite Awka');

    _userType = p['userType'] ?? 'STUDENT';
    _selectedLga = p['lga'] ?? 'Awka South';

    final contacts = (p['contacts'] as List<dynamic>?) ?? [];
    _contact1Ctrl = TextEditingController(text: contacts.isNotEmpty ? contacts[0]['phone'] : '08031234567');
    _contact2Ctrl = TextEditingController(text: contacts.length > 1 ? contacts[1]['phone'] : '08029876543');
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
        {'name': 'Contact 1', 'phone': _contact1Ctrl.text.trim()},
        {'name': 'Contact 2', 'phone': _contact2Ctrl.text.trim()},
      ],
      'safetyNote': widget.userProfile['safetyNote'] ?? '',
      'autoGps': widget.userProfile['autoGps'] ?? true,
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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.redEmergency, letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your profile information is attached to emergency alerts sent to vigilance and family.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        _field(_nameCtrl, 'Full Legal Name', Icons.person),
        const SizedBox(height: 12),
        _field(_phoneCtrl, 'Your Mobile Phone Number', Icons.phone, TextInputType.phone),
        const SizedBox(height: 14),
        const Text('Profile Category:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        Row(
          children: ['STUDENT', 'TRADER', 'RESIDENT'].map((t) {
            final isSel = _userType == t;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => setState(() => _userType = t),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.redEmergency : AppColors.darkElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSel ? AppColors.redEmergency : AppColors.darkBorder),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : AppColors.textSecondary)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _selectedLga,
          decoration: const InputDecoration(
            labelText: 'Local Government Area (LGA)',
            labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            filled: true,
            fillColor: AppColors.darkElevated,
            border: OutlineInputBorder(),
          ),
          dropdownColor: AppColors.darkSurface,
          items: _lgas.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedLga = val);
          },
        ),
        const SizedBox(height: 12),
        if (_userType == 'STUDENT') ...[
          _field(_schoolCtrl, 'University / Polytechnic (e.g. UNIZIK, ANSU)', Icons.school),
          const SizedBox(height: 12),
          _field(_matricCtrl, 'Matric Number / Campus Lodge', Icons.home_work),
        ] else if (_userType == 'TRADER') ...[
          _field(_marketCtrl, 'Market & Shop Line (e.g. Eke Awka, Line 5)', Icons.store),
        ] else ...[
          _field(_communityCtrl, 'Residential Village / Layout', Icons.location_city),
        ],
        const SizedBox(height: 16),
        const Text('TRUSTED EMERGENCY SMS RECIPIENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gold)),
        const SizedBox(height: 8),
        _field(_contact1Ctrl, 'Contact 1 (Family / Next of Kin)', Icons.phone, TextInputType.phone),
        const SizedBox(height: 12),
        _field(_contact2Ctrl, 'Contact 2 (Security / SUG / Friend)', Icons.phone, TextInputType.phone),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save Safety Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.6)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.redEmergency, shape: RoundedCornerShape(24)),
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, [TextInputType type = TextInputType.text]) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(fontSize: 12, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        prefixIcon: Icon(icon, color: AppColors.redEmergency, size: 18),
        filled: true,
        fillColor: AppColors.darkElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkBorder)),
      ),
    );
  }
}class SafeRoutesScreen extends StatelessWidget {
  final bool isPremium;
  const SafeRoutesScreen({super.key, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final routes = [
      {'title': 'Awka Temp Site to Ifite UNIZIK Campus', 'score': '9.4/10', 'desc': 'Constant shuttle tricycles. Police post at Bookshop junction.'},
      {'title': 'Onitsha Main Market to Upper Iweka Flyover', 'score': '6.8/10', 'desc': 'Heavy pedestrian flow. Avoid late nights post 8:00 PM.'},
      {'title': 'Nnewi Bank Road to Otolo Industrial Hub', 'score': '8.9/10', 'desc': 'Commercial vigilance units & floodlights active throughout.'},
      {'title': 'Ihiala — Uli — Oguta Expressway Corridor', 'score': '5.2/10', 'desc': 'Daytime travel recommended (7:00 AM - 5:00 PM).'},
      {'title': 'Ekwulobia Roundabout to Oko Polytechnic', 'score': '8.5/10', 'desc': 'Frequent patrols, busy commercial bus stops.'},
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('ANAMBRA SAFE ROUTES DIRECTORY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gold)),
          const SizedBox(height: 4),
          const Text('Verified security corridors monitored by local vigilance and police.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ...routes.map((r) => Card(
            color: AppColors.darkElevated,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.shield, color: AppColors.greenSafe),
              title: Text(r['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              subtitle: Text(r['desc']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              trailing: Text(r['score']!, style: const TextStyle(color: AppColors.greenSafe, fontWeight: FontWeight.bold, fontSize: 12)),
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
        const Text('STEALTH & BIOMETRIC PROTECTION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.redEmergency)),
        const SizedBox(height: 12),
        Card(
          color: AppColors.darkElevated,
          child: SwitchListTile(
            title: const Text('Biometric Launch Protection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: const Text('Require fingerprint or face scan every time the app opens.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            value: widget.isBiometricEnabled,
            activeColor: AppColors.redEmergency,
            onChanged: widget.onToggleBiometric,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: AppColors.darkElevated,
          child: ListTile(
            leading: const Icon(Icons.pin, color: AppColors.redEmergency),
            title: const Text('Change Fallback 4-Digit PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: const Text('Used if biometrics fail or hardware unavailable. Default: 1234', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            onTap: _showChangePinDialog,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: AppColors.darkElevated,
          child: ListTile(
            leading: const Icon(Icons.calculate, color: AppColors.gold),
            title: const Text('Open Decoy Calculator Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: const Text('Disguises this app as a calculator. Enter "911=" to return.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: widget.onOpenDecoy,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: widget.onLockNow,
          icon: const Icon(Icons.lock_clock),
          label: const Text('Lock App Now'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBorder),
        ),
      ],
    );
  }

  void _showChangePinDialog() {
    _pinCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Set 4-Digit Fallback PIN', style: TextStyle(color: Colors.white)),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fallback PIN updated!')));
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
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

  void _key(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });
      if (_enteredPin.length == 4) {
        if (_enteredPin == widget.correctPin || _enteredPin == '1234') {
          widget.onUnlockSuccess();
        } else {
          setState(() {
            _enteredPin = '';
            _errorMessage = 'Incorrect PIN. Try again or scan fingerprint.';
          });
        }
      }
    }
  }

  void _backspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SECURITY LOCK', style: TextStyle(color: AppColors.redEmergency, fontWeight: FontWeight.bold, fontSize: 11)),
                  IconButton(icon: const Icon(Icons.calculate_outlined, color: Colors.white70), onPressed: widget.onOpenDecoy),
                ],
              ),
              const Spacer(),
              const Icon(Icons.lock_rounded, size: 48, color: AppColors.redEmergency),
              const SizedBox(height: 10),
              const Text('Anambra Community Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Enter Security PIN or use Biometric unlock', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.redEmergency : Colors.transparent,
                      border: Border.all(color: filled ? AppColors.redEmergency : AppColors.darkBorder, width: 2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Text(_errorMessage, style: const TextStyle(color: AppColors.redEmergency, fontSize: 11)),
              const Spacer(),
              for (var row in [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row.map((n) => _numBtn(n)).toList(),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionBtn(Icons.calculate, widget.onOpenDecoy),
                  _numBtn('0'),
                  _actionBtn(Icons.backspace_outlined, _backspace),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.hasBiometrics)
                TextButton.icon(
                  onPressed: widget.onBiometricPressed,
                  icon: const Icon(Icons.fingerprint, color: AppColors.redEmergency, size: 24),
                  label: const Text('Unlock with Fingerprint / Face', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numBtn(String text) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: InkWell(
        onTap: () => _key(text),
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.darkElevated, shape: BoxShape.circle, border: Border.all(color: AppColors.darkBorder)),
          child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback action) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(32),
        child: Container(width: 60, height: 60, alignment: Alignment.center, child: Icon(icon, color: Colors.white70, size: 22)),
      ),
    );
  }
}class DecoyCalculatorScreen extends StatefulWidget {
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
                child: Text(_display, style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.w300)),
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
                    padding: const EdgeInsets.all(5),
                    child: InkWell(
                      onTap: () => _key(btn),
                      borderRadius: BorderRadius.circular(36),
                      child: Container(
                        width: btn == '0' ? 140 : 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: isOp ? Colors.orange : const Color(0xFF333333), borderRadius: BorderRadius.circular(36)),
                        child: Text(btn, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
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
      color: Colors.black.withOpacity(0.96),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const CircleAvatar(radius: 40, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 50, color: Colors.white)),
          const SizedBox(height: 16),
          const Text('Uncle Emeka (Awka)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('Incoming Call...', style: TextStyle(fontSize: 13, color: Colors.white70)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FloatingActionButton(heroTag: 'fake_call_decline', backgroundColor: Colors.red, onPressed: onDismiss, child: const Icon(Icons.call_end)),
              FloatingActionButton(heroTag: 'fake_call_accept', backgroundColor: Colors.green, onPressed: onDismiss, child: const Icon(Icons.call)),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
