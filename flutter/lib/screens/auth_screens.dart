import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPLASH SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final state = context.read<AppState>();
    await state.tryAutoLogin();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      state.isLoggedIn ? '/home' : '/login',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PPNColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: PPNColors.accent,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: PPNColors.accent.withOpacity(0.5),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.hub_rounded, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ConnectPath',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Proximity Professional Network',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: PPNColors.accent.withOpacity(0.8),
                    strokeWidth: 2.5,
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

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  bool _loading    = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppState>().login(_emailCtrl.text.trim(), _passCtrl.text);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PPNColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 56, 32, 40),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: PPNColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.hub_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to your ConnectPath account',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                    ),
                  ],
                ),
              ),

              // ── Form card ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                decoration: const BoxDecoration(
                  color: PPNColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: PPNColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: PPNColors.danger.withOpacity(0.3)),
                          ),
                          child: Text(_error!,
                              style: const TextStyle(color: PPNColors.danger, fontSize: 13)),
                        ),

                      _label('Email'),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'you@university.edu',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 16),

                      _label('Password'),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Min 6 characters' : null,
                      ),
                      const SizedBox(height: 28),

                      ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Sign In'),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ",
                              style: TextStyle(color: PPNColors.textMid)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, '/register'),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: PPNColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: PPNColors.textDark,
            fontSize: 14)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REGISTER SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _profCtrl    = TextEditingController();
  final _courseCtrl  = TextEditingController();
  final _deptCtrl    = TextEditingController();
  int? _gradYear;
  bool _obscure  = true;
  bool _loading  = false;
  String? _error;
  int _step      = 0; // 0 = account, 1 = profile

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _passCtrl, _profCtrl, _courseCtrl, _deptCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<AppState>().api;
      await api.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        name: _nameCtrl.text.trim(),
        profession: _profCtrl.text.trim().isEmpty ? null : _profCtrl.text.trim(),
        course: _courseCtrl.text.trim().isEmpty ? null : _courseCtrl.text.trim(),
        department: _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
        graduationYear: _gradYear,
      );
      await context.read<AppState>().login(
        _emailCtrl.text.trim(), _passCtrl.text);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PPNColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _step == 1
                            ? setState(() => _step = 0)
                            : Navigator.pushReplacementNamed(context, '/login'),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Create Account',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    _step == 0 ? 'Step 1 of 2 — Account details' : 'Step 2 of 2 — Your profile',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _step == 0 ? 0.5 : 1.0,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(PPNColors.accent),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // ── Form card ──
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: const BoxDecoration(
                  color: PPNColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: PPNColors.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: PPNColors.danger.withOpacity(0.3)),
                            ),
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: PPNColors.danger, fontSize: 13)),
                          ),

                        if (_step == 0) ..._buildStep0() else ..._buildStep1(),
                        const SizedBox(height: 28),

                        ElevatedButton(
                          onPressed: _loading
                              ? null
                              : _step == 0
                                  ? () {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() => _step = 1);
                                      }
                                    }
                                  : _register,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(_step == 0 ? 'Next' : 'Create Account'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account? ',
                                style: TextStyle(color: PPNColors.textMid)),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushReplacementNamed(context, '/login'),
                              child: const Text('Sign In',
                                  style: TextStyle(
                                      color: PPNColors.accent,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStep0() => [
    _label('Full Name'),
    TextFormField(
      controller: _nameCtrl,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
          hintText: 'Arjun Sharma', prefixIcon: Icon(Icons.person_outline)),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
    ),
    const SizedBox(height: 16),
    _label('Email'),
    TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
          hintText: 'you@university.edu', prefixIcon: Icon(Icons.email_outlined)),
      validator: (v) =>
          (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
    ),
    const SizedBox(height: 16),
    _label('Password'),
    TextFormField(
      controller: _passCtrl,
      obscureText: _obscure,
      decoration: InputDecoration(
        hintText: 'Min 6 characters',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (v) =>
          (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
    ),
  ];

  List<Widget> _buildStep1() => [
    _label('Profession / Role'),
    TextFormField(
      controller: _profCtrl,
      decoration: const InputDecoration(
          hintText: 'e.g. Full Stack Developer',
          prefixIcon: Icon(Icons.work_outline)),
    ),
    const SizedBox(height: 16),
    _label('Course / Degree'),
    TextFormField(
      controller: _courseCtrl,
      decoration: const InputDecoration(
          hintText: 'e.g. B.Tech Computer Science',
          prefixIcon: Icon(Icons.school_outlined)),
    ),
    const SizedBox(height: 16),
    _label('Department'),
    TextFormField(
      controller: _deptCtrl,
      decoration: const InputDecoration(
          hintText: 'e.g. Computer Science & Engineering',
          prefixIcon: Icon(Icons.apartment_outlined)),
    ),
    const SizedBox(height: 16),
    _label('Graduation Year (optional)'),
    TextFormField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
          hintText: 'e.g. 2026', prefixIcon: Icon(Icons.calendar_today_outlined)),
      onChanged: (v) => _gradYear = int.tryParse(v),
    ),
  ];

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: PPNColors.textDark,
            fontSize: 14)),
  );
}
