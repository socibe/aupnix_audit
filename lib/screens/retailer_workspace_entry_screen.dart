import 'package:flutter/material.dart';

import '../business_context.dart';
import '../services/retailer_workspace_service.dart';
import 'retailer_business_information_screen.dart';
import 'retailer_onboarding_screen.dart';
import 'retailer_payment_authorization_screen.dart';
import 'retailer_store_location_screen.dart';

class RetailerWorkspaceEntryScreen extends StatefulWidget {
  const RetailerWorkspaceEntryScreen({
    super.key,
    this.startBusinessInformation = false,
  });

  final bool startBusinessInformation;

  @override
  State<RetailerWorkspaceEntryScreen> createState() =>
      _RetailerWorkspaceEntryScreenState();
}

class _RetailerWorkspaceEntryScreenState
    extends State<RetailerWorkspaceEntryScreen> {
  bool _isResolving = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _resolveWorkspace();
  }

  Future<void> _resolveWorkspace() async {
    try {
      final resolution = await RetailerWorkspaceService.instance
          .resolveCurrentWorkspace();

      if (!mounted) {
        return;
      }

      if (widget.startBusinessInformation &&
          resolution.businessId != null &&
          resolution.destination == RetailerWorkspaceDestination.businessInformation) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const RetailerBusinessInformationScreen(),
          ),
        );
        return;
      }

      switch (resolution.destination) {
        case RetailerWorkspaceDestination.createWorkspace:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const RetailerOnboardingScreen(),
            ),
          );
          return;

        case RetailerWorkspaceDestination.businessInformation:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const RetailerBusinessInformationScreen(),
            ),
          );
          return;

        case RetailerWorkspaceDestination.storeSetup:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const RetailerStoreLocationScreen(),
            ),
          );
          return;

        case RetailerWorkspaceDestination.paymentAuthorization:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const RetailerPaymentAuthorizationScreen(),
            ),
          );
          return;

        case RetailerWorkspaceDestination.authorizationRecovery:
        case RetailerWorkspaceDestination.dashboard:
        case RetailerWorkspaceDestination.unavailable:
          setState(() {
            _isResolving = false;
            _errorMessage =
                'This retailer workspace is ready for the next stage, '
                'but that stage is not available yet.';
          });
          return;
      }
    } catch (error, stackTrace) {
      debugPrint(
        'AUPNIX_RETAILER_WORKSPACE_RESOLUTION_ERROR: $error',
      );
      debugPrint(
        'AUPNIX_RETAILER_WORKSPACE_RESOLUTION_STACK: $stackTrace',
      );

      if (!mounted) {
        return;
      }

      BusinessContext.instance.clear();

      setState(() {
        _isResolving = false;
        _errorMessage =
            'We could not determine your retailer workspace. '
            'Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const headingColor = Color(0xFF111111);
    const bodyColor = Color(0xFF6B6B6B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _isResolving
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Retailer Workspace',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: headingColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage ??
                            'We could not determine the next step.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: bodyColor,
                          fontSize: 16,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _resolveWorkspace,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}


