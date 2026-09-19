import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../business_context.dart';
import '../models/business_image.dart';
import '../repositories/business_image_repository.dart';
import '../repositories/business_profile_repository.dart';
import '../services/business_image_service.dart';
import '../services/retailer_workspace_service.dart';
import 'retailer_onboarding_screen.dart';
import 'retailer_store_location_screen.dart';

class RetailerBusinessInformationScreen extends StatefulWidget {
  const RetailerBusinessInformationScreen({
    super.key,
  });

  @override
  State<RetailerBusinessInformationScreen> createState() =>
      _RetailerBusinessInformationScreenState();
}

class _RetailerBusinessInformationScreenState
    extends State<RetailerBusinessInformationScreen> {
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  XFile? _profileSelection;
  XFile? _bannerSelection;

  Uint8List? _profilePreviewBytes;
  Uint8List? _bannerPreviewBytes;

  bool _isSaving = false;
  bool _isLoading = true;
  String? _storeNameError;

  @override
  void initState() {
    super.initState();
    _loadExistingBusinessInformation();
  }

  Future<void> _loadExistingBusinessInformation() async {
    final businessId = BusinessContext.instance.businessId;

    if (businessId == null || businessId.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError(
          'Your business workspace is unavailable. '
          'Please return and create the workspace again.',
        );
      }
      return;
    }

    try {
      final profileRepository = BusinessProfileRepository.instance;
      final imageRepository = BusinessImageRepository.instance;
      final imageService = BusinessImageService.instance;

      final profile = await profileRepository.getBusinessProfile(businessId);

      final profileImage = await imageRepository.getBusinessImage(
        businessId: businessId,
        imageRole: BusinessImage.profileRole,
      );

      final bannerImage = await imageRepository.getBusinessImage(
        businessId: businessId,
        imageRole: BusinessImage.bannerRole,
      );

      Uint8List? profileBytes;
      Uint8List? bannerBytes;

      if (profileImage != null) {
        profileBytes = await imageService.downloadImage(
          profileImage.storageKey,
        );
      }

      if (bannerImage != null) {
        bannerBytes = await imageService.downloadImage(
          bannerImage.storageKey,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _storeNameController.text =
            profile?['display_name'] is String
                ? profile!['display_name'] as String
                : '';
        _descriptionController.text =
            profile?['description'] is String
                ? profile!['description'] as String
                : '';
        _profilePreviewBytes = profileBytes;
        _bannerPreviewBytes = bannerBytes;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'AUPNIX_RETAILER_STEP_2_LOAD_ERROR: $error',
      );
      debugPrint(
        'AUPNIX_RETAILER_STEP_2_LOAD_STACK: $stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showError(
        'We could not load your saved business information. '
        'Please try again.',
      );
    }
  }

  void _goBackToOnboarding() {
    if (_isSaving || !mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const RetailerOnboardingScreen(),
      ),
    );
  }
  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectProfileImage() async {
    final file = await BusinessImageService.instance.pickImage();

    if (file == null || !mounted) {
      return;
    }

    final bytes = await file.readAsBytes();

    if (bytes.length > BusinessImageService.maxOriginalBytes) {
      _showError(
        'The selected profile image is larger than 10 MB.',
      );
      return;
    }

    setState(() {
      _profileSelection = file;
      _profilePreviewBytes = bytes;
    });
  }

  Future<void> _selectBannerImage() async {
    final file = await BusinessImageService.instance.pickImage();

    if (file == null || !mounted) {
      return;
    }

    final bytes = await file.readAsBytes();

    if (bytes.length > BusinessImageService.maxOriginalBytes) {
      _showError(
        'The selected banner image is larger than 10 MB.',
      );
      return;
    }

    setState(() {
      _bannerSelection = file;
      _bannerPreviewBytes = bytes;
    });
  }

  Future<void> _continue() async {
    if (_isSaving || _isLoading) {
      return;
    }

    final businessId = BusinessContext.instance.businessId;

    if (businessId == null || businessId.trim().isEmpty) {
      _showError(
        'Your business workspace is unavailable. '
        'Please return and create the workspace again.',
      );
      return;
    }

    final storeName = _storeNameController.text.trim();

    if (storeName.isEmpty) {
      setState(() {
        _storeNameError = 'Store Name is required.';
      });
      return;
    }

    setState(() {
      _storeNameError = null;
      _isSaving = true;
    });

    try {
      final imageService = BusinessImageService.instance;

      if (_profileSelection != null) {
        final processed = await imageService.processProfileImage(
          _profileSelection!,
        );

        await imageService.uploadAndPersist(
          businessId: businessId,
          imageRole: BusinessImage.profileRole,
          processedBytes: processed,
        );
      }

      if (_bannerSelection != null) {
        final processed = await imageService.processBannerImage(
          _bannerSelection!,
        );

        await imageService.uploadAndPersist(
          businessId: businessId,
          imageRole: BusinessImage.bannerRole,
          processedBytes: processed,
        );
      }

      await BusinessProfileRepository.instance.saveBusinessInformation(
        businessId: businessId,
        displayName: storeName,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      await RetailerWorkspaceService.instance.completeBusinessInformation();

      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const RetailerStoreLocationScreen(),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'AUPNIX_RETAILER_STEP_2_SAVE_ERROR: $error',
      );
      debugPrint(
        'AUPNIX_RETAILER_STEP_2_SAVE_STACK: $stackTrace',
      );

      if (!mounted) {
        return;
      }

      _showError(
        'We could not save your business information. '
        'Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const headingColor = Color(0xFF111111);
    const bodyColor = Color(0xFF6B6B6B);
    const borderColor = Color(0xFFE3E3E3);
    const buttonColor = Color(0xFF111111);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBackToOnboarding();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth < 420 ? 20.0 : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: (_isSaving || _isLoading) ? null : _goBackToOnboarding,
                                icon: const Icon(Icons.arrow_back),
                                tooltip: 'Back',
                              ),
                            ),
                            Image.asset(
                              'assets/images/aupnix_black.png',
                              width: 120,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Step 2 of 4',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: bodyColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 0.5,
                          minHeight: 5,
                          backgroundColor: Color(0xFFE9E9E9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            buttonColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Tell Us About Your Business',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: headingColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your workspace is ready. Now tell us '
                        'about your business.',
                        style: TextStyle(
                          color: bodyColor,
                          fontSize: 16,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Store Identity',
                        style: TextStyle(
                          color: headingColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: _ProfileImageSelector(
                          imageBytes: _profilePreviewBytes,
                          onPressed: _isLoading ? () {} : _selectProfileImage,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _BannerImageSelector(
                        imageBytes: _bannerPreviewBytes,
                        onPressed: _isLoading ? () {} : _selectBannerImage,
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Business Details',
                        style: TextStyle(
                          color: headingColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _storeNameController,
                        cursorColor: headingColor,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_storeNameError != null) {
                            setState(() {
                              _storeNameError = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Store Name',
                          hintText: 'Enter your store name',
                          errorText: _storeNameError,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: borderColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: borderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: headingColor,
                              width: 1.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _descriptionController,
                        cursorColor: headingColor,
                        minLines: 3,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          labelText: 'Business Description',
                          hintText: 'Tell customers about your business',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: borderColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: borderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: headingColor,
                              width: 1.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_isSaving || _isLoading) ? null : _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            disabledBackgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 21,
                                  height: 21,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 20,
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
    ),
  );
  }
}

class _ProfileImageSelector extends StatelessWidget {
  const _ProfileImageSelector({
    required this.imageBytes,
    required this.onPressed,
  });

  final Uint8List? imageBytes;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: const Color(0xFFF3F3F3),
                backgroundImage: imageBytes == null
                    ? null
                    : MemoryImage(imageBytes!),
                child: imageBytes == null
                    ? const Icon(
                        Icons.storefront_outlined,
                        size: 34,
                        color: Color(0xFF777777),
                      )
                    : null,
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Store Profile Picture',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Optional',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF777777),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _BannerImageSelector extends StatelessWidget {
  const _BannerImageSelector({
    required this.imageBytes,
    required this.onPressed,
  });

  final Uint8List? imageBytes;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: AspectRatio(
            aspectRatio: 3 / 1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(14),
                image: imageBytes == null
                    ? null
                    : DecorationImage(
                        image: MemoryImage(imageBytes!),
                        fit: BoxFit.cover,
                      ),
              ),
              child: imageBytes == null
                  ? const Center(
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        size: 28,
                        color: Color(0xFF777777),
                      ),
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF111111),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Store Banner',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Optional',
          style: TextStyle(
            color: Color(0xFF777777),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}



