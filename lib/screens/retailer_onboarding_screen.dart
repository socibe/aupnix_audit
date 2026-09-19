import 'package:flutter/material.dart';

import '../business_context.dart';
import '../services/retailer_workspace_service.dart';
import 'retailer_business_information_screen.dart';

class RetailerOnboardingScreen extends StatefulWidget {
  const RetailerOnboardingScreen({
    super.key,
  });

  @override
  State<RetailerOnboardingScreen> createState() =>
      _RetailerOnboardingScreenState();
}

class _RetailerOnboardingScreenState
    extends State<RetailerOnboardingScreen> {
  bool _isCreatingBusiness = false;

  Future<void> _createBusiness() async {
    if (_isCreatingBusiness) {
      return;
    }

    setState(() {
      _isCreatingBusiness = true;
    });

    try {
      final resolution = await RetailerWorkspaceService.instance
          .resolveCurrentWorkspace();
      final businessId = resolution.businessId ??
          await RetailerWorkspaceService.instance.createWorkspace();

      BusinessContext.instance.establish(
        businessId: businessId,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const RetailerBusinessInformationScreen(),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'AUPNIX_RETAILER_BUSINESS_CREATION_ERROR: $error',
      );
      debugPrint(
        'AUPNIX_RETAILER_BUSINESS_CREATION_STACK: $stackTrace',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not create your Retailer business workspace. '
            'Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBusiness = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    const headingColor = Color(0xFF111111);
    const bodyColor = Color(0xFF6B6B6B);
    const buttonColor = Color(0xFF111111);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            final horizontalPadding =
                constraints.maxWidth < 420 ? 24.0 : 32.0;

            final logoWidth = compact ? 140.0 : 155.0;
            final illustrationWidth = compact ? 185.0 : 205.0;

            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 20 : 24,
                horizontalPadding,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 312,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/aupnix_black.png',
                          width: logoWidth,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: compact ? 28 : 34),
                      Center(
                        child: SizedBox(
                          width: illustrationWidth,
                          child: Image.asset(
                            'assets/images/Local_Storefront.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 32 : 42),
                      const Text(
                        'Create Your Retailer\nWorkspace',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: headingColor,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 40 / 34,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Set up your store on AUPNIX and manage '
                        'your business from one simple workspace. '
                        'Get started in just a few steps.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: bodyColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          height: 27 / 18,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Center(
                        child: Text(
                          'Step 1 of 4',
                          style: TextStyle(
                            color: bodyColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed:
                              _isCreatingBusiness ? null : _createBusiness,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            disabledBackgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isCreatingBusiness
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Create Retailer Workspace',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 22,
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
          },
        ),
      ),
    );
  }
}
