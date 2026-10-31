import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/network/api_exception.dart';
import '../models/general_repository.dart';
import '../utils/api_language.dart';
import '../widgets/app_back_button.dart';

/// What the reviews screen should load.
///
/// [expectedSubjectType] is the `subject.type` the backend must return for the
/// reviews to be shown (e.g. `pharmacy`). The backend can answer with a
/// different vendor's data when the vendor type is not honoured, so the screen
/// refuses to show reviews whose subject does not match.
class ReviewTarget {
  final String type; // restaurant | provider | product
  final String expectedSubjectType;
  final String title;
  final int? vendorId;
  final int? vendorType;
  final int? productId;
  final int? productType;

  const ReviewTarget({
    required this.type,
    required this.expectedSubjectType,
    required this.title,
    this.vendorId,
    this.vendorType,
    this.productId,
    this.productType,
  });
}

class RatingReviewsScreen extends StatefulWidget {
  final ReviewTarget? target;

  const RatingReviewsScreen({super.key, this.target});

  @override
  State<RatingReviewsScreen> createState() => _RatingReviewsScreenState();
}

class _RatingReviewsScreenState extends State<RatingReviewsScreen> {
  static const _tabs = <(String, String)>[
    ('All Reviews', ''),
    ('Most Recent', 'most_recent'),
    ('Highest Rated', 'highest_rated'),
  ];

  int _activeTab = 0;
  int _requestId = 0;
  bool _loading = false;
  String? _unavailableMessage;
  double _average = 0;
  int _total = 0;
  Map<String, int> _breakdown = const {};
  List<Map<String, dynamic>> _reviews = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final target = widget.target;
    if (target == null) {
      setState(() => _unavailableMessage = 'Reviews are not available here.');
      return;
    }
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _unavailableMessage = null;
    });
    try {
      final result = await Get.find<GeneralRepository>().fetchReviews(
        type: target.type,
        language: apiLanguageCode(),
        vendorId: target.vendorId,
        vendorType: target.vendorType,
        productId: target.productId,
        productType: target.productType,
        filter: _tabs[_activeTab].$2,
      );
      if (!mounted || requestId != _requestId) return;
      if (result.subjectType != target.expectedSubjectType) {
        setState(() {
          _unavailableMessage = 'Reviews are not available for this yet.';
          _reviews = const [];
        });
        return;
      }
      setState(() {
        _average = result.averageRating;
        _total = result.totalReviews;
        _breakdown = result.ratingBreakdown;
        _reviews = result.reviews;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _unavailableMessage = error.message);
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectTab(int index) {
    if (index == _activeTab) return;
    setState(() => _activeTab = index);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: const Color(0xFFFFFDF9),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AppBackButton(onTap: () => Navigator.pop(context)),
              ),
              Text(
                target?.title.isNotEmpty == true
                    ? target!.title
                    : 'Rating & Reviews',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading && _reviews.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
            )
          : _unavailableMessage != null
          ? _buildMessage(_unavailableMessage!)
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  _buildOverview(),
                  const SizedBox(height: 18),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  if (_reviews.isEmpty)
                    _buildMessage('No reviews yet')
                  else
                    Column(
                      children: [
                        for (final review in _reviews) _buildReviewCard(review),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildMessage(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFFA59A94),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B25C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _average.toStringAsFixed(1),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_total reviews',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Container(height: 100, width: 0.8, color: const Color(0xFFEAD8C9)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                for (final star in ['5', '4', '3', '2', '1']) ...[
                  _buildBreakdownRow(
                    star,
                    _total == 0 ? 0 : (_breakdown[star] ?? 0) / _total,
                    '${_breakdown[star] ?? 0}',
                  ),
                  if (star != '1') const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String starLabel, double fraction, String count) {
    return Row(
      children: [
        Text(
          starLabel,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5E00),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            count,
            textAlign: TextAlign.end,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _activeTab == index;
          return Padding(
            padding: EdgeInsets.only(
              right: index == _tabs.length - 1 ? 0 : 10,
            ),
            child: GestureDetector(
              onTap: () => _selectTab(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFFFEDE6),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _tabs[index].$1,
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : const Color(0xFF5C5651),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] as int;
    final image = review['userImage'] as String;
    final name = review['userName'] as String;
    final when = review['timeAgo'] as String;
    final comment = review['comment'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: image.isEmpty
                    ? Container(
                        width: 36,
                        height: 36,
                        color: const Color(0xFFF3EFEA),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFFA59A94),
                          size: 20,
                        ),
                      )
                    : Image.network(
                        image,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 36,
                          height: 36,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Customer' : name,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      when,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  rating.clamp(0, 5),
                  (_) => const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFAE00),
                    size: 13,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: GoogleFonts.outfit(
                color: const Color(0xFF7A6A60),
                fontSize: 10.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
