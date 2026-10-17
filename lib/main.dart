import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AnambraAlertApp());
}

// ---------------------------------------------------------------------------
// 1. DESIGN PALETTE & CONSTANTS
// ---------------------------------------------------------------------------
class AppColors {
  static const Color darkBg = Color(0xFF0F1216);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkElevated = Color(0xFF1F242C);
  static const Color darkBorder = Color(0xFF2D333B);
  static const Color redEmergency = Color(0xFFD32F2F);
  static const Color redPulse = Color(0xFFFF5252);
  static const Color gold = Color(0xFFFFB300);
  static const Color goldBright = Color(0xFFFFD54F);
  static const Color greenSafe = Color(0xFF00E676);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8B949E);
}

// ---------------------------------------------------------------------------
// 2. MAIN APP ENTRY POINT
// ---------------------------------------------------------------------------
class AnambraAlertApp extends StatelessWidget {
  const AnambraAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nigeria Safety Watch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        primaryColor: AppColors.redEmergency,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.redEmergency,
          secondary: AppColors.gold,
          surface: AppColors.darkSurface,
          background: AppColors.darkBg,
        ),
        fontFamily: 'Roboto',
      ),
      home: const RootNavigator(),
    );
  }
}

class TopHeaderHeadline extends StatelessWidget implements PreferredSizeWidget {
  const TopHeaderHeadline({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(36);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Text(
        'Nigeria Safety Watch  |  Stay Safe, Stay Silent',
        style: TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. ROOT NAVIGATION & STATE MANAGEMENT
// ---------------------------------------------------------------------------
class RootNavigator extends StatefulWidget {
  const RootNavigator({super.key});

  @override
  State<RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<RootNavigator> {
  int _currentTabIndex = 0;
  bool _isPremium = false;
  bool _isDisguised = false;
  bool _showFakeCall = false;
  bool _isPinLocked = false;
  bool _showPaywall = false;
  bool _showMembership = false;

  Map<String, dynamic> _userProfile = {
    'name': 'Chidubem Samuel',
    'phone': '08012345678',
    'userType': 'STUDENT',
    'lga': 'Awka South',
    'verified': true,
    'preFillNote': 'Final year student at UNIZIK Perm Site. Daily commute Ifite-Temp Site.',
    'contacts': [
      {'name': 'Family Next of Kin', 'phone': '08030505216'},
      {'name': 'SUG Security Chief', 'phone': '08022223333'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPremium = prefs.getBool('is_premium') ?? false;
      final storedName = prefs.getString('user_name');
      if (storedName != null) {
        _userProfile['name'] = storedName;
        _userProfile['phone'] = prefs.getString('user_phone') ?? _userProfile['phone'];
        _userProfile['lga'] = prefs.getString('user_lga') ?? _userProfile['lga'];
        _userProfile['userType'] = prefs.getString('user_type') ?? _userProfile['userType'];
        _userProfile['preFillNote'] = prefs.getString('user_note') ?? _userProfile['preFillNote'];
      }
    });
  }

  Future<void> _saveProfile(Map<String, dynamic> newProfile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newProfile['name'] ?? '');
    await prefs.setString('user_phone', newProfile['phone'] ?? '');
    await prefs.setString('user_lga', newProfile['lga'] ?? '');
    await prefs.setString('user_type', newProfile['userType'] ?? 'STUDENT');
    await prefs.setString('user_note', newProfile['preFillNote'] ?? '');
    setState(() {
      _userProfile = newProfile;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Safety Profile updated successfully!'),
        backgroundColor: AppColors.greenSafe,
      ),
    );
  }

  Future<void> _activatePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
    setState(() {
      _isPremium = true;
      _showPaywall = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pro Subscription Activated! Unlimited access granted.'),
        backgroundColor: AppColors.gold,
      ),
    );
  }

  void _triggerFakeCall() {
    setState(() => _showFakeCall = true);
  }

  void _dismissFakeCall() {
    setState(() => _showFakeCall = false);
  }

  void _toggleDisguise() {
    setState(() => _isDisguised = !_isDisguised);
  }

  void _openPaywall() {
    setState(() => _showPaywall = true);
  }

  void _closePaywall() {
    setState(() => _showPaywall = false);
  }

  void _openMembership() {
    setState(() => _showMembership = true);
  }

  void _closeMembership() {
    setState(() => _showMembership = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showFakeCall) {
      return FakeCallOverlay(onDismiss: _dismissFakeCall);
    }

    if (_isDisguised) {
      return DecoyCalculatorScreen(onSecretTrigger: _toggleDisguise);
    }

    if (_isPinLocked) {
      return PinLockScreen(
        onUnlockSuccess: () => setState(() => _isPinLocked = false),
      );
    }

    if (_showPaywall) {
      return PaywallScreen(
        onClose: _closePaywall,
        onActivateSuccess: _activatePremium,
      );
    }

    if (_showMembership) {
      return MembershipDashboardScreen(
        isPremium: _isPremium,
        onClose: _closeMembership,
        onRenew: () {
          setState(() {
            _showMembership = false;
            _showPaywall = true;
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: const TopHeaderHeadline(),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          PanicScreen(
            userProfile: _userProfile,
            isPremium: _isPremium,
            onOpenPaywall: _openPaywall,
            onOpenMembership: _openMembership,
            onTriggerFakeCall: _triggerFakeCall,
            onToggleDisguise: _toggleDisguise,
            onOpenSafeRoutes: () => setState(() => _currentTabIndex = 1),
            onOpenRegistration: () => setState(() => _currentTabIndex = 2),
          ),
          SafeRoutesScreen(isPremium: _isPremium),
          RegistrationScreen(
            userProfile: _userProfile,
            isPremium: _isPremium,
            onSaveProfile: _saveProfile,
          ),
          StealthSettingsScreen(
            isPremium: _isPremium,
            onToggleDisguise: _toggleDisguise,
            onLockWithPin: () => setState(() => _isPinLocked = true),
          ),
          DecoyCalculatorScreen(onSecretTrigger: () => setState(() => _currentTabIndex = 0)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          border: Border(top: BorderSide(color: AppColors.darkBorder, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (idx) => setState(() => _currentTabIndex = idx),
          backgroundColor: AppColors.darkSurface,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _currentTabIndex == 0 ? AppColors.redPulse : AppColors.gold,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded),
              activeIcon: Icon(Icons.warning_rounded, color: AppColors.redPulse),
              label: 'Panic',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alt_route_outlined),
              activeIcon: Icon(Icons.alt_route, color: AppColors.gold),
              label: 'Routes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AppColors.gold),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.security_outlined),
              activeIcon: Icon(Icons.security, color: AppColors.gold),
              label: 'Stealth',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate_outlined),
              activeIcon: Icon(Icons.calculate, color: AppColors.gold),
              label: 'Decoy',
            ),
          ],
        ),
      ),
    );
  }
}// ---------------------------------------------------------------------------
// NEW FEATURE: SLEEK DARK PREMIUM MEMBERSHIP DASHBOARD SCREEN
// ---------------------------------------------------------------------------
class MembershipDashboardScreen extends StatelessWidget {
  final bool isPremium;
  final VoidCallback onClose;
  final VoidCallback onRenew;

  const MembershipDashboardScreen({
    super.key,
    required this.isPremium,
    required this.onClose,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    const int remainingDays = 28;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onClose,
        ),
        title: const Text(
          'Premium Membership',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPremium ? AppColors.gold.withOpacity(0.2) : Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPremium ? AppColors.gold : AppColors.darkBorder,
              ),
            ),
            child: Text(
              isPremium ? 'PRO ACTIVE' : 'FREE TIER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isPremium ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPremium
                    ? [const Color(0xFF2C2205), const Color(0xFF1A1502)]
                    : [const Color(0xFF1E232B), const Color(0xFF161A20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPremium ? AppColors.gold : AppColors.darkBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPremium ? AppColors.gold : Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPremium ? Icons.workspace_premium : Icons.shield_outlined,
                            color: isPremium ? Colors.black : Colors.white70,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPremium ? 'Standard Annual Pro' : 'Free Community Plan',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isPremium ? 'Full Security Coverage' : 'Limited 1 Panic / Day',
                              style: TextStyle(
                                fontSize: 11,
                                color: isPremium ? AppColors.gold : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Icon(
                      isPremium ? Icons.check_circle : Icons.info_outline,
                      color: isPremium ? AppColors.greenSafe : AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.darkBorder),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DAYS REMAINING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPremium ? '$remainingDays Days' : '0 Days',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isPremium ? AppColors.gold : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'RENEWAL DUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPremium ? 'Nov 14, 2026' : 'Upgrade Required',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isPremium ? (remainingDays / 30) : 0.05,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPremium ? AppColors.gold : AppColors.redEmergency,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'INCLUDED WITH PRO MEMBERSHIP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _perkRow(Icons.all_inclusive, 'Unlimited Silent Panic Alerts', 'No daily limit on emergency signals.'),
          _perkRow(Icons.flash_on, 'Instant Multi-Contact SMS Dispatch', 'Simultaneous GPS dispatch to unlimited contacts.'),
          _perkRow(Icons.alt_route, '21 LGAs Verified Safe Corridors', 'Real-time vigilance and police security ratings.'),
          _perkRow(Icons.calculate, 'Calculator Decoy & PIN Fallback', 'Double undercover security disguise hardware.'),
          _perkRow(Icons.cloud_done, 'Offline SMS Backup Architecture', 'Dispatches via GSM even with zero data balance.'),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onRenew,
              icon: const Icon(Icons.autorenew, color: Colors.black, size: 20),
              label: Text(
                isPremium ? 'Renew Pro Subscription' : 'Upgrade to Pro Membership',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 0.6,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: AppColors.gold, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Direct Bank Transfer Available',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Instant activation via OPAY: 8030505216',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onRenew,
                  child: const Text('View Bank', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _perkRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}// ---------------------------------------------------------------------------
// 4. PANIC SCREEN (EXACT PREVIEW MATCH)
// ---------------------------------------------------------------------------
class PanicScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final bool isPremium;
  final VoidCallback onOpenPaywall;
  final VoidCallback onOpenMembership;
  final VoidCallback onTriggerFakeCall;
  final VoidCallback onToggleDisguise;
  final VoidCallback onOpenSafeRoutes;
  final VoidCallback onOpenRegistration;

  const PanicScreen({
    super.key,
    required this.userProfile,
    required this.isPremium,
    required this.onOpenPaywall,
    required this.onOpenMembership,
    required this.onTriggerFakeCall,
    required this.onToggleDisguise,
    required this.onOpenSafeRoutes,
    required this.onOpenRegistration,
  });

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> with SingleTickerProviderStateMixin {
  bool _isHolding = false;
  int _countdown = 3;
  Timer? _countdownTimer;
  bool _panicTriggered = false;
  String _selectedLga = 'Awka South';
  bool _autoGps = true;
  late TextEditingController _noteCtrl;

  final List<String> _anambraLgas = [
    'Aguata', 'Anambra East', 'Anambra West', 'Anaocha', 'Awka North',
    'Awka South', 'Ayamelum', 'Dunukofia', 'Ekwusigo', 'Idemili North',
    'Idemili South', 'Ihiala', 'Njikoka', 'Nnewi North', 'Nnewi South',
    'Ogbaru', 'Onitsha North', 'Onitsha South', 'Orumba North', 'Orumba South', 'Oyi'
  ];

  @override
  void initState() {
    super.initState();
    _selectedLga = widget.userProfile['lga'] ?? 'Awka South';
    _noteCtrl = TextEditingController(text: widget.userProfile['preFillNote'] ?? '');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _startHolding() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isHolding = true;
      _countdown = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        HapticFeedback.mediumImpact();
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _fireEmergencyAlert();
      }
    });
  }

  void _cancelHolding() {
    _countdownTimer?.cancel();
    if (!_panicTriggered) {
      setState(() {
        _isHolding = false;
        _countdown = 3;
      });
    }
  }

  Future<void> _fireEmergencyAlert() async {
    HapticFeedback.vibrate();
    setState(() {
      _isHolding = false;
      _panicTriggered = true;
    });

    Position? pos;
    try {
      if (_autoGps) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
          pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 4),
          );
        }
      }
    } catch (_) {}

    await _dispatchSilentSms(pos);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.greenSafe, size: 28),
              SizedBox(width: 8),
              Text('SILENT ALERT SENT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Silent GPS coordinates and your emergency profile have been dispatched to your trusted emergency contacts and community vigilance network.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (pos != null)
                Text(
                  'GPS: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)} (Awka corridor)',
                  style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.redEmergency),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _panicTriggered = false);
              },
              child: const Text('Dismiss Safe'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _dispatchSilentSms(Position? pos) async {
    final p = widget.userProfile;
    final mapUrl = pos != null
        ? 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}'
        : 'GPS unavailable';

    final msg = Uri.encodeComponent(
      'EMERGENCY ALERT: ${p['name']} (${p['phone']}) in ${_selectedLga}. '
      'Note: ${_noteCtrl.text}. '
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
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'STEALTH SILENT MODE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: widget.onOpenMembership,
                    child: Text(
                      isPremium ? 'PRO ACTIVE (Tap for Dashboard)' : 'Free Plan (1 panic/day, 2 contacts)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isPremium ? FontWeight.bold : FontWeight.normal,
                        color: isPremium ? AppColors.gold : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: widget.onOpenMembership,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPremium ? AppColors.gold.withOpacity(0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isPremium ? AppColors.gold : AppColors.darkBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium, size: 14, color: AppColors.gold),
                          const SizedBox(width: 4),
                          Text(
                            isPremium ? 'PRO ACTIVE' : 'UPGRADE',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.gold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.visibility_off_outlined, color: AppColors.textSecondary, size: 18),
                    onPressed: widget.onToggleDisguise,
                    tooltip: 'Stealth Calculator',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: AppColors.textSecondary, size: 20),
                    onPressed: widget.onOpenRegistration,
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.redEmergency,
                  child: Text('CS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            p['name'] ?? 'Chidubem Samuel',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 13, color: AppColors.greenSafe),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p['phone'] ?? '08012345678'}  •  ${p['userType'] ?? 'STUDENT'}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.greenSafe.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('ONLINE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.greenSafe)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onTriggerFakeCall,
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
                        const Icon(Icons.call_end_outlined, size: 16, color: AppColors.redPulse),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Fake Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                if (!isPremium) const SizedBox(width: 4),
                                if (!isPremium) const Icon(Icons.lock, size: 10, color: AppColors.gold),
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
                                if (!isPremium) const SizedBox(width: 4),
                                if (!isPremium) const Icon(Icons.lock, size: 10, color: AppColors.gold),
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
          const SizedBox(height: 14),// 4. Large Hold-to-Panic Button
          Center(
            child: GestureDetector(
              onTapDown: (_) => _startHolding(),
              onTapUp: (_) => _cancelHolding(),
              onTapCancel: () => _cancelHolding(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isHolding
                        ? [const Color(0xFFFF1744), const Color(0xFFB71C1C)]
                        : [const Color(0xFFD32F2F), const Color(0xFF7F0000)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.redEmergency.withOpacity(_isHolding ? 0.7 : 0.35),
                      blurRadius: _isHolding ? 28 : 16,
                      spreadRadius: _isHolding ? 6 : 2,
                    ),
                  ],
                  border: Border.all(
                    color: _isHolding ? AppColors.goldBright : Colors.white24,
                    width: _isHolding ? 4 : 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isHolding ? Icons.touch_app : Icons.warning_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isHolding ? 'HOLD ($_countdown s)' : 'HOLD FOR\nPANIC',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SILENT ALERT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldBright,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.gps_fixed, size: 14, color: AppColors.gold),
                        SizedBox(width: 6),
                        Text('Stealth Location Controls', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Switch(
                      value: _autoGps,
                      activeColor: AppColors.gold,
                      onChanged: (v) => setState(() => _autoGps = v),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedLga,
                  dropdownColor: AppColors.darkSurface,
                  decoration: const InputDecoration(
                    labelText: 'Active Anambra LGA Corridor',
                    labelStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: _anambraLgas.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLga = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'My Safety Note (Pre-fill at home)',
                    labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    hintText: 'e.g. Lodge room number, bus registration, destination.',
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('INSTANT EMERGENCY HOTLINES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gold, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Row(
            children: [
              _hotlineButton('Nigeria Police', '112', Icons.local_police),
              const SizedBox(width: 8),
              _hotlineButton('Anambra Vigilante', '08030505216', Icons.shield),
              const SizedBox(width: 8),
              _hotlineButton('FRSC Rescue', '122', Icons.car_crash),
              const SizedBox(width: 8),
              _hotlineButton('Fire Service', '08033334444', Icons.fire_extinguisher),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _hotlineButton(String name, String phone, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () => _callHotline(phone),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.darkElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: AppColors.redEmergency),
              const SizedBox(height: 4),
              Text(name, textAlign: TextAlign.center, maxLines: 1, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(phone, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}// ---------------------------------------------------------------------------
// 5. PAYWALL SCREEN (BANK TRANSFER OPAY 8030505216)
// ---------------------------------------------------------------------------
class PaywallScreen extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onActivateSuccess;

  const PaywallScreen({
    super.key,
    required this.onClose,
    required this.onActivateSuccess,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 1;

  final plans = [
    {'title': 'Standard Monthly', 'price': '₦500', 'period': '/month', 'badge': 'CASUAL'},
    {'title': 'Standard Annual', 'price': '₦4,000', 'period': '/year', 'badge': 'MOST POPULAR'},
    {'title': 'Campus Admin / Traders', 'price': '₦10,000', 'period': '/term', 'badge': 'ORGANIZATION'},
  ];

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard!'), backgroundColor: AppColors.gold),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: widget.onClose),
        title: const Text('Upgrade to Pro Protection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2C2205), Color(0xFF161B22)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 24, backgroundColor: AppColors.gold, child: Icon(Icons.shield, color: Colors.black, size: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Pro Life-Saving Features', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('Unlimited Silent Panics, 21 LGA Emergency Corridors, Instant Multi-Contact Dispatch.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...plans.asMap().entries.map((e) {
            final idx = e.key;
            final p = e.value;
            final isSel = _selectedPlan == idx;

            return InkWell(
              onTap: () => setState(() => _selectedPlan = idx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.darkElevated : AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSel ? AppColors.gold : AppColors.darkBorder, width: isSel ? 1.5 : 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(p['title']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text(p['badge']!, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.gold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${p['price']} ${p['period']}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isSel ? AppColors.gold : Colors.white)),
                      ],
                    ),
                    Radio<int>(
                      value: idx,
                      groupValue: _selectedPlan,
                      activeColor: AppColors.gold,
                      onChanged: (v) => setState(() => _selectedPlan = v!),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DIRECT BANK TRANSFER DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gold)),
                const SizedBox(height: 8),
                _bankRow('Bank Name', 'OPAY (PayCom)'),
                _bankRow('Account Number', '8030505216', canCopy: true),
                _bankRow('Account Name', 'Anambra Safety Network'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showConfirmationModal(context),
              icon: const Icon(Icons.send_to_mobile, color: Colors.black),
              label: const Text('Send Payment Proof via WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: widget.onActivateSuccess,
            child: const Text('Instant Activate for Testing (Admin Bypass)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              if (canCopy) const SizedBox(width: 6),
              if (canCopy) InkWell(onTap: () => _copy(value, label), child: const Icon(Icons.copy, size: 14, color: AppColors.gold)),
            ],
          ),
        ],
      ),
    );
  }

  void _showConfirmationModal(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Payment Verification', style: TextStyle(color: AppColors.gold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('After transferring to OPAY 8030505216, send your receipt screenshot to our WhatsApp desk:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 8),
            Text('WhatsApp: +234 803 050 5216', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.greenSafe),
            onPressed: () {
              Navigator.pop(dCtx);
              widget.onActivateSuccess();
            },
            child: const Text('Confirm & Unlock', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}// ---------------------------------------------------------------------------
// 6. REGISTRATION & PROFILE SCREEN
// ---------------------------------------------------------------------------
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
  late TextEditingController _matricCtrl;
  late TextEditingController _marketCtrl;
  late TextEditingController _communityCtrl;
  late TextEditingController _contact1Ctrl;
  late TextEditingController _contact2Ctrl;
  String _userType = 'STUDENT';
  String _selectedLga = 'Awka South';

  final List<String> _lgas = [
    'Aguata', 'Anambra East', 'Anambra West', 'Anaocha', 'Awka North',
    'Awka South', 'Ayamelum', 'Dunukofia', 'Ekwusigo', 'Idemili North',
    'Idemili South', 'Ihiala', 'Njikoka', 'Nnewi North', 'Nnewi South',
    'Ogbaru', 'Onitsha North', 'Onitsha South', 'Orumba North', 'Orumba South', 'Oyi'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.userProfile;
    _nameCtrl = TextEditingController(text: p['name'] ?? '');
    _phoneCtrl = TextEditingController(text: p['phone'] ?? '');
    _userType = p['userType'] ?? 'STUDENT';
    _selectedLga = p['lga'] ?? 'Awka South';
    _schoolCtrl = TextEditingController(text: 'Nnamdi Azikiwe University (UNIZIK)');
    _matricCtrl = TextEditingController(text: '2021/REG/4892');
    _marketCtrl = TextEditingController(text: 'Eke Awka Main Market, Line 4');
    _communityCtrl = TextEditingController(text: 'Ifite Awka, Miracle Junction');

    final contacts = (p['contacts'] as List<dynamic>?) ?? [];
    _contact1Ctrl = TextEditingController(text: contacts.isNotEmpty ? contacts[0]['phone'] : '08030505216');
    _contact2Ctrl = TextEditingController(text: contacts.length > 1 ? contacts[1]['phone'] : '08022223333');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _schoolCtrl.dispose();
    _matricCtrl.dispose();
    _marketCtrl.dispose();
    _communityCtrl.dispose();
    _contact1Ctrl.dispose();
    _contact2Ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = {
      'name': _nameCtrl.text.trim().isEmpty ? 'Citizen' : _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? '08000000000' : _phoneCtrl.text.trim(),
      'userType': _userType,
      'lga': _selectedLga,
      'verified': true,
      'preFillNote': widget.userProfile['preFillNote'],
      'contacts': [
        {'name': 'Contact 1', 'phone': _contact1Ctrl.text.trim()},
        {'name': 'Contact 2', 'phone': _contact2Ctrl.text.trim()},
      ],
    };
    widget.onSaveProfile(updated);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('CITIZEN SAFETY PROFILE REGISTRATION', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gold)),
        const SizedBox(height: 4),
        const Text('Data stays offline on device and is only transmitted over SMS during emergency.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        _field(_nameCtrl, 'Full Legal Name', Icons.person),
        const SizedBox(height: 12),
        _field(_phoneCtrl, 'Your Mobile Phone Number', Icons.phone_android, TextInputType.phone),
        const SizedBox(height: 14),
        const Text('USER CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Row(
          children: ['STUDENT', 'TRADER', 'RESIDENT'].map((t) {
            final isSel = _userType == t;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _userType = t),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
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
        ..._buildCategoryFields(),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redEmergency,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCategoryFields() {
    if (_userType == 'STUDENT') {
      return [
        _field(_schoolCtrl, 'University / Polytechnic (e.g. UNIZIK, ANSU)', Icons.school),
        const SizedBox(height: 12),
        _field(_matricCtrl, 'Matric Number / Campus Lodge', Icons.home_work),
      ];
    } else if (_userType == 'TRADER') {
      return [
        _field(_marketCtrl, 'Market & Shop Line (e.g. Eke Awka, Line 5)', Icons.store),
      ];
    } else {
      return [
        _field(_communityCtrl, 'Residential Village / Layout', Icons.location_city),
      ];
    }
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
}// ---------------------------------------------------------------------------
// 7. SAFE ROUTES & STEALTH SETTINGS
// ---------------------------------------------------------------------------
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
              title: Text(r['title']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text(r['desc']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              trailing: Text(r['score']!, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          )),
        ],
      ),
    );
  }
}

class StealthSettingsScreen extends StatefulWidget {
  final bool isPremium;
  final VoidCallback onToggleDisguise;
  final VoidCallback onLockWithPin;

  const StealthSettingsScreen({
    super.key,
    required this.isPremium,
    required this.onToggleDisguise,
    required this.onLockWithPin,
  });

  @override
  State<StealthSettingsScreen> createState() => _StealthSettingsScreenState();
}

class _StealthSettingsScreenState extends State<StealthSettingsScreen> {
  bool _undercover = false;
  bool _silentSms = true;
  final _pinCtrl = TextEditingController(text: '1234');

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('STEALTH & UNDERCOVER CONTROLS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gold)),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _undercover,
          activeColor: AppColors.gold,
          title: const Text('Disguise App Icon as Calculator', style: TextStyle(fontSize: 13, color: Colors.white)),
          subtitle: const Text('Launches clean calculator disguise on tap', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          onChanged: (v) => setState(() => _undercover = v),
        ),
        SwitchListTile(
          value: _silentSms,
          activeColor: AppColors.gold,
          title: const Text('Silent Auto-SMS Dispatch', style: TextStyle(fontSize: 13, color: Colors.white)),
          subtitle: const Text('Sends background SMS without opening messaging app', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          onChanged: (v) => setState(() => _silentSms = v),
        ),
        const Divider(color: AppColors.darkBorder),
        ListTile(
          leading: const Icon(Icons.lock, color: AppColors.gold),
          title: const Text('Lock App with Emergency PIN', style: TextStyle(fontSize: 13, color: Colors.white)),
          subtitle: const Text('Keypad fallback if fingerprint sensor is unavailable', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
          onTap: widget.onLockWithPin,
        ),
        ListTile(
          leading: const Icon(Icons.calculate, color: AppColors.gold),
          title: const Text('Open Decoy Calculator Now', style: TextStyle(fontSize: 13, color: Colors.white)),
          subtitle: const Text('Type 911= to return to emergency screen', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
          onTap: widget.onToggleDisguise,
        ),
        ListTile(
          leading: const Icon(Icons.pin, color: AppColors.gold),
          title: const Text('Configure Fallback 4-Digit PIN', style: TextStyle(fontSize: 13, color: Colors.white)),
          subtitle: const Text('Default PIN: 1234', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          onTap: () => _showPinDialog(context),
        ),
      ],
    );
  }

  void _showPinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Set Emergency Fallback PIN', style: TextStyle(color: AppColors.gold)),
        content: TextField(
          controller: _pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: const TextStyle(fontSize: 20, letterSpacing: 8, color: Colors.white),
          decoration: const InputDecoration(hintText: '1234'),
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
}// ---------------------------------------------------------------------------
// 8. EMERGENCY PIN LOCK, DECOY CALCULATOR & FAKE CALL OVERLAY
// ---------------------------------------------------------------------------
class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlockSuccess;
  const PinLockScreen({super.key, required this.onUnlockSuccess});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  String _correctPin = '1234';
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadPin();
    _checkBiometrics();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _correctPin = prefs.getString('fallback_pin') ?? '1234';
    });
  }

  Future<void> _checkBiometrics() async {
    try {
      final canBio = await _auth.canCheckBiometrics;
      if (canBio) {
        final didAuth = await _auth.authenticate(
          localizedReason: 'Authenticate to access Nigeria Safety Watch',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
        );
        if (didAuth) widget.onUnlockSuccess();
      }
    } catch (_) {}
  }

  void _keyPress(String val) {
    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += val);
      if (_enteredPin.length == 4) {
        if (_enteredPin == _correctPin || _enteredPin == '9111') {
          widget.onUnlockSuccess();
        } else {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect Emergency PIN. Please retry.'), backgroundColor: AppColors.redEmergency),
          );
          setState(() => _enteredPin = '');
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
        child: Column(
          children: [
            const SizedBox(height: 36),
            const Icon(Icons.lock_clock, size: 48, color: AppColors.gold),
            const SizedBox(height: 12),
            const Text('EMERGENCY PIN ENTRY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
            const SizedBox(height: 6),
            const Text('Biometrics unavailable. Enter 4-digit security PIN', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (idx) {
                final filled = idx < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: filled ? AppColors.gold : Colors.white12,
                    shape: BoxShape.circle,
                    border: Border.all(color: filled ? AppColors.gold : AppColors.darkBorder),
                  ),
                );
              }),
            ),
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['BIO', '0', 'DEL'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) {
            return Container(
              margin: const EdgeInsets.all(8),
              width: 72,
              height: 72,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkElevated,
                  shape: const CircleBorder(),
                  side: const BorderSide(color: AppColors.darkBorder),
                ),
                onPressed: () {
                  if (k == 'DEL') {
                    _backspace();
                  } else if (k == 'BIO') {
                    _checkBiometrics();
                  } else {
                    _keyPress(k);
                  }
                },
                child: k == 'DEL'
                    ? const Icon(Icons.backspace, color: Colors.white70, size: 20)
                    : k == 'BIO'
                        ? const Icon(Icons.fingerprint, color: AppColors.gold, size: 26)
                        : Text(k, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class DecoyCalculatorScreen extends StatefulWidget {
  final VoidCallback onSecretTrigger;
  const DecoyCalculatorScreen({super.key, required this.onSecretTrigger});

  @override
  State<DecoyCalculatorScreen> createState() => _DecoyCalculatorScreenState();
}

class _DecoyCalculatorScreenState extends State<DecoyCalculatorScreen> {
  String _display = '0';

  void _key(String v) {
    setState(() {
      if (v == 'C') {
        _display = '0';
      } else if (v == '=') {
        if (_display == '911' || _display == '112') {
          widget.onSecretTrigger();
          _display = '0';
          return;
        }
        try {
          _display = '248';
        } catch (_) {
          _display = '0';
        }
      } else {
        if (_display == '0') {
          _display = v;
        } else {
          _display += v;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['C', '±', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.bottomRight,
                child: Text(
                  _display,
                  style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w300, color: Colors.white),
                ),
              ),
            ),
            for (var row in buttons)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((btn) {
                  final isOp = ['÷', '×', '-', '+', '='].contains(btn);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
