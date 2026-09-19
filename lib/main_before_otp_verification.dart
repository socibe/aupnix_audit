import 'package:flutter/material.dart';

void main() {
  runApp(const AupnixApp());
}

class AupnixApp extends StatelessWidget {
  const AupnixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AUPNIX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D1216),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: Color(0x55888888),
          selectionHandleColor: Colors.white,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

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

            final scale = (availableWidth / artworkWidth)
                .clamp(0.0, availableHeight / artworkHeight);

            final displayedWidth = artworkWidth * scale;
            final displayedHeight = artworkHeight * scale;

            final leftOffset = (availableWidth - displayedWidth) / 2;
            final topOffset = (availableHeight - displayedHeight) / 2;

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
                          builder: (context) => const LoginScreen(),
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool obscurePassword = true;

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
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                  ),
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
          key: const ValueKey('emailField'),
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
          key: const ValueKey('passwordField'),
          controller: passwordController,
          focusNode: passwordFocusNode,
          cursorColor: Colors.white,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
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
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: tealColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _SocialLogoBox(
              assetPath: 'assets/images/google_logo.png',
            ),
            SizedBox(width: compact ? 20 : 26),
            const _SocialLogoBox(
              assetPath: 'assets/images/apple_logo.png',
            ),
          ],
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
                builder: (context) => const CreateAccountScreen(),
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

class _SocialLogoBox extends StatelessWidget {
  const _SocialLogoBox({
    required this.assetPath,
  });

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Image.asset(
        assetPath,
        width: 27,
        height: 27,
        fit: BoxFit.contain,
      ),
    );
  }
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode fullNameFocusNode = FocusNode();
  final FocusNode mobileFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    fullNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    fullNameFocusNode.dispose();
    mobileFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0D0F12);
    const primaryTextColor = Color(0xFFF4F4F4);
    const secondaryTextColor = Color(0xFFBFC0C2);
    const tealColor = Color(0xFF08AEB7);

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
                keyboardOpen ? 12 : 20,
                24,
                keyboardOpen ? 32 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                  ),
                  child: _buildCreateAccountContent(
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
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

  Widget _buildCreateAccountContent({
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color tealColor,
    required bool compact,
  }) {
    final logoWidth = compact ? 155.0 : 185.0;
    final logoHeight = compact ? 46.0 : 54.0;

    final headingSize = compact ? 32.0 : 42.0;
    final descriptionSize = compact ? 16.0 : 19.0;
    final fieldHeight = compact ? 54.0 : 59.0;
    final fieldSpacing = compact ? 10.0 : 14.0;
    final buttonHeight = compact ? 52.0 : 57.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/aupnix_logo.png',
          width: logoWidth,
          height: logoHeight,
          fit: BoxFit.contain,
        ),

        SizedBox(height: compact ? 8 : 13),

        Text(
          'Create Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: headingSize,
            fontWeight: FontWeight.w700,
            height: 1.08,
          ),
        ),

        SizedBox(height: compact ? 7 : 10),

        Text(
          'Create your account to discover products\n'
          'and local stores near you.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: descriptionSize,
            fontWeight: FontWeight.w400,
            height: 1.25,
          ),
        ),

        SizedBox(height: compact ? 16 : 22),

        _buildAccountField(
          controller: fullNameController,
          focusNode: fullNameFocusNode,
          hintText: 'Full Name',
          icon: Icons.person_outline,
          height: fieldHeight,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            mobileFocusNode.requestFocus();
          },
        ),

        SizedBox(height: fieldSpacing),

        _buildAccountField(
          controller: mobileController,
          focusNode: mobileFocusNode,
          hintText: 'Mobile Number',
          icon: Icons.phone_outlined,
          height: fieldHeight,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            emailFocusNode.requestFocus();
          },
        ),

        SizedBox(height: fieldSpacing),

        _buildAccountField(
          controller: emailController,
          focusNode: emailFocusNode,
          hintText: 'Email Address',
          icon: Icons.mail_outline,
          height: fieldHeight,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            passwordFocusNode.requestFocus();
          },
        ),

        SizedBox(height: fieldSpacing),

        _buildAccountField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          hintText: 'Password',
          icon: Icons.lock_outline,
          height: fieldHeight,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            confirmPasswordFocusNode.requestFocus();
          },
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
              size: 23,
            ),
          ),
        ),

        SizedBox(height: fieldSpacing),

        _buildAccountField(
          controller: confirmPasswordController,
          focusNode: confirmPasswordFocusNode,
          hintText: 'Confirm Password',
          icon: Icons.lock_outline,
          height: fieldHeight,
          obscureText: obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                obscureConfirmPassword = !obscureConfirmPassword;
              });
            },
            icon: Icon(
              obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF9B9DA0),
              size: 23,
            ),
          ),
        ),

        SizedBox(height: compact ? 18 : 22),

        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: tealColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(29),
              ),
            ),
            child: Text(
              'Create Account',
              style: TextStyle(
                fontSize: compact ? 18 : 19,
                fontWeight: FontWeight.w700,
              ),
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                'OR',
                style: TextStyle(
                  color: const Color(0xFF8F9397),
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w500,
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

        SizedBox(height: compact ? 18 : 20),

        SizedBox(
          width: double.infinity,
          height: compact ? 52 : 55,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7F7F7),
              foregroundColor: const Color(0xFF1A1A1A),
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(29),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/google_logo.png',
                  width: 23,
                  height: 23,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: const Color(0xFF202124),
                    fontSize: compact ? 17 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: compact ? 18 : 24),

        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                color: const Color(0xFFBFC0C2),
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w400,
              ),
              children: const [
                TextSpan(
                  text: 'Already have an account? ',
                ),
                TextSpan(
                  text: 'Sign In',
                  style: TextStyle(
                    color: Color(0xFF08AEB7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    required double height,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        cursorColor: Colors.white,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          color: Color(0xFFF4F4F4),
          fontSize: 17,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF8B8F93),
            fontSize: 17,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF9B9DA0),
            size: 23,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFF171A1D),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFF454A4F),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFF08AEB7),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
