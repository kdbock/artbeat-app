import 'package:flutter/material.dart';
import '../services/enhanced_gift_service.dart';
import '../models/gift_campaign_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Screen for managing gift campaigns
class GiftCampaignScreen extends StatefulWidget {
  const GiftCampaignScreen({super.key});

  @override
  State<GiftCampaignScreen> createState() => _GiftCampaignScreenState();
}

class _GiftCampaignScreenState extends State<GiftCampaignScreen>
    with SingleTickerProviderStateMixin {
  final EnhancedGiftService _giftService = EnhancedGiftService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Campaigns'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Campaigns'),
            Tab(text: 'Discover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMyCampaignsTab(), _buildDiscoverTab()],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "gift_campaign_fab",
        onPressed: () => _showCreateCampaignDialog(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMyCampaignsTab() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your campaigns'));
    }

    return StreamBuilder<List<GiftCampaignModel>>(
      stream: _giftService.getArtistCampaigns(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading campaigns: ${snapshot.error}'),
          );
        }

        final campaigns = snapshot.data ?? [];

        if (campaigns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No campaigns yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first fundraising campaign',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showCreateCampaignDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Campaign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            final campaign = campaigns[index];
            return _buildCampaignCard(campaign, isOwner: true);
          },
        );
      },
    );
  }

  Widget _buildDiscoverTab() {
    return StreamBuilder<List<GiftCampaignModel>>(
      stream: _giftService.getActiveCampaigns(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading campaigns: ${snapshot.error}'),
          );
        }

        final campaigns = snapshot.data ?? [];

        if (campaigns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No active campaigns',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new campaigns to support',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            final campaign = campaigns[index];
            return _buildCampaignCard(campaign, isOwner: false);
          },
        );
      },
    );
  }

  Widget _buildCampaignCard(
    GiftCampaignModel campaign, {
    required bool isOwner,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusChip(campaign.status),
                          const SizedBox(width: 8),
                          Text(
                            '${campaign.supporterCount} supporters',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isOwner) _buildCampaignMenu(campaign),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              campaign.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Progress
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${campaign.currentAmount.toStringAsFixed(2)} raised',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${campaign.progressPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: campaign.progressPercentage / 100,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Goal: \$${campaign.goalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                if (!isOwner && campaign.isActive)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _supportCampaign(campaign),
                      icon: const Icon(Icons.favorite, size: 16),
                      label: const Text('Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (isOwner) ...[
                  if (campaign.isActive)
                    TextButton.icon(
                      onPressed: () => _pauseCampaign(campaign.id),
                      icon: const Icon(Icons.pause, size: 16),
                      label: const Text('Pause'),
                    ),
                  if (campaign.isPaused)
                    TextButton.icon(
                      onPressed: () => _resumeCampaign(campaign.id),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Resume'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _viewCampaignDetails(campaign),
                    child: const Text('View Details'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(CampaignStatus status) {
    MaterialColor color;
    String label;

    switch (status) {
      case CampaignStatus.active:
        color = Colors.green;
        label = 'Active';
        break;
      case CampaignStatus.paused:
        color = Colors.orange;
        label = 'Paused';
        break;
      case CampaignStatus.completed:
        color = Colors.blue;
        label = 'Completed';
        break;
      case CampaignStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color.shade700,
        ),
      ),
    );
  }

  Widget _buildCampaignMenu(GiftCampaignModel campaign) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _editCampaign(campaign);
            break;
          case 'pause':
            _pauseCampaign(campaign.id);
            break;
          case 'resume':
            _resumeCampaign(campaign.id);
            break;
          case 'complete':
            _completeCampaign(campaign.id);
            break;
          case 'cancel':
            _cancelCampaign(campaign.id);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (campaign.isActive)
          const PopupMenuItem(
            value: 'pause',
            child: ListTile(
              leading: Icon(Icons.pause),
              title: Text('Pause'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (campaign.isPaused)
          const PopupMenuItem(
            value: 'resume',
            child: ListTile(
              leading: Icon(Icons.play_arrow),
              title: Text('Resume'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (campaign.isActive || campaign.isPaused)
          const PopupMenuItem(
            value: 'complete',
            child: ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Mark Complete'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (campaign.isActive || campaign.isPaused)
          const PopupMenuItem(
            value: 'cancel',
            child: ListTile(
              leading: Icon(Icons.cancel),
              title: Text('Cancel'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  void _showCreateCampaignDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => const CreateCampaignDialog(),
    ).then((result) {
      if (result == true) {
        // Refresh campaigns
        setState(() {});
      }
    });
  }

  void _supportCampaign(GiftCampaignModel campaign) {
    // Navigate to enhanced gift purchase screen with campaign context
    Navigator.pushNamed(
      context,
      '/enhanced-gift-purchase',
      arguments: {
        'recipientId': campaign.artistId,
        'recipientName': 'Artist', // You might want to fetch the actual name
        'campaign': campaign,
      },
    );
  }

  void _editCampaign(GiftCampaignModel campaign) {
    showDialog<bool>(
      context: context,
      builder: (context) => EditCampaignDialog(campaign: campaign),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _pauseCampaign(String campaignId) async {
    try {
      await _giftService.pauseCampaign(campaignId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Campaign paused')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error pausing campaign: $e')));
      }
    }
  }

  void _resumeCampaign(String campaignId) async {
    try {
      await _giftService.resumeCampaign(campaignId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Campaign resumed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error resuming campaign: $e')));
      }
    }
  }

  void _completeCampaign(String campaignId) async {
    try {
      await _giftService.completeCampaign(campaignId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign marked as complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing campaign: $e')),
        );
      }
    }
  }

  void _cancelCampaign(String campaignId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Campaign'),
        content: const Text(
          'Are you sure you want to cancel this campaign? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Campaign'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Campaign'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _giftService.cancelCampaign(campaignId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Campaign cancelled')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling campaign: $e')),
          );
        }
      }
    }
  }

  void _viewCampaignDetails(GiftCampaignModel campaign) {
    // Navigate to detailed campaign view
    Navigator.pushNamed(context, '/campaign-details', arguments: campaign);
  }
}

/// Dialog for creating a new campaign
class CreateCampaignDialog extends StatefulWidget {
  const CreateCampaignDialog({super.key});

  @override
  State<CreateCampaignDialog> createState() => _CreateCampaignDialogState();
}

class _CreateCampaignDialogState extends State<CreateCampaignDialog> {
  final EnhancedGiftService _giftService = EnhancedGiftService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalController = TextEditingController();

  bool _isLoading = false;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Campaign'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Campaign Title',
                  hintText: 'e.g., New Art Studio Equipment',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what you\'re raising funds for...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: 'Goal Amount',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a goal amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('End Date (Optional)'),
                subtitle: Text(
                  _endDate != null
                      ? 'Ends: ${_endDate!.toLocal().toString().split(' ')[0]}'
                      : 'No end date set',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectEndDate,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCampaign,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _createCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _giftService.createGiftCampaign(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        goalAmount: double.parse(_goalController.text),
        endDate: _endDate,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating campaign: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Dialog for editing an existing campaign
class EditCampaignDialog extends StatefulWidget {
  final GiftCampaignModel campaign;

  const EditCampaignDialog({super.key, required this.campaign});

  @override
  State<EditCampaignDialog> createState() => _EditCampaignDialogState();
}

class _EditCampaignDialogState extends State<EditCampaignDialog> {
  final EnhancedGiftService _giftService = EnhancedGiftService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _goalController;

  bool _isLoading = false;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.campaign.title);
    _descriptionController = TextEditingController(
      text: widget.campaign.description,
    );
    _goalController = TextEditingController(
      text: widget.campaign.goalAmount.toString(),
    );
    _endDate = widget.campaign.endDate?.toDate();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Campaign'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Campaign Title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: 'Goal Amount',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a goal amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount < widget.campaign.currentAmount) {
                    return 'Goal cannot be less than current amount raised';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('End Date'),
                subtitle: Text(
                  _endDate != null
                      ? 'Ends: ${_endDate!.toLocal().toString().split(' ')[0]}'
                      : 'No end date set',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _selectEndDate,
                      icon: const Icon(Icons.calendar_today),
                    ),
                    if (_endDate != null)
                      IconButton(
                        onPressed: () => setState(() => _endDate = null),
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateCampaign,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _updateCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updates = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'goalAmount': double.parse(_goalController.text),
      };

      if (_endDate != null) {
        updates['endDate'] = Timestamp.fromDate(_endDate!);
      } else {
        updates['endDate'] = FieldValue.delete();
      }

      await _giftService.updateGiftCampaign(widget.campaign.id, updates);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating campaign: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
