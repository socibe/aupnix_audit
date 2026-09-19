import 'dart:async';

import 'package:flutter/material.dart';
import 'screens/retailer_workspace_entry_screen.dart';
 import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'location_service.dart';
import 'screens/customer_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wsondyzropkzqougudgj.supabase.co',
    publishableKey: 'sb_publishable_04gOSOdDs1-CP5aO4iBtDA_7tf8w-Ic',
  );

  runApp(const AupnixApp());
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AupnixApp extends StatefulWidget {
  const AupnixApp({super.key});

  @override
  State<AupnixApp> createState() => _AupnixAppState();
}

class _AupnixAppState extends State<AupnixApp>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;

  bool _hasNavigatedToRoleSelection = false;
  bool _hasNavigatedToPasswordRecovery = false;
  bool _pendingRoleSelectionNavigation = false;
  bool _roleSelectionNavigationScheduled = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        debugPrint(
          'AUPNIX AUTH EVENT: ${data.event} | '
          'session=${data.session != null} | '
          'currentSession=${Supabase.instance.client.auth.currentSession != null}',
        );

        if (data.event == AuthChangeEvent.passwordRecovery) {
          debugPrint('AUPNIX AUTH: password recovery event received.');
          _navigateToPasswordRecovery();
          return;
        }

        if (data.event == AuthChangeEvent.signedIn) {
          debugPrint(
            'AUPNIX AUTH: signedIn received; '
            'navigator=${appNavigatorKey.currentState != null}',
          );

          _pendingRoleSelectionNavigation = true;
          _scheduleRoleSelectionNavigation();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('AUPNIX authentication state error: $error');
        debugPrint('AUPNIX authentication state stack: $stackTrace');
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _pendingRoleSelectionNavigation) {
      _scheduleRoleSelectionNavigation();
    }
  }

  void _navigateToPasswordRecovery() {
    if (_hasNavigatedToPasswordRecovery || !mounted) {
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return;
    }

    _hasNavigatedToPasswordRecovery = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      appNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const SetNewPasswordScreen(),
        ),
        (route) => false,
      );
    });
  }

  void _scheduleRoleSelectionNavigation() {
    if (!_pendingRoleSelectionNavigation ||
        _hasNavigatedToRoleSelection ||
        !mounted) {
      return;
    }

    if (_roleSelectionNavigationScheduled) {
      return;
    }

    _roleSelectionNavigationScheduled = true;

    // Explicitly request a Flutter frame after the OAuth/deep-link return.
    // This prevents navigation from waiting indefinitely for user interaction.
    WidgetsBinding.instance.ensureVisualUpdate();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _roleSelectionNavigationScheduled = false;

      if (!mounted ||
          !_pendingRoleSelectionNavigation ||
          _hasNavigatedToRoleSelection) {
        return;
      }

      _attemptRoleSelectionNavigation();
    });
  }

  void _attemptRoleSelectionNavigation() {
    if (!_pendingRoleSelectionNavigation ||
        _hasNavigatedToRoleSelection ||
        !mounted) {
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      _retryRoleSelectionNavigation();
      return;
    }

    final navigator = appNavigatorKey.currentState;

    if (navigator == null) {
      _retryRoleSelectionNavigation();
      return;
    }

    _hasNavigatedToRoleSelection = true;
    _pendingRoleSelectionNavigation = false;

    debugPrint(
      'AUPNIX AUTH NAVIGATION: navigating to RoleSelectionScreen',
    );

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const RoleSelectionScreen(),
      ),
      (route) => false,
    );
  }

  void _retryRoleSelectionNavigation() {
    if (!_pendingRoleSelectionNavigation ||
        _hasNavigatedToRoleSelection ||
        !mounted) {
      return;
    }

    Future<void>.delayed(
      const Duration(milliseconds: 100),
    ).then((_) {
      if (!mounted ||
          !_pendingRoleSelectionNavigation ||
          _hasNavigatedToRoleSelection) {
        return;
      }

      _scheduleRoleSelectionNavigation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'AUPNIX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D1216),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.black,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: Color(0x55888888),
          selectionHandleColor: Colors.white,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }
}
// -----------------------------------------------------------------------------
// SCREEN 1 - WELCOME
// -----------------------------------------------------------------------------

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const double artworkWidth = 935;
  static const double artworkHeight = 1681;

  static const double buttonLeft = 58;
  static const double buttonTop = 1392;
  static const double buttonWidth = 816;
  static const double buttonHeight = 117;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1216),
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;

            final widthScale = availableWidth / artworkWidth;
            final heightScale = availableHeight / artworkHeight;
            final scale =
                widthScale < heightScale ? widthScale : heightScale;

            final displayedWidth = artworkWidth * scale;
            final displayedHeight = artworkHeight * scale;

            final leftOffset =
                (availableWidth - displayedWidth) / 2;
            final topOffset =
                (availableHeight - displayedHeight) / 2;

            return Stack(
              children: [
                Positioned(
                  left: leftOffset,
                  top: topOffset,
                  width: displayedWidth,
                  height: displayedHeight,
                  child: Image.asset(
                    'assets/images/welcome_screen.png',
                    width: artworkWidth,
                    height: artworkHeight,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  left: leftOffset + buttonLeft * scale,
                  top: topOffset + buttonTop * scale,
                  width: buttonWidth * scale,
                  height: buttonHeight * scale,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const LoginScreen(),
                        ),
                      );
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SCREEN 3 - LOGIN
// -----------------------------------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool obscurePassword = true;
  bool isSigningIn = false;
  bool isSigningInWithGoogle = false;

  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and password.'),
        ),
      );
      return;
    }

    setState(() {
      isSigningIn = true;
    });

    try {
      await AuthService.instance.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed in successfully.'),
        ),
      );

      appNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const RoleSelectionScreen(),
        ),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSigningIn = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (isSigningInWithGoogle) return;

    setState(() {
      isSigningInWithGoogle = true;
    });

    try {
      await AuthService.instance.signInWithGoogle();
    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSigningInWithGoogle = false;
        });
      }
    }
  }
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF131517);
    const primaryTextColor = Color(0xFFF4F4F4);
    const secondaryTextColor = Color(0xFFBFC0C2);
    const tealColor = Color(0xFF08A6A3);

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final keyboardOpen =
                MediaQuery.viewInsetsOf(context).bottom > 0;

            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.manual,
              padding: EdgeInsets.fromLTRB(
                24,
                keyboardOpen ? 12 : 24,
                24,
                keyboardOpen ? 32 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 520),
                  child: _buildLoginContent(
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    backgroundColor: backgroundColor,
                    tealColor: tealColor,
                    compact: keyboardOpen,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginContent({
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color backgroundColor,
    required Color tealColor,
    required bool compact,
  }) {
    final double gapSmall = compact ? 5 : 8;
    final double gapMedium = compact ? 10 : 15;
    final double gapLarge = compact ? 14 : 20;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/aupnix_logo.png',
          width: compact ? 160 : 190,
          height: compact ? 46 : 54,
          fit: BoxFit.contain,
        ),
        SizedBox(height: compact ? 8 : 15),
        Text(
          'Welcome Back',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: compact ? 30 : 36,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        SizedBox(height: gapSmall),
        Text(
          'Sign In To Continue With AUPNIX.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: compact ? 15 : 17,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
        SizedBox(height: gapLarge),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Email Address',
            style: TextStyle(
              color: Color(0xFFE5E5E5),
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(height: gapSmall),
        TextField(
          controller: emailController,
          focusNode: emailFocusNode,
          cursorColor: Colors.white,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            passwordFocusNode.requestFocus();
          },
          style: TextStyle(
            color: primaryTextColor,
            fontSize: compact ? 16 : 17,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your email address...',
            hintStyle: TextStyle(
              color: const Color(0xFF888B8E),
              fontSize: compact ? 16 : 17,
            ),
            prefixIcon: const Icon(
              Icons.mail_outline,
              color: Color(0xFF9B9DA0),
              size: 24,
            ),
            filled: true,
            fillColor: backgroundColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: compact ? 11 : 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: tealColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: tealColor,
                width: 1.2,
              ),
            ),
          ),
        ),
        SizedBox(height: gapMedium),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Password',
            style: TextStyle(
              color: Color(0xFFE5E5E5),
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(height: gapSmall),
        TextField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          cursorColor: Colors.white,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _signIn(),
          style: TextStyle(
            color: primaryTextColor,
            fontSize: compact ? 16 : 17,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your password...',
            hintStyle: TextStyle(
              color: const Color(0xFF888B8E),
              fontSize: compact ? 16 : 17,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF9B9DA0),
              size: 24,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9B9DA0),
                size: 25,
              ),
            ),
            filled: true,
            fillColor: backgroundColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: compact ? 11 : 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF303234),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: tealColor,
                width: 1.2,
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 2 : 5),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ForgotPasswordScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: const Color(0xFFD2D3D4),
                fontSize: compact ? 15 : 17,
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        SizedBox(
          width: double.infinity,
          height: compact ? 52 : 56,
          child: ElevatedButton(
            onPressed: isSigningIn ? null : _signIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: tealColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  tealColor.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isSigningIn
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: compact ? 18 : 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        SizedBox(height: compact ? 12 : 18),
        Text(
          'Or sign in with:',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: compact ? 15 : 17,
          ),
        ),
        SizedBox(height: compact ? 8 : 11),
        GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isSigningInWithGoogle ? null : _signInWithGoogle,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: isSigningInWithGoogle
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF08A6A3),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/images/google_logo.png', width: 22, height: 22, fit: BoxFit.contain),
                          const SizedBox(width: 10),
                          const Text('Login with Google', style: TextStyle(color: Color(0xFF202124), fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
        SizedBox(height: compact ? 12 : 18),
        const Divider(
          color: Color(0xFF292B2D),
          thickness: 1,
          height: 1,
        ),
        SizedBox(height: compact ? 10 : 15),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const CreateAccountScreen(),
              ),
            );
          },
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                color: const Color(0xFFD2D3D4),
                fontSize: compact ? 15 : 17,
              ),
              children: const [
                TextSpan(
                  text: "Don't Have An Account? ",
                ),
                TextSpan(
                  text: 'Sign Up',
                  style: TextStyle(
                    color: Color(0xFF08A6A3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// SCREEN 4 - CREATE ACCOUNT
// -----------------------------------------------------------------------------


// -----------------------------------------------------------------------------
// SCREEN 4 - FORGOT PASSWORD
// -----------------------------------------------------------------------------


class CreateAccountScreen extends StatefulWidget {   const CreateAccountScreen({super.key});    @override   State<CreateAccountScreen> createState() =>       _CreateAccountScreenState(); }  class _CreateAccountScreenState     extends State<CreateAccountScreen> {   final TextEditingController fullNameController =       TextEditingController();    final TextEditingController mobileController =       TextEditingController();    final TextEditingController emailController =       TextEditingController();    final TextEditingController passwordController =       TextEditingController();    final TextEditingController confirmPasswordController =       TextEditingController();    final FocusNode fullNameFocusNode = FocusNode();   final FocusNode mobileFocusNode = FocusNode();   final FocusNode emailFocusNode = FocusNode();   final FocusNode passwordFocusNode = FocusNode();   final FocusNode confirmPasswordFocusNode =       FocusNode();    bool obscurePassword = true;   bool obscureConfirmPassword = true;   bool isCreatingAccount = false;    Future<void> _createAccount() async {     final fullName = fullNameController.text.trim();     final mobileNumber = mobileController.text.trim();     final email = emailController.text.trim();     final password = passwordController.text;     final confirmPassword =         confirmPasswordController.text;      if (fullName.isEmpty ||         mobileNumber.isEmpty ||         email.isEmpty ||         password.isEmpty ||         confirmPassword.isEmpty) {       ScaffoldMessenger.of(context).showSnackBar(         const SnackBar(           content: Text('Please fill in all fields.'),         ),       );       return;     }      if (password != confirmPassword) {       ScaffoldMessenger.of(context).showSnackBar(         const SnackBar(           content: Text('Passwords do not match.'),         ),       );       return;     }      setState(() {       isCreatingAccount = true;     });      try {       await AuthService.instance.signUp(         email: email,         password: password,         fullName: fullName,         mobileNumber: mobileNumber,       );        if (!mounted) return;        Navigator.of(context).pushReplacement(         MaterialPageRoute(           builder: (context) => EmailConfirmationScreen(             email: email,           ),         ),       );     } on AuthException catch (error) {       if (!mounted) return;        ScaffoldMessenger.of(context).showSnackBar(         SnackBar(content: Text(error.message)),       );     } catch (error) {       if (!mounted) return;        ScaffoldMessenger.of(context).showSnackBar(         SnackBar(           content: Text(             'Something went wrong: $error',           ),         ),       );     } finally {       if (mounted) {         setState(() {           isCreatingAccount = false;         });       }     }   }    @override   void dispose() {     fullNameController.dispose();     mobileController.dispose();     emailController.dispose();     passwordController.dispose();     confirmPasswordController.dispose();      fullNameFocusNode.dispose();     mobileFocusNode.dispose();     emailFocusNode.dispose();     passwordFocusNode.dispose();     confirmPasswordFocusNode.dispose();      super.dispose();   }    @override   Widget build(BuildContext context) {     const backgroundColor = Color(0xFF0D0F12);     const primaryTextColor = Color(0xFFF4F4F4);     const secondaryTextColor = Color(0xFFBFC0C2);     const tealColor = Color(0xFF08AEB7);      return Scaffold(       backgroundColor: backgroundColor,       resizeToAvoidBottomInset: true,       body: SafeArea(         child: LayoutBuilder(           builder: (context, constraints) {             final keyboardOpen =                 MediaQuery.viewInsetsOf(context).bottom > 0;              return SingleChildScrollView(               keyboardDismissBehavior:                   ScrollViewKeyboardDismissBehavior.manual,               padding: EdgeInsets.fromLTRB(                 24,                 keyboardOpen ? 12 : 20,                 24,                 keyboardOpen ? 32 : 24,               ),               child: Center(                 child: ConstrainedBox(                   constraints:                       const BoxConstraints(maxWidth: 520),                   child: _buildCreateAccountContent(                     primaryTextColor: primaryTextColor,                     secondaryTextColor: secondaryTextColor,                     tealColor: tealColor,                     compact: keyboardOpen,                   ),                 ),               ),             );           },         ),       ),     );   }    Widget _buildCreateAccountContent({     required Color primaryTextColor,     required Color secondaryTextColor,     required Color tealColor,     required bool compact,   }) {     final logoWidth = compact ? 155.0 : 185.0;     final logoHeight = compact ? 46.0 : 54.0;      final headingSize = compact ? 32.0 : 42.0;     final descriptionSize = compact ? 16.0 : 19.0;     final fieldHeight = compact ? 54.0 : 59.0;     final fieldSpacing = compact ? 10.0 : 14.0;     final buttonHeight = compact ? 52.0 : 57.0;      return Column(       mainAxisSize: MainAxisSize.min,       children: [         Image.asset(           'assets/images/aupnix_logo.png',           width: logoWidth,           height: logoHeight,           fit: BoxFit.contain,         ),         SizedBox(height: compact ? 8 : 13),         Text(           'Create Account',           textAlign: TextAlign.center,           style: TextStyle(             color: primaryTextColor,             fontSize: headingSize,             fontWeight: FontWeight.w700,             height: 1.08,           ),         ),         SizedBox(height: compact ? 7 : 10),         Text(           'Create your account to discover products\n'           'and local stores near you.',           textAlign: TextAlign.center,           style: TextStyle(             color: secondaryTextColor,             fontSize: descriptionSize,             fontWeight: FontWeight.w400,             height: 1.25,           ),         ),         SizedBox(height: compact ? 16 : 22),         _buildAccountField(           controller: fullNameController,           focusNode: fullNameFocusNode,           hintText: 'Full Name',           icon: Icons.person_outline,           height: fieldHeight,           keyboardType: TextInputType.name,           textInputAction: TextInputAction.next,           onSubmitted: (_) {             mobileFocusNode.requestFocus();           },         ),         SizedBox(height: fieldSpacing),         _buildAccountField(           controller: mobileController,           focusNode: mobileFocusNode,           hintText: 'Mobile Number',           icon: Icons.phone_outlined,           height: fieldHeight,           keyboardType: TextInputType.phone,           textInputAction: TextInputAction.next,           onSubmitted: (_) {             emailFocusNode.requestFocus();           },         ),         SizedBox(height: fieldSpacing),         _buildAccountField(           controller: emailController,           focusNode: emailFocusNode,           hintText: 'Email Address',           icon: Icons.mail_outline,           height: fieldHeight,           keyboardType: TextInputType.emailAddress,           textInputAction: TextInputAction.next,           onSubmitted: (_) {             passwordFocusNode.requestFocus();           },         ),         SizedBox(height: fieldSpacing),         _buildAccountField(           controller: passwordController,           focusNode: passwordFocusNode,           hintText: 'Password',           icon: Icons.lock_outline,           height: fieldHeight,           obscureText: obscurePassword,           textInputAction: TextInputAction.next,           onSubmitted: (_) {             confirmPasswordFocusNode.requestFocus();           },           suffixIcon: IconButton(             onPressed: () {               setState(() {                 obscurePassword =                     !obscurePassword;               });             },             icon: Icon(               obscurePassword                   ? Icons.visibility_off_outlined                   : Icons.visibility_outlined,               color: const Color(0xFF9B9DA0),               size: 23,             ),           ),         ),         SizedBox(height: fieldSpacing),         _buildAccountField(           controller: confirmPasswordController,           focusNode: confirmPasswordFocusNode,           hintText: 'Confirm Password',           icon: Icons.lock_outline,           height: fieldHeight,           obscureText: obscureConfirmPassword,           textInputAction: TextInputAction.done,           suffixIcon: IconButton(             onPressed: () {               setState(() {                 obscureConfirmPassword =                     !obscureConfirmPassword;               });             },             icon: Icon(               obscureConfirmPassword                   ? Icons.visibility_off_outlined                   : Icons.visibility_outlined,               color: const Color(0xFF9B9DA0),               size: 23,             ),           ),         ),         SizedBox(height: compact ? 18 : 22),         SizedBox(           width: double.infinity,           height: buttonHeight,           child: ElevatedButton(             onPressed:                 isCreatingAccount ? null : _createAccount,             style: ElevatedButton.styleFrom(               backgroundColor: tealColor,               foregroundColor: Colors.white,               disabledBackgroundColor:                   tealColor.withValues(alpha: 0.5),               elevation: 0,               padding: EdgeInsets.zero,               shape: RoundedRectangleBorder(                 borderRadius: BorderRadius.circular(29),               ),             ),             child: isCreatingAccount                 ? const SizedBox(                     width: 23,                     height: 23,                     child: CircularProgressIndicator(                       strokeWidth: 2,                       color: Colors.white,                     ),                   )                 : Text(                     'Create Account',                     style: TextStyle(                       fontSize: compact ? 18 : 19,                       fontWeight: FontWeight.w700,                     ),                   ),           ),         ),         SizedBox(height: compact ? 18 : 22),         Row(           children: [             const Expanded(               child: Divider(                 color: Color(0xFF2C3034),                 thickness: 1,               ),             ),             Padding(               padding:                   const EdgeInsets.symmetric(horizontal: 15),               child: Text(                 'OR',                 style: TextStyle(                   color: const Color(0xFF8F9397),                   fontSize: compact ? 14 : 16,                   fontWeight: FontWeight.w500,                 ),               ),             ),             const Expanded(               child: Divider(                 color: Color(0xFF2C3034),                 thickness: 1,               ),             ),           ],         ),         SizedBox(height: compact ? 18 : 20),         SizedBox(           width: double.infinity,           height: compact ? 52 : 55,           child: ElevatedButton(             onPressed: () => AuthService.instance.signInWithGoogle(),             style: ElevatedButton.styleFrom(               backgroundColor: const Color(0xFFFFFFFF),               foregroundColor: const Color(0xFF1A1A1A),               elevation: 0,               padding: EdgeInsets.zero,               shape: RoundedRectangleBorder(                 borderRadius: BorderRadius.circular(29),               ),             ),             child: Row(               mainAxisAlignment:                   MainAxisAlignment.center,               children: [                 Image.asset(                   'assets/images/google_logo.png',                   width: 23,                   height: 23,                   fit: BoxFit.contain,                 ),                 const SizedBox(width: 12),                 Text(                   'Continue with Google',                   style: TextStyle(                     color: const Color(0xFF202124),                     fontSize: compact ? 17 : 18,                     fontWeight: FontWeight.w600,                   ),                 ),               ],             ),           ),         ),         SizedBox(height: compact ? 18 : 24),         GestureDetector(           behavior: HitTestBehavior.opaque,           onTap: () {             Navigator.of(context).pop();           },           child: RichText(             textAlign: TextAlign.center,             text: TextSpan(               style: TextStyle(                 color: const Color(0xFFBFC0C2),                 fontSize: compact ? 16 : 18,                 fontWeight: FontWeight.w400,               ),               children: const [                 TextSpan(                   text: 'Already have an account? ',                 ),                 TextSpan(                   text: 'Sign In',                   style: TextStyle(                     color: Color(0xFF08AEB7),                     fontWeight: FontWeight.w600,                   ),                 ),               ],             ),           ),         ),       ],     );   }    Widget _buildAccountField({     required TextEditingController controller,     required FocusNode focusNode,     required String hintText,     required IconData icon,     required double height,     TextInputType? keyboardType,     TextInputAction? textInputAction,     bool obscureText = false,     Widget? suffixIcon,     void Function(String)? onSubmitted,   }) {     return SizedBox(       width: double.infinity,       height: height,       child: TextField(         controller: controller,         focusNode: focusNode,         cursorColor: Colors.white,         keyboardType: keyboardType,         textInputAction: textInputAction,         obscureText: obscureText,         onSubmitted: onSubmitted,         style: const TextStyle(           color: Color(0xFFF4F4F4),           fontSize: 17,         ),         decoration: InputDecoration(           hintText: hintText,           hintStyle: const TextStyle(             color: Color(0xFF8B8F93),             fontSize: 17,           ),           prefixIcon: Icon(             icon,             color: const Color(0xFF9B9DA0),             size: 23,           ),           suffixIcon: suffixIcon,           filled: true,           fillColor: const Color(0xFF171A1D),           contentPadding:               const EdgeInsets.symmetric(             horizontal: 14,             vertical: 14,           ),           enabledBorder: OutlineInputBorder(             borderRadius: BorderRadius.circular(13),             borderSide: const BorderSide(               color: Color(0xFF454A4F),               width: 1,             ),           ),           focusedBorder: OutlineInputBorder(             borderRadius: BorderRadius.circular(13),             borderSide: const BorderSide(               color: Color(0xFF08AEB7),               width: 1.2,             ),           ),         ),       ),     );   } }  // ----------------------------------------------------------------------------- // SCREEN 6 - ROLE SELECTION // -----------------------------------------------------------------------------  class EmailConfirmationScreen extends StatelessWidget {   const EmailConfirmationScreen({     super.key,     required this.email,   });    final String email;    static const backgroundColor = Color(0xFF0D0F12);   static const primaryTextColor = Color(0xFFF4F4F4);   static const secondaryTextColor = Color(0xFFBFC0C2);   static const tealColor = Color(0xFF08AEB7);   static const mutedColor = Color(0xFF8F9397);    @override   Widget build(BuildContext context) {     return Scaffold(       backgroundColor: backgroundColor,       body: SafeArea(         child: LayoutBuilder(           builder: (context, constraints) {             final compact =                 MediaQuery.viewInsetsOf(context).bottom > 0 ||                 constraints.maxHeight < 700;              return SingleChildScrollView(               padding: EdgeInsets.fromLTRB(                 24,                 compact ? 24 : 40,                 24,                 compact ? 32 : 40,               ),               child: Center(                 child: ConstrainedBox(                   constraints: const BoxConstraints(maxWidth: 520),                   child: Column(                     mainAxisSize: MainAxisSize.min,                     children: [                       Image.asset(                         'assets/images/aupnix_logo.png',                         width: compact ? 155 : 185,                         height: compact ? 46 : 54,                         fit: BoxFit.contain,                       ),                       SizedBox(height: compact ? 24 : 38),                       Container(                         width: compact ? 76 : 88,                         height: compact ? 76 : 88,                         decoration: BoxDecoration(                           color: tealColor.withValues(alpha: 0.12),                           shape: BoxShape.circle,                           border: Border.all(                             color: tealColor.withValues(alpha: 0.35),                             width: 1,                           ),                         ),                         child: Icon(                           Icons.mark_email_read_outlined,                           color: tealColor,                           size: compact ? 38 : 44,                         ),                       ),                       SizedBox(height: compact ? 22 : 30),                       Text(                         'Check Your Email',                         textAlign: TextAlign.center,                         style: TextStyle(                           color: primaryTextColor,                           fontSize: compact ? 32 : 42,                           fontWeight: FontWeight.w700,                           height: 1.08,                         ),                       ),                       SizedBox(height: compact ? 10 : 14),                       Text(                         'We sent a confirmation email to',                         textAlign: TextAlign.center,                         style: TextStyle(                           color: secondaryTextColor,                           fontSize: compact ? 16 : 19,                           fontWeight: FontWeight.w400,                           height: 1.25,                         ),                       ),                       const SizedBox(height: 8),                       Text(                         email,                         textAlign: TextAlign.center,                         style: TextStyle(                           color: primaryTextColor,                           fontSize: compact ? 16 : 18,                           fontWeight: FontWeight.w600,                           height: 1.3,                         ),                       ),                       SizedBox(height: compact ? 24 : 30),                       Container(                         width: double.infinity,                         padding: EdgeInsets.all(compact ? 20 : 24),                         decoration: BoxDecoration(                           color: const Color(0xFF15191D),                           borderRadius: BorderRadius.circular(18),                           border: Border.all(                             color: const Color(0xFF2C3034),                             width: 1,                           ),                         ),                         child: Column(                           children: [                             Text(                               'Please open your mailbox and click on '                               '"Confirm Email Address" to verify your '                               'account and continue to AUPNIX.',                               textAlign: TextAlign.center,                               style: TextStyle(                                 color: secondaryTextColor,                                 fontSize: compact ? 15 : 17,                                 fontWeight: FontWeight.w400,                                 height: 1.45,                               ),                             ),                             SizedBox(height: compact ? 18 : 22),                             Row(                               children: [                                 const Expanded(                                   child: Divider(                                     color: Color(0xFF2C3034),                                     thickness: 1,                                   ),                                 ),                                 Padding(                                   padding: const EdgeInsets.symmetric(                                     horizontal: 14,                                   ),                                   child: Text(                                     'NEXT',                                     style: TextStyle(                                       color: mutedColor,                                       fontSize: compact ? 12 : 13,                                       fontWeight: FontWeight.w600,                                       letterSpacing: 0.8,                                     ),                                   ),                                 ),                                 const Expanded(                                   child: Divider(                                     color: Color(0xFF2C3034),                                     thickness: 1,                                   ),                                 ),                               ],                             ),                             SizedBox(height: compact ? 18 : 22),                             Text(                               'After confirming your email, AUPNIX will '                               'automatically continue to the Role Selection '                               'page.',                               textAlign: TextAlign.center,                               style: TextStyle(                                 color: const Color(0xFF8F9397),                                 fontSize: compact ? 14 : 15,                                 fontWeight: FontWeight.w400,                                 height: 1.45,                               ),                             ),                           ],                         ),                       ),                       SizedBox(height: compact ? 24 : 32),                       Text(                         'Your account information has been saved securely.',                         textAlign: TextAlign.center,                         style: TextStyle(                           color: const Color(0xFF6F7478),                           fontSize: compact ? 13 : 14,                           fontWeight: FontWeight.w400,                           height: 1.4,                         ),                       ),                     ],                   ),                 ),               ),             );           },         ),       ),     );   } } class RoleSelectionScreen extends StatefulWidget {   const RoleSelectionScreen({super.key});    @override   State<RoleSelectionScreen> createState() =>       _RoleSelectionScreenState(); }  enum AupnixRole {   customer,   retailer, }  class _RoleSelectionScreenState     extends State<RoleSelectionScreen> {   static const backgroundColor =       Color(0xFF0E1417);    static const cardColor =       Color(0xFF151D20);    static const cardHighlight =       Color(0xFF1B282A);    static const primaryTextColor =       Color(0xFFF7FAFA);    static const secondaryTextColor =       Color(0xFFA8B2B3);    static const tealColor =       Color(0xFF35B3A6);    static const borderColor =       Color(0xFF303B3D);    static const mutedButtonColor =       Color(0xFF263235);    AupnixRole? selectedRole;    void _selectRole(AupnixRole role) {     setState(() {       selectedRole = role;     });   }    bool _isSavingRole = false;    Future<void> _continue() async {     final role = selectedRole;     if (role == null || _isSavingRole) {       return;     }      setState(() {       _isSavingRole = true;     });      try {       await AuthService.instance.saveOnboardingRole(         role: role == AupnixRole.customer ? 'customer' : 'retailer',       );        if (!mounted) return;        Navigator.of(context).push(         MaterialPageRoute(           builder: (context) =>               const EnableLocationScreen(),         ),       );     } catch (error, stackTrace) {       debugPrint('AUPNIX_ROLE_SAVE_ERROR: $error');       debugPrint('AUPNIX_ROLE_SAVE_STACK: $stackTrace');       if (!mounted) return;        ScaffoldMessenger.of(context).showSnackBar(         SnackBar(           content: Text("Unable to save your role. Please try again."),         ),       );     } finally {       if (mounted) {         setState(() {           _isSavingRole = false;         });       }     }   }    @override   Widget build(BuildContext context) {     return Scaffold(       backgroundColor: backgroundColor,       body: SafeArea(         child: LayoutBuilder(           builder: (context, constraints) {             final width = constraints.maxWidth;             final height = constraints.maxHeight;              final keyboardOpen =                 MediaQuery.viewInsetsOf(context).bottom > 0;              final compact =                 height < 720 || keyboardOpen;              final horizontalPadding = width >= 700                 ? 48.0                 : width >= 480                     ? 32.0                     : 20.0;              final maxContentWidth =                 width >= 700 ? 620.0 : 540.0;              return Stack(               children: [                 const Positioned.fill(                   child: _RoleBackground(),                 ),                 SingleChildScrollView(                   keyboardDismissBehavior:                       ScrollViewKeyboardDismissBehavior                           .manual,                   padding: EdgeInsets.fromLTRB(                     horizontalPadding,                     compact ? 14 : 24,                     horizontalPadding,                     28,                   ),                   child: Center(                     child: ConstrainedBox(                       constraints: BoxConstraints(                         maxWidth: maxContentWidth,                       ),                       child: Column(                         children: [                           Image.asset(                             'assets/images/aupnix_logo.png',                             width: width >= 600                                 ? 185                                 : width >= 400                                     ? 160                                     : 145,                             height: width >= 600                                 ? 54                                 : width >= 400                                     ? 47                                     : 43,                             fit: BoxFit.contain,                           ),                           SizedBox(                             height:                                 compact ? 18 : 28,                           ),                           Text(                             'Choose Your Role',                             textAlign:                                 TextAlign.center,                             style: TextStyle(                               color:                                   primaryTextColor,                               fontSize: width >= 600                                   ? 36                                   : width >= 400                                       ? 32                                       : 29,                               fontWeight:                                   FontWeight.w700,                               height: 1.08,                               letterSpacing: -0.5,                             ),                           ),                           const SizedBox(height: 9),                           Text(                             'Select how you want to use AUPNIX.',                             textAlign:                                 TextAlign.center,                             style: TextStyle(                               color:                                   secondaryTextColor,                               fontSize: width >= 600                                   ? 17                                   : 15.5,                               height: 1.35,                             ),                           ),                           SizedBox(                             height:                                 compact ? 24 : 32,                           ),                           _RoleCard(                             role:                                 AupnixRole.customer,                             selected:                                 selectedRole ==                                     AupnixRole                                         .customer,                             title: 'Customer',                             subtitle:                                 'Discover products, compare options, and find trusted stores near you.',                             cardHeight:                                 width >= 600                                     ? 190                                     : width >= 400                                         ? 180                                         : 170,                             onTap: () {                               _selectRole(                                 AupnixRole.customer,                               );                             },                           ),                           SizedBox(                             height:                                 compact ? 14 : 18,                           ),                           _RoleCard(                             role:                                 AupnixRole.retailer,                             selected:                                 selectedRole ==                                     AupnixRole                                         .retailer,                             title: 'Retailer',                             subtitle:                                 'Showcase your products and connect with customers in your local area.',                             cardHeight:                                 width >= 600                                     ? 190                                     : width >= 400                                         ? 180                                         : 170,                             onTap: () {                               _selectRole(                                 AupnixRole.retailer,                               );                             },                           ),                           SizedBox(                             height:                                 compact ? 20 : 26,                           ),                           SizedBox(                             width: double.infinity,                             height:                                 compact ? 52 : 56,                             child:                                 AnimatedContainer(                               duration:                                   const Duration(                                 milliseconds: 180,                               ),                               curve:                                   Curves.easeOut,                               decoration:                                   BoxDecoration(                                 borderRadius:                                     BorderRadius                                         .circular(                                   30,                                 ),                                 boxShadow:                                     selectedRole ==                                             null                                         ? const []                                         : [                                             BoxShadow(                                               color:                                                   tealColor.withValues(                                                 alpha:                                                     0.18,                                               ),                                               blurRadius:                                                   18,                                               offset:                                                   const Offset(                                                 0,                                                 7,                                               ),                                             ),                                           ],                               ),                               child:                                   ElevatedButton(                                 onPressed:                                     selectedRole ==                                             null                                         ? null                                         : _continue,                                 style:                                     ElevatedButton                                         .styleFrom(                                   backgroundColor:                                       tealColor,                                   disabledBackgroundColor:                                       mutedButtonColor,                                   foregroundColor:                                       Colors.white,                                   disabledForegroundColor:                                       const Color(                                     0xFF788486,                                   ),                                   elevation: 0,                                   padding:                                       EdgeInsets.zero,                                   shape:                                       RoundedRectangleBorder(                                     borderRadius:                                         BorderRadius                                             .circular(                                       30,                                     ),                                   ),                                 ),                                 child: Row(                                   mainAxisAlignment:                                       MainAxisAlignment                                           .center,                                   children: [                                     Text(                                       'Continue',                                       style:                                           TextStyle(                                         fontSize:                                             width >=                                                     600                                                 ? 18                                                 : 17,                                         fontWeight:                                             FontWeight                                                 .w700,                                       ),                                     ),                                     const SizedBox(                                         width: 9),                                     Icon(                                       Icons                                           .arrow_forward_rounded,                                       size: width >=                                               600                                           ? 21                                           : 20,                                       color:                                           selectedRole ==                                                   null                                               ? const Color(                                                   0xFF788486,                                                 )                                               : Colors                                                   .white,                                     ),                                   ],                                 ),                               ),                             ),                           ),                           const SizedBox(height: 14),                           AnimatedSwitcher(                             duration:                                 const Duration(                               milliseconds: 180,                             ),                             child: selectedRole ==                                     null                                 ? const Text(                                     'Choose an option above to continue',                                     key: ValueKey(                                       'roleHint',                                     ),                                     textAlign:                                         TextAlign                                             .center,                                     style: TextStyle(                                       color: Color(                                         0xFF737D7F,                                       ),                                       fontSize: 13,                                     ),                                   )                                 : Text(                                     selectedRole ==                                             AupnixRole                                                 .customer                                         ? 'Customer selected'                                         : 'Retailer selected',                                     key: ValueKey(                                       selectedRole,                                     ),                                     textAlign:                                         TextAlign                                             .center,                                     style:                                         const TextStyle(                                       color: Color(                                         0xFF6DC8C0,                                       ),                                       fontSize: 13,                                       fontWeight:                                           FontWeight                                               .w500,                                     ),                                   ),                           ),                         ],                       ),                     ),                   ),                 ),               ],             );           },         ),       ),     );   } }  // ----------------------------------------------------------------------------- // SCREEN 7 - ENABLE LOCATION // -----------------------------------------------------------------------------  class EnableLocationScreen extends StatefulWidget {   const EnableLocationScreen({super.key});    static const backgroundColor = Color(0xFF090D13);   static const primaryTextColor = Color(0xFFF4F5F6);   static const secondaryTextColor = Color(0xFFA8A9B0);   static const mutedTextColor = Color(0xFF73747D);   static const primaryTeal = Color(0xFF11B8B4);    @override   State<EnableLocationScreen> createState() => _EnableLocationScreenState(); }  

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isSendingResetLink = false;
  bool resetLinkSent = false;

  Future<void> _sendResetLink() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() {
      isSendingResetLink = true;
      resetLinkSent = false;
    });

    try {
      await AuthService.instance.resetPassword(email: email);
      if (!mounted) return;
      setState(() {
        resetLinkSent = true;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSendingResetLink = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF131517);
    const primaryTextColor = Color(0xFFF4F4F4);
    const secondaryTextColor = Color(0xFFBFC0C2);
    const tealColor = Color(0xFF08A6A3);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/aupnix_logo.png', width: 190, height: 54, fit: BoxFit.contain),
                  const SizedBox(height: 15),
                  const Text('Forgot Password', style: TextStyle(color: primaryTextColor, fontSize: 36, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Enter your email address and we will send you a password reset link.', textAlign: TextAlign.center, style: TextStyle(color: secondaryTextColor, fontSize: 17)),
                  const SizedBox(height: 32),
                  const Align(alignment: Alignment.centerLeft, child: Text('Email Address', style: TextStyle(color: Color(0xFFE5E5E5), fontSize: 18))),
                  const SizedBox(height: 8),
                  TextField(controller: emailController, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.done, onSubmitted: (_) => _sendResetLink(), style: const TextStyle(color: primaryTextColor, fontSize: 17), decoration: InputDecoration(hintText: 'Enter your email address...', prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF9B9DA0)), filled: true, fillColor: backgroundColor, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF303234))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: tealColor)))),
                  const SizedBox(height: 22),
                  SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: isSendingResetLink ? null : _sendResetLink, style: ElevatedButton.styleFrom(backgroundColor: tealColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29))), child: isSendingResetLink ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white)) : const Text('Send Reset Link', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)))),
                  if (resetLinkSent) ...[
                    const SizedBox(height: 18),
                    const Text('Reset link sent. Please check your email and tap the link to continue.', textAlign: TextAlign.center, style: TextStyle(color: secondaryTextColor, fontSize: 15)),
                  ],
                  const SizedBox(height: 18),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to Login', style: TextStyle(color: Color(0xFFD2D3D4), fontSize: 16))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SCREEN 5 - SET NEW PASSWORD
// -----------------------------------------------------------------------------

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isUpdatingPassword = false;

  Future<void> _updatePassword() async {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter and confirm your new password.')));
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters.')));
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    setState(() { isUpdatingPassword = true; });

    try {
      await AuthService.instance.updatePassword(password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully.')));
      appNavigatorKey.currentState?.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong: $error')));
    } finally {
      if (mounted) setState(() { isUpdatingPassword = false; });
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF131517);
    const primaryTextColor = Color(0xFFF4F4F4);
    const secondaryTextColor = Color(0xFFBFC0C2);
    const tealColor = Color(0xFF08A6A3);

    return Scaffold(backgroundColor: backgroundColor, body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 32), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Image.asset('assets/images/aupnix_logo.png', width: 190, height: 54, fit: BoxFit.contain),
      const SizedBox(height: 15),
      const Text('Set New Password', style: TextStyle(color: primaryTextColor, fontSize: 36, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Create a new password for your AUPNIX account.', textAlign: TextAlign.center, style: TextStyle(color: secondaryTextColor, fontSize: 17)),
      const SizedBox(height: 32),
      _buildPasswordField('New Password', 'Enter your new password...', passwordController, obscurePassword, () => setState(() { obscurePassword = !obscurePassword; }), TextInputAction.next),
      const SizedBox(height: 18),
      _buildPasswordField('Confirm Password', 'Confirm your new password...', confirmPasswordController, obscureConfirmPassword, () => setState(() { obscureConfirmPassword = !obscureConfirmPassword; }), TextInputAction.done, (_) => _updatePassword()),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: isUpdatingPassword ? null : _updatePassword, style: ElevatedButton.styleFrom(backgroundColor: tealColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29))), child: isUpdatingPassword ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white)) : const Text('Update Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)))),
    ]))))));
  }

  Widget _buildPasswordField(String label, String hint, TextEditingController controller, bool obscureText, VoidCallback onToggle, TextInputAction action, [ValueChanged<String>? onSubmitted]) {
    return Column(children: [
      Align(alignment: Alignment.centerLeft, child: Text(label, style: const TextStyle(color: Color(0xFFE5E5E5), fontSize: 18))),
      const SizedBox(height: 8),
      TextField(controller: controller, obscureText: obscureText, textInputAction: action, onSubmitted: onSubmitted, style: const TextStyle(color: Color(0xFFF4F4F4), fontSize: 17), decoration: InputDecoration(hintText: hint, prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9B9DA0)), suffixIcon: IconButton(onPressed: onToggle, icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF9B9DA0))), filled: true, fillColor: const Color(0xFF131517), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF303234))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF08A6A3))))),
    ]);
  }
}


// -----------------------------------------------------------------------------
// SCREEN 4 - FORGOT PASSWORD
// -----------------------------------------------------------------------------



// -----------------------------------------------------------------------------
// SCREEN 5 - SET NEW PASSWORD
// -----------------------------------------------------------------------------



// -----------------------------------------------------------------------------
// SCREEN 4 - FORGOT PASSWORD
// -----------------------------------------------------------------------------



// -----------------------------------------------------------------------------
// SCREEN 5 - SET NEW PASSWORD
// -----------------------------------------------------------------------------



// -----------------------------------------------------------------------------
// SCREEN 6 - ROLE SELECTION
// -----------------------------------------------------------------------------

class EmailConfirmationScreen extends StatelessWidget {
  const EmailConfirmationScreen({
    super.key,
    required this.email,
  });

  final String email;

  static const backgroundColor = Color(0xFF0D0F12);
  static const primaryTextColor = Color(0xFFF4F4F4);
  static const secondaryTextColor = Color(0xFFBFC0C2);
  static const tealColor = Color(0xFF08AEB7);
  static const mutedColor = Color(0xFF8F9397);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                MediaQuery.viewInsetsOf(context).bottom > 0 ||
                constraints.maxHeight < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                compact ? 24 : 40,
                24,
                compact ? 32 : 40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/aupnix_logo.png',
                        width: compact ? 155 : 185,
                        height: compact ? 46 : 54,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: compact ? 24 : 38),
                      Container(
                        width: compact ? 76 : 88,
                        height: compact ? 76 : 88,
                        decoration: BoxDecoration(
                          color: tealColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tealColor.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          color: tealColor,
                          size: compact ? 38 : 44,
                        ),
                      ),
                      SizedBox(height: compact ? 22 : 30),
                      Text(
                        'Check Your Email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: compact ? 32 : 42,
                          fontWeight: FontWeight.w700,
                          height: 1.08,
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 14),
                      Text(
                        'We sent a confirmation email to',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: compact ? 16 : 19,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: compact ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: compact ? 24 : 30),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(compact ? 20 : 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15191D),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF2C3034),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Please open your mailbox and click on '
                              '"Confirm Email Address" to verify your '
                              'account and continue to AUPNIX.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: compact ? 15 : 17,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                              ),
                            ),
                            SizedBox(height: compact ? 18 : 22),
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                    color: Color(0xFF2C3034),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    'NEXT',
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: compact ? 12 : 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(
                                    color: Color(0xFF2C3034),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: compact ? 18 : 22),
                            Text(
                              'After confirming your email, AUPNIX will '
                              'automatically continue to the Role Selection '
                              'page.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF8F9397),
                                fontSize: compact ? 14 : 15,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 24 : 32),
                      Text(
                        'Your account information has been saved securely.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF6F7478),
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
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
    );
  }
}
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

enum AupnixRole {
  customer,
  retailer,
}

class _RoleSelectionScreenState
    extends State<RoleSelectionScreen> {
  static const backgroundColor =
      Color(0xFF0E1417);

  static const cardColor =
      Color(0xFF151D20);

  static const cardHighlight =
      Color(0xFF1B282A);

  static const primaryTextColor =
      Color(0xFFF7FAFA);

  static const secondaryTextColor =
      Color(0xFFA8B2B3);

  static const tealColor =
      Color(0xFF35B3A6);

  static const borderColor =
      Color(0xFF303B3D);

  static const mutedButtonColor =
      Color(0xFF263235);

  AupnixRole? selectedRole;

  void _selectRole(AupnixRole role) {
    setState(() {
      selectedRole = role;
    });
  }

  bool _isSavingRole = false;

  Future<void> _continue() async {
    final role = selectedRole;
    if (role == null || _isSavingRole) {
      return;
    }

    setState(() {
      _isSavingRole = true;
    });

    try {
      await AuthService.instance.saveOnboardingRole(
        role: role == AupnixRole.customer ? 'customer' : 'retailer',
      );

      if (!mounted) return;

      if (role == AupnixRole.retailer) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                const RetailerWorkspaceEntryScreen(
                  startBusinessInformation: true,
                ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                const EnableLocationScreen(),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('AUPNIX_ROLE_SAVE_ERROR: $error');
      debugPrint('AUPNIX_ROLE_SAVE_STACK: $stackTrace');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to save your role. Please try again."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingRole = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final keyboardOpen =
                MediaQuery.viewInsetsOf(context).bottom > 0;

            final compact =
                height < 720 || keyboardOpen;

            final horizontalPadding = width >= 700
                ? 48.0
                : width >= 480
                    ? 32.0
                    : 20.0;

            final maxContentWidth =
                width >= 700 ? 620.0 : 540.0;

            return Stack(
              children: [
                const Positioned.fill(
                  child: _RoleBackground(),
                ),
                SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior
                          .manual,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 14 : 24,
                    horizontalPadding,
                    28,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxContentWidth,
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/aupnix_logo.png',
                            width: width >= 600
                                ? 185
                                : width >= 400
                                    ? 160
                                    : 145,
                            height: width >= 600
                                ? 54
                                : width >= 400
                                    ? 47
                                    : 43,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(
                            height:
                                compact ? 18 : 28,
                          ),
                          Text(
                            'Choose Your Role',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color:
                                  primaryTextColor,
                              fontSize: width >= 600
                                  ? 36
                                  : width >= 400
                                      ? 32
                                      : 29,
                              fontWeight:
                                  FontWeight.w700,
                              height: 1.08,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'Select how you want to use AUPNIX.',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color:
                                  secondaryTextColor,
                              fontSize: width >= 600
                                  ? 17
                                  : 15.5,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(
                            height:
                                compact ? 24 : 32,
                          ),
                          _RoleCard(
                            role:
                                AupnixRole.customer,
                            selected:
                                selectedRole ==
                                    AupnixRole
                                        .customer,
                            title: 'Customer',
                            subtitle:
                                'Discover products, compare options, and find trusted stores near you.',
                            cardHeight:
                                width >= 600
                                    ? 190
                                    : width >= 400
                                        ? 180
                                        : 170,
                            onTap: () {
                              _selectRole(
                                AupnixRole.customer,
                              );
                            },
                          ),
                          SizedBox(
                            height:
                                compact ? 14 : 18,
                          ),
                          _RoleCard(
                            role:
                                AupnixRole.retailer,
                            selected:
                                selectedRole ==
                                    AupnixRole
                                        .retailer,
                            title: 'Retailer',
                            subtitle:
                                'Showcase your products and connect with customers in your local area.',
                            cardHeight:
                                width >= 600
                                    ? 190
                                    : width >= 400
                                        ? 180
                                        : 170,
                            onTap: () {
                              _selectRole(
                                AupnixRole.retailer,
                              );
                            },
                          ),
                          SizedBox(
                            height:
                                compact ? 20 : 26,
                          ),
                          SizedBox(
                            width: double.infinity,
                            height:
                                compact ? 52 : 56,
                            child:
                                AnimatedContainer(
                              duration:
                                  const Duration(
                                milliseconds: 180,
                              ),
                              curve:
                                  Curves.easeOut,
                              decoration:
                                  BoxDecoration(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  30,
                                ),
                                boxShadow:
                                    selectedRole ==
                                            null
                                        ? const []
                                        : [
                                            BoxShadow(
                                              color:
                                                  tealColor.withValues(
                                                alpha:
                                                    0.18,
                                              ),
                                              blurRadius:
                                                  18,
                                              offset:
                                                  const Offset(
                                                0,
                                                7,
                                              ),
                                            ),
                                          ],
                              ),
                              child:
                                  ElevatedButton(
                                onPressed:
                                    selectedRole ==
                                            null
                                        ? null
                                        : _continue,
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      tealColor,
                                  disabledBackgroundColor:
                                      mutedButtonColor,
                                  foregroundColor:
                                      Colors.white,
                                  disabledForegroundColor:
                                      const Color(
                                    0xFF788486,
                                  ),
                                  elevation: 0,
                                  padding:
                                      EdgeInsets.zero,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      30,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Text(
                                      'Continue',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            width >=
                                                    600
                                                ? 18
                                                : 17,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                    ),
                                    const SizedBox(
                                        width: 9),
                                    Icon(
                                      Icons
                                          .arrow_forward_rounded,
                                      size: width >=
                                              600
                                          ? 21
                                          : 20,
                                      color:
                                          selectedRole ==
                                                  null
                                              ? const Color(
                                                  0xFF788486,
                                                )
                                              : Colors
                                                  .white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration:
                                const Duration(
                              milliseconds: 180,
                            ),
                            child: selectedRole ==
                                    null
                                ? const Text(
                                    'Choose an option above to continue',
                                    key: ValueKey(
                                      'roleHint',
                                    ),
                                    textAlign:
                                        TextAlign
                                            .center,
                                    style: TextStyle(
                                      color: Color(
                                        0xFF737D7F,
                                      ),
                                      fontSize: 13,
                                    ),
                                  )
                                : Text(
                                    selectedRole ==
                                            AupnixRole
                                                .customer
                                        ? 'Customer selected'
                                        : 'Retailer selected',
                                    key: ValueKey(
                                      selectedRole,
                                    ),
                                    textAlign:
                                        TextAlign
                                            .center,
                                    style:
                                        const TextStyle(
                                      color: Color(
                                        0xFF6DC8C0,
                                      ),
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight
                                              .w500,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SCREEN 7 - ENABLE LOCATION
// -----------------------------------------------------------------------------

class EnableLocationScreen extends StatefulWidget {
  const EnableLocationScreen({super.key});

  static const backgroundColor = Color(0xFF090D13);
  static const primaryTextColor = Color(0xFFF4F5F6);
  static const secondaryTextColor = Color(0xFFA8A9B0);
  static const mutedTextColor = Color(0xFF73747D);
  static const primaryTeal = Color(0xFF11B8B4);

  @override
  State<EnableLocationScreen> createState() => _EnableLocationScreenState();
}

class _EnableLocationDialog extends StatefulWidget {
  const _EnableLocationDialog();

  @override
  State<_EnableLocationDialog> createState() => _EnableLocationDialogState();
}

class _EnableLocationDialogState extends State<_EnableLocationDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: EnableLocationScreen.backgroundColor,
      title: const Text(
        'Enter Your Location',
        style: TextStyle(
          color: EnableLocationScreen.primaryTextColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.streetAddress,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          color: EnableLocationScreen.primaryTextColor,
        ),
        decoration: InputDecoration(
          hintText: 'Enter an address, area, or locality',
          hintStyle: const TextStyle(
            color: EnableLocationScreen.mutedTextColor,
          ),
          filled: true,
          fillColor: const Color(0xFF111820),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: EnableLocationScreen.primaryTeal,
            ),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: EnableLocationScreen.secondaryTextColor,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: EnableLocationScreen.primaryTeal,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Location'),
        ),
      ],
    );
  }
}

class _EnableLocationScreenState extends State<EnableLocationScreen>
    with WidgetsBindingObserver {
  bool _isSavingLocation = false;
  bool _shouldRetryAfterLocationSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _shouldRetryAfterLocationSettings &&
        !_isSavingLocation) {
      _shouldRetryAfterLocationSettings = false;
      _allowLocationAccess();
    }
  }

  Future<void> _continueAfterLocationDecision() async {
    final role = await AuthService.instance.getOnboardingRole();

    if (!mounted) {
      return;
    }

    final destination = role == 'retailer'
        ? const RetailerWorkspaceEntryScreen()
        : const CustomerHomeScreen();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => destination,
      ),
    );
  }
  Future<void> _allowLocationAccess() async {
    if (_isSavingLocation) return;

    setState(() => _isSavingLocation = true);

    try {
      await LocationService.instance.saveCurrentLocation();

      if (!mounted) return;

            await _continueAfterLocationDecision();
    } on LocationServiceException catch (error) {
      if (error.code == LocationServiceErrorCode.serviceDisabled) {
        _shouldRetryAfterLocationSettings = true;
      }

      if (!mounted) return;

      final message = switch (error.code) {
        LocationServiceErrorCode.emptyAddress =>
          'Please enter a location.',
        LocationServiceErrorCode.noGeocodingResult =>
          'We could not find that location. Please check the address and try again.',
        LocationServiceErrorCode.serviceDisabled =>
          'Please turn on location services and try again.',
        LocationServiceErrorCode.permissionDenied =>
          'Location permission was denied. Please allow access to continue.',
        LocationServiceErrorCode.permissionDeniedForever =>
          'Location permission is disabled. Please enable it in your device settings.',
        LocationServiceErrorCode.locationFailed =>
          'We could not determine your current location. Please try again.',
        LocationServiceErrorCode.geocodingFailed =>
          'We could not determine your address. Please try again.',
        LocationServiceErrorCode.saveFailed =>
          'We could not save your location. Please try again.',
        null =>
          'We could not save your location. Please try again.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not save your location. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingLocation = false);
      }
    }
  }

  Future<void> _showManualLocationDialog() async {
    final address = await showDialog<String>(
      context: context,
      builder: (_) => const _EnableLocationDialog(),
    );

    if (address == null || !mounted) return;

    setState(() => _isSavingLocation = true);

    try {
      await LocationService.instance.saveManualLocation(
        address: address,
      );

      if (!mounted) return;

            await _continueAfterLocationDecision();
    } on LocationServiceException catch (error) {

      if (!mounted) return;

      final message = switch (error.code) {
        LocationServiceErrorCode.emptyAddress =>
          'Please enter a location.',
        LocationServiceErrorCode.noGeocodingResult =>
          'We could not find that location. Please check the address and try again.',
        LocationServiceErrorCode.geocodingFailed =>
          'We could not determine that location. Please try again.',
        LocationServiceErrorCode.saveFailed =>
          'We could not save your location. Please try again.',
        LocationServiceErrorCode.serviceDisabled =>
          'Please turn on location services and try again.',
        LocationServiceErrorCode.permissionDenied =>
          'Location permission was denied. Please allow access to continue.',
        LocationServiceErrorCode.permissionDeniedForever =>
          'Location permission is disabled. Please enable it in your device settings.',
        LocationServiceErrorCode.locationFailed =>
          'We could not determine your current location. Please try again.',
        null =>
          'We could not save your location. Please try again.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not save your location. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingLocation = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EnableLocationScreen.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final horizontalPadding = width < 380
                ? 20.0
                : width < 600
                    ? 28.0
                    : 40.0;

            final contentWidth = width < 600
                ? width - (horizontalPadding * 2)
                : 500.0;

            final compact = height < 700;
            final veryShort = height < 560;

            final logoWidth = width < 380
                ? 155.0
                : width < 600
                    ? 172.0
                    : 190.0;

            final illustrationSize = width < 380
                ? 190.0
                : width < 600
                    ? 220.0
                    : 235.0;

            final headingSize = width < 380
                ? 27.0
                : width < 600
                    ? 30.0
                    : 32.0;

            final descriptionSize = width < 380
                ? 14.5
                : width < 600
                    ? 15.5
                    : 16.0;

            final buttonHeight = width < 380 ? 54.0 : 58.0;

            final topPadding = veryShort
                ? 10.0
                : compact
                    ? 16.0
                    : 26.0;

            final logoToHeroSpacing = veryShort
                ? 12.0
                : compact
                    ? 18.0
                    : 30.0;

            final heroToHeadingSpacing = veryShort
                ? 12.0
                : compact
                    ? 18.0
                    : 24.0;

            final headingToDescriptionSpacing = veryShort
                ? 7.0
                : compact
                    ? 9.0
                    : 11.0;

            final descriptionToButtonSpacing = veryShort
                ? 18.0
                : compact
                    ? 24.0
                    : 30.0;

            final buttonToManualSpacing = veryShort
                ? 12.0
                : compact
                    ? 16.0
                    : 18.0;

            final manualToFooterSpacing = veryShort
                ? 14.0
                : compact
                    ? 20.0
                    : 24.0;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                veryShort ? 16 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/aupnix_logo.png',
                        width: logoWidth,
                        height: logoWidth * 0.282,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: logoToHeroSpacing),
                      Image.asset(
                        'assets/images/location_hero.png',
                        width: illustrationSize,
                        height: illustrationSize,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      SizedBox(height: heroToHeadingSpacing),
                      Text(
                        'Find Stores Near You',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                          color: EnableLocationScreen.primaryTextColor,
                          fontSize: headingSize,
                          fontWeight: FontWeight.w700,
                          height: 1.08,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: headingToDescriptionSpacing),
                      Text(
                        'Allow AUPNIX to use your location to\n'
                        'discover nearby stores, products, and\n'
                        'better local prices.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: EnableLocationScreen.secondaryTextColor,
                          fontSize: descriptionSize,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: descriptionToButtonSpacing),
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: _isSavingLocation
                              ? null
                              : _allowLocationAccess,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                EnableLocationScreen.primaryTeal,
                            disabledBackgroundColor:
                                EnableLocationScreen.primaryTeal,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: const StadiumBorder(),
                          ),
                          child: _isSavingLocation
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Allow Location Access',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: width < 380 ? 17.0 : 18.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: buttonToManualSpacing),
                      Semantics(
                        button: true,
                        label: 'Enter Location Manually',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _isSavingLocation
                              ? null
                              : _showManualLocationDialog,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 10,
                            ),
                            child: Text(
                              'Enter Location Manually',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    EnableLocationScreen.secondaryTextColor,
                                fontSize: width < 380 ? 15.5 : 17.0,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        button: true,
                        label: 'Later / No, Thanks',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _isSavingLocation
                              ? null
                              : _continueAfterLocationDecision,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 10,
                            ),
                            child: Text(
                              'Later / No, Thanks',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: EnableLocationScreen.mutedTextColor,
                                fontSize: width < 380 ? 14.5 : 15.5,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: manualToFooterSpacing),
                      Text(
                        'Your location is used to improve your local\n'
                        'shopping experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: EnableLocationScreen.mutedTextColor,
                          fontSize: width < 380 ? 12.5 : 14.0,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
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
    );
  }
}
// -----------------------------------------------------------------------------
// ROLE BACKGROUND
// -----------------------------------------------------------------------------
// ROLE BACKGROUND
// -----------------------------------------------------------------------------

class _RoleBackground
    extends StatelessWidget {
  const _RoleBackground();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _RoleBackgroundPainter(),
    );
  }
}

class _RoleBackgroundPainter
    extends CustomPainter {
  const _RoleBackgroundPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width * 0.5,
      size.height * 0.30,
    );

    final glowRadius =
        size.width * 0.55;

    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x0D35B3A6),
          Color(0x0335B3A6),
          Colors.transparent,
        ],
        stops: [
          0,
          0.55,
          1,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: glowRadius,
        ),
      );

    canvas.drawCircle(
      center,
      glowRadius,
      glowPaint,
    );

    final linePaint = Paint()
      ..color = const Color(0x0535B3A6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(
      Offset(
        size.width * 0.04,
        size.height * 0.16,
      ),
      38,
      linePaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.96,
        size.height * 0.82,
      ),
      48,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _RoleBackgroundPainter
        oldDelegate,
  ) {
    return false;
  }
}

// -----------------------------------------------------------------------------
// ROLE CARD
// -----------------------------------------------------------------------------

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.cardHeight,
    required this.onTap,
  });

  final AupnixRole role;
  final bool selected;
  final String title;
  final String subtitle;
  final double cardHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.sizeOf(context).width;

    final illustrationSize = width >= 600
        ? 76.0
        : width >= 400
            ? 70.0
            : 64.0;

    final titleSize = width >= 600
        ? 20.0
        : width >= 400
            ? 18.5
            : 18.0;

    final subtitleSize = width >= 600
        ? 14.0
        : width >= 400
            ? 13.5
            : 13.0;

    final border = selected
        ? _RoleSelectionScreenState
            .tealColor
        : _RoleSelectionScreenState
            .borderColor;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(18),
          splashColor:
              const Color(0x1235B3A6),
          highlightColor:
              const Color(0x0835B3A6),
          child: AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 220,
            ),
            curve:
                Curves.easeOutCubic,
            width: double.infinity,
            height: cardHeight,
            decoration: BoxDecoration(
              color: selected
                  ? _RoleSelectionScreenState
                      .cardHighlight
                  : _RoleSelectionScreenState
                      .cardColor,
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: border,
                width:
                    selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color:
                            _RoleSelectionScreenState
                                .tealColor
                                .withValues(
                          alpha: 0.08,
                        ),
                        blurRadius: 18,
                        offset:
                            const Offset(0, 7),
                      ),
                    ]
                  : [
                      const BoxShadow(
                        color:
                            Color(0x18000000),
                        blurRadius: 12,
                        offset:
                            Offset(0, 5),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -38,
                  right: -38,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,
                      color: selected
                          ? const Color(
                              0x0D35B3A6,
                            )
                          : const Color(
                              0x0535B3A6,
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width:
                            illustrationSize,
                        height:
                            illustrationSize,
                        decoration:
                            BoxDecoration(
                          color: selected
                              ? const Color(
                                  0x1235B3A6,
                                )
                              : const Color(
                                  0x08FFFFFF,
                                ),
                          border:
                              Border.all(
                            color: selected
                                ? const Color(
                                    0x3035B3A6,
                                  )
                                : const Color(
                                    0x0D2D383A,
                                  ),
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            18,
                          ),
                        ),
                        child:
                            CustomPaint(
                          painter:
                              role ==
                                      AupnixRole
                                          .customer
                                  ? _CustomerIllustrationPainter(
                                      active:
                                          selected,
                                    )
                                  : _RetailerIllustrationPainter(
                                      active:
                                          selected,
                                    ),
                        ),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color:
                                    _RoleSelectionScreenState
                                        .primaryTextColor,
                                fontSize:
                                    titleSize,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(
                                height: 5),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: TextStyle(
                                color:
                                    _RoleSelectionScreenState
                                        .secondaryTextColor,
                                fontSize:
                                    subtitleSize,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(
                                height: 7),
                            Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                Text(
                                  selected
                                      ? 'Selected'
                                      : 'Select',
                                  style:
                                      TextStyle(
                                    color: selected
                                        ? _RoleSelectionScreenState
                                            .tealColor
                                        : const Color(
                                            0xFF778284,
                                          ),
                                    fontSize:
                                        12,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                                const SizedBox(
                                    width: 4),
                                Icon(
                                  Icons
                                      .arrow_forward_rounded,
                                  size: 14,
                                  color: selected
                                      ? _RoleSelectionScreenState
                                          .tealColor
                                      : const Color(
                                          0xFF667173,
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 11,
                    right: 11,
                    child:
                        _SelectionIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SELECTION INDICATOR
// -----------------------------------------------------------------------------

class _SelectionIndicator
    extends StatelessWidget {
  const _SelectionIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration:
          const BoxDecoration(
        color:
            _RoleSelectionScreenState
                .tealColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.check_rounded,
        color: Color(0xFF102322),
        size: 19,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CUSTOMER ILLUSTRATION
// -----------------------------------------------------------------------------

class _CustomerIllustrationPainter
    extends CustomPainter {
  const _CustomerIllustrationPainter({
    required this.active,
  });

  final bool active;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final scale =
        size.shortestSide / 100;

    canvas.save();
    canvas.scale(scale);

    final mainColor = active
        ? const Color(0xFFE5F4F2)
        : const Color(0xFFD1D8D8);

    final accentColor = active
        ? const Color(0xFF72D5CA)
        : const Color(0xFF69BDB5);

    final mainStroke = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin =
          StrokeJoin.round;

    final accentStroke = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin =
          StrokeJoin.round;

    final fill = Paint()
      ..color = active
          ? const Color(0x1A35B3A6)
          : const Color(0x1035B3A6)
      ..style = PaintingStyle.fill;

    final bag = Path()
      ..moveTo(20, 34)
      ..lineTo(80, 34)
      ..lineTo(74, 83)
      ..quadraticBezierTo(
        73.5,
        88,
        68,
        88,
      )
      ..lineTo(32, 88)
      ..quadraticBezierTo(
        26.5,
        88,
        26,
        83,
      )
      ..close();

    canvas.drawPath(bag, fill);
    canvas.drawPath(bag, mainStroke);

    final handle = Path()
      ..moveTo(34, 34)
      ..cubicTo(
        34,
        19,
        42,
        13,
        50,
        13,
      )
      ..cubicTo(
        58,
        13,
        66,
        19,
        66,
        34,
      );

    canvas.drawPath(
      handle,
      mainStroke,
    );

    final innerHandle = Path()
      ..moveTo(39, 32)
      ..cubicTo(
        40,
        22,
        44,
        19,
        50,
        19,
      )
      ..cubicTo(
        56,
        19,
        60,
        22,
        61,
        32,
      );

    canvas.drawPath(
      innerHandle,
      accentStroke,
    );

    final product =
        RRect.fromRectAndRadius(
      const Rect.fromLTWH(
        34,
        47,
        32,
        22,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(
      product,
      accentStroke,
    );

    canvas.drawLine(
      const Offset(41, 54),
      const Offset(59, 54),
      accentStroke,
    );

    canvas.drawLine(
      const Offset(41, 60),
      const Offset(54, 60),
      accentStroke,
    );

    canvas.drawLine(
      const Offset(78, 18),
      const Offset(78, 29),
      accentStroke,
    );

    canvas.drawLine(
      const Offset(72.5, 23.5),
      const Offset(83.5, 23.5),
      accentStroke,
    );

    canvas.drawLine(
      const Offset(16, 55),
      const Offset(16, 62),
      accentStroke,
    );

    canvas.drawLine(
      const Offset(12.5, 58.5),
      const Offset(19.5, 58.5),
      accentStroke,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant
        _CustomerIllustrationPainter
        oldDelegate,
  ) {
    return oldDelegate.active != active;
  }
}

// -----------------------------------------------------------------------------
// RETAILER ILLUSTRATION
// -----------------------------------------------------------------------------

class _RetailerIllustrationPainter
    extends CustomPainter {
  const _RetailerIllustrationPainter({
    required this.active,
  });

  final bool active;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final scale =
        size.shortestSide / 100;

    canvas.save();
    canvas.scale(scale);

    final mainColor = active
        ? const Color(0xFFE5F4F2)
        : const Color(0xFFD1D8D8);

    final accentColor = active
        ? const Color(0xFF72D5CA)
        : const Color(0xFF69BDB5);

    final mainStroke = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin =
          StrokeJoin.round;

    final accentStroke = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin =
          StrokeJoin.round;

    final fill = Paint()
      ..color = active
          ? const Color(0x1A35B3A6)
          : const Color(0x1035B3A6)
      ..style = PaintingStyle.fill;

    final building =
        RRect.fromRectAndRadius(
      const Rect.fromLTWH(
        14,
        34,
        72,
        54,
      ),
      const Radius.circular(5),
    );

    canvas.drawRRect(
      building,
      fill,
    );

    canvas.drawRRect(
      building,
      mainStroke,
    );

    final roof = Path()
      ..moveTo(10, 34)
      ..lineTo(16, 18)
      ..lineTo(84, 18)
      ..lineTo(90, 34);

    canvas.drawPath(
      roof,
      mainStroke,
    );

    final awning = Path()
      ..moveTo(11, 34)
      ..lineTo(89, 34)
      ..lineTo(85, 47)
      ..lineTo(15, 47)
      ..close();

    canvas.drawPath(
      awning,
      mainStroke,
    );

    canvas.drawLine(
      const Offset(29, 34),
      const Offset(30, 47),
      accentStroke,
    );

    canvas.drawLine(
      const Offset(43, 34),
      const Offset(43.5, 47),
      accentStroke,
    );

    canvas.drawLine(
      const Offset(57, 34),
      const Offset(56.5, 47),
      accentStroke,
    );

    canvas.drawLine(
      const Offset(71, 34),
      const Offset(70, 47),
      accentStroke,
    );

    final door =
        RRect.fromRectAndRadius(
      const Rect.fromLTWH(
        42,
        57,
        16,
        31,
      ),
      const Radius.circular(2),
    );

    canvas.drawRRect(
      door,
      mainStroke,
    );

    canvas.drawLine(
      const Offset(50, 58),
      const Offset(50, 87),
      accentStroke,
    );

    final handlePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      const Offset(54, 73),
      1.6,
      handlePaint,
    );

    final leftWindow =
        RRect.fromRectAndRadius(
      const Rect.fromLTWH(
        20,
        57,
        16,
        18,
      ),
      const Radius.circular(2),
    );

    canvas.drawRRect(
      leftWindow,
      accentStroke,
    );

    final rightWindow =
        RRect.fromRectAndRadius(
      const Rect.fromLTWH(
        64,
        57,
        16,
        18,
      ),
      const Radius.circular(2),
    );

    canvas.drawRRect(
      rightWindow,
      accentStroke,
    );

    canvas.drawLine(
      const Offset(23, 65),
      const Offset(33, 65),
      accentStroke,
    );

    canvas.drawLine(
      const Offset(67, 65),
      const Offset(77, 65),
      accentStroke,
    );

    canvas.drawLine(
      const Offset(23, 70),
      const Offset(33, 70),
      accentStroke,
    );

    canvas.drawLine(
      const Offset(67, 70),
      const Offset(77, 70),
      accentStroke,
    );

    final sign =
        RRect.fromRectAndRadius(
      const Rect.fromLTWH(
        37,
        22,
        26,
        8,
      ),
      const Radius.circular(2),
    );

    canvas.drawRRect(
      sign,
      accentStroke,
    );

    canvas.drawCircle(
      const Offset(50, 26),
      2,
      accentStroke,
    );

    canvas.drawLine(
      const Offset(9, 91),
      const Offset(91, 91),
      mainStroke,
    );

    canvas.drawLine(
      const Offset(88, 14),
      const Offset(88, 23),
      accentStroke,
    );

    canvas.drawLine(
      const Offset(83.5, 18.5),
      const Offset(92.5, 18.5),
      accentStroke,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant
        _RetailerIllustrationPainter
        oldDelegate,
  ) {
    return oldDelegate.active != active;
  }
}

