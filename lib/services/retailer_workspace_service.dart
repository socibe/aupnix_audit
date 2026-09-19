import 'package:supabase_flutter/supabase_flutter.dart';

import '../business_context.dart';

enum RetailerWorkspaceDestination {
  createWorkspace,
  businessInformation,
  storeSetup,
  paymentAuthorization,
  authorizationRecovery,
  dashboard,
  unavailable,
}

class RetailerWorkspaceResolution {
  const RetailerWorkspaceResolution({
    required this.destination,
    this.businessId,
    this.businessStatus,
    this.onboardingState,
    this.paymentAuthorizationStatus,
  });

  final RetailerWorkspaceDestination destination;
  final String? businessId;
  final String? businessStatus;
  final String? onboardingState;
  final String? paymentAuthorizationStatus;
}

class RetailerWorkspaceService {
  RetailerWorkspaceService._();

  static final RetailerWorkspaceService instance =
      RetailerWorkspaceService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<RetailerWorkspaceResolution> resolveCurrentWorkspace() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw StateError('No authenticated user is available.');
    }

    final memberships = await _supabase
        .from('business_memberships')
        .select('business_id, role, status')
        .eq('user_id', user.id)
        .eq('role', 'owner')
        .eq('status', 'active');

    if (memberships.isEmpty) {
      BusinessContext.instance.clear();

      return const RetailerWorkspaceResolution(
        destination: RetailerWorkspaceDestination.createWorkspace,
      );
    }

    for (final membership in memberships) {
      final businessId = membership['business_id'];

      if (businessId is! String || businessId.trim().isEmpty) {
        continue;
      }

      final business = await _supabase
          .from('businesses')
          .select('id, status')
          .eq('id', businessId)
          .maybeSingle();

      if (business == null) {
        continue;
      }

      final businessStatus = business['status'];

      if (businessStatus is! String) {
        continue;
      }

      final onboarding = await _supabase
          .from('retailer_onboarding_states')
          .select('business_id, state')
          .eq('business_id', businessId)
          .maybeSingle();

      if (onboarding == null) {
        await _supabase
            .from('retailer_onboarding_states')
            .upsert(
              {
                'business_id': businessId,
                'state': 'WORKSPACE_CREATED',
              },
              onConflict: 'business_id',
              ignoreDuplicates: true,
            );

        BusinessContext.instance.establish(
          businessId: businessId,
        );

        return RetailerWorkspaceResolution(
          destination: RetailerWorkspaceDestination.businessInformation,
          businessId: businessId,
          businessStatus: businessStatus,
          onboardingState: 'WORKSPACE_CREATED',
        );
      }

      final onboardingState = onboarding['state'];

      if (onboardingState is! String) {
        continue;
      }

      final payment = await _supabase
          .from('business_payment_authorizations')
          .select('status')
          .eq('business_id', businessId)
          .maybeSingle();

      final paymentStatus = payment?['status'];
      final normalizedPaymentStatus =
          paymentStatus is String ? paymentStatus : null;

      BusinessContext.instance.establish(
        businessId: businessId,
      );

      return RetailerWorkspaceResolution(
        destination: _destinationFor(
          onboardingState: onboardingState,
          paymentStatus: normalizedPaymentStatus,
          businessStatus: businessStatus,
        ),
        businessId: businessId,
        businessStatus: businessStatus,
        onboardingState: onboardingState,
        paymentAuthorizationStatus: normalizedPaymentStatus,
      );
    }

    BusinessContext.instance.clear();

    return const RetailerWorkspaceResolution(
      destination: RetailerWorkspaceDestination.createWorkspace,
    );
  }

  Future<void> completeBusinessInformation() async {
    final businessId = BusinessContext.instance.businessId;

    if (businessId == null || businessId.trim().isEmpty) {
      throw StateError(
        'No active retailer business is available.',
      );
    }

    final current = await _supabase
        .from('retailer_onboarding_states')
        .select('business_id, state')
        .eq('business_id', businessId)
        .maybeSingle();

    if (current == null) {
      throw StateError(
        'Retailer onboarding state could not be found for the active '
        'business workspace.',
      );
    }

    final currentState = current['state'];

    if (currentState == 'BUSINESS_INFORMATION_COMPLETED') {
      return;
    }

    if (currentState != 'WORKSPACE_CREATED') {
      throw StateError(
        'Retailer onboarding state cannot be advanced from '
        '$currentState to BUSINESS_INFORMATION_COMPLETED.',
      );
    }

    await _supabase
        .from('retailer_onboarding_states')
        .update({
          'state': 'BUSINESS_INFORMATION_COMPLETED',
        })
        .eq('business_id', businessId)
        .eq('state', 'WORKSPACE_CREATED');

    final updated = await _supabase
        .from('retailer_onboarding_states')
        .select('business_id, state')
        .eq('business_id', businessId)
        .maybeSingle();

    if (updated == null ||
        updated['state'] != 'BUSINESS_INFORMATION_COMPLETED') {
      throw StateError(
        'Retailer onboarding state update could not be verified.',
      );
    }
  }
  Future<String> createWorkspace() async {
    final result = await _supabase.rpc(
      'get_or_create_retailer_workspace',
    );

    if (result is! String || result.trim().isEmpty) {
      throw StateError(
        'Retailer workspace creation did not return a valid business ID.',
      );
    }

    final businessId = result.trim();

    final business = await _supabase
        .from('businesses')
        .select('id, status')
        .eq('id', businessId)
        .maybeSingle();

    if (business == null || business['id'] is! String) {
      throw StateError(
        'Created retailer workspace could not be verified.',
      );
    }

    BusinessContext.instance.establish(
      businessId: businessId,
    );

    return businessId;
  }

  Future<void> completeStoreSetup() async {
    final businessId = BusinessContext.instance.businessId;

    if (businessId == null || businessId.trim().isEmpty) {
      throw StateError(
        'No active retailer business is available.',
      );
    }

    final current = await _supabase
        .from('retailer_onboarding_states')
        .select('business_id, state')
        .eq('business_id', businessId)
        .maybeSingle();

    if (current == null) {
      throw StateError(
        'Retailer onboarding state could not be found for the active '
        'business workspace.',
      );
    }

    final currentState = current['state'];

    if (currentState == 'STORE_SETUP_COMPLETED') {
      return;
    }

    if (currentState != 'BUSINESS_INFORMATION_COMPLETED') {
      throw StateError(
        'Retailer onboarding state cannot be advanced from '
        '$currentState to STORE_SETUP_COMPLETED.',
      );
    }

    await _supabase
        .from('retailer_onboarding_states')
        .update({
          'state': 'STORE_SETUP_COMPLETED',
        })
        .eq('business_id', businessId)
        .eq('state', 'BUSINESS_INFORMATION_COMPLETED');

    final updated = await _supabase
        .from('retailer_onboarding_states')
        .select('business_id, state')
        .eq('business_id', businessId)
        .maybeSingle();

    if (updated == null ||
        updated['state'] != 'STORE_SETUP_COMPLETED') {
      throw StateError(
        'Retailer onboarding state update could not be verified.',
      );
    }
  }
  RetailerWorkspaceDestination _destinationFor({
    required String onboardingState,
    required String? paymentStatus,
    required String businessStatus,
  }) {
    if (onboardingState == 'COMPLETED') {
      if (paymentStatus == 'active' && businessStatus == 'active') {
        return RetailerWorkspaceDestination.dashboard;
      }

      if (paymentStatus == 'revoked') {
        return RetailerWorkspaceDestination.authorizationRecovery;
      }

      return RetailerWorkspaceDestination.unavailable;
    }

    switch (onboardingState) {
      case 'WORKSPACE_CREATED':
        return RetailerWorkspaceDestination.businessInformation;
      case 'BUSINESS_INFORMATION_COMPLETED':
        return RetailerWorkspaceDestination.storeSetup;
      case 'STORE_SETUP_COMPLETED':
      case 'PAYMENT_AUTHORIZATION_PENDING':
      case 'PAYMENT_AUTHORIZATION_FAILED':
        return RetailerWorkspaceDestination.paymentAuthorization;
      default:
        return RetailerWorkspaceDestination.unavailable;
    }
  }
}

