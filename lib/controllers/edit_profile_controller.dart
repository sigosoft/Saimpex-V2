import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/colors.dart';
import '../constants/country_codes.dart';
import '../core/network/api_exception.dart';
import '../core/storage/session_store.dart';
import '../models/auth_user.dart';
import '../models/profile_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';

class EditProfileController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final nameFocus = FocusNode();
  final phoneFocus = FocusNode();

  final nameText = ''.obs;
  final phoneText = ''.obs;
  final countryCode = '+222'.obs;
  final countryFlag = '🇲🇷'.obs;
  final remoteImage = RxnString();
  final localImagePath = RxnString();
  final editingName = false.obs;
  final editingPhone = false.obs;
  final isSaving = false.obs;

  bool _edited = false;

  ProfileRepository get _profile => Get.find<ProfileRepository>();
  SessionStore get _session => Get.find<SessionStore>();

  Future<void> loadProfile() async {
    _edited = false;
    final cached = _session.readUser();
    if (cached != null) {
      _fill(cached);
    }

    final token = _session.token;
    if (token == null || token.isEmpty) return;

    try {
      final profile = (await _profile.fetchProfile(
        apiLanguageCode(),
      )).mergedWith(cached);
      if (!_edited) {
        _fill(profile);
      }
      await _session.saveSession(token: token, user: profile);
    } on ApiException catch (error) {
      if (cached == null) {
        showAppToast(error.message);
      }
    }
  }

  void _fill(AuthUser user) {
    nameController.text = user.name;
    phoneController.text = user.mobile;
    nameText.value = user.name;
    phoneText.value = user.mobile;
    final code = (user.countryCode == null || user.countryCode!.isEmpty)
        ? '+222'
        : user.countryCode!;
    countryCode.value = code;
    countryFlag.value = flagForCountryCode(code);
    remoteImage.value = user.image;
  }

  void setCountry(String code, String flag) {
    _edited = true;
    countryCode.value = code;
    countryFlag.value = flag;
  }

  void startEditName() {
    _edited = true;
    editingName.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameFocus.requestFocus();
    });
  }

  void finishNameEdit() {
    nameText.value = nameController.text;
    editingName.value = false;
  }

  void startEditPhone() {
    _edited = true;
    editingPhone.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      phoneFocus.requestFocus();
    });
  }

  void finishPhoneEdit() {
    phoneText.value = phoneController.text;
    editingPhone.value = false;
  }

  Future<void> pickAvatar() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (photo == null) return;

    final extension = photo.path.split('.').last.toLowerCase();
    if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
      showAppToast('core_profile_image_type'.tr);
      return;
    }

    final file = File(photo.path);
    final bytes = await file.length();
    if (bytes > 2048 * 1024) {
      showAppToast('core_profile_image_size'.tr);
      return;
    }

    _edited = true;
    localImagePath.value = photo.path;
  }

  Future<void> updateProfile() async {
    if (isSaving.value) return;

    finishNameEdit();
    finishPhoneEdit();

    final name = nameController.text.trim();
    final mobile = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (name.length < 3 || name.length > 100) {
      showAppToast('core_profile_name_length'.tr);
      return;
    }
    if (mobile.isEmpty) {
      showAppToast('core_profile_enter_whatsapp'.tr);
      return;
    }

    final token = _session.token;
    if (token == null || token.isEmpty) {
      showAppToast('core_profile_login_required'.tr);
      return;
    }

    isSaving.value = true;
    try {
      final result = await _profile.updateProfile(
        name: name,
        countryCode: countryCode.value,
        mobile: mobile,
        language: apiLanguageCode(),
        imagePath: localImagePath.value,
      );
      await _session.saveSession(token: token, user: result.user);
      _fill(result.user);
      localImagePath.value = null;
      showAppToast(result.message, backgroundColor: AppColors.primaryOrange);
      Get.back(result: true);
    } on ApiException catch (error) {
      showAppToast(error.message);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    nameFocus.dispose();
    phoneFocus.dispose();
    super.onClose();
  }
}
