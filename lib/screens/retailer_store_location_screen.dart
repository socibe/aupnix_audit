import '../business_context.dart';
import '../services/retailer_workspace_service.dart';
import '../repositories/business_location_operating_hours_repository.dart';
import '../repositories/business_location_repository.dart';
import '../repositories/business_profile_repository.dart';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'retailer_business_information_screen.dart';
import 'retailer_store_location_picker_screen.dart';
import 'package:flutter/services.dart';

class RetailerStoreLocationScreen extends StatefulWidget {
  const RetailerStoreLocationScreen({
    super.key,
  });

  @override
  State<RetailerStoreLocationScreen> createState() =>
      _RetailerStoreLocationScreenState();
}

class _RetailerStoreLocationScreenState
    extends State<RetailerStoreLocationScreen> {
  final _businessLocationRepository = BusinessLocationRepository();
  final _operatingHoursRepository = BusinessLocationOperatingHoursRepository();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _localityController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _mobileController = TextEditingController();

  final Map<String, _OperatingHours> _hours = {
    'Monday': _OperatingHours.open(
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 20, minute: 0),
    ),
    'Tuesday': _OperatingHours.open(
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 20, minute: 0),
    ),
    'Wednesday': _OperatingHours.open(
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 20, minute: 0),
    ),
    'Thursday': _OperatingHours.open(
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 20, minute: 0),
    ),
    'Friday': _OperatingHours.open(
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 20, minute: 0),
    ),
    'Saturday': _OperatingHours.open(
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 20, minute: 0),
    ),
    'Sunday': _OperatingHours.closed(),
  };

  bool _isSaving = false;
  String? _locationError;
  LatLng? _confirmedStoreLocation;
  String? _mobileError;

  @override
  void initState() {
    super.initState();
    _loadExistingLocation();
  }

  void _goBackToBusinessInformation() {
    if (_isSaving || !mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const RetailerBusinessInformationScreen(),
      ),
    );
  }
  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _localityController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLocation() async {
    final businessId = BusinessContext.instance.businessId;
    if (businessId == null || businessId.trim().isEmpty) {
      return;
    }

    try {
      final profile =
          await BusinessProfileRepository.instance.getBusinessProfile(
        businessId,
      );
      final contactPhone = profile?['contact_phone'];
      if (contactPhone is String && contactPhone.trim().isNotEmpty) {
        _mobileController.text = contactPhone;
      }

      final location = await _businessLocationRepository.getPrimaryLocation(
        businessId,
      );
      if (location != null) {
        if (mounted) {
          _addressLine1Controller.text =
              (location['address_line_1'] as String?) ?? '';
          _addressLine2Controller.text =
              (location['address_line_2'] as String?) ?? '';
          _localityController.text =
              (location['locality'] as String?) ?? '';
          _cityController.text = (location['city'] as String?) ?? '';
          _stateController.text = (location['state'] as String?) ?? '';
          _pinCodeController.text =
              (location['postal_code'] as String?) ?? '';
          final latitude = location['latitude'];
          final longitude = location['longitude'];
          if (latitude is num && longitude is num) {
            setState(() {
              _confirmedStoreLocation = LatLng(
                latitude.toDouble(),
                longitude.toDouble(),
              );
            });
          }
        }

        final locationId = location['id'];
        if (locationId is String && locationId.trim().isNotEmpty) {
          final savedHours =
              await _operatingHoursRepository.getForLocation(locationId);

          if (savedHours.isNotEmpty && mounted) {
            const dayNames = <int, String>{
              1: 'Monday',
              2: 'Tuesday',
              3: 'Wednesday',
              4: 'Thursday',
              5: 'Friday',
              6: 'Saturday',
              7: 'Sunday',
            };
            final restoredHours = <String, _OperatingHours>{};

            for (final row in savedHours) {
              final dayOfWeek = row['day_of_week'];
              if (dayOfWeek is! int) {
                continue;
              }

              final day = dayNames[dayOfWeek];
              if (day == null) {
                continue;
              }

              final isClosed = row['is_closed'] == true;
              if (isClosed) {
                restoredHours[day] = _OperatingHours.closed();
                continue;
              }

              final opening = _parseStoredTime(row['opening_time']);
              final closing = _parseStoredTime(row['closing_time']);
              if (opening != null && closing != null) {
                restoredHours[day] = _OperatingHours.open(opening, closing);
              }
            }

            if (restoredHours.isNotEmpty) {
              setState(() {
                _hours.addAll(restoredHours);
              });
            }
          }
        }
      }
    } catch (error) {
      debugPrint('AUPNIX_RETAILER_STEP_3_LOAD_ERROR: $error');
    }
  }

  TimeOfDay? _parseStoredTime(dynamic value) {
    if (value is! String) {
      return null;
    }

    final parts = value.split(':');
    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }
  Future<void> _editHours(String day) async {
    final current = _hours[day]!;
    var isClosed = current.isClosed;
    var opening = current.opening ?? const TimeOfDay(hour: 9, minute: 0);
    var closing = current.closing ?? const TimeOfDay(hour: 20, minute: 0);

    final result = await showModalBottomSheet<_OperatingHours>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Closed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: isClosed,
                      activeTrackColor: const Color(0xFF1C9F95),
                      activeThumbColor: Colors.white,
                      onChanged: (value) {
                        setSheetState(() {
                          isClosed = value;
                        });
                      },
                    ),
                    if (!isClosed) ...[
                      const SizedBox(height: 8),
                      _TimeSelector(
                        label: 'Opens',
                        value: opening,
                        onTap: () async {
                          final selected = await showTimePicker(
                            context: context,
                            initialTime: opening,
                          );
                          if (selected != null) {
                            setSheetState(() {
                              opening = selected;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _TimeSelector(
                        label: 'Closes',
                        value: closing,
                        onTap: () async {
                          final selected = await showTimePicker(
                            context: context,
                            initialTime: closing,
                          );
                          if (selected != null) {
                            setSheetState(() {
                              closing = selected;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop(
                            isClosed
                                ? _OperatingHours.closed()
                                : _OperatingHours.open(opening, closing),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111111),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          'Save Hours',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _hours[day] = result;
      });
    }
  }

  Future<void> _pinStoreLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => RetailerStoreLocationPickerScreen(
          initialLocation: _confirmedStoreLocation,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _confirmedStoreLocation = result;
        _locationError = null;
      });
    }
  }
  Future<void> _continue() async {
    if (_isSaving) {
      return;
    }

    if (_confirmedStoreLocation == null) {
      setState(() {
        _locationError = 'Please pin and confirm your store location before continuing.';
      });
      return;
    }
    final businessId = BusinessContext.instance.businessId;
    if (businessId == null || businessId.trim().isEmpty) {
      setState(() {
        _locationError = 'Your business workspace is unavailable. Please return and create the workspace again.';
      });
      return;
    }

    final addressLine1 = _addressLine1Controller.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pinCode = _pinCodeController.text.trim();
    final mobile = _mobileController.text.trim();

    setState(() {
      _locationError = addressLine1.isEmpty ||
              city.isEmpty ||
              state.isEmpty ||
              pinCode.isEmpty
          ? 'Please complete all required store location fields.'
          : !RegExp(r'^\d{6}$').hasMatch(pinCode)
              ? 'PIN Code must be exactly 6 digits.'
              : null;
      _mobileError = mobile.isEmpty
          ? 'Mobile Number is required.'
          : !RegExp(r'^\d{10}$').hasMatch(mobile)
              ? 'Mobile Number must be exactly 10 digits.'
              : null;
    });

    if (_locationError != null || _mobileError != null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await BusinessProfileRepository.instance.updateContactPhone(
        businessId: businessId,
        contactPhone: mobile,
      );

      final locationId = await _businessLocationRepository.upsertPrimaryLocation(
        businessId: businessId,
        addressLine1: addressLine1,
        addressLine2: _addressLine2Controller.text.trim().isEmpty ? null : _addressLine2Controller.text.trim(),
        locality: _localityController.text.trim().isEmpty ? null : _localityController.text.trim(),
        city: city,
        state: state,
        postalCode: pinCode,
        latitude: _confirmedStoreLocation?.latitude,
        longitude: _confirmedStoreLocation?.longitude,
      );

      final dayNumbers = <String, int>{
        'Monday': 1,
        'Tuesday': 2,
        'Wednesday': 3,
        'Thursday': 4,
        'Friday': 5,
        'Saturday': 6,
        'Sunday': 7,
      };
      final openingTimes = <int, TimeOfDay?>{};
      final closingTimes = <int, TimeOfDay?>{};
      final closedDays = <int>{};
      for (final entry in _hours.entries) {
        final dayNumber = dayNumbers[entry.key]!;
        if (entry.value.isClosed) {
          closedDays.add(dayNumber);
        } else {
          openingTimes[dayNumber] = entry.value.opening;
          closingTimes[dayNumber] = entry.value.closing;
        }
      }
      await _operatingHoursRepository.replaceForLocation(
        businessLocationId: locationId,
        openingTimes: openingTimes,
        closingTimes: closingTimes,
        closedDays: closedDays,
      );

      await RetailerWorkspaceService.instance.completeStoreSetup();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store details saved successfully.'),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('AUPNIX_RETAILER_STEP_3_SAVE_ERROR: $error');
      debugPrint('AUPNIX_RETAILER_STEP_3_SAVE_STACK: $stackTrace');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not save your store details. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const headingColor = Color(0xFF111111);
    const bodyColor = Color(0xFF666666);
    const borderColor = Color(0xFFE0E0E0);
    const buttonColor = Color(0xFF111111);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBackToBusinessInformation();
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
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
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
                                onPressed:
                                    _isSaving ? null : _goBackToBusinessInformation,
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
                        'Step 3 of 4',
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
                          value: 0.75,
                          minHeight: 5,
                          backgroundColor: Color(0xFFE9E9E9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            buttonColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Set Up Your Store',
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
                        'Add your store location, contact details, and '
                        'operating hours so customers know where and '
                        'when they can visit you.',
                        style: TextStyle(
                          color: bodyColor,
                          fontSize: 16,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(
                        'Store Location',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _addressLine1Controller,
                        label: 'Address Line 1',
                        hint: 'Enter your store address',
                        requiredField: true,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _addressLine2Controller,
                        label: 'Address Line 2',
                        hint: 'Apartment, building, landmark',
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _localityController,
                        label: 'Locality / Area',
                        hint: 'Enter locality or area',
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Field(
                              controller: _cityController,
                              label: 'City',
                              hint: 'City',
                              requiredField: true,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Field(
                              controller: _stateController,
                              label: 'State',
                              hint: 'State',
                              requiredField: true,
                              borderColor: borderColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _pinCodeController,
                        label: 'PIN Code',
                        hint: '6-digit PIN code',
                        requiredField: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        borderColor: borderColor,
                      ),
                      if (_locationError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _locationError!,
                          style: const TextStyle(
                            color: Color(0xFFB3261E),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _pinStoreLocation,
                        icon: Icon(
                          _confirmedStoreLocation == null
                              ? Icons.location_on_outlined
                              : Icons.check_circle_outline,
                          size: 21,
                        ),
                        label: Text(
                          _confirmedStoreLocation == null
                              ? 'Pin Store Location'
                              : 'Store Location Confirmed',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _confirmedStoreLocation == null
                              ? headingColor
                              : const Color(0xFF1C9F95),
                          minimumSize: const Size.fromHeight(50),
                          side: BorderSide(
                            color: _confirmedStoreLocation == null
                                ? borderColor
                                : const Color(0xFF1C9F95),
                          ),
                          backgroundColor: _confirmedStoreLocation == null
                              ? Colors.white
                              : const Color(0xFFEAF8F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(
                        'Store Contact',
                        icon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _mobileController,
                        label: 'Mobile Number',
                        hint: 'XXXXX XXXXX',
                        requiredField: true,
                        keyboardType: TextInputType.phone,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        prefixText: '+91 ',
                        borderColor: borderColor,
                        errorText: _mobileError,
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(
                        'Operating Hours',
                        icon: Icons.access_time_outlined,
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Set the hours customers can visit your store.',
                        style: TextStyle(
                          color: bodyColor,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._hours.keys.map(
                        (day) => _HoursRow(
                          day: day,
                          hours: _hours[day]!,
                          onTap: () => _editHours(day),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            disabledBackgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
    this.title, {
    this.icon,
  });

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      style: const TextStyle(
        color: Color(0xFF111111),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );

    if (icon == null) {
      return titleWidget;
    }

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF111111),
        ),
        const SizedBox(width: 8),
        titleWidget,
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.borderColor,
    this.requiredField = false,
    this.keyboardType,
    this.inputFormatters,
    this.prefixText,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final Color borderColor;
  final bool requiredField;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      cursorColor: Colors.black,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        errorText: errorText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF111111),
            width: 1.3,
          ),
        ),
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  const _HoursRow({
    required this.day,
    required this.hours,
    required this.onTap,
  });

  final String day;
  final _OperatingHours hours;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = hours.isClosed
        ? 'Closed'
        : '${_formatTime(hours.opening!)} – ${_formatTime(hours.closing!)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E5E5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                day,
                style: const TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: hours.isClosed
                    ? const Color(0xFF777777)
                    : const Color(0xFF333333),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 7),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF777777),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  const _TimeSelector({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              _formatTime(value),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.access_time_outlined,
              size: 19,
              color: Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperatingHours {
  _OperatingHours.open(this.opening, this.closing)
      : isClosed = false;

  _OperatingHours.closed()
      : isClosed = true,
        opening = null,
        closing = null;

  final bool isClosed;
  final TimeOfDay? opening;
  final TimeOfDay? closing;
}

String _formatTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

