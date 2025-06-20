import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

class SponsorModal extends StatefulWidget {
  final String artistId;
  const SponsorModal({super.key, required this.artistId});

  @override
  State<SponsorModal> createState() => _SponsorModalState();
}

class _SponsorModalState extends State<SponsorModal> {
  final PaymentService _paymentService = PaymentService();
  final UserService _userService = UserService();
  double _amount = 5.0;
  bool _isMonthly = true;

  Future<void> _sponsorArtist() async {
    try {
      final sponsorId = _userService.currentUserId;
      if (sponsorId == null) {
        throw Exception('User not authenticated');
      }
      // Create sponsorship record
      final sponsorship = {
        'sponsorId': sponsorId,
        'artistId': widget.artistId,
        'amount': _amount,
        'isMonthly': _isMonthly,
        'createdAt': Timestamp.now(),
      };
      await _paymentService.processSponsorshipPayment(sponsorship);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sponsorship successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sponsor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sponsor Artist'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Amount: '),
              Expanded(
                child: Slider(
                  value: _amount,
                  min: 1.0,
                  max: 100.0,
                  divisions: 20,
                  label: ' 24${_amount.toStringAsFixed(0)}',
                  onChanged: (value) => setState(() => _amount = value),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _isMonthly,
                onChanged: (val) => setState(() => _isMonthly = val ?? true),
              ),
              const Text('Monthly Sponsorship'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _sponsorArtist, child: const Text('Sponsor')),
      ],
    );
  }
}
