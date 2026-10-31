import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/country_codes.dart';
import '../controllers/edit_profile_controller.dart';
import '../core/network/api_constants.dart';
import '../widgets/app_back_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final EditProfileController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(EditProfileController());
    controller.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildAvatar(),
                    const SizedBox(height: 40),
                    _buildNameField(),
                    const SizedBox(height: 22),
                    _buildWhatsAppField(),
                    const SizedBox(height: 40),
                    _buildUpdateButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              'core_profile_title'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0D5CC), width: 1.2),
              color: const Color(0xFFF0EBE6),
            ),
            clipBehavior: Clip.antiAlias,
            child: Obx(() => _buildAvatarImage(controller)),
          ),
          PositionedDirectional(
            end: 2,
            bottom: 2,
            child: GestureDetector(
              onTap: controller.pickAvatar,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEAD8C9),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: Color(0xFFFF5E00),
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'core_profile_name'.tr,
          style: GoogleFonts.outfit(
            color: const Color(0xFF5D534A),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        _buildPillField(
          child: Row(
            children: [
              Expanded(
                child: Obx(() {
                  if (controller.editingName.value) {
                    return TextField(
                      controller: controller.nameController,
                      focusNode: controller.nameFocus,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      cursorColor: const Color(0xFFFF5E00),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => controller.finishNameEdit(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    );
                  }
                  return Text(
                    controller.nameText.value,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }),
              ),
              _buildEditAction(onTap: controller.startEditName),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsAppField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'core_profile_whatsapp'.tr,
          style: GoogleFonts.outfit(
            color: const Color(0xFF5D534A),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        _buildPillField(
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showCountryPicker(context),
                child: Obx(
                  () => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.countryFlag.value,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.countryCode.value,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: const Color(0xFFD9CEC4),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.editingPhone.value) {
                    return TextField(
                      controller: controller.phoneController,
                      focusNode: controller.phoneFocus,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      cursorColor: const Color(0xFFFF5E00),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => controller.finishPhoneEdit(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    );
                  }
                  return Text(
                    controller.phoneText.value,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }),
              ),
              _buildEditAction(onTap: controller.startEditPhone),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPillField({required Widget child}) {
    return Container(
      width: double.infinity,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 1),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
  }

  Widget _buildEditAction({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_outlined, color: Color(0xFFFF5E00), size: 15),
          const SizedBox(width: 4),
          Text(
            'core_profile_edit'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Obx(() {
      final saving = controller.isSaving.value;
      return GestureDetector(
        onTap: saving
            ? null
            : () {
                FocusScope.of(context).unfocus();
                controller.updateProfile();
              },
        child: Container(
          width: double.infinity,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5E00).withOpacity(0.40),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'core_profile_update'.tr,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildAvatarImage(EditProfileController controller) {
    final localPath = controller.localImagePath.value;
    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(File(localPath), fit: BoxFit.cover);
    }

    final remote = ApiConstants.mediaUrl(controller.remoteImage.value);
    if (remote == null) {
      return const Icon(
        Icons.person_rounded,
        size: 56,
        color: Color(0xFFA59A94),
      );
    }

    return Image.network(
      remote,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.person_rounded, size: 56, color: Color(0xFFA59A94)),
    );
  }

  void _showCountryPicker(BuildContext context) {
    Get.bottomSheet(
      Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'core_profile_select_country'.tr,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: appCountries.length,
                    itemBuilder: (context, index) {
                      final country = appCountries[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          country.name,
                          style: GoogleFonts.outfit(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Text(
                          country.code,
                          style: GoogleFonts.outfit(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          controller.setCountry(country.code, country.flag);
                          Get.back();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }
}
