import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/network/api_constants.dart';
import '../core/network/dio_client.dart';
import '../core/storage/session_store.dart';

class ProfileImageView extends StatefulWidget {
  const ProfileImageView({
    super.key,
    required this.size,
    required this.placeholder,
    this.imagePath,
    this.useSessionImage = true,
  });

  final double size;
  final Widget placeholder;
  final String? imagePath;
  final bool useSessionImage;

  @override
  State<ProfileImageView> createState() => _ProfileImageViewState();
}

class _ProfileImageViewState extends State<ProfileImageView> {
  Worker? _profileWorker;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    if (widget.useSessionImage && Get.isRegistered<SessionStore>()) {
      _profileWorker = ever<int>(
        Get.find<SessionStore>().profileRevision,
        (_) => _loadPhoto(),
      );
    }
    _loadPhoto();
  }

  @override
  void didUpdateWidget(ProfileImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final imageUrl = widget.useSessionImage
        ? (Get.isRegistered<SessionStore>()
              ? ApiConstants.mediaUrl(
                  Get.find<SessionStore>().readUser()?.image,
                )
              : null)
        : ApiConstants.mediaUrl(widget.imagePath);
    if (imageUrl == null || !Get.isRegistered<DioClient>()) {
      if (mounted) setState(() => _bytes = null);
      return;
    }

    try {
      final response = await Get.find<DioClient>().dio.get<List<int>>(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final data = response.data;
      final loaded =
          response.statusCode == 200 && data != null && _isImageBytes(data);
      if (!mounted) return;
      setState(() {
        _bytes = loaded
            ? (data is Uint8List ? data : Uint8List.fromList(data))
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _bytes = null);
    }
  }

  bool _isImageBytes(List<int> data) {
    if (data.length < 8) return false;
    final jpeg = data[0] == 0xFF && data[1] == 0xD8;
    final png = data[0] == 0x89 && data[1] == 0x50;
    final gif = data[0] == 0x47 && data[1] == 0x49;
    final webp = data[0] == 0x52 && data[1] == 0x49;
    return jpeg || png || gif || webp;
  }

  @override
  void dispose() {
    _profileWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return widget.placeholder;

    return ClipOval(
      child: Image.memory(
        bytes,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }
}
