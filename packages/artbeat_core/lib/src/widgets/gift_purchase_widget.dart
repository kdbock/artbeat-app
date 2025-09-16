import 'package:flutter/material.dart';
import '../services/in_app_purchase_manager.dart';
import '../utils/logger.dart';

/// Widget for purchasing and sending gifts
class GiftPurchaseWidget extends StatefulWidget {
  final String? recipientId;
  final String? recipientName;
  final void Function(String)? onGiftPurchased;
  final void Function(String)? onError;

  const GiftPurchaseWidget({
    super.key,
    this.recipientId,
    this.recipientName,
    this.onGiftPurchased,
    this.onError,
  });

  @override
  State<GiftPurchaseWidget> createState() => _GiftPurchaseWidgetState();
}

class _GiftPurchaseWidgetState extends State<GiftPurchaseWidget> {
  final InAppPurchaseManager _purchaseManager = InAppPurchaseManager();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();

  bool _isLoading = false;
  String? _selectedGiftId;
  List<Map<String, dynamic>> _availableGifts = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableGifts();
    if (widget.recipientName != null) {
      _recipientController.text = widget.recipientName!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  void _loadAvailableGifts() {
    setState(() {
      _availableGifts = _purchaseManager.getAvailableGifts();
    });
  }

  Future<void> _searchRecipients(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // This would typically search your user database
      // For now, we'll just clear the results
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    } catch (e) {
      AppLogger.error('Error searching recipients: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _purchaseGift() async {
    if (_selectedGiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a gift'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final recipientId = widget.recipientId;
    if (recipientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a recipient'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _purchaseManager.purchaseGift(
        recipientId: recipientId,
        giftProductId: _selectedGiftId!,
        message: message,
      );

      if (success) {
        widget.onGiftPurchased?.call(_selectedGiftId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gift purchase initiated!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        widget.onError?.call('Failed to initiate gift purchase');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to initiate gift purchase'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error purchasing gift: $e');
      widget.onError?.call(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send a Gift'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _purchaseGift,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipient selection
            if (widget.recipientId == null) ...[
              const Text(
                'Send to:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  hintText: 'Search for a user...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _searchRecipients,
              ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['profileImageUrl'] != null
                              ? NetworkImage(user['profileImageUrl'] as String)
                              : null,
                          child: user['profileImageUrl'] == null
                              ? Text(
                                  (user['displayName'] as String)[0]
                                      .toUpperCase(),
                                )
                              : null,
                        ),
                        title: Text(user['displayName'] as String),
                        subtitle: Text('@${user['username'] as String}'),
                        onTap: () {
                          _recipientController.text =
                              user['displayName'] as String;
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sending to:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            widget.recipientName ?? 'Unknown User',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Gift selection
            const Text(
              'Choose a gift:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _availableGifts.length,
              itemBuilder: (context, index) {
                final gift = _availableGifts[index];
                final isSelected = _selectedGiftId == gift['productId'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGiftId = gift['productId'] as String;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1)
                          : Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            size: 32,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            gift['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${gift['amount'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${gift['credits']} credits',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Message
            const Text(
              'Add a message:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write a personal message...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Purchase button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _purchaseGift,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        _selectedGiftId != null
                            ? 'Send Gift (\$${_availableGifts.firstWhere((g) => g['productId'] == _selectedGiftId)['amount'].toStringAsFixed(2)})'
                            : 'Select a Gift',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple gift card widget
class GiftCard extends StatelessWidget {
  final Map<String, dynamic> gift;
  final bool isSelected;
  final VoidCallback? onTap;

  const GiftCard({
    super.key,
    required this.gift,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 4 : 2,
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.card_giftcard,
                  size: 48,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  gift['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${gift['amount'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${gift['credits']} credits',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
