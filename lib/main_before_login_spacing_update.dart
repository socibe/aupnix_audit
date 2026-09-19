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

  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 18,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),

                      Image.asset(
                        'assets/images/aupnix_logo.png',
                        width: 190,
                        height: 54,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 9),

                      const Text(
                        'Sign In To Continue With AUPNIX.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email Address',
                          style: TextStyle(
                            color: Color(0xFFE5E5E5),
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 7),

                      TextField(
                        controller: emailController,
                        cursorColor: Colors.white,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          color: primaryTextColor,
                          fontSize: 17,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your email address...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF888B8E),
                            fontSize: 17,
                          ),
                          prefixIcon: const Icon(
                            Icons.mail_outline,
                            color: Color(0xFF9B9DA0),
                            size: 24,
                          ),
                          filled: true,
                          fillColor: backgroundColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: tealColor,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: tealColor,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password',
                          style: TextStyle(
                            color: Color(0xFFE5E5E5),
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 7),

                      TextField(
                        controller: passwordController,
                        cursorColor: Colors.white,
                        obscureText: obscurePassword,
                        style: const TextStyle(
                          color: primaryTextColor,
                          fontSize: 17,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your password...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF888B8E),
                            fontSize: 17,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF9B9DA0),
                            size: 24,
                          ),
                          suffixIcon: IconButton(
                            tooltip: obscurePassword
                                ? 'Show password'
                                : 'Hide password',
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
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
                            borderSide: const BorderSide(
                              color: tealColor,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFFD2D3D4),
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
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
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Or sign in with:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoogleLogo(),
                          SizedBox(width: 46),
                          Icon(
                            Icons.apple,
                            color: Color(0xFFBFC0C2),
                            size: 32,
                          ),
                        ],
                      ),

                      const SizedBox(height: 27),

                      const Divider(
                        color: Color(0xFF292B2D),
                        thickness: 1,
                        height: 1,
                      ),

                      const SizedBox(height: 18),

                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            color: Color(0xFFD2D3D4),
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            TextSpan(
                              text: "Don't Have An Account? ",
                            ),
                            TextSpan(
                              text: 'Sign Up',
                              style: TextStyle(
                                color: tealColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),
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

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFFBFC0C2),
        fontSize: 42,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    );
  }
}
