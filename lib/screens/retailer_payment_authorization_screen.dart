import 'package:flutter/material.dart';

class RetailerPaymentAuthorizationScreen extends StatelessWidget {
  const RetailerPaymentAuthorizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const headingColor = Color(0xFF111111);
    const bodyColor = Color(0xFF666666);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/aupnix_black.png',
                  width: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Payment & Commission Authorization',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your store setup is complete. Payment and commission authorization is the next onboarding stage.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: bodyColor,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Authorization has not been completed yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: bodyColor,
                    fontSize: 14,
                    height: 1.4,
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
