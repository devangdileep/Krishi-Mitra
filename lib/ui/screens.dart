import 'dart:async';
import 'dart:convert';
import 'dart:math' hide Point;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../app/app_state.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../services/ai_services.dart';
import '../services/api_clients.dart';
import '../services/auth_service.dart';
import '../services/human_voice_service.dart';
import '../theme/app_theme.dart';
import 'services_screen.dart';
import 'widgets/premium_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1250), () {
      if (!mounted) return;
      final state = AppStateScope.of(context);
      if (state.user != null) {
        context.go('/home');
      } else if (state.onboardingCompleted) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.86, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: const Hero(
                    tag: 'krishi-logo',
                    child: KrishiLogo(size: 92),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Krishi Mitra',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI farming, built for weak networks',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(999),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.map_rounded,
      title: 'Map every plot simply',
      body:
          'Use GPS scan, tap corners, and get farm area without complex tools.',
    ),
    _OnboardingPageData(
      icon: Icons.auto_awesome_rounded,
      title: 'AI advice from your farm data',
      body: 'Reports combine crops, soil, weather, and farmland boundaries.',
    ),
    _OnboardingPageData(
      icon: Icons.wifi_off_rounded,
      title: 'Ready for rural networks',
      body: 'Cached farms and local previews keep the app useful offline.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    HapticFeedback.lightImpact();
    if (_index < _pages.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await AppStateScope.of(context).completeOnboarding();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              children: [
                Row(
                  children: [
                    const Hero(tag: 'krishi-logo', child: KrishiLogo()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Krishi Mitra',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await AppStateScope.of(context).completeOnboarding();
                        if (context.mounted) context.go('/login');
                      },
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return AnimatedEntrance(
                        child: Center(
                          child: GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      colors: [
                                        colors.primary,
                                        colors.secondary,
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    page.icon,
                                    color: colors.onPrimary,
                                    size: 42,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  page.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  page.body,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      width: _index == index ? 28 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _index == index
                            ? colors.primary
                            : colors.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _continue,
                  icon: Icon(_index == _pages.length - 1
                      ? Icons.arrow_forward_rounded
                      : Icons.swipe_rounded),
                  label: Text(
                    _index == _pages.length - 1 ? 'Start farming' : 'Next',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _AuthStep { details, otp }

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _registerMode = false;
  bool _loading = false;
  _AuthStep _step = _AuthStep.details;
  AuthOtpChallenge? _challenge;
  Timer? _ticker;
  int _secondsRemaining = 0;
  String? _error;

  @override
  void dispose() {
    _ticker?.cancel();
    _name.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final challenge = await widget.auth.requestOtp(
        mode: _registerMode ? AuthFlowMode.register : AuthFlowMode.login,
        name: _registerMode ? _name.text : null,
        phoneNumber: _phone.text,
      );
      if (!mounted) return;
      _otp.clear();
      setState(() {
        _challenge = challenge;
        _step = _AuthStep.otp;
        _secondsRemaining = challenge.secondsRemaining;
      });
      _startTicker();
      _showOtpSnack(challenge);
    } catch (error) {
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final challenge = _challenge;
    if (challenge == null) return;
    final result = widget.auth.validateOtp(challenge, _otp.text);
    if (!result.verified) {
      setState(() {
        _challenge = result.challenge;
        _secondsRemaining = result.challenge.secondsRemaining;
        _error = result.message;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await widget.auth.completeVerifiedChallenge(challenge);
      if (!mounted) return;
      await AppStateScope.of(context).setUser(user);
      if (!mounted) return;
      context.go('/home');
    } catch (error) {
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    final challenge = _challenge;
    if (challenge == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final updated = await widget.auth.resendOtp(challenge);
      if (!mounted) return;
      _otp.clear();
      setState(() {
        _challenge = updated;
        _secondsRemaining = updated.secondsRemaining;
      });
      _startTicker();
      _showOtpSnack(updated);
    } catch (error) {
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final challenge = _challenge;
      if (!mounted || challenge == null) return;
      setState(() => _secondsRemaining = challenge.secondsRemaining);
      if (challenge.secondsRemaining == 0) _ticker?.cancel();
    });
  }

  void _backToDetails() {
    _ticker?.cancel();
    setState(() {
      _step = _AuthStep.details;
      _challenge = null;
      _otp.clear();
      _secondsRemaining = 0;
      _error = null;
    });
  }

  void _toggleMode() {
    _backToDetails();
    setState(() => _registerMode = !_registerMode);
  }

  void _showOtpSnack(AuthOtpChallenge challenge) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Testing OTP: ${challenge.debugCode}')),
    );
  }

  String _friendlyError(Object error) {
    return '$error'
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '');
  }

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final waitingForOtp = _step == _AuthStep.otp;
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: GlassCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const KrishiLogo(size: 72),
                    const SizedBox(height: 16),
                    Text(
                      waitingForOtp
                          ? 'Verify OTP'
                          : _registerMode
                              ? 'Create account'
                              : 'Welcome back',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.primary,
                              ),
                    ),
                    Text(
                      waitingForOtp
                          ? 'Enter the code for ${_challenge?.maskedPhone ?? "your phone"}'
                          : _registerMode
                              ? 'Register with mobile OTP'
                              : 'Login with mobile OTP',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (waitingForOtp)
                      ..._otpFields(context, colors)
                    else
                      ..._detailsFields(),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: colors.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading
                          ? null
                          : waitingForOtp
                              ? _verifyOtp
                              : _requestOtp,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(waitingForOtp
                              ? 'Verify and continue'
                              : _registerMode
                                  ? 'Send OTP to register'
                                  : 'Send OTP to login'),
                    ),
                    if (waitingForOtp)
                      TextButton.icon(
                        onPressed: _loading || _secondsRemaining > 260
                            ? null
                            : _resendOtp,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Resend OTP'),
                      )
                    else
                      TextButton(
                        onPressed: _loading ? null : _toggleMode,
                        child: Text(
                          _registerMode
                              ? 'Already registered? Login'
                              : 'New farmer? Register',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _detailsFields() {
    return [
      if (_registerMode) ...[
        TextField(
          controller: _name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.person_rounded),
            labelText: 'Full name',
          ),
        ),
        const SizedBox(height: 12),
      ],
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.phone_android_rounded),
          labelText: '10 digit mobile number',
        ),
      ),
    ];
  }

  List<Widget> _otpFields(BuildContext context, ColorScheme colors) {
    final challenge = _challenge;
    final attempts = challenge?.attemptsLeft ?? AuthService.maxAttempts;
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.phone_android_rounded, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'OTP sent to ${challenge?.maskedPhone ?? "your phone"}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: _loading ? null : _backToDetails,
              child: const Text('Change'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _otp,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(AuthService.otpLength),
        ],
        onSubmitted: (_) => _loading ? null : _verifyOtp(),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_rounded),
          labelText: '6 digit OTP',
          counterText: '',
          helperText:
              'Expires in ${_formatSeconds(_secondsRemaining)} - $attempts attempts left',
        ),
        maxLength: AuthService.otpLength,
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.tertiaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.sms_rounded, color: colors.tertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Testing OTP: ${challenge?.debugCode ?? "------"}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.api,
    required this.repository,
    required this.weather,
    required this.mandi,
    required this.decisionEngine,
    required this.intelligence,
    required this.voiceService,
  });

  final SupabaseRestClient api;
  final FarmlandRepository repository;
  final WeatherClient weather;
  final DataGovMandiClient mandi;
  final DecisionEngine decisionEngine;
  final FarmlandIntelligence intelligence;
  final HumanVoiceService voiceService;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final user = state.user!;
    final pages = [
      CropsScreen(
        repository: widget.repository,
        weather: widget.weather,
        intelligence: widget.intelligence,
        userId: user.id,
        onOpenAccount: () => setState(() => _index = 4),
      ),
      ReportScreen(
        repository: widget.repository,
        weather: widget.weather,
        intelligence: widget.intelligence,
        decisionEngine: widget.decisionEngine,
        voiceService: widget.voiceService,
        userId: user.id,
      ),
      const ServicesScreen(),
      AlertsScreen(
        api: widget.api,
        repository: widget.repository,
        mandi: widget.mandi,
        userId: user.id,
      ),
      ProfileScreen(api: widget.api),
    ];

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: _AppDrawer(
          userLabel: '${user.name} (${user.phoneNumber})',
          onSelect: (index) {
            Navigator.of(context).pop();
            setState(() => _index = index);
          },
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: pages[_index],
          ),
        ),
        floatingActionButton: GlassOrbButton(
          icon: Icons.mic_rounded,
          tooltip: 'Voice assistant',
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => VoiceAssistantSheet(
              repository: widget.repository,
              decisionEngine: widget.decisionEngine,
              voiceService: widget.voiceService,
              userId: user.id,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: FrostedNavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.agriculture_rounded),
              label: 'Farms',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_rounded),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Services',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_rounded),
              label: 'Market',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.userLabel, required this.onSelect});

  final String userLabel;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final colors = Theme.of(context).colorScheme;
    return Drawer(
      backgroundColor: Colors.transparent,
      child: GlassBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const KrishiLogo(size: 58),
                    const SizedBox(height: 14),
                    Text(
                      'Krishi Mitra',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userLabel,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _DrawerTile(
                icon: Icons.dashboard_rounded,
                label: 'Farms',
                onTap: () => onSelect(0),
              ),
              _DrawerTile(
                icon: Icons.insights_rounded,
                label: 'Insights',
                onTap: () => onSelect(1),
              ),
              _DrawerTile(
                icon: Icons.grid_view_rounded,
                label: 'Services',
                onTap: () => onSelect(2),
              ),
              _DrawerTile(
                icon: Icons.storefront_rounded,
                label: 'Market',
                onTap: () => onSelect(3),
              ),
              _DrawerTile(
                icon: Icons.manage_accounts_rounded,
                label: 'Account',
                onTap: () => onSelect(4),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await state.logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor:
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.42),
        leading: Icon(icon),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class CropsScreen extends StatefulWidget {
  const CropsScreen({
    super.key,
    required this.repository,
    required this.weather,
    required this.intelligence,
    required this.userId,
    required this.onOpenAccount,
  });

  final FarmlandRepository repository;
  final WeatherClient weather;
  final FarmlandIntelligence intelligence;
  final int userId;
  final VoidCallback onOpenAccount;

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  final _cropSearch = TextEditingController(text: 'Rice');
  List<Farmland> _farms = const [];
  bool _loading = true;
  String _selectedCrop = 'Rice';
  String? _selectedFarmId;
  WeatherForecast? _profileWeather;
  bool _profileWeatherLoading = false;
  String? _lastWeatherKey;
  CropIntelligenceReport? _cropReport;
  List<CropHealthIssue> _healthCases = const [];
  bool _cropAiLoading = false;
  String? _cropAiError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfileWeather(AppStateScope.of(context));
  }

  @override
  void dispose() {
    _cropSearch.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _farms = widget.repository.cached(widget.userId);
      _healthCases = widget.intelligence.fieldDoctorCases(widget.userId);
      _loading = _farms.isEmpty;
    });
    try {
      final farms = await widget.repository.refresh(widget.userId);
      if (mounted) {
        setState(() {
          _farms = farms;
          _healthCases = widget.intelligence.fieldDoctorCases(widget.userId);
        });
      }
    } catch (_) {
      // Keep the cached dashboard visible when the network is weak.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _refreshHealthCases() {
    setState(() {
      _healthCases = widget.intelligence.fieldDoctorCases(widget.userId);
    });
  }

  Future<void> _openFieldDoctor() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.55,
        maxChildSize: 0.97,
        builder: (context, controller) => _FieldDoctorSheet(
          userId: widget.userId,
          farms: _farms,
          weather: _profileWeather,
          intelligence: widget.intelligence,
          scrollController: controller,
          onSaved: _refreshHealthCases,
        ),
      ),
    );
    _refreshHealthCases();
  }

  Future<void> _loadProfileWeather(AppState state) async {
    final lat = state.userLat;
    final lng = state.userLng;
    if (lat == null || lng == null) return;
    final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
    if (_lastWeatherKey == key || _profileWeatherLoading) return;
    _lastWeatherKey = key;
    setState(() {
      _profileWeatherLoading = true;
      _profileWeather = null;
    });
    try {
      final weather = await widget.weather.daily(lat, lng);
      if (!mounted) return;
      setState(() => _profileWeather = weather);
    } catch (_) {
      if (!mounted) return;
      setState(() => _profileWeather = null);
    } finally {
      if (mounted) setState(() => _profileWeatherLoading = false);
    }
  }

  Future<void> _openEditor([Farmland? farm]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FarmlandEditorScreen(
          repository: widget.repository,
          userId: widget.userId,
          farmland: farm,
        ),
      ),
    );
    await _load();
  }

  void _chooseCrop(String crop) {
    final clean = _titleCaseCrop(crop.trim());
    if (clean.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCrop = clean;
      _cropSearch.text = clean;
      _cropReport = null;
      _cropAiError = null;
    });
  }

  Future<void> _runCropAnalysis() async {
    final clean = _titleCaseCrop(_cropSearch.text.trim());
    if (clean.isEmpty || _cropAiLoading) return;
    final state = AppStateScope.of(context);
    setState(() {
      _selectedCrop = clean;
      _cropSearch.text = clean;
      _cropAiLoading = true;
      _cropAiError = null;
    });
    try {
      final report = await widget.intelligence.analyzeCrop(
        clean,
        _farms,
        state.userLocationName ?? _profileCoordinateLabel(state),
        weather: _profileWeather,
        latitude: state.userLat,
        longitude: state.userLng,
      );
      if (!mounted) return;
      setState(() {
        _cropReport = report;
        _cropAiError = report == null
            ? 'Groq is not configured or did not return JSON, so the built-in crop guide is shown.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _cropAiError = _friendlyInlineError(error));
    } finally {
      if (mounted) setState(() => _cropAiLoading = false);
    }
  }

  Future<void> _confirmDeleteFarm(Farmland farm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete farmland?'),
        content: Text(
          'This removes "${farm.name}" from your farm workspace and syncs the deletion when possible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.delete(widget.userId, farm.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${farm.name} deleted')),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final totalArea = _farms.fold<double>(
      0,
      (sum, farm) => sum + estimateAreaHectares(farm.boundaryPoints),
    );
    final cropCount = _farms.expand((e) => e.crops).length;
    final mappedFarms =
        _farms.where((farm) => farm.boundaryPoints.length >= 3).length;
    final cropFacts = _cropFactsFor(_selectedCrop);
    final locationName = state.userLocationName;
    final evaluations = _farms
        .map((farm) => _evaluateCropForFarm(
              facts: cropFacts,
              farm: farm,
              weather: _profileWeather,
              userLat: state.userLat,
            ))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final selectedFarm = _farms.where((farm) => farm.id == _selectedFarmId);
    final activeEvaluation = selectedFarm.isEmpty
        ? (evaluations.isEmpty ? null : evaluations.first)
        : evaluations.firstWhere(
            (item) => item.farm.id == selectedFarm.first.id,
            orElse: () => _evaluateCropForFarm(
              facts: cropFacts,
              farm: selectedFarm.first,
              weather: _profileWeather,
              userLat: state.userLat,
            ),
          );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            AnimatedEntrance(
              child: _LocationContextCard(
                locationName: locationName,
                weather: _profileWeather,
                loadingWeather: _profileWeatherLoading,
                onSetLocation: widget.onOpenAccount,
              ),
            ),
            const SizedBox(height: 14),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 60),
              child: _CropSearchPlanner(
                controller: _cropSearch,
                selectedCrop: _selectedCrop,
                loadingAi: _cropAiLoading,
                onSubmitted: _runCropAnalysis,
                onChipSelected: _chooseCrop,
              ),
            ),
            const SizedBox(height: 14),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 120),
              child: _CropAdvisorSummary(
                facts: cropFacts,
                report: _cropReport,
                aiError: _cropAiError,
                weather: _profileWeather,
                locationName: locationName,
              ),
            ),
            const SizedBox(height: 14),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 180),
              child: _FarmCropFitCard(
                cropName: cropFacts.name,
                farms: _farms,
                evaluations: evaluations,
                activeEvaluation: activeEvaluation,
                selectedFarmId: _selectedFarmId,
                aiReport: _cropReport,
                onFarmChanged: (id) => setState(() => _selectedFarmId = id),
                onAddFarm: () => _openEditor(),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 210),
              child: _FieldDoctorCard(
                cases: _healthCases,
                farms: _farms,
                onOpenDoctor: _openFieldDoctor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AnimatedEntrance(
                    delay: const Duration(milliseconds: 220),
                    child: PremiumMetricCard(
                      label: 'Farmland',
                      value: '${_farms.length}',
                      icon: Icons.landscape_rounded,
                      progress: _farms.isEmpty ? 0.12 : 0.82,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedEntrance(
                    delay: const Duration(milliseconds: 260),
                    child: PremiumMetricCard(
                      icon: Icons.polyline_rounded,
                      label: 'Area',
                      value: totalArea == 0
                          ? '--'
                          : '${totalArea.toStringAsFixed(2)} ha',
                      progress: totalArea == 0 ? 0.18 : 0.72,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedEntrance(
                    delay: const Duration(milliseconds: 300),
                    child: PremiumMetricCard(
                      icon: Icons.grass_rounded,
                      label: 'Crops',
                      value: '$cropCount',
                      progress: cropCount == 0 ? 0.2 : 0.65,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 340),
              child: _InsightStrip(
                mappedFarms: mappedFarms,
                totalFarms: _farms.length,
                cropCount: cropCount,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _openEditor();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add or scan farmland'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const ShimmerSkeleton(lines: 5)
            else if (_farms.isEmpty)
              const _EmptyState(
                title: 'No farmlands yet',
                message: 'Tap Add or scan farmland to create your first plot.',
              )
            else
              ..._farms.map(
                (farm) => GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        farm.name.isEmpty
                            ? 'F'
                            : farm.name.substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text(farm.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${farm.soilType ?? "Unknown soil"} - ${farm.crops.length} crops - ${farm.boundaryPoints.length} pts',
                    ),
                    trailing: Wrap(
                      spacing: 2,
                      children: [
                        IconButton(
                          tooltip: 'Delete farmland',
                          onPressed: () => _confirmDeleteFarm(farm),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () => _openEditor(farm),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 380),
              child: _SoilHealthTips(
                farms: _farms,
                weather: _profileWeather,
                locationName: locationName,
                userLat: state.userLat,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 420),
              child: _SeasonalCropCalendar(
                locationName: locationName,
                userLat: state.userLat,
                weather: _profileWeather,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropSearchPlanner extends StatelessWidget {
  const _CropSearchPlanner({
    required this.controller,
    required this.selectedCrop,
    required this.loadingAi,
    required this.onSubmitted,
    required this.onChipSelected,
  });

  final TextEditingController controller;
  final String selectedCrop;
  final bool loadingAi;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onChipSelected;

  static const _popularCrops = [
    'Rice',
    'Wheat',
    'Cotton',
    'Maize',
    'Banana',
    'Coconut',
    'Groundnut',
    'Tomato',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.travel_explore_rounded, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search crop suitability',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      'Area fit, harvest method, market price, and ROI',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => onSubmitted(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              labelText: 'Search a crop',
              hintText: 'Example: Cotton, Rice, Turmeric',
              suffixIcon: IconButton(
                tooltip: 'Analyze crop',
                onPressed: loadingAi ? null : onSubmitted,
                icon: loadingAi
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Quick picks',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _popularCrops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final crop = _popularCrops[index];
                return _ModernSelectorChip(
                  label: crop,
                  icon: Icons.grass_rounded,
                  selected: crop.toLowerCase() == selectedCrop.toLowerCase(),
                  onTap: () => onChipSelected(crop),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSelectorChip extends StatelessWidget {
  const _ModernSelectorChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = selected
        ? colors.primaryContainer
        : colors.surfaceContainerHighest.withValues(alpha: 0.36);
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_rounded : icon,
                size: 16, color: foreground),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? colors.onPrimaryContainer : colors.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationContextCard extends StatelessWidget {
  const _LocationContextCard({
    required this.locationName,
    required this.weather,
    required this.loadingWeather,
    required this.onSetLocation,
  });

  final String? locationName;
  final WeatherForecast? weather;
  final bool loadingWeather;
  final VoidCallback onSetLocation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasLocation = locationName != null && locationName!.trim().isNotEmpty;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasLocation
                      ? Icons.my_location_rounded
                      : Icons.add_location_alt_rounded,
                  color: colors.tertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLocation
                          ? _compactLocationLabel(locationName) ?? locationName!
                          : 'No farm region set',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      hasLocation
                          ? locationName!
                          : 'Set this in Account with map, GPS, or search.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onSetLocation,
                tooltip: hasLocation ? 'Change location' : 'Set location',
                icon: Icon(hasLocation
                    ? Icons.edit_location_alt_rounded
                    : Icons.add_location_alt_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasLocation)
            Text(
              'Crop fit, market notes, and weather cycle get sharper once your default region is saved.',
              style: TextStyle(color: colors.onSurfaceVariant),
            )
          else if (loadingWeather)
            const LinearProgressIndicator(minHeight: 5)
          else
            Row(
              children: [
                Expanded(
                  child: _MiniSignalPill(
                    icon: Icons.thermostat_rounded,
                    label: 'Avg high',
                    value: _averageHighLabel(weather),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniSignalPill(
                    icon: Icons.water_drop_rounded,
                    label: 'Rain',
                    value: _weeklyRainLabel(weather),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniSignalPill(
                    icon: Icons.calendar_month_rounded,
                    label: 'Cycle',
                    value: _weatherCycleLabel(weather),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CropAdvisorSummary extends StatelessWidget {
  const _CropAdvisorSummary({
    required this.facts,
    required this.report,
    required this.aiError,
    required this.weather,
    required this.locationName,
  });

  final _CropAdvisorFacts facts;
  final CropIntelligenceReport? report;
  final String? aiError;
  final WeatherForecast? weather;
  final String? locationName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locationPrefix = locationName == null ? 'India' : locationName!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.grass_rounded, color: colors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facts.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      'Crop decision report for $locationPrefix',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              children: [
                _AdvisorCompactRow(
                  icon: Icons.public_rounded,
                  label: 'Suitable areas',
                  value: report?.suitableArea ?? facts.suitableRegions,
                ),
                _AdvisorDivider(colors: colors),
                _AdvisorCompactRow(
                  icon: Icons.agriculture_rounded,
                  label: 'Harvesting',
                  value: report?.harvestingInfo ?? facts.harvestMethod,
                ),
                _AdvisorDivider(colors: colors),
                _AdvisorCompactRow(
                  icon: Icons.storefront_rounded,
                  label: 'Local price',
                  value: report?.marketPriceEstimate ?? facts.marketPriceRange,
                ),
                _AdvisorDivider(colors: colors),
                _AdvisorCompactRow(
                  icon: Icons.trending_up_rounded,
                  label: 'ROI estimate',
                  value: report?.roiEstimate ?? facts.roiSummary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DetailPill(
                icon: Icons.schedule_rounded,
                label: facts.cropCycle,
              ),
              _DetailPill(
                icon: Icons.science_rounded,
                label: facts.soilPreference,
              ),
              _DetailPill(
                icon: Icons.water_rounded,
                label: facts.waterNeed,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _weatherFitForCrop(facts, weather),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          if (aiError != null) ...[
            const SizedBox(height: 10),
            Text(aiError!, style: TextStyle(color: colors.error)),
          ],
        ],
      ),
    );
  }
}

class _FarmCropFitCard extends StatelessWidget {
  const _FarmCropFitCard({
    required this.cropName,
    required this.farms,
    required this.evaluations,
    required this.activeEvaluation,
    required this.selectedFarmId,
    required this.aiReport,
    required this.onFarmChanged,
    required this.onAddFarm,
  });

  final String cropName;
  final List<Farmland> farms;
  final List<_CropFitEvaluation> evaluations;
  final _CropFitEvaluation? activeEvaluation;
  final String? selectedFarmId;
  final CropIntelligenceReport? aiReport;
  final ValueChanged<String?> onFarmChanged;
  final VoidCallback onAddFarm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final aiFarmNote = activeEvaluation == null
        ? null
        : aiReport?.farmlandEvaluations[activeEvaluation!.farm.id];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.fact_check_rounded, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best farmland for $cropName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      farms.isEmpty
                          ? 'Add land details to compare suitability.'
                          : 'Select a farm or use the highest score.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (farms.isEmpty)
            FilledButton.icon(
              onPressed: onAddFarm,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add farmland for crop matching'),
            )
          else ...[
            Text(
              'Choose farmland',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: farms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final farm = farms[index];
                  final eval = evaluations.firstWhere(
                    (item) => item.farm.id == farm.id,
                    orElse: () => _CropFitEvaluation(
                      farm: farm,
                      score: 0,
                      reason: 'Suitability pending.',
                    ),
                  );
                  final selected = activeEvaluation?.farm.id == farm.id;
                  return _ModernSelectorChip(
                    label: '${farm.name} ${eval.score.toStringAsFixed(0)}%',
                    icon: Icons.landscape_rounded,
                    selected: selected,
                    onTap: () => onFarmChanged(farm.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            if (activeEvaluation != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activeEvaluation!.farm.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  _ScoreBadge(evaluation: activeEvaluation!),
                ],
              ),
              const SizedBox(height: 10),
              _SuitabilityMeter(score: activeEvaluation!.score),
              const SizedBox(height: 10),
              Text(activeEvaluation!.reason),
              if (aiFarmNote != null && aiFarmNote.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  aiFarmNote,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ],
            if (evaluations.length > 1) ...[
              const SizedBox(height: 14),
              Text(
                'Top matches',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final item in evaluations.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.farm.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.score.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FieldDoctorCard extends StatelessWidget {
  const _FieldDoctorCard({
    required this.cases,
    required this.farms,
    required this.onOpenDoctor,
  });

  final List<CropHealthIssue> cases;
  final List<Farmland> farms;
  final VoidCallback onOpenDoctor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final openCases = cases.where((item) => item.status == 'OPEN').length;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.errorContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.health_and_safety_rounded, color: colors.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Field Doctor',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      farms.isEmpty
                          ? 'Add farmland first, then diagnose crop issues.'
                          : '$openCases open crop health ${openCases == 1 ? "case" : "cases"}',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: farms.isEmpty ? null : onOpenDoctor,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Scan'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Record symptoms, get treatment guidance, and save a follow-up task to the selected farmland.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          if (cases.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final item in cases.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SeverityBadge(severity: item.severity),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.cropName} - ${item.issueType}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${item.farmlandName} - follow up ${DateFormat.MMMd().format(DateTime.fromMillisecondsSinceEpoch(item.followUpAt))}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _FieldDoctorSheet extends StatefulWidget {
  const _FieldDoctorSheet({
    required this.userId,
    required this.farms,
    required this.weather,
    required this.intelligence,
    required this.scrollController,
    required this.onSaved,
  });

  final int userId;
  final List<Farmland> farms;
  final WeatherForecast? weather;
  final FarmlandIntelligence intelligence;
  final ScrollController scrollController;
  final VoidCallback onSaved;

  @override
  State<_FieldDoctorSheet> createState() => _FieldDoctorSheetState();
}

class _FieldDoctorSheetState extends State<_FieldDoctorSheet> {
  static const _symptomOptions = [
    'Yellow leaves',
    'Brown spots',
    'Wilting',
    'Leaf holes',
    'White powder',
    'Stunted growth',
    'Fruit rot',
    'Stem borer',
    'Water logging',
  ];

  final _cropName = TextEditingController();
  final _description = TextEditingController();
  final Set<String> _symptoms = {};
  String? _farmId;
  CropHealthIssue? _result;
  bool _diagnosing = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    if (widget.farms.isNotEmpty) {
      final farm = widget.farms.first;
      _farmId = farm.id;
      if (farm.crops.isNotEmpty) _cropName.text = farm.crops.first.name;
    }
  }

  @override
  void dispose() {
    _cropName.dispose();
    _description.dispose();
    super.dispose();
  }

  Farmland? get _selectedFarm {
    if (widget.farms.isEmpty) return null;
    return widget.farms.firstWhere(
      (farm) => farm.id == _farmId,
      orElse: () => widget.farms.first,
    );
  }

  Future<void> _diagnose() async {
    final farm = _selectedFarm;
    final crop = _cropName.text.trim();
    if (farm == null || crop.isEmpty) {
      _showSnack('Select farmland and crop first.');
      return;
    }
    if (_symptoms.isEmpty && _description.text.trim().isEmpty) {
      _showSnack('Choose symptoms or describe what you see.');
      return;
    }
    setState(() {
      _diagnosing = true;
      _saved = false;
      _result = null;
    });
    try {
      final issue = await widget.intelligence.diagnoseFieldIssue(
        userId: widget.userId,
        farm: farm,
        cropName: crop,
        symptomTags: _symptoms.toList(),
        description: _description.text,
        weather: widget.weather,
      );
      if (!mounted) return;
      setState(() => _result = issue);
    } finally {
      if (mounted) setState(() => _diagnosing = false);
    }
  }

  Future<void> _saveCase() async {
    final issue = _result;
    if (issue == null) return;
    await widget.intelligence.saveFieldDoctorCase(issue);
    widget.onSaved();
    if (!mounted) return;
    setState(() => _saved = true);
    _showSnack('Field Doctor case saved.');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassBackground(
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.errorContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.health_and_safety_rounded, color: colors.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Field Doctor',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      'Diagnose symptoms and save a follow-up.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.farms.isEmpty)
            const _EmptyState(
              title: 'No farmland',
              message: 'Add farmland first to save crop health cases.',
            )
          else ...[
            DropdownButtonFormField<String>(
              key: ValueKey(_farmId),
              initialValue: _farmId,
              decoration: const InputDecoration(
                labelText: 'Farmland',
                prefixIcon: Icon(Icons.landscape_rounded),
              ),
              items: widget.farms
                  .map(
                    (farm) => DropdownMenuItem(
                      value: farm.id,
                      child: Text(
                        farm.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                final farm = widget.farms.firstWhere(
                  (item) => item.id == id,
                  orElse: () => widget.farms.first,
                );
                setState(() {
                  _farmId = id;
                  _result = null;
                  _saved = false;
                  if (farm.crops.isNotEmpty) {
                    _cropName.text = farm.crops.first.name;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cropName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Crop affected',
                prefixIcon: Icon(Icons.grass_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Symptoms',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final symptom in _symptomOptions)
                  FilterChip(
                    label: Text(symptom),
                    selected: _symptoms.contains(symptom),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _symptoms.add(symptom);
                        } else {
                          _symptoms.remove(symptom);
                        }
                        _result = null;
                        _saved = false;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Describe the crop problem',
                alignLabelWithHint: true,
                hintText:
                    'Example: brown spots on lower leaves after rain, spreading slowly...',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _diagnosing ? null : _diagnose,
              icon: _diagnosing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: const Text('Diagnose crop issue'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 14),
              _FieldDoctorResultCard(issue: _result!),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _saved ? null : _saveCase,
                icon: Icon(_saved
                    ? Icons.check_circle_rounded
                    : Icons.bookmark_add_rounded),
                label: Text(_saved ? 'Saved to farm log' : 'Save case'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FieldDoctorResultCard extends StatelessWidget {
  const _FieldDoctorResultCard({required this.issue});

  final CropHealthIssue issue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final followUp = DateTime.fromMillisecondsSinceEpoch(issue.followUpAt);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SeverityBadge(severity: issue.severity),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue.issueType,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                '${(issue.confidence * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReportText(title: 'Diagnosis', text: issue.diagnosis),
          _ReportText(title: 'Do Today', text: issue.immediateAction),
          _ReportText(
              title: 'Organic/IPM Option', text: issue.organicTreatment),
          _ReportText(
            title: 'Chemical Option',
            text: issue.chemicalTreatment,
          ),
          _ReportText(title: 'Weather Advice', text: issue.weatherAdvice),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.46),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.event_available_rounded, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recheck ${DateFormat.MMMd().format(followUp)} and compare the same patch.',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        severity,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _AdvisorInfoTile extends StatelessWidget {
  const _AdvisorInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvisorCompactRow extends StatelessWidget {
  const _AdvisorCompactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: colors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvisorDivider extends StatelessWidget {
  const _AdvisorDivider({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      color: colors.outlineVariant.withValues(alpha: 0.64),
    );
  }
}

class _MiniSignalPill extends StatelessWidget {
  const _MiniSignalPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: colors.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SuitabilityMeter extends StatelessWidget {
  const _SuitabilityMeter({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = score >= 78
        ? colors.primary
        : score >= 60
            ? colors.tertiary
            : colors.error;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: (score / 100).clamp(0, 1),
        minHeight: 8,
        color: color,
        backgroundColor: color.withValues(alpha: 0.16),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.evaluation});

  final _CropFitEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = evaluation.score >= 78
        ? colors.primary
        : evaluation.score >= 60
            ? colors.tertiary
            : colors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${evaluation.label} ${evaluation.score.toStringAsFixed(0)}%',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _CropIntelligenceSheet extends StatefulWidget {
  const _CropIntelligenceSheet({
    required this.farms,
    required this.intelligence,
    required this.scrollController,
  });

  final List<Farmland> farms;
  final FarmlandIntelligence intelligence;
  final ScrollController scrollController;

  @override
  State<_CropIntelligenceSheet> createState() => _CropIntelligenceSheetState();
}

class _CropIntelligenceSheetState extends State<_CropIntelligenceSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Farmland> get _results {
    final terms = _query.text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    if (terms.isEmpty) return widget.farms;
    return widget.farms.where((farm) {
      final text = [
        farm.name,
        farm.soilType ?? '',
        farm.irrigationType ?? '',
        farm.waterSource ?? '',
        farm.terrainType ?? '',
        farm.previousCrop ?? '',
        farm.nearestMarket ?? '',
        ...farm.crops.map((crop) => [
              crop.name,
              crop.variety ?? '',
              crop.growthStage ?? '',
              crop.coveragePercent.toStringAsFixed(0),
            ].join(' ')),
      ].join(' ').toLowerCase();
      return terms.every(text.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final results = _results;
    return GlassBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _query,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                labelText: 'Search crops, farms, soil, market',
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _query.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.farms.isEmpty
                  ? const Center(
                      child: _EmptyState(
                        title: 'No farmlands yet',
                        message:
                            'Add farmland details to unlock crop intelligence.',
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final farm = results[index];
                        final report = widget.intelligence.instantPreview(
                          farm,
                          null,
                        );
                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: colors.primaryContainer,
                                    foregroundColor: colors.primary,
                                    child: Text(farm.name.isEmpty
                                        ? 'F'
                                        : farm.name[0].toUpperCase()),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          farm.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        Text(
                                          '${farm.crops.length} crops - ${estimateAreaHectares(farm.boundaryPoints).toStringAsFixed(2)} ha',
                                          style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              for (final crop in farm.crops.take(3))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.grass_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${crop.name} - ${crop.coveragePercent.toStringAsFixed(0)}%',
                                        ),
                                      ),
                                      Text(crop.coverageSummary(
                                        estimateAreaHectares(
                                            farm.boundaryPoints),
                                      )),
                                    ],
                                  ),
                                ),
                              const Divider(height: 18),
                              Text(
                                report.smartActionWindow,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmSearchSheet extends StatefulWidget {
  const _FarmSearchSheet({
    required this.farms,
    required this.scrollController,
  });

  final List<Farmland> farms;
  final ScrollController scrollController;

  @override
  State<_FarmSearchSheet> createState() => _FarmSearchSheetState();
}

class _FarmSearchSheetState extends State<_FarmSearchSheet> {
  final _query = TextEditingController();
  List<Farmland> _results = const [];

  @override
  void initState() {
    super.initState();
    _results = _filteredFarms();
    _query.addListener(_refreshResults);
  }

  @override
  void didUpdateWidget(covariant _FarmSearchSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.farms != widget.farms) {
      _results = _filteredFarms();
    }
  }

  @override
  void dispose() {
    _query
      ..removeListener(_refreshResults)
      ..dispose();
    super.dispose();
  }

  void _refreshResults() {
    setState(() => _results = _filteredFarms());
  }

  List<Farmland> _filteredFarms() {
    final terms = _query.text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    if (terms.isEmpty) return widget.farms;
    return widget.farms.where((farm) {
      final searchable = _searchableFarmText(farm);
      return terms.every((term) => searchable.contains(term));
    }).toList();
  }

  String _searchableFarmText(Farmland farm) {
    final cropText = farm.crops.map((crop) => crop.name).join(' ').trim();
    final mappedText = farm.boundaryPoints.length >= 3
        ? 'mapped geofenced boundary'
        : 'unmapped needs boundary';
    return [
      farm.name,
      farm.soilType ?? '',
      cropText,
      farm.syncStatus,
      mappedText,
      '${farm.crops.length} crops',
      '${farm.boundaryPoints.length} points',
    ].join(' ').toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final query = _query.text.trim();
    final resultLabel = query.isEmpty
        ? '${widget.farms.length} saved farms'
        : '${_results.length} matching farms';

    return GlassBackground(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.manage_search_rounded, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find farmland',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '$resultLabel - offline search',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                labelText: 'Search by farm, crop, soil, mapped status',
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: _query.clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: widget.farms.isEmpty
                  ? const Center(
                      child: _EmptyState(
                        title: 'No farmlands yet',
                        message: 'Add a farm to make search useful.',
                      ),
                    )
                  : _results.isEmpty
                      ? _SearchEmptyState(query: query)
                      : ListView.builder(
                          controller: widget.scrollController,
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            return _FarmSearchResultTile(
                              farm: _results[index],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmSearchResultTile extends StatelessWidget {
  const _FarmSearchResultTile({required this.farm});

  final Farmland farm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = farm.name.trim().isEmpty ? 'Unnamed farm' : farm.name.trim();
    final initial = name.substring(0, 1).toUpperCase();
    final soil = (farm.soilType == null || farm.soilType!.trim().isEmpty)
        ? 'Unknown soil'
        : farm.soilType!.trim();
    final cropSummary = farm.crops.isEmpty
        ? 'No crops added'
        : farm.crops.map((crop) => crop.name).where((name) {
            return name.trim().isNotEmpty;
          }).join(', ');
    final mapped = farm.boundaryPoints.length >= 3;
    final area = estimateAreaHectares(farm.boundaryPoints);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(context).pop(farm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.primary,
                  child: Text(initial),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        cropSummary.isEmpty ? 'No crops added' : cropSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SearchMetaChip(icon: Icons.terrain_rounded, label: soil),
                _SearchMetaChip(
                  icon: Icons.grass_rounded,
                  label: '${farm.crops.length} crops',
                ),
                _SearchMetaChip(
                  icon: mapped
                      ? Icons.check_circle_rounded
                      : Icons.add_location_alt_rounded,
                  label: mapped
                      ? '${area.toStringAsFixed(2)} ha'
                      : '${farm.boundaryPoints.length} pts',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchMetaChip extends StatelessWidget {
  const _SearchMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 42, color: colors.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              'No match for "$query"',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a crop name, soil type, or mapped status.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoilHealthTips extends StatelessWidget {
  const _SoilHealthTips({
    required this.farms,
    required this.weather,
    required this.locationName,
    required this.userLat,
  });

  final List<Farmland> farms;
  final WeatherForecast? weather;
  final String? locationName;
  final double? userLat;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final place = _compactLocationLabel(locationName);
    final tips = _tipsForLocation();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.eco_rounded, color: colors.tertiary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place == null ? 'Soil health tips' : '$place soil tips',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      _soilSubtitle(place),
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tip.icon, color: colors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tip.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tip.tag,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: colors.secondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tip.detail,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _soilSubtitle(String? place) {
    final rain = _weeklyRainTotal(weather);
    final soil = _primarySoil(farms);
    if (place != null && soil != null) {
      return '${enumLabel(soil)} soil guidance using local weather';
    }
    if (place != null && rain != null) {
      return 'Based on ${rain.toStringAsFixed(0)} mm expected rain this week';
    }
    return 'Set profile location for local weather guidance';
  }

  List<_SoilTip> _tipsForLocation() {
    final tips = <_SoilTip>[];
    final place = _compactLocationLabel(locationName) ?? 'your area';
    final soil = (_primarySoil(farms) ?? '').toLowerCase();
    final rain = _weeklyRainTotal(weather);
    final avgHigh = _averageHigh(weather);
    final isCoastalKerala = _isCoastalKeralaLocation(locationName, userLat);

    if (rain != null && rain >= 35) {
      tips.add(_SoilTip(
        icon: Icons.water_rounded,
        title: 'Drainage first',
        detail: '$place is getting a wet signal. Clear field channels and '
            'delay irrigation or fertilizer before heavy rain.',
        tag: 'This week',
      ));
    } else if (avgHigh != null && avgHigh >= 34) {
      tips.add(_SoilTip(
        icon: Icons.thermostat_rounded,
        title: 'Heat moisture check',
        detail: 'With hot afternoons near $place, irrigate early morning and '
            'mulch exposed beds to reduce quick topsoil drying.',
        tag: 'Hot week',
      ));
    } else {
      tips.add(_SoilTip(
        icon: Icons.water_drop_rounded,
        title: 'Moisture check',
        detail: 'Use the squeeze test before sowing. If topsoil crumbles fast, '
            'give light irrigation before planting.',
        tag: 'Daily',
      ));
    }

    if (soil.contains('laterite') || soil.contains('red')) {
      tips.add(_SoilTip(
        icon: Icons.science_rounded,
        title: 'Red soil pH',
        detail: 'Red/laterite soils around $place can turn acidic and drain '
            'fast. Add compost and test pH before lime decisions.',
        tag: 'Local soil',
      ));
    } else if (soil.contains('black')) {
      tips.add(_SoilTip(
        icon: Icons.grain_rounded,
        title: 'Black soil timing',
        detail: 'Avoid working black soil when sticky after rain. Wait until '
            'it is friable to protect structure and roots.',
        tag: 'Soil fit',
      ));
    } else if (soil.contains('sandy')) {
      tips.add(_SoilTip(
        icon: Icons.compost_rounded,
        title: 'Water holding',
        detail: 'Sandy patches need compost and split irrigation. Smaller, '
            'more frequent watering is safer than one heavy dose.',
        tag: 'Local soil',
      ));
    } else {
      tips.add(_SoilTip(
        icon: Icons.science_rounded,
        title: 'Soil test baseline',
        detail:
            'Add soil pH and organic carbon for each farm. The app can then '
            'rank crops with better confidence.',
        tag: 'Profile',
      ));
    }

    if (isCoastalKerala) {
      tips.add(_SoilTip(
        icon: Icons.flood_rounded,
        title: 'Monsoon prep',
        detail: 'For Kannur/coastal Kerala fields, keep beds raised for '
            'vegetables and avoid waterlogging near banana, turmeric, and ginger.',
        tag: 'Coastal',
      ));
    } else if (rain != null && rain <= 8) {
      tips.add(_SoilTip(
        icon: Icons.spa_rounded,
        title: 'Dry-week cover',
        detail: 'Rain is low this week. Keep residue or green cover between '
            'rows to hold moisture and reduce soil temperature.',
        tag: 'Dry week',
      ));
    } else {
      tips.add(_SoilTip(
        icon: Icons.compost_rounded,
        title: 'Organic matter',
        detail: 'Mix mature compost before the next crop cycle to improve '
            'water retention, biology, and nutrient buffering.',
        tag: 'Seasonal',
      ));
    }

    final cropNames = farms
        .expand((farm) => farm.crops)
        .map((crop) => crop.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    tips.add(_SoilTip(
      icon: Icons.recycling_rounded,
      title: cropNames.isEmpty ? 'Crop rotation' : 'Rotate ${cropNames.first}',
      detail: cropNames.isEmpty
          ? 'Alternate legumes with cereals to fix nitrogen and break pest cycles.'
          : 'After ${cropNames.first}, add a legume or cover crop window to '
              'reduce pest carryover and rebuild nitrogen.',
      tag: 'Rotation',
    ));

    return tips.take(4).toList();
  }
}

class _SoilTip {
  const _SoilTip({
    required this.icon,
    required this.title,
    required this.detail,
    required this.tag,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String tag;
}

class _SeasonalCropCalendar extends StatelessWidget {
  const _SeasonalCropCalendar({
    required this.locationName,
    required this.userLat,
    required this.weather,
  });

  final String? locationName;
  final double? userLat;
  final WeatherForecast? weather;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final plan = _cropPlanFor(now);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(Icons.calendar_month_rounded, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      plan.subtitle,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(plan.tag),
                backgroundColor: colors.primaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: plan.crops
                .map((crop) => Chip(
                      avatar: const Icon(Icons.grass_rounded, size: 16),
                      label: Text(crop),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.insights_rounded,
                  color: colors.onSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan.note,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _SeasonalCropPlan _cropPlanFor(DateTime now) {
    final monthName = DateFormat.MMMM().format(now);
    final place = _compactLocationLabel(locationName);
    final season = _seasonForMonth(now.month);
    final rain = _weeklyRainTotal(weather);
    final avgHigh = _averageHigh(weather);

    if (_isCoastalKeralaLocation(locationName, userLat)) {
      final location = place ?? 'Coastal Kerala';
      final crops = now.month >= 5 && now.month <= 8
          ? const [
              'Banana',
              'Coconut',
              'Turmeric',
              'Ginger',
              'Cowpea',
              'Yardlong bean',
            ]
          : const [
              'Coconut',
              'Black pepper',
              'Banana',
              'Tapioca',
              'Vegetables',
              'Paddy',
            ];
      final rainNote = rain != null && rain >= 35
          ? 'Rain is active, so prefer raised beds, clean drains, and avoid low patches for vegetables.'
          : 'Pre-monsoon humidity favors banana, coconut, spices, and short-duration vegetables with drainage ready.';
      return _SeasonalCropPlan(
        title: '$location crop window',
        subtitle: 'Recommended for $monthName from local climate',
        tag: 'Local',
        crops: crops,
        note: rainNote,
      );
    }

    if (_isDryInteriorLocation(locationName, userLat)) {
      final hotNote = avgHigh != null && avgHigh >= 34
          ? 'This is a hot week, so choose drought-tolerant crops or plant only with assured irrigation.'
          : 'Choose crops that tolerate dry spells and match your saved irrigation source.';
      return _SeasonalCropPlan(
        title: '${place ?? 'Dry belt'} crop window',
        subtitle: 'Recommended for $monthName and low-rainfall regions',
        tag: 'Dry fit',
        crops: const [
          'Groundnut',
          'Bajra',
          'Sesame',
          'Cotton',
          'Red gram',
          'Castor',
        ],
        note: hotNote,
      );
    }

    final rainNote = rain == null
        ? 'Add profile location to tune this list with rainfall and temperature.'
        : rain >= 45
            ? 'Wet-week signal: pick drainage-safe fields and delay sowing in waterlogged plots.'
            : avgHigh != null && avgHigh >= 34
                ? 'Hot-week signal: confirm irrigation before committing a large area.'
                : 'Weather looks manageable. Compare each crop with your farm soil and market plan.';

    return _SeasonalCropPlan(
      title: place == null ? '$season season crops' : '$place $season crops',
      subtitle: 'Recommended for $monthName',
      tag: season,
      crops: _seasonCrops(season),
      note: rainNote,
    );
  }

  String _seasonForMonth(int month) {
    if (month >= 6 && month <= 9) return 'Kharif';
    if (month >= 10 || month <= 2) return 'Rabi';
    return 'Zaid';
  }

  List<String> _seasonCrops(String season) {
    switch (season) {
      case 'Kharif':
        return [
          'Rice',
          'Maize',
          'Cotton',
          'Soybean',
          'Groundnut',
          'Jowar',
          'Bajra',
          'Sugarcane',
        ];
      case 'Rabi':
        return [
          'Wheat',
          'Mustard',
          'Gram',
          'Barley',
          'Peas',
          'Linseed',
          'Sunflower',
        ];
      default: // Zaid
        return [
          'Watermelon',
          'Muskmelon',
          'Cucumber',
          'Bitter gourd',
          'Pumpkin',
          'Moong dal',
        ];
    }
  }
}

class _SeasonalCropPlan {
  const _SeasonalCropPlan({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.crops,
    required this.note,
  });

  final String title;
  final String subtitle;
  final String tag;
  final List<String> crops;
  final String note;
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({
    required this.mappedFarms,
    required this.totalFarms,
    required this.cropCount,
  });

  final int mappedFarms;
  final int totalFarms;
  final int cropCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mappedRatio = totalFarms == 0 ? 0.0 : mappedFarms / totalFarms;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.bubble_chart_rounded, color: colors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm intelligence',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      totalFarms == 0
                          ? 'Create a geofenced farm to unlock AI insights.'
                          : '$mappedFarms of $totalFarms farms are mapped for AI analysis.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: mappedRatio.clamp(0, 1),
              minHeight: 7,
              color: colors.secondary,
              backgroundColor:
                  colors.secondaryContainer.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniPill(label: 'Mapped', value: '$mappedFarms'),
              const SizedBox(width: 8),
              _MiniPill(label: 'Crops', value: '$cropCount'),
              const SizedBox(width: 8),
              const _MiniPill(label: 'Sync', value: 'Local first'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class FarmlandEditorScreen extends StatefulWidget {
  const FarmlandEditorScreen({
    super.key,
    required this.repository,
    required this.userId,
    this.farmland,
  });

  final FarmlandRepository repository;
  final int userId;
  final Farmland? farmland;

  @override
  State<FarmlandEditorScreen> createState() => _FarmlandEditorScreenStateV2();
}

class _FarmlandEditorScreenState extends State<FarmlandEditorScreen> {
  MapLibreMapController? _mapController;
  final _name = TextEditingController();
  final _soil = TextEditingController();
  final _cropName = TextEditingController();
  final _cropCoverage = TextEditingController();

  // Advanced fields
  String? _irrigationType;
  String? _waterSource;
  String? _terrainType;
  double? _elevation;
  String? _farmingPractice;
  String? _previousCrop;
  final _soilPH = TextEditingController();
  String? _landOwnership;
  final _nearestMarket = TextEditingController();
  final _farmAge = TextEditingController();

  LatLng _center = const LatLng(20.5937, 78.9629);
  List<BoundaryPoint> _boundary = [];
  List<CropItem> _crops = [];
  String _message = 'Use GPS scan or tap map corners to mark the field.';
  double? _accuracy;
  bool _saving = false;
  bool _locating = false;
  bool _isFullscreen = false;

  // GPS Stream
  StreamSubscription<Position>? _gpsStream;
  List<Position> _recentPositions = [];
  int _coldStartCount = 0;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    final farm = widget.farmland;
    if (farm != null) {
      _name.text = farm.name;
      _soil.text = farm.soilType ?? '';
      _center = LatLng(farm.locationLat, farm.locationLng);
      _boundary = List.of(farm.boundaryPoints);
      _crops = List.of(farm.crops);

      _irrigationType = farm.irrigationType;
      _waterSource = farm.waterSource;
      _terrainType = farm.terrainType;
      _elevation = farm.elevation;
      _farmingPractice = farm.farmingPractice;
      _previousCrop = farm.previousCrop;
      if (farm.soilPH != null) _soilPH.text = farm.soilPH.toString();
      _landOwnership = farm.landOwnership;
      if (farm.nearestMarket != null) _nearestMarket.text = farm.nearestMarket!;
      if (farm.farmAge != null) _farmAge.text = farm.farmAge.toString();
    }
  }

  @override
  void dispose() {
    _gpsStream?.cancel();
    _name.dispose();
    _soil.dispose();
    _cropName.dispose();
    _cropCoverage.dispose();
    _soilPH.dispose();
    _nearestMarket.dispose();
    _farmAge.dispose();
    super.dispose();
  }

  double get _area => estimateAreaHectares(_boundary);
  double get _heat =>
      (_boundary.length * 4 + _crops.length * 2).clamp(18, 100).toDouble();

  Future<void> _startWalkBoundary() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _message = 'Location permission is off.');
      return;
    }

    setState(() {
      _isRecording = true;
      _boundary.clear();
      _recentPositions.clear();
      _coldStartCount = 0;
      _isFullscreen = true;
      _message = 'Recording boundary. Start walking...';
    });

    _gpsStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen((position) {
      _coldStartCount++;
      if (_coldStartCount <= 3) return; // skip cold start jitter

      _recentPositions.add(position);
      if (_recentPositions.length > 5) _recentPositions.removeAt(0);

      final avgLat =
          _recentPositions.map((p) => p.latitude).reduce((a, b) => a + b) /
              _recentPositions.length;
      final avgLng =
          _recentPositions.map((p) => p.longitude).reduce((a, b) => a + b) /
              _recentPositions.length;

      if (mounted) {
        setState(() {
          _center = LatLng(avgLat, avgLng);
          _accuracy = position.accuracy;
          _elevation = position.altitude;

          if (_isRecording && position.accuracy < 15) {
            _boundary.add(BoundaryPoint(lat: avgLat, lng: avgLng));
            _updateMapPolygon();
            _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
          }
        });
      }
    });
  }

  void _stopWalkBoundary() {
    _gpsStream?.cancel();
    _gpsStream = null;
    setState(() {
      _isRecording = false;
      _message = 'Finished recording. ${_boundary.length} corners added.';
      _isFullscreen = false;
    });
  }

  Future<Position?> _currentPosition() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _message =
            'Location permission is off. You can still tap the map.');
        return null;
      }
      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _useLocation() async {
    final position = await _currentPosition();
    if (position == null) return;
    final point = LatLng(position.latitude, position.longitude);
    setState(() {
      _center = point;
      _accuracy = position.accuracy;
      _elevation = position.altitude;
      _message =
          'Centered on your location. Accuracy about ${position.accuracy.toInt()} m.';
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 17.5));
  }

  Future<void> _scanPlot() async {
    final position = await _currentPosition();
    if (position == null) return;
    final point = LatLng(position.latitude, position.longitude);
    setState(() {
      _center = point;
      _accuracy = position.accuracy;
      _elevation = position.altitude;
      _boundary = _starterBoundary(point, position.accuracy);
      _message = 'Starter geofence scanned. Tap map corners to refine it.';
      _updateMapPolygon();
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 18.0));
  }

  void _onMapClick(math.Point<double> point, LatLng coordinates) {
    if (_isRecording) return;
    setState(() {
      _boundary = [
        ..._boundary,
        BoundaryPoint(lat: coordinates.latitude, lng: coordinates.longitude)
      ];
      _center = _centroid(_boundary) ?? coordinates;
      _message = _boundary.length < 3
          ? 'Corner ${_boundary.length} saved. Add ${3 - _boundary.length} more.'
          : 'Geofence ready with ${_boundary.length} corners.';
      _updateMapPolygon();
    });
  }

  void _updateMapPolygon() {
    if (_mapController == null) return;
    _mapController!.clearSymbols();
    _mapController!.clearFills();
    _mapController!.clearLines();

    if (_boundary.isEmpty) return;

    for (var p in _boundary) {
      _mapController!.addSymbol(SymbolOptions(
        geometry: LatLng(p.lat, p.lng),
        iconImage: "marker",
        iconSize: 0.5,
      ));
    }

    if (_boundary.length >= 3) {
      final points = _boundary.map((e) => LatLng(e.lat, e.lng)).toList();
      _mapController!.addFill(FillOptions(
        geometry: [points],
        fillColor: "#108A62",
        fillOpacity: 0.3,
        fillOutlineColor: "#108A62",
      ));
    }
  }

  Future<void> _save() async {
    if (_boundary.isEmpty && widget.farmland == null) {
      setState(() =>
          _message = 'Set the farm location first using GPS or map taps.');
      return;
    }
    setState(() => _saving = true);
    await widget.repository.save(
      userId: widget.userId,
      id: widget.farmland?.id,
      name: _name.text,
      soilType: _soil.text,
      crops: _crops,
      lat: _center.latitude,
      lng: _center.longitude,
      boundary: _boundary,
      heatIndex: _heat,
      irrigationType: _irrigationType,
      waterSource: _waterSource,
      terrainType: _terrainType,
      elevation: _elevation,
      farmingPractice: _farmingPractice,
      previousCrop: _previousCrop,
      soilPH: double.tryParse(_soilPH.text),
      landOwnership: _landOwnership,
      nearestMarket: _nearestMarket.text.trim().isEmpty
          ? null
          : _nearestMarket.text.trim(),
      farmAge: int.tryParse(_farmAge.text),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _deleteFarm() async {
    final farm = widget.farmland;
    if (farm == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete farmland?'),
        content:
            Text('Delete "${farm.name}" and its saved crop/boundary details?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    await widget.repository.delete(widget.userId, farm.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Widget _buildMap() {
    return MapLibreMap(
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: widget.farmland == null ? 4 : 16,
      ),
      styleString: '''{
        "version": 8,
        "sources": {
          "osm": {
            "type": "raster",
            "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
            "tileSize": 256
          }
        },
        "layers": [{
          "id": "osm",
          "type": "raster",
          "source": "osm",
          "minzoom": 0,
          "maxzoom": 19
        }]
      }''',
      onMapCreated: (controller) {
        _mapController = controller;
        _updateMapPolygon();
      },
      onMapClick: _onMapClick,
      myLocationEnabled: true,
      myLocationRenderMode: MyLocationRenderMode.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isFullscreen) {
      return Scaffold(
        body: Stack(
          children: [
            _buildMap(),
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: GlassCard(
                child: Column(
                  children: [
                    Text('Walking Boundary...',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                        'Corners: ${_boundary.length} | Accuracy: ${_accuracy?.toStringAsFixed(1) ?? "--"}m'),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: FilledButton.icon(
                onPressed: _stopWalkBoundary,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Finish Walking'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56)),
              ),
            ),
          ],
        ),
      );
    }

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title:
              Text(widget.farmland == null ? 'Add Farmland' : 'Edit Farmland'),
          backgroundColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            GlassCard(
              child: Column(
                children: [
                  TextField(
                      controller: _name,
                      decoration:
                          const InputDecoration(labelText: 'Farm name')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _soil,
                      decoration:
                          const InputDecoration(labelText: 'Soil type')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _boundary.length >= 3
                              ? 'Plot boundary ready'
                              : 'Plot setup',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fullscreen_rounded),
                        tooltip: 'Fullscreen Map',
                        onPressed: () => setState(() => _isFullscreen = true),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_message,
                      style: TextStyle(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Corners ${_boundary.length}')),
                      Chip(
                          label: Text(_area == 0
                              ? 'Area scan needed'
                              : 'Area ${_area.toStringAsFixed(2)} ha')),
                      Chip(
                          label: Text(_accuracy == null
                              ? 'GPS manual'
                              : 'GPS ~${_accuracy!.toInt()} m')),
                    ],
                  ),
                  if (_locating)
                    const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: LinearProgressIndicator()),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isRecording ? null : _startWalkBoundary,
                          icon: const Icon(Icons.directions_walk_rounded),
                          label: const Text('Walk Boundary'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _locating ? null : _useLocation,
                          icon: const Icon(Icons.my_location_rounded),
                          label: const Text('Use Location'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildMap(),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _boundary.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  _boundary.removeLast();
                                  _updateMapPolygon();
                                });
                              },
                        child: const Text('Undo point'),
                      ),
                      TextButton(
                        onPressed: _boundary.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  _boundary.clear();
                                  _updateMapPolygon();
                                });
                              },
                        child: const Text('Clear boundary'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('▶ Advanced farm details (optional)'),
                  subtitle: const Text('Improves AI agronomy insights'),
                  children: [
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _irrigationType,
                      decoration:
                          const InputDecoration(labelText: 'Irrigation Type'),
                      items: irrigationTypes
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(enumLabel(e))))
                          .toList(),
                      onChanged: (v) => setState(() => _irrigationType = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _waterSource,
                      decoration:
                          const InputDecoration(labelText: 'Water Source'),
                      items: waterSources
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(enumLabel(e))))
                          .toList(),
                      onChanged: (v) => setState(() => _waterSource = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _terrainType,
                      decoration:
                          const InputDecoration(labelText: 'Terrain Type'),
                      items: terrainTypes
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(enumLabel(e))))
                          .toList(),
                      onChanged: (v) => setState(() => _terrainType = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _farmingPractice,
                      decoration:
                          const InputDecoration(labelText: 'Farming Practice'),
                      items: farmingPractices
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(enumLabel(e))))
                          .toList(),
                      onChanged: (v) => setState(() => _farmingPractice = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _landOwnership,
                      decoration:
                          const InputDecoration(labelText: 'Land Ownership'),
                      items: landOwnershipTypes
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(enumLabel(e))))
                          .toList(),
                      onChanged: (v) => setState(() => _landOwnership = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _soilPH,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Soil pH (1.0 - 14.0)')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _farmAge,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Years Farmed')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _nearestMarket,
                        decoration: const InputDecoration(
                            labelText: 'Nearest Market/Town')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Crops on this land',
                      style: Theme.of(context).textTheme.titleMedium),
                  if (_crops.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _buildDonutChart(colors),
                    ),
                  ..._crops.map(
                    (crop) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(crop.name),
                      subtitle: Text(crop.coverageSummary(_area)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => setState(() => _crops.remove(crop)),
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: _cropName,
                              decoration:
                                  const InputDecoration(labelText: 'Crop'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: TextField(
                              controller: _cropCoverage,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Coverage %'))),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        if (_cropName.text.trim().isEmpty) return;
                        final percent =
                            double.tryParse(_cropCoverage.text) ?? 0;
                        setState(() {
                          _crops.add(CropItem(
                              name: _cropName.text.trim(),
                              coveragePercent: percent));
                          _cropName.clear();
                          _cropCoverage.clear();
                        });
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add crop'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.farmland == null
                      ? 'Save Farmland'
                      : 'Update Farmland'),
            ),
            if (widget.farmland != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _saving ? null : _deleteFarm,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete farmland'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart(ColorScheme colors) {
    if (_crops.isEmpty) return const SizedBox();
    final remaining =
        100.0 - _crops.fold<double>(0, (sum, c) => sum + c.coveragePercent);
    return Row(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                color: colors.surfaceContainerHighest,
                strokeWidth: 12,
              ),
              ..._crops.asMap().entries.map((entry) {
                final idx = entry.key;
                final crop = entry.value;
                final previous = _crops
                    .take(idx)
                    .fold<double>(0, (sum, c) => sum + c.coveragePercent);
                return Transform.rotate(
                  angle: previous / 100 * 2 * pi,
                  child: CircularProgressIndicator(
                    value: crop.coveragePercent / 100,
                    color: Colors.primaries[idx % Colors.primaries.length],
                    strokeWidth: 12,
                  ),
                );
              }),
              const Text('🍩', style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._crops.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: Colors.primaries[
                                    entry.key % Colors.primaries.length],
                                shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                '${entry.value.coveragePercent.toStringAsFixed(0)}% ${entry.value.name}')),
                      ],
                    ),
                  )),
              if (remaining > 0)
                Row(
                  children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                        child:
                            Text('${remaining.toStringAsFixed(0)}% Remaining')),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FarmlandEditorScreenStateV2 extends State<FarmlandEditorScreen> {
  static const _standardStyleUrl = 'https://demotiles.maplibre.org/style.json';
  static const _satelliteStyleJson = '''
{
  "version": 8,
  "sources": {
    "world-imagery": {
      "type": "raster",
      "tiles": [
        "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
      ],
      "tileSize": 256,
      "attribution": "Tiles by Esri"
    }
  },
  "layers": [
    {
      "id": "world-imagery",
      "type": "raster",
      "source": "world-imagery",
      "minzoom": 0,
      "maxzoom": 19
    }
  ]
}
''';

  MapLibreMapController? _mapController;
  MapLibreMapController? _dragController;
  final Map<String, _BoundaryHandle> _boundaryHandles = {};

  final _name = TextEditingController();
  final _soil = TextEditingController();
  final _cropName = TextEditingController();
  final _cropVariety = TextEditingController();
  final _soilPH = TextEditingController();
  final _previousCrop = TextEditingController();
  final _nearestMarket = TextEditingController();
  final _farmAge = TextEditingController();

  String? _irrigationType;
  String? _waterSource;
  String? _terrainType;
  double? _elevation;
  String? _farmingPractice;
  String? _landOwnership;

  String? _cropGrowthStage;
  DateTime? _cropSowingDate;
  double _cropCoverageValue = 25;

  LatLng _center = const LatLng(20.5937, 78.9629);
  List<BoundaryPoint> _boundary = [];
  List<CropItem> _crops = [];
  String _message = 'Use walk mode, GPS scan, or map taps to mark the field.';
  double? _accuracy;
  bool _saving = false;
  bool _locating = false;
  bool _isFullscreen = false;
  bool _satelliteStyle = false;
  bool _offlineDownloading = false;
  double? _offlineProgress;

  StreamSubscription<Position>? _gpsStream;
  final List<Position> _recentPositions = [];
  int _coldStartCount = 0;
  bool _isRecording = false;
  bool _recordingPaused = false;

  @override
  void initState() {
    super.initState();
    final farm = widget.farmland;
    if (farm != null) {
      _name.text = farm.name;
      _soil.text = farm.soilType ?? '';
      _center = LatLng(farm.locationLat, farm.locationLng);
      _boundary = List.of(farm.boundaryPoints);
      _crops = List.of(farm.crops);
      _irrigationType = farm.irrigationType;
      _waterSource = farm.waterSource;
      _terrainType = farm.terrainType;
      _elevation = farm.elevation;
      _farmingPractice = farm.farmingPractice;
      _previousCrop.text = farm.previousCrop ?? '';
      if (farm.soilPH != null) _soilPH.text = farm.soilPH.toString();
      _landOwnership = farm.landOwnership;
      _nearestMarket.text = farm.nearestMarket ?? '';
      if (farm.farmAge != null) _farmAge.text = farm.farmAge.toString();
    }
  }

  @override
  void dispose() {
    _gpsStream?.cancel();
    _name.dispose();
    _soil.dispose();
    _cropName.dispose();
    _cropVariety.dispose();
    _soilPH.dispose();
    _previousCrop.dispose();
    _nearestMarket.dispose();
    _farmAge.dispose();
    super.dispose();
  }

  double get _area => estimateAreaHectares(_boundary);

  double get _heat =>
      (_boundary.length * 4 + _crops.length * 2).clamp(18, 100).toDouble();

  double get _coverageTotal =>
      _crops.fold<double>(0, (sum, crop) => sum + crop.coveragePercent);

  double get _coverageRemaining =>
      (100 - _coverageTotal).clamp(0, 100).toDouble();

  String get _activeStyleUrl {
    if (!_satelliteStyle) return _standardStyleUrl;
    final key = AppConfig.mapTilerKey;
    if (key.isNotEmpty) {
      return 'https://api.maptiler.com/maps/hybrid/style.json?key=$key';
    }
    return _satelliteStyleJson;
  }

  String get _activeStyleLabel {
    if (!_satelliteStyle) return 'Vector map';
    return AppConfig.mapTilerKey.isEmpty
        ? 'Satellite imagery'
        : 'MapTiler satellite';
  }

  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() =>
          _message = 'Location permission is off. You can still tap the map.');
      return false;
    }
    return true;
  }

  Future<void> _startWalkBoundary() async {
    if (!await _ensureLocationPermission()) return;
    await _gpsStream?.cancel();
    setState(() {
      _isRecording = true;
      _recordingPaused = false;
      _boundary = [];
      _recentPositions.clear();
      _coldStartCount = 0;
      _isFullscreen = true;
      _message = 'Recording boundary. Walk the field edge slowly.';
    });
    unawaited(_redrawMapAnnotations());

    _gpsStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _coldStartCount++;
      _recentPositions.add(position);
      if (_recentPositions.length > 5) _recentPositions.removeAt(0);

      final avgLat = _recentPositions
              .map((item) => item.latitude)
              .reduce((a, b) => a + b) /
          _recentPositions.length;
      final avgLng = _recentPositions
              .map((item) => item.longitude)
              .reduce((a, b) => a + b) /
          _recentPositions.length;
      final point = LatLng(avgLat, avgLng);

      if (!mounted) return;
      setState(() {
        _center = point;
        _accuracy = position.accuracy;
        _elevation = position.altitude;
      });

      if (_coldStartCount <= 3 || _recordingPaused) {
        setState(() => _message = 'Warming up GPS for a stable lock...');
        return;
      }
      if (position.accuracy > 15) {
        setState(() => _message =
            'GPS accuracy is ${position.accuracy.toStringAsFixed(0)} m. Move into open sky if possible.');
        return;
      }

      final pointAsBoundary = BoundaryPoint(lat: avgLat, lng: avgLng);
      final farEnough = _boundary.isEmpty ||
          _distanceMeters(_boundary.last, pointAsBoundary) >= 5;
      if (!farEnough) return;

      setState(() {
        _boundary = [..._boundary, pointAsBoundary];
        _message =
            'Walking... ${_boundary.length} points captured, GPS ${position.accuracy.toStringAsFixed(0)} m.';
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(point));
      unawaited(_redrawMapAnnotations());
    });
  }

  Future<void> _finishWalkBoundary() async {
    await _gpsStream?.cancel();
    _gpsStream = null;
    setState(() {
      _isRecording = false;
      _recordingPaused = false;
      if (_boundary.length >= 3) {
        _boundary = _simplifyBoundary(_boundary, toleranceMeters: 4);
        if (_boundary.length > 3 &&
            _distanceMeters(_boundary.first, _boundary.last) < 12) {
          _boundary = _boundary.sublist(0, _boundary.length - 1);
        }
        _center = _centroid(_boundary) ?? _center;
        _message =
            'Boundary finished with ${_boundary.length} editable corners.';
      } else {
        _message = 'Walk mode stopped. Add at least 3 boundary corners.';
      }
      _isFullscreen = false;
    });
    unawaited(_redrawMapAnnotations());
  }

  Future<Position?> _currentPosition() async {
    setState(() => _locating = true);
    try {
      if (!await _ensureLocationPermission()) return null;
      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _useLocation() async {
    final position = await _currentPosition();
    if (position == null) return;
    final point = LatLng(position.latitude, position.longitude);
    setState(() {
      _center = point;
      _accuracy = position.accuracy;
      _elevation = position.altitude;
      _message =
          'Centered on your location. Accuracy about ${position.accuracy.toInt()} m.';
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 17.5));
    unawaited(_redrawMapAnnotations());
  }

  Future<void> _scanPlot() async {
    final position = await _currentPosition();
    if (position == null) return;
    final point = LatLng(position.latitude, position.longitude);
    setState(() {
      _center = point;
      _accuracy = position.accuracy;
      _elevation = position.altitude;
      _boundary = _starterBoundary(point, position.accuracy);
      _message =
          'Starter geofence scanned from GPS accuracy. Drag handles to refine it.';
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 18.0));
    unawaited(_redrawMapAnnotations());
  }

  Future<void> _downloadOfflineRegion() async {
    setState(() {
      _offlineDownloading = true;
      _offlineProgress = 0;
      _message = 'Saving map tiles for offline use...';
    });
    try {
      await downloadOfflineRegion(
        OfflineRegionDefinition(
          bounds: _offlineBounds(),
          mapStyleUrl: _activeStyleUrl,
          minZoom: 12,
          maxZoom: 17,
        ),
        metadata: {
          'farm': _name.text.trim().isEmpty ? 'Farmland' : _name.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        },
        onEvent: (event) {
          if (!mounted) return;
          if (event is InProgress) {
            setState(() => _offlineProgress = event.progress);
          } else if (event is Success) {
            setState(() => _message = 'Offline map region saved.');
          } else if (event is Error) {
            setState(() => _message = 'Offline map save failed.');
          }
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline map region saved')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Offline map save failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _offlineDownloading = false;
          _offlineProgress = null;
        });
      }
    }
  }

  LatLngBounds _offlineBounds() {
    if (_boundary.length >= 3) {
      return _boundsForBoundary(_boundary, padding: 0.01);
    }
    return LatLngBounds(
      southwest: _offset(_center, -900, -900),
      northeast: _offset(_center, 900, 900),
    );
  }

  void _onMapClick(math.Point<double> point, LatLng coordinates) {
    if (_isRecording) return;
    final newPoint =
        BoundaryPoint(lat: coordinates.latitude, lng: coordinates.longitude);
    if (_boundary.length >= 3 &&
        _distanceMeters(_boundary.first, newPoint) < 12) {
      setState(() {
        _message =
            'Boundary closed with ${_boundary.length} corners. Drag handles to adjust.';
      });
      return;
    }
    setState(() {
      _boundary = [..._boundary, newPoint];
      _center = _centroid(_boundary) ?? coordinates;
      _message = _boundary.length < 3
          ? 'Corner ${_boundary.length} saved. Add ${3 - _boundary.length} more.'
          : 'Boundary ready. Drag green handles or grey midpoints to edit.';
    });
    unawaited(_redrawMapAnnotations());
  }

  void _attachDragHandler(MapLibreMapController controller) {
    if (_dragController == controller) return;
    _dragController = controller;
    controller.onFeatureDrag.add(_handleFeatureDrag);
  }

  void _handleFeatureDrag(
    math.Point<double> point,
    LatLng origin,
    LatLng current,
    LatLng delta,
    String id,
    Annotation? annotation,
    DragEventType eventType,
  ) {
    final handle = _boundaryHandles[id];
    if (handle == null) return;
    final moved = BoundaryPoint(lat: current.latitude, lng: current.longitude);
    if (handle.kind == _BoundaryHandleKind.vertex) {
      if (handle.index < 0 || handle.index >= _boundary.length) return;
      setState(() {
        final next = List<BoundaryPoint>.of(_boundary);
        next[handle.index] = moved;
        _boundary = next;
        _center = _centroid(_boundary) ?? _center;
        _message = 'Corner ${handle.index + 1} adjusted.';
      });
      if (eventType == DragEventType.end) {
        unawaited(_redrawMapAnnotations());
      }
      return;
    }

    if (eventType == DragEventType.end) {
      final insertAt = (handle.index + 1).clamp(0, _boundary.length).toInt();
      setState(() {
        final next = List<BoundaryPoint>.of(_boundary);
        next.insert(insertAt, moved);
        _boundary = next;
        _center = _centroid(_boundary) ?? _center;
        _message = 'New boundary corner added.';
      });
      unawaited(_redrawMapAnnotations());
    }
  }

  Future<void> _redrawMapAnnotations() async {
    final controller = _mapController;
    if (controller == null) return;
    _boundaryHandles.clear();
    try {
      await controller.clearFills();
      await controller.clearLines();
      await controller.clearCircles();

      if (_accuracy != null) {
        final ring = _circleBoundary(
          _center,
          _accuracy!.clamp(8, 80).toDouble(),
        );
        await controller.addFill(
          FillOptions(
            geometry: [ring],
            fillColor: '#8BC6EC',
            fillOpacity: 0.14,
          ),
        );
        await controller.addLine(
          LineOptions(
            geometry: [...ring, ring.first],
            lineColor: '#8BC6EC',
            lineWidth: 2,
            lineOpacity: 0.7,
          ),
        );
      }

      if (_boundary.length >= 3) {
        final polygon =
            _boundary.map((point) => LatLng(point.lat, point.lng)).toList();
        await controller.addFill(
          FillOptions(
            geometry: [polygon],
            fillColor: '#108A62',
            fillOpacity: 0.28,
          ),
        );
        await controller.addLine(
          LineOptions(
            geometry: [...polygon, polygon.first],
            lineColor: '#A7E8B4',
            lineWidth: 3,
          ),
        );
      } else if (_boundary.length >= 2) {
        await controller.addLine(
          LineOptions(
            geometry:
                _boundary.map((point) => LatLng(point.lat, point.lng)).toList(),
            lineColor: '#A7E8B4',
            lineWidth: 3,
          ),
        );
      }

      final circleOptions = <CircleOptions>[];
      final circleData = <Map<String, dynamic>>[];
      for (var i = 0; i < _boundary.length; i++) {
        final point = _boundary[i];
        circleOptions.add(
          CircleOptions(
            geometry: LatLng(point.lat, point.lng),
            circleRadius: 9,
            circleColor: '#22C58B',
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2,
            draggable: !_isRecording,
          ),
        );
        circleData.add({'kind': 'vertex', 'index': i});
      }

      if (!_isRecording && _boundary.length >= 2) {
        final edgeCount =
            _boundary.length >= 3 ? _boundary.length : _boundary.length - 1;
        for (var i = 0; i < edgeCount; i++) {
          final a = _boundary[i];
          final b = _boundary[(i + 1) % _boundary.length];
          final mid = _midpoint(a, b);
          circleOptions.add(
            CircleOptions(
              geometry: LatLng(mid.lat, mid.lng),
              circleRadius: 6,
              circleColor: '#C8D3CE',
              circleStrokeColor: '#0E2417',
              circleStrokeWidth: 1,
              draggable: true,
            ),
          );
          circleData.add({'kind': 'midpoint', 'index': i});
        }
      }

      if (circleOptions.isNotEmpty) {
        final circles = await controller.addCircles(circleOptions, circleData);
        for (var i = 0; i < circles.length; i++) {
          final data = circleData[i];
          _boundaryHandles[circles[i].id] = _BoundaryHandle(
            data['kind'] == 'vertex'
                ? _BoundaryHandleKind.vertex
                : _BoundaryHandleKind.midpoint,
            data['index'] as int,
          );
        }
      }
    } catch (_) {
      // The style may still be loading. onStyleLoadedCallback redraws again.
    }
  }

  Future<void> _save() async {
    if (_boundary.isEmpty && widget.farmland == null) {
      setState(() =>
          _message = 'Set the farm location first using GPS or map taps.');
      return;
    }
    if (_coverageTotal > 100.01) {
      _showEditorSnack('Crop coverage cannot exceed 100%.');
      return;
    }
    final soilPH = double.tryParse(_soilPH.text.trim());
    if (soilPH != null && (soilPH < 1 || soilPH > 14)) {
      _showEditorSnack('Soil pH must be between 1 and 14.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.save(
        userId: widget.userId,
        id: widget.farmland?.id,
        name: _name.text,
        soilType: _soil.text,
        crops: _crops,
        lat: _center.latitude,
        lng: _center.longitude,
        boundary: _boundary,
        heatIndex: _heat,
        irrigationType: _irrigationType,
        waterSource: _waterSource,
        terrainType: _terrainType,
        elevation: _elevation,
        farmingPractice: _farmingPractice,
        previousCrop: _previousCrop.text.trim().isEmpty
            ? null
            : _previousCrop.text.trim(),
        soilPH: soilPH,
        landOwnership: _landOwnership,
        nearestMarket: _nearestMarket.text.trim().isEmpty
            ? null
            : _nearestMarket.text.trim(),
        farmAge: int.tryParse(_farmAge.text.trim()),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteFarm() async {
    final farm = widget.farmland;
    if (farm == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete farmland?'),
        content: Text(
          'Delete "${farm.name}" and its saved crop and boundary details?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    await widget.repository.delete(widget.userId, farm.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showEditorSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildMap() {
    return MapLibreMap(
      key: ValueKey(_activeStyleUrl),
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: widget.farmland == null && _boundary.isEmpty ? 4 : 16,
      ),
      styleString: _activeStyleUrl,
      onMapCreated: (controller) {
        _mapController = controller;
        _attachDragHandler(controller);
      },
      onStyleLoadedCallback: () => unawaited(_redrawMapAnnotations()),
      onMapClick: _onMapClick,
      myLocationEnabled: true,
      myLocationRenderMode: MyLocationRenderMode.normal,
      dragEnabled: true,
      annotationConsumeTapEvents: const [AnnotationType.circle],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_isFullscreen) return _buildFullscreenEditor(colors);

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title:
              Text(widget.farmland == null ? 'Add Farmland' : 'Edit Farmland'),
          backgroundColor: Colors.transparent,
          actions: [
            if (widget.farmland != null)
              IconButton(
                tooltip: 'Delete farmland',
                onPressed: _saving ? null : _deleteFarm,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _buildBasicDetailsCard(),
            const SizedBox(height: 12),
            _buildBoundaryCard(colors),
            const SizedBox(height: 12),
            _buildCropsCard(colors),
            const SizedBox(height: 12),
            _buildAdvancedDetailsCard(),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.farmland == null
                      ? 'Save Farmland'
                      : 'Update Farmland'),
            ),
            if (widget.farmland != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _saving ? null : _deleteFarm,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete farmland'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicDetailsCard() {
    return GlassCard(
      child: Column(
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Farm name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _soil,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Soil type'),
          ),
        ],
      ),
    );
  }

  Widget _buildBoundaryCard(ColorScheme colors) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _boundary.length >= 3 ? 'Plot boundary ready' : 'Plot setup',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: Icon(_satelliteStyle
                    ? Icons.satellite_alt_rounded
                    : Icons.map_rounded),
                tooltip: _activeStyleLabel,
                onPressed: () {
                  setState(() => _satelliteStyle = !_satelliteStyle);
                  _showEditorSnack(
                    _satelliteStyle ? _activeStyleLabel : 'Vector map enabled.',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen_rounded),
                tooltip: 'Fullscreen map',
                onPressed: () => setState(() => _isFullscreen = true),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_message, style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Corners ${_boundary.length}')),
              Chip(
                label: Text(
                  _area == 0
                      ? 'Area scan needed'
                      : 'Area ${_area.toStringAsFixed(2)} ha',
                ),
              ),
              Chip(
                label: Text(_accuracy == null
                    ? 'GPS manual'
                    : 'GPS ${_accuracy!.toInt()} m'),
              ),
              if (_elevation != null)
                Chip(label: Text('Elev ${_elevation!.toStringAsFixed(0)} m')),
            ],
          ),
          if (_locating || _offlineDownloading) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: _offlineProgress),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _isRecording ? null : _startWalkBoundary,
                icon: const Icon(Icons.directions_walk_rounded),
                label: const Text('Walk boundary'),
              ),
              FilledButton.tonalIcon(
                onPressed: _locating ? null : _scanPlot,
                icon: const Icon(Icons.crop_free_rounded),
                label: const Text('Scan plot'),
              ),
              OutlinedButton.icon(
                onPressed: _locating ? null : _useLocation,
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('GPS'),
              ),
              OutlinedButton.icon(
                onPressed: _offlineDownloading ? null : _downloadOfflineRegion,
                icon: const Icon(Icons.offline_pin_rounded),
                label: const Text('Offline map'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildMap(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _boundary.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _boundary =
                              _boundary.sublist(0, _boundary.length - 1);
                          _message = 'Last boundary point removed.';
                        });
                        unawaited(_redrawMapAnnotations());
                      },
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Undo'),
              ),
              TextButton.icon(
                onPressed: _boundary.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _boundary = [];
                          _message = 'Boundary cleared. Tap or walk to redraw.';
                        });
                        unawaited(_redrawMapAnnotations());
                      },
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenEditor(ColorScheme colors) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  GlassCard(
                    child: Row(
                      children: [
                        Icon(
                          _isRecording
                              ? Icons.directions_walk_rounded
                              : Icons.edit_location_alt_rounded,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isRecording
                                    ? 'Walk-the-boundary'
                                    : 'Fullscreen boundary edit',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'Corners ${_boundary.length} | ${_accuracy == null ? "GPS manual" : "GPS ${_accuracy!.toStringAsFixed(0)} m"}',
                                style:
                                    TextStyle(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close fullscreen',
                          onPressed: () =>
                              setState(() => _isFullscreen = false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _message,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        if (_isRecording)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _recordingPaused = !_recordingPaused;
                                      _message = _recordingPaused
                                          ? 'Boundary recording paused.'
                                          : 'Boundary recording resumed.';
                                    });
                                  },
                                  icon: Icon(_recordingPaused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded),
                                  label: Text(
                                      _recordingPaused ? 'Resume' : 'Pause'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _finishWalkBoundary,
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Finish'),
                                ),
                              ),
                            ],
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _boundary.isEmpty
                                    ? null
                                    : () {
                                        setState(() {
                                          _boundary = _boundary.sublist(
                                            0,
                                            _boundary.length - 1,
                                          );
                                          _message =
                                              'Last boundary point removed.';
                                        });
                                        unawaited(_redrawMapAnnotations());
                                      },
                                icon: const Icon(Icons.undo_rounded),
                                label: const Text('Undo'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _scanPlot,
                                icon: const Icon(Icons.crop_free_rounded),
                                label: const Text('Scan'),
                              ),
                              FilledButton.icon(
                                onPressed: () =>
                                    setState(() => _isFullscreen = false),
                                icon: const Icon(Icons.done_rounded),
                                label: const Text('Done'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropsCard(ColorScheme colors) {
    final sliderMax = _coverageRemaining <= 0 ? 0.0 : _coverageRemaining;
    if (_cropCoverageValue > sliderMax && sliderMax > 0) {
      _cropCoverageValue = sliderMax;
    }
    final remainingAfterSlider =
        (_coverageRemaining - _cropCoverageValue).clamp(0, 100).toDouble();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  icon: Icons.pie_chart_rounded,
                  title: 'Crops on this land',
                ),
              ),
              Text('${_coverageTotal.toStringAsFixed(0)}% used'),
            ],
          ),
          const SizedBox(height: 12),
          _CropCoverageDonut(
            crops: _crops,
            totalAreaHa: _area,
            remainingPercent: _coverageRemaining,
          ),
          const SizedBox(height: 12),
          for (final crop in _crops) _buildCropTile(crop),
          if (_crops.isNotEmpty) const Divider(height: 24),
          TextField(
            controller: _cropName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Crop name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cropVariety,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Variety'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _cropGrowthStage,
            decoration: const InputDecoration(labelText: 'Growth stage'),
            items: cropGrowthStages
                .map(
                  (stage) => DropdownMenuItem(
                    value: stage,
                    child: Text(growthStageLabel(stage)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _cropGrowthStage = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Coverage ${_cropCoverageValue.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text('Remaining ${remainingAfterSlider.toStringAsFixed(0)}%'),
            ],
          ),
          Slider(
            value: sliderMax <= 0
                ? 0
                : _cropCoverageValue.clamp(0, sliderMax).toDouble(),
            min: 0,
            max: sliderMax <= 0 ? 1 : sliderMax,
            divisions:
                sliderMax <= 0 ? null : sliderMax.round().clamp(1, 100).toInt(),
            label: '${_cropCoverageValue.toStringAsFixed(0)}%',
            onChanged: sliderMax <= 0
                ? null
                : (value) => setState(() => _cropCoverageValue = value),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickSowingDate,
            icon: const Icon(Icons.event_rounded),
            label: Text(_cropSowingDate == null
                ? 'Sowing date'
                : DateFormat('yyyy-MM-dd').format(_cropSowingDate!)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _addCrop,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add crop'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropTile(CropItem crop) {
    final details = <String>[
      crop.coverageSummary(_area),
      if (crop.variety != null && crop.variety!.trim().isNotEmpty)
        crop.variety!.trim(),
      if (crop.growthStage != null) growthStageLabel(crop.growthStage),
      if (crop.sowingDate != null) 'Sown ${crop.sowingDate}',
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title:
          Text(crop.name, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(details.join(' - ')),
      trailing: IconButton(
        tooltip: 'Remove crop',
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: () => setState(() => _crops.remove(crop)),
      ),
    );
  }

  Future<void> _pickSowingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _cropSowingDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _cropSowingDate = picked);
  }

  void _addCrop() {
    final name = _cropName.text.trim();
    if (name.isEmpty) {
      _showEditorSnack('Enter a crop name.');
      return;
    }
    if (_cropCoverageValue <= 0) {
      _showEditorSnack('Set crop coverage above 0%.');
      return;
    }
    if (_coverageTotal + _cropCoverageValue > 100.01) {
      _showEditorSnack('Total crop coverage cannot exceed 100%.');
      return;
    }
    final crop = CropItem(
      name: name,
      coveragePercent: _cropCoverageValue,
      variety:
          _cropVariety.text.trim().isEmpty ? null : _cropVariety.text.trim(),
      growthStage: _cropGrowthStage,
      sowingDate: _cropSowingDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(_cropSowingDate!),
    );
    setState(() {
      _crops = [..._crops, crop];
      _cropName.clear();
      _cropVariety.clear();
      _cropGrowthStage = null;
      _cropSowingDate = null;
      _cropCoverageValue = _coverageRemaining.clamp(0, 25).toDouble();
      if (_cropCoverageValue <= 0) _cropCoverageValue = 0;
    });
  }

  Widget _buildAdvancedDetailsCard() {
    return GlassCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: const Icon(Icons.tune_rounded),
          title: const Text('Advanced farm details'),
          subtitle: const Text('Optional data for stronger AI reports'),
          children: [
            const SizedBox(height: 8),
            _dropdownField(
              label: 'Irrigation type',
              value: _irrigationType,
              values: irrigationTypes,
              onChanged: (value) => setState(() => _irrigationType = value),
            ),
            _dropdownField(
              label: 'Water source',
              value: _waterSource,
              values: waterSources,
              onChanged: (value) => setState(() => _waterSource = value),
            ),
            _dropdownField(
              label: 'Terrain type',
              value: _terrainType,
              values: terrainTypes,
              onChanged: (value) => setState(() => _terrainType = value),
            ),
            _dropdownField(
              label: 'Farming practice',
              value: _farmingPractice,
              values: farmingPractices,
              onChanged: (value) => setState(() => _farmingPractice = value),
            ),
            _dropdownField(
              label: 'Land ownership',
              value: _landOwnership,
              values: landOwnershipTypes,
              onChanged: (value) => setState(() => _landOwnership = value),
            ),
            TextField(
              controller: _previousCrop,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Previous crop'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _soilPH,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Soil pH (1-14)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _farmAge,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Years farmed'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nearestMarket,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nearest market'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.terrain_rounded),
              title: const Text('Elevation'),
              subtitle: Text(_elevation == null
                  ? 'Auto-captured from GPS'
                  : '${_elevation!.toStringAsFixed(0)} m from GPS'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(enumLabel(item)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

enum _BoundaryHandleKind { vertex, midpoint }

class _BoundaryHandle {
  const _BoundaryHandle(this.kind, this.index);

  final _BoundaryHandleKind kind;
  final int index;
}

class _CropCoverageDonut extends StatelessWidget {
  const _CropCoverageDonut({
    required this.crops,
    required this.totalAreaHa,
    required this.remainingPercent,
  });

  final List<CropItem> crops;
  final double totalAreaHa;
  final double remainingPercent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final segments = [
      for (var i = 0; i < crops.length; i++)
        _DonutSegment(
          label: crops[i].name,
          percent: crops[i].coveragePercent,
          color: _cropSegmentColor(i),
        ),
      if (remainingPercent > 0)
        _DonutSegment(
          label: 'Remaining',
          percent: remainingPercent,
          color: colors.surfaceContainerHighest,
        ),
    ];

    if (segments.isEmpty) {
      return GlassCard(
        margin: EdgeInsets.zero,
        child: Text(
          'Add crop coverage to see the field split.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 112,
          height: 112,
          child: CustomPaint(
            painter: _DonutChartPainter(segments),
            child: Center(
              child: Text(
                '${(100 - remainingPercent).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              for (final segment in segments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: segment.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          segment.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${segment.percent.toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
              if (totalAreaHa > 0 && crops.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Area estimates use ${totalAreaHa.toStringAsFixed(2)} ha.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutSegment {
  const _DonutSegment({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter(this.segments);

  final List<_DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.shortestSide * 0.16;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    var start = -pi / 2;
    for (final segment in segments) {
      if (segment.percent <= 0) continue;
      final sweep = (segment.percent / 100) * 2 * pi;
      paint.color = segment.color;
      canvas.drawArc(rect.deflate(stroke / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

Color _cropSegmentColor(int index) {
  const colors = [
    Color(0xFF25C28A),
    Color(0xFF8BC6EC),
    Color(0xFFF2C94C),
    Color(0xFFFF8A65),
    Color(0xFF9B8AFB),
    Color(0xFF56CCF2),
  ];
  return colors[index % colors.length];
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.repository,
    required this.weather,
    required this.intelligence,
    required this.decisionEngine,
    required this.voiceService,
    required this.userId,
  });

  final FarmlandRepository repository;
  final WeatherClient weather;
  final FarmlandIntelligence intelligence;
  final DecisionEngine decisionEngine;
  final HumanVoiceService voiceService;
  final int userId;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Farmland> _farms = const [];
  Farmland? _selected;
  WeatherForecast? _weather;
  ComprehensiveReport? _report;
  bool _refreshing = false;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _farms = widget.repository.cached(widget.userId);
    if (_farms.isEmpty) {
      _farms = await widget.repository.refresh(widget.userId);
    }
    _selected = _farms.isEmpty ? null : _farms.first;
    setState(() {});
    await _refreshReport();
  }

  Future<void> _refreshReport() async {
    final farm = _selected;
    if (farm == null) return;
    setState(() {
      _report = widget.intelligence.instantPreview(farm, null);
      _refreshing = true;
    });
    try {
      final weather =
          await widget.weather.daily(farm.locationLat, farm.locationLng);
      final report = await widget.intelligence.analyze(farm, weather);
      if (mounted) {
        setState(() {
          _weather = weather;
          _report = report;
        });
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _speak() async {
    final state = AppStateScope.of(context);
    final report = _report;
    if (report == null) return;
    setState(() => _speaking = true);
    late final VoicePlaybackResult result;
    try {
      result = await widget.voiceService.speak(
        _reportSpeech(report),
        state.selectedLanguage,
        contextLabel: 'Krishi Mitra farm report',
      );
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
    final message = result.message;
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _reportSpeech(ComprehensiveReport report) {
    final suggestions = report.expertSuggestions.take(4).join('. ');
    return [
      report.smartActionWindow,
      report.weeklyRisks,
      report.yieldTimeline,
      if (suggestions.isNotEmpty) 'Recommended actions. $suggestions',
    ].join('. ');
  }

  String _voiceLabel() {
    if (_speaking) return 'Speaking...';
    if (widget.voiceService.cloudVoiceReady) {
      return 'Read in Indian neural voice';
    }
    return 'Read aloud offline';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          const _BrandHeader(
              title: 'AI Farm Report', subtitle: 'Krishi Mitra analysis'),
          const SizedBox(height: 16),
          if (_farms.isEmpty)
            const _EmptyState(
                title: 'No farmland', message: 'Add a geofenced farm first.')
          else ...[
            DropdownButtonFormField<Farmland>(
              initialValue: _selected,
              items: _farms
                  .map((farm) =>
                      DropdownMenuItem(value: farm, child: Text(farm.name)))
                  .toList(),
              onChanged: (farm) {
                setState(() => _selected = farm);
                _refreshReport();
              },
              decoration: const InputDecoration(labelText: 'Select farmland'),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                      icon: Icons.cloud_rounded, title: 'Weather Forecast'),
                  const SizedBox(height: 8),
                  Text(_weatherSummary(_weather)),
                  if (_weather != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _weather!.daily.time.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final date =
                              DateTime.parse(_weather!.daily.time[index]);
                          return Chip(
                            label: Text(
                              '${DateFormat.MMMd().format(date)}\n${_weather!.daily.maxTemp[index].toStringAsFixed(1)} C',
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Expanded(
                          child: _SectionTitle(
                              icon: Icons.info_rounded,
                              title: 'AI Crop Sustainability Report')),
                      if (_refreshing)
                        const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  if (_refreshing) ...[
                    const SizedBox(height: 8),
                    Text(
                        'Showing local preview. Refreshing latest AI and weather silently.',
                        style: TextStyle(color: colors.primary)),
                  ],
                  const SizedBox(height: 12),
                  if (_report == null)
                    const LinearProgressIndicator()
                  else
                    _ReportBody(report: _report!),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _speaking ? null : _speak,
                          icon: _speaking
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.record_voice_over_rounded),
                          label: Text(_voiceLabel()),
                        ),
                      ),
                      if (_speaking) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () async {
                            await widget.voiceService.stop();
                            if (mounted) setState(() => _speaking = false);
                          },
                          icon: const Icon(Icons.stop_rounded),
                          tooltip: 'Stop reading',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({
    super.key,
    required this.api,
    required this.repository,
    required this.mandi,
    required this.userId,
  });

  final SupabaseRestClient api;
  final FarmlandRepository repository;
  final DataGovMandiClient mandi;
  final int userId;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  static const _defaultCrops = [
    'Banana',
    'Coconut',
    'Tomato',
    'Onion',
    'Groundnut',
    'Turmeric',
    'Rice',
    'Wheat',
  ];

  List<PestAlert> _alerts = const [];
  List<Farmland> _farms = const [];
  List<MandiPriceRecord> _mandiRecords = const [];
  bool _loading = true;
  bool _mandiLoading = true;
  bool _usingFallbackMandi = false;
  String? _selectedCommodity;
  String? _mandiError;
  String? _lastMandiKey;
  bool _userChangedCommodity = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateScope.of(context);
    _selectedCommodity ??= _defaultMarketCrop(state);
    _loadMandi(state);
  }

  Future<void> _load() async {
    setState(() => _farms = widget.repository.cached(widget.userId));
    try {
      final alerts = await widget.api.getAlerts();
      final farms = await widget.repository.refresh(widget.userId);
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _farms = farms;
        if (!_userChangedCommodity) {
          _selectedCommodity = _defaultMarketCrop(AppStateScope.of(context));
          _lastMandiKey = null;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _alerts = const [];
          _farms = widget.repository.cached(widget.userId);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _loadMandi(AppStateScope.of(context), force: true);
      }
    }
  }

  Future<void> _loadMandi(AppState state, {bool force = false}) async {
    final crop = _selectedCommodity ?? _defaultMarketCrop(state);
    final commodity = _mandiCommodityForCrop(crop);
    final stateName = _stateFromLocationName(state.userLocationName) ??
        (_isCoastalKeralaLocation(state.userLocationName, state.userLat)
            ? 'Kerala'
            : null);
    final key = '$commodity|${stateName ?? 'india'}';
    if (!force && _lastMandiKey == key) return;
    _lastMandiKey = key;
    setState(() {
      _mandiLoading = true;
      _mandiError = null;
      _usingFallbackMandi = false;
    });

    try {
      final records = await widget.mandi.prices(
        commodity: commodity,
        state: stateName,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _mandiRecords = records.isEmpty
            ? _fallbackMandiRecords(commodity, stateName)
            : records;
        _usingFallbackMandi = records.isEmpty;
        _mandiError = records.isEmpty
            ? 'No live mandi rows found for $commodity in ${stateName ?? 'India'}. Showing fallback planning data.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mandiRecords = _fallbackMandiRecords(commodity, stateName);
        _usingFallbackMandi = true;
        _mandiError =
            'Live mandi data is unavailable right now. Showing offline planning data.';
      });
    } finally {
      if (mounted) setState(() => _mandiLoading = false);
    }
  }

  String _defaultMarketCrop(AppState state) {
    final farmCrop = _farms
        .expand((farm) => farm.crops)
        .map((crop) => crop.name.trim())
        .firstWhere((name) => name.isNotEmpty, orElse: () => '');
    if (farmCrop.isNotEmpty) return _titleCaseCrop(farmCrop);
    if (_isCoastalKeralaLocation(state.userLocationName, state.userLat)) {
      return 'Banana';
    }
    return 'Rice';
  }

  List<String> _cropOptions(AppState state) {
    final options = <String>{
      for (final farm in _farms)
        for (final crop in farm.crops)
          if (crop.name.trim().isNotEmpty) _titleCaseCrop(crop.name),
      ..._defaultCrops,
    }.toList();
    if (_isCoastalKeralaLocation(state.userLocationName, state.userLat)) {
      options.insertAll(0, const ['Banana', 'Coconut', 'Turmeric']);
    }
    return options.toSet().toList();
  }

  void _selectCommodity(String? crop) {
    if (crop == null || crop.trim().isEmpty) return;
    setState(() {
      _selectedCommodity = crop;
      _userChangedCommodity = true;
      _lastMandiKey = null;
    });
    _loadMandi(AppStateScope.of(context), force: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final crop = _selectedCommodity ?? _defaultMarketCrop(state);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          const _BrandHeader(
              title: 'Market & Alerts',
              subtitle: 'Mandi prices, pest signals, local updates'),
          const SizedBox(height: 16),
          AnimatedEntrance(
            child: _MandiOpportunityRadar(
              crop: crop,
              cropOptions: _cropOptions(state),
              records: _mandiRecords,
              farms: _farms,
              locationName: state.userLocationName,
              loading: _mandiLoading,
              error: _mandiError,
              usingFallback: _usingFallbackMandi,
              onCropChanged: _selectCommodity,
              onRefresh: () => _loadMandi(state, force: true),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedEntrance(
            delay: const Duration(milliseconds: 80),
            child: _FarmNegotiatorCard(
              crop: crop,
              records: _mandiRecords,
              farms: _farms,
              locationName: state.userLocationName,
              usingFallback: _usingFallbackMandi,
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(
            icon: Icons.notifications_active_rounded,
            title: 'Community alerts',
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_alerts.isEmpty)
            const _EmptyState(
                title: 'No alerts', message: 'Your region is quiet right now.')
          else
            ..._alerts.map(
              (alert) => GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text('${alert.cropName}: ${alert.pestType}'),
                  subtitle: Text(
                      '${alert.severity} severity near ${alert.locationLat.toStringAsFixed(3)}, ${alert.locationLng.toStringAsFixed(3)}'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MandiOpportunityRadar extends StatelessWidget {
  const _MandiOpportunityRadar({
    required this.crop,
    required this.cropOptions,
    required this.records,
    required this.farms,
    required this.locationName,
    required this.loading,
    required this.error,
    required this.usingFallback,
    required this.onCropChanged,
    required this.onRefresh,
  });

  final String crop;
  final List<String> cropOptions;
  final List<MandiPriceRecord> records;
  final List<Farmland> farms;
  final String? locationName;
  final bool loading;
  final String? error;
  final bool usingFallback;
  final ValueChanged<String?> onCropChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final location = _compactLocationLabel(locationName) ?? 'your region';
    final safeOptions = cropOptions.isEmpty ? const ['Banana'] : cropOptions;
    final opportunity = _MandiOpportunity.from(
      crop: crop,
      records: records,
      farms: farms,
      locationName: locationName,
    );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.storefront_rounded, color: colors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mandi Opportunity Radar',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Gov price signal for $location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh mandi prices',
                onPressed: loading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Track crop',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: safeOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = safeOptions[index];
                return _ModernSelectorChip(
                  label: option,
                  icon: Icons.grass_rounded,
                  selected: option == crop,
                  onTap: loading ? () {} : () => onCropChanged(option),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          if (loading) ...[
            const LinearProgressIndicator(minHeight: 5),
            const SizedBox(height: 10),
            Text(
              'Fetching official mandi prices...',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ] else if (records.isEmpty) ...[
            const _EmptyState(
              title: 'No mandi rows',
              message: 'Try another crop or refresh after some time.',
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    opportunity.headline,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: opportunity.score >= 72
                        ? colors.primaryContainer
                        : colors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${opportunity.score.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: opportunity.score >= 72
                          ? colors.primary
                          : colors.tertiary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(opportunity.reason),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MarketMetric(
                    label: 'Best mandi',
                    value: opportunity.bestMarket,
                    icon: Icons.store_mall_directory_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MarketMetric(
                    label: 'Best price',
                    value: _formatInr(opportunity.bestPrice),
                    icon: Icons.payments_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MarketMetric(
                    label: 'Price gap',
                    value: '${opportunity.spreadPercent.toStringAsFixed(0)}%',
                    icon: Icons.compare_arrows_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      opportunity.action,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            if (opportunity.bestFarmName != null) ...[
              const SizedBox(height: 10),
              _AdvisorInfoTile(
                icon: Icons.landscape_rounded,
                label: 'Farm link',
                value:
                    '${opportunity.bestFarmName} is connected to this crop. Use this price signal before harvest or area planning.',
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Top mandi rows',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final record in opportunity.topRecords)
              _MandiMarketRow(record: record),
            const SizedBox(height: 8),
            Text(
              usingFallback
                  ? 'Offline planning data. Refresh for live data.gov.in mandi rows.'
                  : 'Source: data.gov.in AGMARKNET daily mandi prices.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(error!, style: TextStyle(color: colors.tertiary)),
            ],
          ],
        ],
      ),
    );
  }
}

class _MarketMetric extends StatelessWidget {
  const _MarketMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MandiMarketRow extends StatelessWidget {
  const _MandiMarketRow({required this.record});

  final MandiPriceRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.grain_rounded, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.market,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${record.district} - ${record.variety} - ${record.arrivalDate}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatInr(record.modalPrice),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MandiOpportunity {
  const _MandiOpportunity({
    required this.headline,
    required this.reason,
    required this.action,
    required this.bestMarket,
    required this.bestPrice,
    required this.spreadPercent,
    required this.score,
    required this.topRecords,
    this.bestFarmName,
  });

  final String headline;
  final String reason;
  final String action;
  final String bestMarket;
  final double bestPrice;
  final double spreadPercent;
  final double score;
  final List<MandiPriceRecord> topRecords;
  final String? bestFarmName;

  factory _MandiOpportunity.from({
    required String crop,
    required List<MandiPriceRecord> records,
    required List<Farmland> farms,
    required String? locationName,
  }) {
    final sorted = records.where((item) => item.modalPrice > 0).toList()
      ..sort((a, b) => b.modalPrice.compareTo(a.modalPrice));
    if (sorted.isEmpty) {
      return const _MandiOpportunity(
        headline: 'No price signal',
        reason: 'No mandi records are available for this crop yet.',
        action: 'Refresh later or select another crop.',
        bestMarket: '--',
        bestPrice: 0,
        spreadPercent: 0,
        score: 0,
        topRecords: [],
      );
    }

    final best = sorted.first;
    final district = _districtFromLocationName(locationName);
    final districtRows = district == null
        ? const <MandiPriceRecord>[]
        : sorted
            .where(
                (item) => item.district.toLowerCase() == district.toLowerCase())
            .toList();
    final comparisonRows = districtRows.isEmpty ? sorted : districtRows;
    final avg = comparisonRows.fold<double>(
          0,
          (sum, item) => sum + item.modalPrice,
        ) /
        comparisonRows.length;
    final spread = avg <= 0 ? 0.0 : ((best.modalPrice - avg) / avg) * 100;
    final score = (55 + spread * 1.7 + sorted.length.clamp(0, 20)).clamp(5, 96);
    final connectedFarm = _connectedFarmForCrop(crop, farms);

    final headline = spread >= 18
        ? 'Price gap detected'
        : spread >= 8
            ? 'Good selling window'
            : 'Local sale looks fine';
    final action = spread >= 18
        ? 'Call ${best.market} before selling. The top mandi is ${spread.toStringAsFixed(0)}% above the comparison price.'
        : spread >= 8
            ? 'Watch ${best.market}. A small transport check may improve net return.'
            : 'Sell near your normal mandi unless quality or transport costs change.';
    final reason = districtRows.isEmpty
        ? '${best.market}, ${best.district} has the strongest modal price among the latest rows.'
        : 'Compared with $district rows, ${best.market} is currently the strongest visible price.';

    return _MandiOpportunity(
      headline: headline,
      reason: reason,
      action: action,
      bestMarket: best.market,
      bestPrice: best.modalPrice,
      spreadPercent: spread.clamp(0, 999).toDouble(),
      score: score.toDouble(),
      topRecords: sorted.take(4).toList(),
      bestFarmName: connectedFarm?.name,
    );
  }
}

enum _OfferUnit { kg, qtl }

class _FarmNegotiatorCard extends StatefulWidget {
  const _FarmNegotiatorCard({
    required this.crop,
    required this.records,
    required this.farms,
    required this.locationName,
    required this.usingFallback,
  });

  final String crop;
  final List<MandiPriceRecord> records;
  final List<Farmland> farms;
  final String? locationName;
  final bool usingFallback;

  @override
  State<_FarmNegotiatorCard> createState() => _FarmNegotiatorCardState();
}

class _FarmNegotiatorCardState extends State<_FarmNegotiatorCard> {
  final _offer = TextEditingController();
  final _quantity = TextEditingController(text: '100');
  final _transport = TextEditingController();
  _OfferUnit _unit = _OfferUnit.kg;
  String _grade = 'FAQ';
  String _urgency = 'Can hold';

  @override
  void dispose() {
    _offer.dispose();
    _quantity.dispose();
    _transport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final plan = _NegotiationPlan.from(
      crop: widget.crop,
      records: widget.records,
      farms: widget.farms,
      offerText: _offer.text,
      quantityText: _quantity.text,
      transportText: _transport.text,
      unit: _unit,
      grade: _grade,
      urgency: _urgency,
      locationName: widget.locationName,
    );
    final tone = plan.verdictColor(colors);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.handshake_rounded, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm Negotiator',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Check a buyer offer before saying yes',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.shortVerdict,
                  style: TextStyle(color: tone, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<_OfferUnit>(
            segments: const [
              ButtonSegment(
                value: _OfferUnit.kg,
                label: Text('INR/kg'),
                icon: Icon(Icons.scale_rounded),
              ),
              ButtonSegment(
                value: _OfferUnit.qtl,
                label: Text('INR/qtl'),
                icon: Icon(Icons.inventory_2_rounded),
              ),
            ],
            selected: {_unit},
            onSelectionChanged: (value) => setState(() => _unit = value.first),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _offer,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Buyer offer',
                    prefixIcon: const Icon(Icons.payments_rounded),
                    hintText: _unit == _OfferUnit.kg ? '32' : '3200',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _quantity,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Quantity kg',
                    prefixIcon: Icon(Icons.shopping_bag_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _transport,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Transport cost if selling at mandi',
              hintText: 'Optional total INR',
              prefixIcon: Icon(Icons.local_shipping_rounded),
            ),
          ),
          const SizedBox(height: 12),
          _NegotiatorSelector(
            label: 'Grade',
            values: const ['Grade A', 'FAQ', 'Lower'],
            selected: _grade,
            icon: Icons.workspace_premium_rounded,
            onChanged: (value) => setState(() => _grade = value),
          ),
          const SizedBox(height: 10),
          _NegotiatorSelector(
            label: 'Urgency',
            values: const ['Can hold', '2-3 days', 'Sell today'],
            selected: _urgency,
            icon: Icons.timer_rounded,
            onChanged: (value) => setState(() => _urgency = value),
          ),
          const SizedBox(height: 14),
          if (widget.records.isEmpty)
            Text(
              'Mandi signal is loading above. Enter an offer now, then refresh prices.',
              style: TextStyle(color: colors.onSurfaceVariant),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tone.withValues(alpha: 0.38)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.verdict,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: tone,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(plan.reason),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MarketMetric(
                    label: 'Ask price',
                    value: plan.formatPrice(plan.askQtl),
                    icon: Icons.campaign_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MarketMetric(
                    label: 'Walk-away',
                    value: plan.formatPrice(plan.walkAwayQtl),
                    icon: Icons.block_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MarketMetric(
                    label: 'Net offer',
                    value: plan.offerEntered
                        ? plan.formatPrice(plan.netOfferQtl)
                        : 'Enter offer',
                    icon: Icons.receipt_long_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.record_voice_over_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      plan.script,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            if (plan.bestFarmName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Linked farm: ${plan.bestFarmName}',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
            if (widget.usingFallback) ...[
              const SizedBox(height: 8),
              Text(
                'Using offline planning data until live mandi rows refresh.',
                style: TextStyle(color: colors.tertiary),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _NegotiatorSelector extends StatelessWidget {
  const _NegotiatorSelector({
    required this.label,
    required this.values,
    required this.selected,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final List<String> values;
  final String selected;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final value = values[index];
              return _ModernSelectorChip(
                label: value,
                icon: icon,
                selected: value == selected,
                onTap: () => onChanged(value),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NegotiationPlan {
  const _NegotiationPlan({
    required this.offerEntered,
    required this.verdict,
    required this.shortVerdict,
    required this.reason,
    required this.script,
    required this.askQtl,
    required this.walkAwayQtl,
    required this.netOfferQtl,
    required this.unit,
    this.bestFarmName,
  });

  final bool offerEntered;
  final String verdict;
  final String shortVerdict;
  final String reason;
  final String script;
  final double askQtl;
  final double walkAwayQtl;
  final double netOfferQtl;
  final _OfferUnit unit;
  final String? bestFarmName;

  factory _NegotiationPlan.from({
    required String crop,
    required List<MandiPriceRecord> records,
    required List<Farmland> farms,
    required String offerText,
    required String quantityText,
    required String transportText,
    required _OfferUnit unit,
    required String grade,
    required String urgency,
    required String? locationName,
  }) {
    final sorted = records.where((item) => item.modalPrice > 0).toList()
      ..sort((a, b) => b.modalPrice.compareTo(a.modalPrice));
    final offer = _parseMoney(offerText);
    final offerQtl = unit == _OfferUnit.kg ? offer * 100 : offer;
    final quantityKg = max(_parseMoney(quantityText), 1);
    final transportPerQtl =
        _parseMoney(transportText) / max(quantityKg / 100, 1);
    final benchmark = sorted.isEmpty
        ? _fallbackModalPrice(_mandiCommodityForCrop(crop))
        : sorted.fold<double>(0, (sum, item) => sum + item.modalPrice) /
            sorted.length;
    final best = sorted.isEmpty ? benchmark : sorted.first.modalPrice;
    final gradeFactor = switch (grade) {
      'Grade A' => 1.06,
      'Lower' => 0.9,
      _ => 1.0,
    };
    final urgencyFactor = switch (urgency) {
      'Sell today' => 0.94,
      '2-3 days' => 0.98,
      _ => 1.03,
    };
    final bestFarm = _connectedFarmForCrop(crop, farms);
    final ask = max(best * 0.96 - transportPerQtl, benchmark * 0.98) *
        gradeFactor *
        urgencyFactor;
    final walkAway =
        max(benchmark * 0.86 * gradeFactor - transportPerQtl, 0).toDouble();

    var verdict = 'Enter buyer offer';
    var shortVerdict = 'Ready';
    var reason =
        'Latest mandi benchmark for $crop is ${_formatInr(benchmark)}. Add the buyer offer to calculate your negotiation range.';

    if (offer > 0) {
      if (offerQtl >= ask * 0.98) {
        verdict = 'Accept or close quickly';
        shortVerdict = 'Accept';
        reason =
            'The buyer offer is near or above the ask range after grade, urgency, and transport comparison.';
      } else if (offerQtl >= walkAway) {
        verdict = 'Negotiate before accepting';
        shortVerdict = 'Negotiate';
        reason =
            'The offer is above your walk-away point but below the stronger mandi-linked ask price.';
      } else {
        verdict = urgency == 'Sell today'
            ? 'Accept only if urgent'
            : 'Do not accept yet';
        shortVerdict = urgency == 'Sell today' ? 'Careful' : 'Reject';
        reason =
            'The offer is below the safe floor suggested by the current mandi benchmark.';
      }
    }

    final place = _compactLocationLabel(locationName) ?? 'nearby mandi';
    final script =
        'Current $place mandi signal for $crop supports ${_formatOfferPrice(ask, unit)}. '
        'I can give $grade produce at ${_formatOfferPrice(ask, unit)} if pickup is today. '
        'My minimum is ${_formatOfferPrice(walkAway, unit)}.';

    return _NegotiationPlan(
      offerEntered: offer > 0,
      verdict: verdict,
      shortVerdict: shortVerdict,
      reason: reason,
      script: script,
      askQtl: ask,
      walkAwayQtl: walkAway,
      netOfferQtl: offerQtl,
      unit: unit,
      bestFarmName: bestFarm?.name,
    );
  }

  Color verdictColor(ColorScheme colors) {
    return switch (shortVerdict) {
      'Accept' => colors.primary,
      'Negotiate' => colors.tertiary,
      'Careful' => colors.tertiary,
      'Reject' => colors.error,
      _ => colors.onSurfaceVariant,
    };
  }

  String formatPrice(double qtlPrice) => _formatOfferPrice(qtlPrice, unit);
}

class _MarketPricesCard extends StatelessWidget {
  const _MarketPricesCard();

  static const _prices = [
    _MandiPrice(crop: 'Rice (Common)', price: '₹2,183/qtl', trend: 'stable'),
    _MandiPrice(crop: 'Wheat', price: '₹2,275/qtl', trend: 'up'),
    _MandiPrice(crop: 'Maize', price: '₹2,090/qtl', trend: 'stable'),
    _MandiPrice(crop: 'Soybean', price: '₹4,600/qtl', trend: 'up'),
    _MandiPrice(crop: 'Cotton', price: '₹6,620/qtl', trend: 'down'),
    _MandiPrice(crop: 'Groundnut', price: '₹5,850/qtl', trend: 'up'),
    _MandiPrice(crop: 'Tomato', price: '₹1,200/qtl', trend: 'down'),
    _MandiPrice(crop: 'Onion', price: '₹2,100/qtl', trend: 'stable'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.storefront_rounded, color: colors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mandi price reference',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Indicative MSP and market rates',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._prices.map((price) {
            final trendIcon = price.trend == 'up'
                ? Icons.trending_up_rounded
                : price.trend == 'down'
                    ? Icons.trending_down_rounded
                    : Icons.trending_flat_rounded;
            final trendColor = price.trend == 'up'
                ? colors.primary
                : price.trend == 'down'
                    ? colors.error
                    : colors.onSurfaceVariant;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.grain_rounded,
                      size: 18, color: colors.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      price.crop,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    price.price,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(trendIcon, size: 20, color: trendColor),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'Prices are indicative. Check local mandi for latest rates.',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MandiPrice {
  const _MandiPrice({
    required this.crop,
    required this.price,
    required this.trend,
  });

  final String crop;
  final String price;
  final String trend;
}

class _LocationSearchHit {
  const _LocationSearchHit({
    required this.label,
    required this.shortLabel,
    required this.lat,
    required this.lng,
  });

  final String label;
  final String shortLabel;
  final double lat;
  final double lng;

  factory _LocationSearchHit.fromJson(Map<String, dynamic> json) {
    final label = json['display_name']?.toString() ?? '';
    final shortLabel = label.split(',').take(3).join(', ').trim();
    return _LocationSearchHit(
      label: label,
      shortLabel: shortLabel.isEmpty ? label : shortLabel,
      lat: double.tryParse(json['lat']?.toString() ?? '') ?? 20.5937,
      lng: double.tryParse(json['lon']?.toString() ?? '') ?? 78.9629,
    );
  }
}

List<_LocationSearchHit> _fallbackLocationSearch(String query) {
  final clean = query.toLowerCase();
  const knownLocations = [
    _LocationSearchHit(
      label: 'Kannur, Kerala, India',
      shortLabel: 'Kannur, Kerala',
      lat: 11.8745,
      lng: 75.3704,
    ),
    _LocationSearchHit(
      label: 'Kozhikode, Kerala, India',
      shortLabel: 'Kozhikode, Kerala',
      lat: 11.2588,
      lng: 75.7804,
    ),
    _LocationSearchHit(
      label: 'Kochi, Kerala, India',
      shortLabel: 'Kochi, Kerala',
      lat: 9.9312,
      lng: 76.2673,
    ),
    _LocationSearchHit(
      label: 'Bengaluru, Karnataka, India',
      shortLabel: 'Bengaluru, Karnataka',
      lat: 12.9716,
      lng: 77.5946,
    ),
    _LocationSearchHit(
      label: 'Mysuru, Karnataka, India',
      shortLabel: 'Mysuru, Karnataka',
      lat: 12.2958,
      lng: 76.6394,
    ),
    _LocationSearchHit(
      label: 'Coimbatore, Tamil Nadu, India',
      shortLabel: 'Coimbatore, Tamil Nadu',
      lat: 11.0168,
      lng: 76.9558,
    ),
    _LocationSearchHit(
      label: 'Chennai, Tamil Nadu, India',
      shortLabel: 'Chennai, Tamil Nadu',
      lat: 13.0827,
      lng: 80.2707,
    ),
    _LocationSearchHit(
      label: 'Hyderabad, Telangana, India',
      shortLabel: 'Hyderabad, Telangana',
      lat: 17.3850,
      lng: 78.4867,
    ),
    _LocationSearchHit(
      label: 'Pune, Maharashtra, India',
      shortLabel: 'Pune, Maharashtra',
      lat: 18.5204,
      lng: 73.8567,
    ),
    _LocationSearchHit(
      label: 'Nashik, Maharashtra, India',
      shortLabel: 'Nashik, Maharashtra',
      lat: 19.9975,
      lng: 73.7898,
    ),
    _LocationSearchHit(
      label: 'Ahmedabad, Gujarat, India',
      shortLabel: 'Ahmedabad, Gujarat',
      lat: 23.0225,
      lng: 72.5714,
    ),
    _LocationSearchHit(
      label: 'Lucknow, Uttar Pradesh, India',
      shortLabel: 'Lucknow, Uttar Pradesh',
      lat: 26.8467,
      lng: 80.9462,
    ),
    _LocationSearchHit(
      label: 'Bhubaneswar, Odisha, India',
      shortLabel: 'Bhubaneswar, Odisha',
      lat: 20.2961,
      lng: 85.8245,
    ),
  ];
  return knownLocations
      .where((hit) => hit.label.toLowerCase().contains(clean))
      .take(5)
      .toList();
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.api});

  final SupabaseRestClient api;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _deleteReasons = [
    'No longer farming',
    'Created a duplicate account',
    'Changing my phone number',
    'Privacy or data concerns',
    'App is hard to use',
    'Missing features I need',
    'Other',
  ];

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _locationSearch = TextEditingController();

  bool _editing = false;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  bool _selectingLocation = false;
  MapLibreMapController? _profileMapController;
  LatLng? _profileLocation;
  String _profileLocationName = '';
  double? _profileAccuracy;
  bool _searchingLocation = false;
  List<_LocationSearchHit> _locationSearchResults = const [];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _locationSearch.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocationForProfile() async {
    setState(() => _saving = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission is off.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);
      setState(() {
        _profileLocation = LatLng(position.latitude, position.longitude);
        _profileAccuracy = position.accuracy;
        _profileLocationName =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      });
      _profileMapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(_profileLocation!, 15.0));
    } catch (e) {
      setState(() => _error = 'Could not get location: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onProfileMapClick(math.Point<double> point, LatLng coordinates) {
    setState(() {
      _profileLocation = coordinates;
      _profileLocationName =
          'Lat: ${coordinates.latitude.toStringAsFixed(4)}, Lng: ${coordinates.longitude.toStringAsFixed(4)}';
    });
  }

  Future<void> _searchProfileLocation() async {
    final query = _locationSearch.text.trim();
    if (query.length < 2) {
      setState(() {
        _locationSearchResults = const [];
        _error = 'Type at least 2 letters to search location.';
      });
      return;
    }
    setState(() {
      _searchingLocation = true;
      _error = null;
    });
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'countrycodes': 'in',
        'limit': '5',
      });
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'KrishiMitraFlutter/1.0'},
      );
      var hits = <_LocationSearchHit>[];
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as List;
        hits = decoded
            .whereType<Map>()
            .map((item) => _LocationSearchHit.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .where((hit) => hit.label.isNotEmpty)
            .toList();
      }
      if (hits.isEmpty) {
        hits = _fallbackLocationSearch(query);
      }
      if (!mounted) return;
      setState(() {
        _locationSearchResults = hits;
        if (hits.isEmpty) _error = 'No matching Indian location found.';
      });
    } catch (_) {
      final hits = _fallbackLocationSearch(query);
      if (!mounted) return;
      setState(() {
        _locationSearchResults = hits;
        if (hits.isEmpty) _error = 'Location search is unavailable right now.';
      });
    } finally {
      if (mounted) setState(() => _searchingLocation = false);
    }
  }

  void _selectProfileLocationHit(_LocationSearchHit hit) {
    setState(() {
      _profileLocation = LatLng(hit.lat, hit.lng);
      _profileLocationName = hit.shortLabel;
      _locationSearch.text = hit.shortLabel;
      _locationSearchResults = const [];
    });
    _profileMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_profileLocation!, 12.5),
    );
  }

  Future<void> _saveProfileLocation(AppState state) async {
    if (_profileLocation == null) return;
    await state.setUserLocation(
      _profileLocationName,
      _profileLocation!.latitude,
      _profileLocation!.longitude,
    );
    setState(() => _selectingLocation = false);
  }

  void _startEdit(UserProfile user) {
    setState(() {
      _editing = true;
      _error = null;
      _name.text = user.name;
      _phone.text = user.phoneNumber;
    });
  }

  Future<void> _saveProfile(AppState state, UserProfile user) async {
    final cleanName = _name.text.trim();
    if (cleanName.length < 2) {
      setState(() => _error = 'Enter your full name.');
      return;
    }

    late final String cleanPhone;
    try {
      cleanPhone = normalizePhoneNumber(_phone.text);
    } catch (error) {
      setState(() => _error = '$error');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.api.updateUserProfile(
        userId: user.id,
        name: cleanName,
        phoneNumber: cleanPhone,
      );
      await state.updateUser(updated);
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (error) {
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount(AppState state, UserProfile user) async {
    final reason = await _askDeleteReason();
    if (reason == null || reason.trim().isEmpty) return;

    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.api.deleteAccount(user: user, reason: reason.trim());
      await state.deleteLocalAccount(user.id);
      if (!mounted) return;
      context.go('/login');
    } catch (error) {
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<String?> _askDeleteReason() {
    var selectedReason = _deleteReasons.first;
    final otherReason = TextEditingController();
    String? dialogError;

    return showDialog<String>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final showOther = selectedReason == 'Other';
            return AlertDialog(
              title: const Text('Delete account?'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This removes your account and farm data. Please select a reason before continuing.',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      ..._deleteReasons.map(
                        (reason) => RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(reason),
                          value: reason,
                          groupValue: selectedReason,
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              selectedReason = value;
                              dialogError = null;
                            });
                          },
                        ),
                      ),
                      if (showOther) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: otherReason,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Tell us why',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                      if (dialogError != null) ...[
                        const SizedBox(height: 8),
                        Text(dialogError!,
                            style: TextStyle(color: colors.error)),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    final reason = showOther
                        ? otherReason.text.trim()
                        : selectedReason.trim();
                    if (reason.isEmpty) {
                      setDialogState(
                          () => dialogError = 'Please enter a reason.');
                      return;
                    }
                    Navigator.of(context).pop(reason);
                  },
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('Delete account'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(otherReason.dispose);
  }

  String _friendlyError(Object error) {
    return '$error'
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final user = state.user;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              const _BrandHeader(
                title: 'Account',
                subtitle: 'Profile, preferences, data controls',
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.primary,
                      child: Text(
                        user.name.isEmpty
                            ? 'K'
                            : user.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '+91 ${user.phoneNumber}',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.verified_rounded, size: 16),
                      label: const Text('OTP'),
                      backgroundColor: colors.primaryContainer,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionTitle(
                            icon: Icons.location_on_rounded,
                            title: 'My Region / Location',
                          ),
                        ),
                        if (!_selectingLocation)
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _selectingLocation = true;
                              if (_profileLocation == null &&
                                  state.userLat != null &&
                                  state.userLng != null) {
                                _profileLocation =
                                    LatLng(state.userLat!, state.userLng!);
                                _profileLocationName = state.userLocationName ??
                                    _profileLocationName;
                                _locationSearch.text = _profileLocationName;
                              }
                            }),
                            icon: const Icon(Icons.edit_location_alt_rounded),
                            label: const Text('Set'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_selectingLocation) ...[
                      Text(
                          'Tap on the map or use GPS to set your default farm location.',
                          style: TextStyle(color: colors.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: MapLibreMap(
                            initialCameraPosition: CameraPosition(
                              target: _profileLocation ??
                                  (state.userLat != null
                                      ? LatLng(state.userLat!, state.userLng!)
                                      : const LatLng(20.5937, 78.9629)),
                              zoom: state.userLat != null ? 12 : 4,
                            ),
                            styleString: '''{
                              "version": 8,
                              "sources": {
                                "osm": {
                                  "type": "raster",
                                  "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
                                  "tileSize": 256
                                }
                              },
                              "layers": [{
                                "id": "osm",
                                "type": "raster",
                                "source": "osm",
                                "minzoom": 0,
                                "maxzoom": 19
                              }]
                            }''',
                            onMapCreated: (controller) =>
                                _profileMapController = controller,
                            onMapClick: _onProfileMapClick,
                            myLocationEnabled: true,
                            myLocationRenderMode: MyLocationRenderMode.normal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_profileLocation != null)
                        Text('Selected: $_profileLocationName',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _locationSearch,
                        textInputAction: TextInputAction.search,
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => _searchProfileLocation(),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          labelText: 'Search location',
                          hintText: 'Kannur, Pune, Nashik...',
                          suffixIcon: IconButton(
                            tooltip: 'Search location',
                            onPressed: _searchingLocation
                                ? null
                                : _searchProfileLocation,
                            icon: _searchingLocation
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.travel_explore_rounded),
                          ),
                        ),
                      ),
                      if (_locationSearchResults.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._locationSearchResults.map(
                          (hit) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: OutlinedButton.icon(
                              onPressed: () => _selectProfileLocationHit(hit),
                              icon: const Icon(Icons.place_rounded),
                              label: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  hit.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saving
                                  ? null
                                  : _getCurrentLocationForProfile,
                              icon: const Icon(Icons.my_location_rounded),
                              label: const Text('Get my location'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _profileLocation == null
                                  ? null
                                  : () => _saveProfileLocation(state),
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Save Location'),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectingLocation = false),
                        child: const Text('Cancel'),
                      ),
                    ] else ...[
                      _ProfileInfoRow(
                        icon: Icons.map_rounded,
                        label: 'Location',
                        value: state.userLocationName ?? 'Not set',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionTitle(
                            icon: Icons.manage_accounts_rounded,
                            title: 'Profile details',
                          ),
                        ),
                        if (!_editing)
                          TextButton.icon(
                            onPressed: () => _startEdit(user),
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_editing) ...[
                      TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(labelText: 'Full name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: '10 digit mobile number',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => setState(() {
                                        _editing = false;
                                        _error = null;
                                      }),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => _saveProfile(state, user),
                              icon: _saving
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save_rounded),
                              label: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _ProfileInfoRow(
                        icon: Icons.person_rounded,
                        label: 'Name',
                        value: user.name,
                      ),
                      const SizedBox(height: 8),
                      _ProfileInfoRow(
                        icon: Icons.phone_android_rounded,
                        label: 'Phone',
                        value: '+91 ${user.phoneNumber}',
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: colors.error)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: state.selectedLanguage,
                      items: SupportedLanguages.all
                          .map((lang) => DropdownMenuItem(
                              value: lang.code, child: Text(lang.displayName)))
                          .toList(),
                      onChanged: (code) {
                        if (code != null) state.setLanguage(code);
                      },
                      decoration: const InputDecoration(labelText: 'Language'),
                    ),
                    const SizedBox(height: 16),
                    _ThemeSwitch(
                      checked: state.darkThemeEnabled,
                      onChanged: state.setDarkTheme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _deleting
                          ? null
                          : () async {
                              await state.logout();
                              if (context.mounted) context.go('/login');
                            },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Log out'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed:
                          _deleting ? null : () => _deleteAccount(state, user),
                      icon: _deleting
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_forever_rounded),
                      label: const Text('Delete account'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class VoiceAssistantSheet extends StatefulWidget {
  const VoiceAssistantSheet({
    super.key,
    required this.repository,
    required this.decisionEngine,
    required this.voiceService,
    required this.userId,
  });

  final FarmlandRepository repository;
  final DecisionEngine decisionEngine;
  final HumanVoiceService voiceService;
  final int userId;

  @override
  State<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends State<VoiceAssistantSheet> {
  final _speech = SpeechToText();
  String _text = 'Tap the mic and ask your farm question';
  bool _listening = false;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    // Stop any audio that might be playing from the ReportScreen or elsewhere.
    widget.voiceService.stop();
  }

  @override
  void dispose() {
    _speech.stop();
    // Don't orphan playback when the sheet closes.
    if (_speaking) widget.voiceService.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    final state = AppStateScope.of(context);
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize();
    if (!available) return;
    setState(() {
      _listening = true;
      _text = 'Listening...';
    });
    await _speech.listen(
      localeId: state.selectedLanguage,
      onResult: (result) async {
        if (!result.finalResult) {
          setState(() => _text = result.recognizedWords);
          return;
        }
        final farms = widget.repository.cached(widget.userId);
        final farmContext = farms
            .map((farm) =>
                '${farm.name}: ${farm.crops.map((e) => e.name).join(", ")}; soil ${farm.soilType}; boundary ${farm.boundaryPoints.length} points')
            .join('\n');
        final answer = await widget.decisionEngine.advice(
          'Farmer said: "${result.recognizedWords}". Saved farms:\n$farmContext',
          state.selectedLanguage,
        );
        if (mounted) {
          setState(() {
            _listening = false;
            _speaking = true;
            _text = answer;
          });
        }
        late final VoicePlaybackResult voiceResult;
        try {
          voiceResult = await widget.voiceService.speak(
            answer,
            state.selectedLanguage,
            contextLabel: 'Krishi Mitra answer',
          );
        } finally {
          if (mounted) setState(() => _speaking = false);
        }
        if (mounted) {
          setState(() => _text = answer);
          final message = voiceResult.message;
          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final performance = UiPerformance.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    return GlassBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: GlassCard(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.78,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary.withValues(alpha: 0.18),
                            AppTheme.skyBlueAccent.withValues(alpha: 0.14),
                            AppTheme.warmAmber.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        children: [
                          _VoiceOrb(
                            active: _listening || _speaking,
                            listening: _listening,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Krishi Mitra AI',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            avatar: Icon(
                              widget.voiceService.cloudVoiceReady
                                  ? Icons.graphic_eq_rounded
                                  : Icons.phone_android_rounded,
                              size: 18,
                            ),
                            label: Text(widget.voiceService.voiceStatusLabel),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: screenHeight * 0.25,
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            _text,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ),
                      ),
                    ),
                    if (_speaking) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.voiceService.cloudVoiceReady
                            ? 'Speaking with Indian-tuned neural voice'
                            : 'Speaking with best available Indian device voice',
                        style: TextStyle(color: colors.primary),
                      ),
                    ],
                    const SizedBox(height: 22),
                    GlassOrbButton(
                      active: _listening || _speaking,
                      onPressed: _speaking ? null : _toggle,
                      icon: _listening ? Icons.stop_rounded : Icons.mic_rounded,
                      tooltip:
                          _listening ? 'Stop listening' : 'Start voice input',
                    ),
                    if (!performance.lowEnd) ...[
                      const SizedBox(height: 10),
                      Text(
                        _listening
                            ? 'Listening live'
                            : 'Tap to speak naturally',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceOrb extends StatefulWidget {
  const _VoiceOrb({required this.active, required this.listening});

  final bool active;
  final bool listening;

  @override
  State<_VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<_VoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didUpdateWidget(covariant _VoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    final performance = UiPerformance.of(context);
    if (widget.active &&
        !performance.lowEnd &&
        !performance.disableAnimations) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = widget.active ? _controller.value : 0.0;
        return Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.95),
                colors.primary.withValues(alpha: 0.72),
                AppTheme.skyBlueAccent.withValues(alpha: 0.78),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.28 + pulse * 0.2),
                blurRadius: 30 + pulse * 16,
                spreadRadius: 2 + pulse * 4,
              ),
            ],
          ),
          child: Icon(
            widget.listening ? Icons.graphic_eq_rounded : Icons.auto_awesome,
            color: Colors.white,
            size: 46,
          ),
        );
      },
    );
  }
}

class _ThemeSwitch extends StatefulWidget {
  const _ThemeSwitch({required this.checked, required this.onChanged});

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  State<_ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<_ThemeSwitch> {
  String? _message;

  @override
  void didUpdateWidget(covariant _ThemeSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checked != widget.checked) {
      setState(() => _message = widget.checked
          ? 'Switching to dark mode...'
          : 'Switching to light mode...');
      Timer(const Duration(milliseconds: 950), () {
        if (mounted) setState(() => _message = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => widget.onChanged(!widget.checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Icon(
                widget.checked
                    ? Icons.dark_mode_rounded
                    : Icons.wb_sunny_rounded,
                key: ValueKey(widget.checked),
                color: widget.checked ? colors.secondary : colors.tertiary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dark Theme',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      _message ??
                          (widget.checked
                              ? 'Night glass palette active'
                              : 'Day glass palette active'),
                      key: ValueKey(_message ?? widget.checked),
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 520),
              width: 70,
              height: 38,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: widget.checked
                    ? colors.primaryContainer
                    : colors.tertiaryContainer,
              ),
              alignment:
                  widget.checked ? Alignment.centerRight : Alignment.centerLeft,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: colors.surface,
                child: Icon(
                  widget.checked
                      ? Icons.dark_mode_rounded
                      : Icons.wb_sunny_rounded,
                  size: 17,
                  color: widget.checked ? colors.primary : colors.tertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvisorHeaderSignal extends StatelessWidget {
  const _AdvisorHeaderSignal({
    required this.hasLocation,
    required this.weather,
    required this.farms,
    required this.onTap,
  });

  final bool hasLocation;
  final WeatherForecast? weather;
  final List<Farmland> farms;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mapped =
        farms.where((farm) => farm.boundaryPoints.length >= 3).length;
    final score = (0.22 +
            (hasLocation ? 0.3 : 0) +
            (weather != null ? 0.22 : 0) +
            (farms.isNotEmpty ? 0.14 : 0) +
            (mapped > 0 ? 0.12 : 0))
        .clamp(0.08, 1.0);
    final label = hasLocation ? 'Local' : 'Set';

    return Tooltip(
      message: hasLocation
          ? 'Local readiness: tap to change profile location'
          : 'Set profile location',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: score.toDouble(),
                  strokeWidth: 4,
                  color: colors.primary,
                  backgroundColor: colors.primary.withValues(alpha: 0.16),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radar_rounded, size: 18, color: colors.primary),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.title,
    required this.subtitle,
    this.leading,
  });

  final String title;
  final String subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return PremiumAppBar(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: Builder(
        builder: (context) => IconButton.filledTonal(
          tooltip: 'Menu',
          onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
          icon: const Icon(Icons.menu_rounded),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.eco_rounded, size: 40),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colors.primary),
        const SizedBox(width: 8),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800, color: colors.primary)),
      ],
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final ComprehensiveReport report;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (report.cropAnalysis.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.36),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No crop rows returned yet. Add crops or refresh the report to generate farm readiness scoring.',
            ),
          )
        else
          for (final crop in report.cropAnalysis)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _riskColor(crop.sustainabilityColor)
                      .withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: _riskColor(crop.sustainabilityColor),
                    child: const Icon(Icons.eco_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.cropName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(crop.riskReasoning),
                        const SizedBox(height: 6),
                        Text(
                          'Recommendation: ${crop.bestYieldingVariety}',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        const Divider(),
        _ReportText(
            title: 'Smart Action Window', text: report.smartActionWindow),
        _ReportText(title: 'Weekly Risks', text: report.weeklyRisks),
        _ReportText(title: 'Yield Timeline', text: report.yieldTimeline),
        _ReportText(
            title: 'Expert Suggestions',
            text: report.expertSuggestions.join('\n')),
      ],
    );
  }
}

class _ReportText extends StatelessWidget {
  const _ReportText({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }
}

class _CropAdvisorFacts {
  const _CropAdvisorFacts({
    required this.name,
    required this.aliases,
    required this.suitableRegions,
    required this.climateWindow,
    required this.soilPreference,
    required this.waterNeed,
    required this.cropCycle,
    required this.harvestMethod,
    required this.marketPriceRange,
    required this.inputCostPerHa,
    required this.expectedYieldPerHa,
    required this.roiSummary,
    required this.bestSeason,
    required this.soilKeywords,
    required this.goodWaterSources,
    required this.minTemp,
    required this.maxTemp,
    required this.minPh,
    required this.maxPh,
  });

  final String name;
  final List<String> aliases;
  final String suitableRegions;
  final String climateWindow;
  final String soilPreference;
  final String waterNeed;
  final String cropCycle;
  final String harvestMethod;
  final String marketPriceRange;
  final String inputCostPerHa;
  final String expectedYieldPerHa;
  final String roiSummary;
  final String bestSeason;
  final List<String> soilKeywords;
  final List<String> goodWaterSources;
  final double minTemp;
  final double maxTemp;
  final double minPh;
  final double maxPh;
}

class _CropFitEvaluation {
  const _CropFitEvaluation({
    required this.farm,
    required this.score,
    required this.reason,
  });

  final Farmland farm;
  final double score;
  final String reason;

  String get label {
    if (score >= 78) return 'Strong fit';
    if (score >= 60) return 'Can work';
    return 'Needs care';
  }
}

const _cropKnowledgeBase = [
  _CropAdvisorFacts(
    name: 'Rice',
    aliases: ['paddy', 'nel', 'chawal'],
    suitableRegions:
        'Kerala lowlands, coastal Karnataka, Tamil Nadu deltas, West Bengal, Odisha, Assam, and irrigated plains.',
    climateWindow: 'Warm 24-34 C climate with dependable water.',
    soilPreference:
        'Clay loam, alluvial, red loam, or laterite with water holding.',
    waterNeed: 'High water need',
    cropCycle: '110-150 days',
    harvestMethod:
        'Harvest when 80-85 percent panicles turn golden, then thresh and dry grain to safe moisture.',
    marketPriceRange: 'Indicative paddy price: INR 2,100-2,450 per qtl.',
    inputCostPerHa: 'Typical input cost: INR 55,000-75,000 per ha.',
    expectedYieldPerHa: 'Expected yield: 4-6 t per ha with good water.',
    roiSummary:
        'Moderate ROI. Best when water is assured and local procurement or mill access is reliable.',
    bestSeason: 'Kharif; irrigated Rabi in suitable areas',
    soilKeywords: ['clay', 'alluvial', 'laterite', 'loam', 'red'],
    goodWaterSources: ['canal', 'river', 'pond', 'tank', 'borewell', 'well'],
    minTemp: 20,
    maxTemp: 36,
    minPh: 5.5,
    maxPh: 7.5,
  ),
  _CropAdvisorFacts(
    name: 'Wheat',
    aliases: ['gehun'],
    suitableRegions:
        'Punjab, Haryana, Uttar Pradesh, Madhya Pradesh, Rajasthan, Bihar, and cooler irrigated belts.',
    climateWindow: 'Cool 15-26 C growing window with dry harvest weather.',
    soilPreference: 'Well-drained loam, clay loam, or alluvial soil.',
    waterNeed: 'Medium water need',
    cropCycle: '110-140 days',
    harvestMethod:
        'Harvest when spikes are dry and grain is hard, then thresh promptly to avoid shattering.',
    marketPriceRange: 'Indicative wheat price: INR 2,200-2,500 per qtl.',
    inputCostPerHa: 'Typical input cost: INR 45,000-65,000 per ha.',
    expectedYieldPerHa: 'Expected yield: 3.5-5.5 t per ha.',
    roiSummary:
        'Good ROI in cool Rabi regions with irrigation and nearby procurement.',
    bestSeason: 'Rabi',
    soilKeywords: ['loam', 'alluvial', 'clay', 'black'],
    goodWaterSources: ['canal', 'borewell', 'well', 'river'],
    minTemp: 10,
    maxTemp: 28,
    minPh: 6.0,
    maxPh: 7.8,
  ),
  _CropAdvisorFacts(
    name: 'Cotton',
    aliases: ['kapas'],
    suitableRegions:
        'Maharashtra, Gujarat, Telangana, Karnataka, Andhra Pradesh, Madhya Pradesh, and black soil belts.',
    climateWindow:
        'Warm 21-35 C climate with bright sun and moderate rainfall.',
    soilPreference: 'Deep black cotton soil or well-drained loam.',
    waterNeed: 'Medium water need',
    cropCycle: '160-190 days',
    harvestMethod:
        'Pick fully opened bolls in multiple rounds, keep kapas dry, and avoid mixing stained lint.',
    marketPriceRange: 'Indicative kapas price: INR 6,000-7,400 per qtl.',
    inputCostPerHa: 'Typical input cost: INR 70,000-95,000 per ha.',
    expectedYieldPerHa: 'Expected yield: 1.5-2.8 t per ha.',
    roiSummary:
        'High upside but higher pest and input risk. ROI improves with drip irrigation and timely bollworm scouting.',
    bestSeason: 'Kharif',
    soilKeywords: ['black', 'cotton', 'loam', 'alluvial'],
    goodWaterSources: ['drip', 'borewell', 'well', 'canal'],
    minTemp: 21,
    maxTemp: 37,
    minPh: 6.0,
    maxPh: 8.0,
  ),
  _CropAdvisorFacts(
    name: 'Maize',
    aliases: ['corn', 'makka'],
    suitableRegions:
        'Karnataka, Bihar, Telangana, Andhra Pradesh, Maharashtra, Madhya Pradesh, and irrigated uplands.',
    climateWindow: 'Warm 18-32 C climate with good drainage.',
    soilPreference: 'Fertile loam, red loam, or well-drained alluvial soil.',
    waterNeed: 'Medium water need',
    cropCycle: '90-120 days',
    harvestMethod:
        'Harvest cobs when husk dries and grain is hard, then dry before shelling.',
    marketPriceRange: 'Indicative maize price: INR 1,900-2,300 per qtl.',
    inputCostPerHa: 'Typical input cost: INR 40,000-60,000 per ha.',
    expectedYieldPerHa: 'Expected yield: 4-7 t per ha.',
    roiSummary:
        'Good ROI where poultry feed or starch buyers are nearby and water stress is controlled.',
    bestSeason: 'Kharif or irrigated Rabi',
    soilKeywords: ['loam', 'red', 'alluvial', 'black'],
    goodWaterSources: ['borewell', 'well', 'canal', 'rain_only'],
    minTemp: 18,
    maxTemp: 34,
    minPh: 5.8,
    maxPh: 7.8,
  ),
  _CropAdvisorFacts(
    name: 'Banana',
    aliases: ['plantain', 'nendran'],
    suitableRegions:
        'Kerala, Tamil Nadu, Karnataka, Maharashtra, Andhra Pradesh, Gujarat, and humid irrigated belts.',
    climateWindow: 'Humid 24-34 C climate with wind protection.',
    soilPreference:
        'Deep fertile loam, laterite loam, or alluvial soil with drainage.',
    waterNeed: 'High water need',
    cropCycle: '10-14 months',
    harvestMethod:
        'Harvest mature bunches when fingers are full and angularity reduces, then handle gently.',
    marketPriceRange: 'Indicative farmgate price: INR 12-35 per kg by variety.',
    inputCostPerHa: 'Typical input cost: INR 1.8-3.0 lakh per ha.',
    expectedYieldPerHa: 'Expected yield: 35-60 t per ha.',
    roiSummary:
        'High ROI potential with drip, disease-free suckers, staking, and steady market access.',
    bestSeason: 'Year-round with irrigation',
    soilKeywords: ['loam', 'laterite', 'alluvial', 'red'],
    goodWaterSources: ['drip', 'borewell', 'well', 'canal', 'river'],
    minTemp: 20,
    maxTemp: 36,
    minPh: 6.0,
    maxPh: 7.5,
  ),
  _CropAdvisorFacts(
    name: 'Coconut',
    aliases: ['copra', 'thenga'],
    suitableRegions:
        'Kerala, coastal Karnataka, Tamil Nadu, Andhra Pradesh, Odisha coast, and humid coastal belts.',
    climateWindow: 'Humid tropical 24-32 C climate with low frost risk.',
    soilPreference:
        'Well-drained sandy loam, laterite, alluvial, or coastal soil.',
    waterNeed: 'Medium-high water need',
    cropCycle: 'Perennial crop',
    harvestMethod:
        'Harvest mature nuts every 45-60 days; use trained climbers or safe harvest tools.',
    marketPriceRange:
        'Indicative coconut price: INR 25-45 per nut or local copra rate.',
    inputCostPerHa: 'Typical annual upkeep: INR 45,000-80,000 per ha.',
    expectedYieldPerHa: 'Expected yield: 8,000-14,000 nuts per ha yearly.',
    roiSummary:
        'Long-term steady ROI, strongest where intercropping and local processing are possible.',
    bestSeason: 'Perennial',
    soilKeywords: ['sandy', 'laterite', 'alluvial', 'loam', 'coastal', 'red'],
    goodWaterSources: ['well', 'borewell', 'canal', 'pond', 'tank'],
    minTemp: 20,
    maxTemp: 35,
    minPh: 5.2,
    maxPh: 8.0,
  ),
  _CropAdvisorFacts(
    name: 'Groundnut',
    aliases: ['peanut'],
    suitableRegions:
        'Gujarat, Andhra Pradesh, Tamil Nadu, Karnataka, Rajasthan, and light soil rainfed belts.',
    climateWindow: 'Warm 22-32 C climate with dry harvest window.',
    soilPreference: 'Sandy loam or red loam that lets pods develop easily.',
    waterNeed: 'Low-medium water need',
    cropCycle: '100-120 days',
    harvestMethod:
        'Lift plants when leaves yellow and pods mature, then dry pods before stripping.',
    marketPriceRange: 'Indicative groundnut price: INR 5,500-7,200 per qtl.',
    inputCostPerHa: 'Typical input cost: INR 45,000-70,000 per ha.',
    expectedYieldPerHa: 'Expected yield: 1.5-2.8 t per ha.',
    roiSummary: 'Good ROI in light soils; avoid heavy clay and waterlogging.',
    bestSeason: 'Kharif; summer with irrigation',
    soilKeywords: ['sandy', 'red', 'loam', 'laterite'],
    goodWaterSources: ['rain_only', 'well', 'borewell', 'canal'],
    minTemp: 20,
    maxTemp: 35,
    minPh: 6.0,
    maxPh: 7.8,
  ),
  _CropAdvisorFacts(
    name: 'Dragon Fruit',
    aliases: ['pitaya', 'pitahaya'],
    suitableRegions:
        'Warm, dry-to-subhumid belts with excellent drainage; works in parts of Maharashtra, Gujarat, Karnataka, Telangana, Tamil Nadu, Andhra Pradesh, and selected raised-bed Kerala plots.',
    climateWindow:
        'Warm 20-34 C climate. Avoid standing water, prolonged wet spells, and humid pockets without airflow.',
    soilPreference:
        'Very well-drained sandy loam, red loam, or raised laterite beds with pH 5.5-7.0.',
    waterNeed: 'Low-medium water need with controlled drip',
    cropCycle: '12-18 months to first commercial harvest',
    harvestMethod:
        'Harvest fully colored fruits by hand, grade carefully, and move quickly to premium buyers.',
    marketPriceRange:
        'Indicative price: INR 60-150 per kg depending on grade and buyer access.',
    inputCostPerHa:
        'Typical setup cost is high because support posts, wire, drip, and planting material are required.',
    expectedYieldPerHa:
        'Yield builds gradually after establishment; verify local variety and spacing before scaling.',
    roiSummary:
        'Premium upside, but risky for new farmers without drainage, support structure, and assured buyers.',
    bestSeason:
        'Plant after peak heavy-rain season, or use raised beds and drainage before monsoon',
    soilKeywords: ['sandy', 'red', 'loam', 'laterite'],
    goodWaterSources: ['drip', 'well', 'borewell'],
    minTemp: 20,
    maxTemp: 34,
    minPh: 5.5,
    maxPh: 7.0,
  ),
  _CropAdvisorFacts(
    name: 'Tomato',
    aliases: ['tamatar'],
    suitableRegions:
        'Most Indian vegetable belts with irrigation, especially Karnataka, Maharashtra, Andhra Pradesh, and Tamil Nadu.',
    climateWindow:
        'Mild 18-30 C window; heat and heavy rain raise disease risk.',
    soilPreference: 'Well-drained loam rich in organic matter.',
    waterNeed: 'Medium water need',
    cropCycle: '90-120 days',
    harvestMethod:
        'Pick at mature green to breaker stage for market transport, or red ripe for local sale.',
    marketPriceRange:
        'Indicative price: INR 800-2,500 per qtl; highly volatile.',
    inputCostPerHa: 'Typical input cost: INR 1.2-2.2 lakh per ha.',
    expectedYieldPerHa: 'Expected yield: 25-60 t per ha.',
    roiSummary:
        'Very price-sensitive. ROI can be excellent with staking, drip, and nearby market timing.',
    bestSeason: 'Rabi and mild summer windows',
    soilKeywords: ['loam', 'red', 'alluvial', 'sandy'],
    goodWaterSources: ['drip', 'well', 'borewell', 'canal'],
    minTemp: 16,
    maxTemp: 32,
    minPh: 6.0,
    maxPh: 7.5,
  ),
  _CropAdvisorFacts(
    name: 'Onion',
    aliases: ['pyaz'],
    suitableRegions:
        'Maharashtra, Karnataka, Gujarat, Madhya Pradesh, Rajasthan, and dry irrigated vegetable belts.',
    climateWindow: 'Mild 15-30 C climate with dry bulb maturity period.',
    soilPreference: 'Well-drained sandy loam or loam.',
    waterNeed: 'Medium water need',
    cropCycle: '120-150 days',
    harvestMethod:
        'Harvest after neck fall, cure bulbs in shade, then grade before sale.',
    marketPriceRange:
        'Indicative onion price: INR 1,200-3,000 per qtl; volatile.',
    inputCostPerHa: 'Typical input cost: INR 90,000-1.6 lakh per ha.',
    expectedYieldPerHa: 'Expected yield: 20-35 t per ha.',
    roiSummary:
        'Good ROI when storage and market timing are available; rain at harvest is a major risk.',
    bestSeason: 'Rabi; Kharif in suitable regions',
    soilKeywords: ['sandy', 'loam', 'red', 'alluvial'],
    goodWaterSources: ['drip', 'well', 'borewell', 'canal'],
    minTemp: 13,
    maxTemp: 32,
    minPh: 6.0,
    maxPh: 7.5,
  ),
  _CropAdvisorFacts(
    name: 'Turmeric',
    aliases: ['haldi', 'manjal'],
    suitableRegions:
        'Telangana, Maharashtra, Tamil Nadu, Karnataka, Kerala, Odisha, and humid well-drained belts.',
    climateWindow: 'Warm humid 20-34 C climate with partial shade possible.',
    soilPreference:
        'Well-drained loam or red/laterite soil rich in organic matter.',
    waterNeed: 'Medium-high water need',
    cropCycle: '7-9 months',
    harvestMethod:
        'Harvest when leaves dry, boil rhizomes, dry well, then polish for market.',
    marketPriceRange: 'Indicative turmeric price: INR 7,000-12,000 per qtl.',
    inputCostPerHa: 'Typical input cost: INR 1.2-2.0 lakh per ha.',
    expectedYieldPerHa: 'Expected yield: 20-30 t fresh rhizome per ha.',
    roiSummary:
        'Strong ROI when seed rhizome quality, curing, and storage are managed well.',
    bestSeason: 'Kharif planting',
    soilKeywords: ['loam', 'red', 'laterite', 'alluvial'],
    goodWaterSources: ['well', 'borewell', 'canal', 'pond', 'tank'],
    minTemp: 18,
    maxTemp: 35,
    minPh: 5.5,
    maxPh: 7.5,
  ),
];

_CropAdvisorFacts _cropFactsFor(String cropName) {
  final clean = cropName.trim().toLowerCase();
  for (final facts in _cropKnowledgeBase) {
    if (facts.name.toLowerCase() == clean ||
        facts.aliases.any((alias) => alias.toLowerCase() == clean)) {
      return facts;
    }
  }
  return _CropAdvisorFacts(
    name: _titleCaseCrop(cropName.trim().isEmpty ? 'Crop' : cropName),
    aliases: const [],
    suitableRegions:
        'Best suitability depends on local climate, soil, irrigation, and nearby market demand.',
    climateWindow:
        'Check that the crop temperature window matches the next 3-4 months.',
    soilPreference:
        'Prefer healthy, well-drained soil with pH near 6.0-7.5 unless the crop has special needs.',
    waterNeed: 'Needs verified water plan',
    cropCycle: 'Cycle varies by variety',
    harvestMethod:
        'Harvest at crop maturity using local extension guidance for the selected variety.',
    marketPriceRange:
        'Local price varies. Use nearby mandi rate before committing area.',
    inputCostPerHa:
        'Input cost depends on seed, irrigation, fertilizer, and labor.',
    expectedYieldPerHa:
        'Expected yield depends on variety, spacing, water, and pest control.',
    roiSummary:
        'ROI should be checked against local mandi price, input cost, and yield risk.',
    bestSeason: 'Confirm with local crop calendar',
    soilKeywords: const ['loam', 'alluvial', 'red', 'black', 'laterite'],
    goodWaterSources: const ['well', 'borewell', 'canal', 'river', 'rain_only'],
    minTemp: 18,
    maxTemp: 34,
    minPh: 6.0,
    maxPh: 7.5,
  );
}

_CropFitEvaluation _evaluateCropForFarm({
  required _CropAdvisorFacts facts,
  required Farmland farm,
  required WeatherForecast? weather,
  required double? userLat,
}) {
  final isGeneric = facts.aliases.isEmpty &&
      facts.suitableRegions.startsWith('Best suitability depends');
  final cropName = facts.name.toLowerCase();
  var score = isGeneric ? 38.0 : 50.0;
  final reasons = <String>[];
  final soil = (farm.soilType ?? '').toLowerCase();
  final irrigation = (farm.irrigationType ?? '').toLowerCase();
  final waterSource = (farm.waterSource ?? '').toLowerCase();
  final terrain = (farm.terrainType ?? '').toLowerCase();
  final waterNeed = facts.waterNeed.toLowerCase();

  if (soil.isEmpty || soil == 'unknown') {
    reasons.add('Soil type is not set, so confidence is limited.');
  } else if (facts.soilKeywords.any(soil.contains)) {
    score += isGeneric ? 8 : 16;
    reasons
        .add('${enumLabel(farm.soilType)} soil matches the crop preference.');
  } else {
    score -= isGeneric ? 4 : 10;
    reasons.add(
        '${enumLabel(farm.soilType)} soil may need amendment or testing first.');
  }

  if (farm.soilPH != null) {
    if (farm.soilPH! >= facts.minPh && farm.soilPH! <= facts.maxPh) {
      score += isGeneric ? 5 : 10;
      reasons.add('Soil pH ${farm.soilPH!.toStringAsFixed(1)} is in range.');
    } else {
      score -= isGeneric ? 6 : 10;
      reasons.add(
          'Soil pH ${farm.soilPH!.toStringAsFixed(1)} is outside the preferred range.');
    }
  }

  final waterText = '$irrigation $waterSource';
  final waterMatches = facts.goodWaterSources.any(waterText.contains) ||
      irrigation.contains('drip');
  if (waterNeed.contains('high') && waterText.contains('rain_only')) {
    score -= 12;
    reasons.add('High water demand is risky with rain-only water.');
  } else if (waterMatches) {
    score += waterNeed.contains('low') ? 7 : 10;
    reasons.add('Water setup looks workable for this crop.');
  } else if (waterText.trim().isEmpty && !isGeneric) {
    score -= waterNeed.contains('high') ? 8 : 4;
    reasons.add('Irrigation and water source are not set yet.');
  }

  if (terrain.contains('flat') || terrain.contains('gentle')) {
    score += 5;
  } else if (terrain.contains('hilly') &&
      ['Rice', 'Onion', 'Tomato'].contains(facts.name)) {
    score -= 5;
  }

  final weeklyRain = _weeklyRainTotal(weather);
  if (weeklyRain != null) {
    final rainSensitive =
        ['dragon fruit', 'tomato', 'onion', 'groundnut'].contains(cropName);
    if (rainSensitive && weeklyRain >= 45) {
      score -= cropName == 'dragon fruit' ? 14 : 8;
      reasons.add(
          '${weeklyRain.toStringAsFixed(0)} mm rain this week raises drainage and fungal risk.');
    } else if (waterNeed.contains('high') && weeklyRain < 10 && !waterMatches) {
      score -= 6;
      reasons.add('Low rain means irrigation must be planned before planting.');
    }
  }

  final avgHigh = _averageHigh(weather);
  if (avgHigh != null) {
    if (avgHigh >= facts.minTemp && avgHigh <= facts.maxTemp) {
      score += isGeneric ? 6 : 10;
      reasons.add('Current temperature window fits the crop.');
    } else {
      score -= isGeneric ? 5 : 9;
      reasons.add('Current temperature is not ideal, so timing matters.');
    }
  }

  if (cropName == 'dragon fruit') {
    if (!irrigation.contains('drip')) {
      score -= 5;
      reasons.add('Dragon fruit needs controlled drip and support posts.');
    }
    if (terrain.isEmpty) {
      score -= 4;
      reasons.add('Drainage or terrain is not set, so suitability is reduced.');
    } else if (terrain.contains('valley') || terrain.contains('low')) {
      score -= 8;
      reasons
          .add('Low terrain can hold water, which is risky for dragon fruit.');
    }
  }

  if (farm.boundaryPoints.length >= 3) {
    score += 5;
  } else {
    score -= 3;
    reasons.add('Map the boundary for better area and ROI estimates.');
  }

  if ((farm.previousCrop ?? '').toLowerCase() == facts.name.toLowerCase()) {
    score -= 4;
    reasons.add('Same previous crop may increase pest and nutrient pressure.');
  }

  if (userLat != null && facts.name == 'Wheat' && userLat < 14) {
    score -= 8;
    reasons
        .add('Low-latitude warm regions need a careful Rabi window for wheat.');
  }

  if (isGeneric) {
    reasons.add(
        'This crop is not in the local crop library yet, so the score stays conservative.');
  }

  final area = estimateAreaHectares(farm.boundaryPoints);
  final areaText =
      area > 0 ? '${area.toStringAsFixed(2)} ha mapped' : 'area not mapped';
  final reason = [
    if (reasons.isNotEmpty) reasons.take(4).join(' '),
    'Use this with $areaText, ${farm.nearestMarket ?? 'nearest market not set'}, and current mandi price before planting.',
  ].join(' ');

  return _CropFitEvaluation(
    farm: farm,
    score: score.clamp(5, isGeneric ? 72 : 96).toDouble(),
    reason: reason,
  );
}

String _titleCaseCrop(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part.length == 1
          ? part.toUpperCase()
          : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _friendlyInlineError(Object error) {
  return '$error'
      .replaceFirst('Exception: ', '')
      .replaceFirst('Bad state: ', '');
}

String? _profileCoordinateLabel(AppState state) {
  if (state.userLat == null || state.userLng == null) return null;
  return 'Lat ${state.userLat!.toStringAsFixed(3)}, Lng ${state.userLng!.toStringAsFixed(3)}';
}

const _indianStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Delhi',
  'Jammu and Kashmir',
  'Ladakh',
  'Puducherry',
];

String? _compactLocationLabel(String? locationName) {
  final clean = locationName?.split(',').first.trim();
  if (clean == null || clean.isEmpty) return null;
  return _titleCaseCrop(clean);
}

String? _districtFromLocationName(String? locationName) {
  final first = locationName?.split(',').first.trim();
  if (first == null || first.isEmpty) return null;
  final lower = first.toLowerCase();
  if (lower == 'india' || _indianStates.any((s) => s.toLowerCase() == lower)) {
    return null;
  }
  return _titleCaseCrop(first);
}

String? _stateFromLocationName(String? locationName) {
  final lower = locationName?.toLowerCase() ?? '';
  for (final state in _indianStates) {
    if (lower.contains(state.toLowerCase())) return state;
  }
  return null;
}

String? _primarySoil(List<Farmland> farms) {
  final counts = <String, int>{};
  for (final farm in farms) {
    final soil = farm.soilType?.trim();
    if (soil == null || soil.isEmpty || soil.toLowerCase() == 'unknown') {
      continue;
    }
    counts[soil] = (counts[soil] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

String _mandiCommodityForCrop(String crop) {
  final lower = crop.trim().toLowerCase();
  if (lower.contains('rice') || lower.contains('paddy')) {
    return 'Paddy(Dhan)(Common)';
  }
  if (lower.contains('moong')) return 'Green Gram (Moong)(Whole)';
  if (lower.contains('bajra')) return 'Bajra(Pearl Millet/Cumbu)';
  if (lower.contains('jowar')) return 'Jowar(Sorghum)';
  if (lower.contains('groundnut')) return 'Groundnut';
  if (lower.contains('coconut')) return 'Coconut';
  if (lower.contains('turmeric')) return 'Turmeric';
  if (lower.contains('banana')) return 'Banana';
  if (lower.contains('cotton')) return 'Cotton';
  if (lower.contains('maize')) return 'Maize';
  if (lower.contains('wheat')) return 'Wheat';
  if (lower.contains('tomato')) return 'Tomato';
  if (lower.contains('onion')) return 'Onion';
  return _titleCaseCrop(crop);
}

String _formatInr(double value) {
  return 'INR ${NumberFormat.decimalPattern('en_IN').format(value.round())}/qtl';
}

double _parseMoney(String value) {
  return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
}

String _formatOfferPrice(double qtlPrice, _OfferUnit unit) {
  if (unit == _OfferUnit.kg) {
    final kgPrice = qtlPrice / 100;
    return 'INR ${kgPrice.toStringAsFixed(1)}/kg';
  }
  return _formatInr(qtlPrice);
}

Farmland? _connectedFarmForCrop(String crop, List<Farmland> farms) {
  final clean = crop.toLowerCase();
  for (final farm in farms) {
    for (final item in farm.crops) {
      final name = item.name.toLowerCase();
      if (name.contains(clean) || clean.contains(name)) return farm;
    }
  }
  return farms.isEmpty ? null : farms.first;
}

List<MandiPriceRecord> _fallbackMandiRecords(String commodity, String? state) {
  final stateName = state ?? 'India';
  final date = DateFormat('dd/MM/yyyy').format(DateTime.now());
  final base = _fallbackModalPrice(commodity);
  final markets = stateName == 'Kerala'
      ? const [
          ('Kannur VFPCK', 'Kannur', 1.04),
          ('Kozhikode APMC', 'Kozhikode', 0.96),
          ('Perumbavoor APMC', 'Ernakulam', 1.12),
          ('Kottayam APMC', 'Kottayam', 0.9),
        ]
      : const [
          ('Regional APMC', 'Local District', 1.0),
          ('City Wholesale Market', 'Nearby District', 1.12),
          ('Primary Mandi', 'Main District', 0.94),
          ('Terminal Market', 'Metro District', 1.18),
        ];
  return markets
      .map(
        (item) => MandiPriceRecord(
          state: stateName,
          district: item.$2,
          market: item.$1,
          commodity: commodity,
          variety: 'FAQ',
          grade: 'FAQ',
          arrivalDate: date,
          minPrice: base * item.$3 * 0.92,
          maxPrice: base * item.$3 * 1.08,
          modalPrice: base * item.$3,
        ),
      )
      .toList();
}

double _fallbackModalPrice(String commodity) {
  final lower = commodity.toLowerCase();
  if (lower.contains('banana')) return 3800;
  if (lower.contains('coconut')) return 3200;
  if (lower.contains('turmeric')) return 9000;
  if (lower.contains('groundnut')) return 6200;
  if (lower.contains('tomato')) return 1800;
  if (lower.contains('onion')) return 2200;
  if (lower.contains('wheat')) return 2400;
  if (lower.contains('paddy')) return 2300;
  return 3000;
}

double? _weeklyRainTotal(WeatherForecast? weather) {
  final rain = weather?.daily.precipitation;
  if (rain == null || rain.isEmpty) return null;
  return rain.fold<double>(0, (sum, value) => sum + value);
}

bool _isCoastalKeralaLocation(String? locationName, double? userLat) {
  final lower = locationName?.toLowerCase() ?? '';
  if (lower.contains('kannur') ||
      lower.contains('kozhikode') ||
      lower.contains('calicut') ||
      lower.contains('wayanad') ||
      lower.contains('malappuram') ||
      lower.contains('thrissur') ||
      lower.contains('ernakulam') ||
      lower.contains('kochi') ||
      lower.contains('alappuzha') ||
      lower.contains('kollam') ||
      lower.contains('kerala')) {
    return true;
  }
  return userLat != null && userLat >= 8 && userLat <= 13;
}

bool _isDryInteriorLocation(String? locationName, double? userLat) {
  final lower = locationName?.toLowerCase() ?? '';
  if (lower.contains('rajasthan') ||
      lower.contains('gujarat') ||
      lower.contains('vidarbha') ||
      lower.contains('marathwada') ||
      lower.contains('telangana') ||
      lower.contains('rayalaseema')) {
    return true;
  }
  return userLat != null && userLat >= 16 && userLat <= 29;
}

double? _averageHigh(WeatherForecast? weather) {
  final highs = weather?.daily.maxTemp;
  if (highs == null || highs.isEmpty) return null;
  return highs.reduce((a, b) => a + b) / highs.length;
}

String _averageHighLabel(WeatherForecast? weather) {
  final avg = _averageHigh(weather);
  if (avg == null) return 'No weather';
  return '${avg.toStringAsFixed(0)} C';
}

String _weeklyRainLabel(WeatherForecast? weather) {
  final rain = weather?.daily.precipitation;
  if (rain == null || rain.isEmpty) return 'No data';
  final total = rain.fold<double>(0, (sum, value) => sum + value);
  return '${total.toStringAsFixed(0)} mm';
}

String _weatherCycleLabel(WeatherForecast? weather) {
  final rain = weather?.daily.precipitation;
  final avg = _averageHigh(weather);
  if (rain == null || rain.isEmpty || avg == null) return 'Pending';
  final total = rain.fold<double>(0, (sum, value) => sum + value);
  if (total >= 45) return 'Wet week';
  if (avg >= 34) return 'Hot week';
  if (total <= 5) return 'Dry week';
  return 'Balanced';
}

String _weatherFitForCrop(_CropAdvisorFacts facts, WeatherForecast? weather) {
  final avgHigh = _averageHigh(weather);
  if (avgHigh == null) {
    return 'Weather fit will update after the profile location weather loads.';
  }
  final rain = weather?.daily.precipitation
          ?.fold<double>(0, (sum, value) => sum + value) ??
      0;
  final tempFit = avgHigh >= facts.minTemp && avgHigh <= facts.maxTemp;
  final waterSignal =
      facts.waterNeed.toLowerCase().contains('high') && rain < 15
          ? 'Plan irrigation before planting.'
          : rain > 60
              ? 'Watch drainage and fungal risk this week.'
              : 'Weather cycle is manageable with normal scouting.';
  return tempFit
      ? '${facts.name} fits the current ${avgHigh.toStringAsFixed(0)} C average-high window. $waterSignal'
      : '${facts.name} prefers ${facts.minTemp.toStringAsFixed(0)}-${facts.maxTemp.toStringAsFixed(0)} C, while this week averages ${avgHigh.toStringAsFixed(0)} C. $waterSignal';
}

Color _riskColor(String value) {
  switch (value.toLowerCase()) {
    case 'red':
      return const Color(0xFFD83A34);
    case 'orange':
      return const Color(0xFFD67A00);
    case 'yellow':
      return const Color(0xFFB58B00);
    default:
      return const Color(0xFF108A62);
  }
}

Color _severityColor(String value, ColorScheme colors) {
  switch (value.toLowerCase()) {
    case 'high':
      return colors.error;
    case 'moderate':
      return colors.tertiary;
    case 'low':
      return colors.primary;
    default:
      return colors.onSurfaceVariant;
  }
}

String _weatherSummary(WeatherForecast? weather) {
  if (weather == null) {
    return 'Loading hyperlocal weather. Cached farm report is ready below.';
  }
  final highs = weather.daily.maxTemp;
  final lows = weather.daily.minTemp;
  if (highs.isEmpty || lows.isEmpty) return 'Weather is partially available.';
  final avgHigh = highs.reduce((a, b) => a + b) / highs.length;
  final avgLow = lows.reduce((a, b) => a + b) / lows.length;
  final rain =
      weather.daily.precipitation?.take(3).fold<double>(0, (a, b) => a + b) ??
          0;
  if (rain >= 20) {
    return 'Average ${avgHigh.toStringAsFixed(0)} C/${avgLow.toStringAsFixed(0)} C. Rain is likely soon, so delay irrigation.';
  }
  return 'Average ${avgHigh.toStringAsFixed(0)} C/${avgLow.toStringAsFixed(0)} C. Verify soil moisture before irrigation.';
}

LatLng? _centroid(List<BoundaryPoint> points) {
  if (points.isEmpty) return null;
  final lat = points.map((e) => e.lat).reduce((a, b) => a + b) / points.length;
  final lng = points.map((e) => e.lng).reduce((a, b) => a + b) / points.length;
  return LatLng(lat, lng);
}

BoundaryPoint _midpoint(BoundaryPoint a, BoundaryPoint b) {
  return BoundaryPoint(lat: (a.lat + b.lat) / 2, lng: (a.lng + b.lng) / 2);
}

double _distanceMeters(BoundaryPoint a, BoundaryPoint b) {
  const earthRadius = 6371000.0;
  final dLat = (b.lat - a.lat) * pi / 180;
  final dLng = (b.lng - a.lng) * pi / 180;
  final lat1 = a.lat * pi / 180;
  final lat2 = b.lat * pi / 180;
  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * earthRadius * asin(sqrt(h));
}

List<BoundaryPoint> _simplifyBoundary(
  List<BoundaryPoint> points, {
  required double toleranceMeters,
}) {
  if (points.length <= 3) return points;

  double perpendicularDistance(
    BoundaryPoint point,
    BoundaryPoint start,
    BoundaryPoint end,
  ) {
    final originLat = start.lat * pi / 180;
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLng = 111320.0 * cos(originLat);
    final px = (point.lng - start.lng) * metersPerDegreeLng;
    final py = (point.lat - start.lat) * metersPerDegreeLat;
    final ex = (end.lng - start.lng) * metersPerDegreeLng;
    final ey = (end.lat - start.lat) * metersPerDegreeLat;
    final lengthSquared = ex * ex + ey * ey;
    if (lengthSquared == 0) return sqrt(px * px + py * py);
    final t = ((px * ex + py * ey) / lengthSquared).clamp(0.0, 1.0);
    final dx = px - ex * t;
    final dy = py - ey * t;
    return sqrt(dx * dx + dy * dy);
  }

  List<BoundaryPoint> simplifySegment(List<BoundaryPoint> segment) {
    if (segment.length <= 2) return segment;
    var maxDistance = 0.0;
    var index = 0;
    for (var i = 1; i < segment.length - 1; i++) {
      final distance =
          perpendicularDistance(segment[i], segment.first, segment.last);
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }
    if (maxDistance <= toleranceMeters) {
      return [segment.first, segment.last];
    }
    final left = simplifySegment(segment.sublist(0, index + 1));
    final right = simplifySegment(segment.sublist(index));
    return [...left.sublist(0, left.length - 1), ...right];
  }

  return simplifySegment(points);
}

List<LatLng> _circleBoundary(LatLng center, double radiusMeters) {
  const segments = 48;
  return List.generate(segments, (index) {
    final angle = 2 * pi * index / segments;
    return _offset(
      center,
      cos(angle) * radiusMeters,
      sin(angle) * radiusMeters,
    );
  });
}

LatLngBounds _boundsForBoundary(
  List<BoundaryPoint> points, {
  double padding = 0,
}) {
  var minLat = points.first.lat;
  var maxLat = points.first.lat;
  var minLng = points.first.lng;
  var maxLng = points.first.lng;
  for (final point in points.skip(1)) {
    minLat = min(minLat, point.lat);
    maxLat = max(maxLat, point.lat);
    minLng = min(minLng, point.lng);
    maxLng = max(maxLng, point.lng);
  }
  return LatLngBounds(
    southwest: LatLng(minLat - padding, minLng - padding),
    northeast: LatLng(maxLat + padding, maxLng + padding),
  );
}

List<BoundaryPoint> _starterBoundary(LatLng center, double accuracy) {
  final allowance = accuracy.clamp(8, 35).toDouble();
  final halfWidth = 30 + allowance;
  final halfHeight = 22 + allowance * 0.65;
  return [
    _offset(center, halfHeight, -halfWidth),
    _offset(center, halfHeight, halfWidth),
    _offset(center, -halfHeight, halfWidth),
    _offset(center, -halfHeight, -halfWidth),
  ].map((e) => BoundaryPoint(lat: e.latitude, lng: e.longitude)).toList();
}

LatLng _offset(LatLng center, double northMeters, double eastMeters) {
  const metersPerDegreeLat = 111320.0;
  final metersPerDegreeLng = 111320.0 * cos(center.latitude * pi / 180);
  return LatLng(
    center.latitude + northMeters / metersPerDegreeLat,
    center.longitude + eastMeters / metersPerDegreeLng,
  );
}
