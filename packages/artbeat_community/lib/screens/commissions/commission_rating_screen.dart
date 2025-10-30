import 'package:flutter/material.dart';
import '../../models/direct_commission_model.dart';
import '../../services/commission_rating_service.dart';

class CommissionRatingScreen extends StatefulWidget {
  final DirectCommissionModel commission;

  const CommissionRatingScreen({Key? key, required this.commission})
    : super(key: key);

  @override
  State<CommissionRatingScreen> createState() => _CommissionRatingScreenState();
}

class _CommissionRatingScreenState extends State<CommissionRatingScreen> {
  late TextEditingController _commentController;
  double _overallRating = 5;
  double _qualityRating = 5;
  double _communicationRating = 5;
  double _timelinessRating = 5;
  bool _wouldRecommend = true;
  final Set<String> _selectedTags = {};
  bool _isLoading = false;

  static const List<String> _availableTags = [
    'excellent-quality',
    'great-communication',
    'fast-delivery',
    'professional',
    'responsive',
    'attention-to-detail',
    'easy-to-work-with',
    'worth-the-price',
  ];

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please write a comment')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = CommissionRatingService();
      await service.submitRating(
        commissionId: widget.commission.id,
        ratedUserId: widget.commission.artistId,
        ratedUserName: widget.commission.artistName,
        overallRating: _overallRating,
        qualityRating: _qualityRating,
        communicationRating: _communicationRating,
        timelinessRating: _timelinessRating,
        comment: _commentController.text,
        wouldRecommend: _wouldRecommend,
        tags: _selectedTags.toList(),
        isArtistRating: false,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Commission'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artist info
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.commission.artistName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.commission.title,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Overall Rating
            _buildRatingSection(
              title: 'Overall Rating',
              currentRating: _overallRating,
              onChanged: (value) => setState(() => _overallRating = value),
            ),
            const SizedBox(height: 24),

            // Detailed Ratings
            Text(
              'Detailed Ratings',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildDetailedRating(
              label: 'Quality of Work',
              value: _qualityRating,
              onChanged: (v) => setState(() => _qualityRating = v),
            ),
            const SizedBox(height: 12),

            _buildDetailedRating(
              label: 'Communication',
              value: _communicationRating,
              onChanged: (v) => setState(() => _communicationRating = v),
            ),
            const SizedBox(height: 12),

            _buildDetailedRating(
              label: 'Timeliness',
              value: _timelinessRating,
              onChanged: (v) => setState(() => _timelinessRating = v),
            ),
            const SizedBox(height: 24),

            // Would Recommend
            CheckboxListTile(
              value: _wouldRecommend,
              onChanged: (value) =>
                  setState(() => _wouldRecommend = value ?? false),
              title: const Text('I would recommend this artist to others'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Tags
            Text(
              'What stood out? (Select all that apply)',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag.replaceAll('-', ' ')),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Comment
            Text(
              'Tell us more',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share your experience working with this artist...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection({
    required String title,
    required double currentRating,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              currentRating.toStringAsFixed(1),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: currentRating,
                min: 1,
                max: 5,
                divisions: 4,
                label: currentRating.toStringAsFixed(1),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final value = index + 1.0;
              return GestureDetector(
                onTap: () => onChanged(value),
                child: Icon(
                  Icons.star,
                  color: currentRating >= value
                      ? Colors.amber
                      : Colors.grey[300],
                  size: 32,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedRating({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label)),
        Expanded(
          flex: 3,
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
