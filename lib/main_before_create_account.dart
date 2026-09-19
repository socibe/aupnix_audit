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

        RichText(
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
