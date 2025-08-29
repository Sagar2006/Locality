import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locality/services/auth_service.dart';
import 'package:locality/screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  String _loginError = '';
  String _registerError = '';
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _loginError = '';
      });
      try {
        await _authService.signInWithEmailAndPassword(
          _loginEmailController.text.trim(),
          _loginPasswordController.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _loginError = e.message ?? 'Failed to sign in';
        });
      } catch (e) {
        setState(() {
          _loginError = e.toString();
        });
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    if (_registerFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _registerError = '';
      });
      try {
        final credential = await _authService.registerWithEmailAndPassword(
          _registerEmailController.text.trim(),
          _registerPasswordController.text.trim(),
        );
        await _authService.createUserInDatabase(
          credential,
          _registerNameController.text.trim(),
          '',
          '',
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _registerError = e.message ?? 'Failed to register';
        });
      } catch (e) {
        setState(() {
          _registerError = e.toString();
        });
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, child) {
          final t = _tabController.animation!.value;
          final Color begin = const Color(0xFF6C63FF);
          final Color end = const Color(0xFF2196F3);
          final Color bg = Color.lerp(begin, end, t) ?? begin;
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg.withOpacity(0.12), Colors.white],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  // Animated/abstract widget placeholder
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(24 + 24 * t),
                      boxShadow: [
                        BoxShadow(
                          color: bg.withOpacity(0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(Icons.bubble_chart, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 48),
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: bg,
                    labelColor: bg,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Register'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Login Form
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Form(
                            key: _loginFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Material(
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(16),
                                  child: TextFormField(
                                    controller: _loginEmailController,
                                    decoration: InputDecoration(
                                      labelText: 'Email address',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                    ),
                                    style: const TextStyle(fontSize: 18),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!value.contains('@') || !value.contains('.')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Material(
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(16),
                                  child: TextFormField(
                                    controller: _loginPasswordController,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                    ),
                                    style: const TextStyle(fontSize: 18),
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 32),
                                if (_loginError.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Text(
                                      _loginError,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: bg,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text('Login'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Register Form
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Form(
                            key: _registerFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Material(
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(16),
                                  child: TextFormField(
                                    controller: _registerNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Full Name',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                    ),
                                    style: const TextStyle(fontSize: 18),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Material(
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(16),
                                  child: TextFormField(
                                    controller: _registerEmailController,
                                    decoration: InputDecoration(
                                      labelText: 'Email address',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                    ),
                                    style: const TextStyle(fontSize: 18),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!value.contains('@') || !value.contains('.')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Material(
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(16),
                                  child: TextFormField(
                                    controller: _registerPasswordController,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                    ),
                                    style: const TextStyle(fontSize: 18),
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 32),
                                if (_registerError.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Text(
                                      _registerError,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: bg,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text('Register'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0, top: 16),
                    child: RichText(
                      text: TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(color: bg, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
