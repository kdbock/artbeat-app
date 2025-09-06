import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../services/stripe_service.dart';
import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../theme/community_colors.dart';

class CommissionDetailScreen extends StatefulWidget {
  final DirectCommissionModel commission;

  const CommissionDetailScreen({super.key, required this.commission});

  @override
  State<CommissionDetailScreen> createState() => _CommissionDetailScreenState();
}

class _CommissionDetailScreenState extends State<CommissionDetailScreen>
    with SingleTickerProviderStateMixin {
  final DirectCommissionService _commissionService = DirectCommissionService();
  final StripeService _stripeService = StripeService();
  final _messageController = TextEditingController();
  late final TabController _tabController;

  DirectCommissionModel? _commission;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _commission = widget.commission;
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadCommissionDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCommissionDetails() async {
    try {
      final commission = await _commissionService.getCommission(
        widget.commission.id,
      );
      setState(() {
        _commission = commission;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading commission details: $e')),
        );
      }
    }
  }

  bool get _isArtist => _commission?.artistId == _currentUserId;
  bool get _isClient => _commission?.clientId == _currentUserId;

  @override
  Widget build(BuildContext context) {
    if (_commission == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return core.MainLayout(
      currentIndex: 3,
      appBar: core.EnhancedUniversalHeader(
        title: _commission!.title,
        showBackButton: true,
        showSearch: false,
        backgroundGradient: CommunityColors.communityGradient,
        titleGradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              if (_isArtist && _commission!.status == CommissionStatus.pending)
                const PopupMenuItem(
                  value: 'provide_quote',
                  child: Text('Provide Quote'),
                ),
              if (_isClient && _commission!.status == CommissionStatus.quoted)
                const PopupMenuItem(
                  value: 'accept_quote',
                  child: Text('Accept Quote'),
                ),
              if (_isArtist &&
                  _commission!.status == CommissionStatus.inProgress)
                const PopupMenuItem(
                  value: 'mark_complete',
                  child: Text('Mark Complete'),
                ),
              const PopupMenuItem(
                value: 'cancel',
                child: Text('Cancel Commission'),
              ),
            ],
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Banner
          _buildStatusBanner(),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Messages'),
              Tab(text: 'Files'),
              Tab(text: 'Milestones'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildMessagesTab(),
                _buildFilesTab(),
                _buildMilestonesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final status = _commission!.status;
    final statusColor = _getStatusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: statusColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(_getStatusIcon(status), color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStatusDescription(status),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_shouldShowActionButton())
            ElevatedButton(
              onPressed: _handlePrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
              ),
              child: Text(_getPrimaryActionText()),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information
          _buildInfoCard('Commission Details', [
            _buildInfoRow('Type', _commission!.type.displayName),
            _buildInfoRow('Client', _commission!.clientName),
            _buildInfoRow('Artist', _commission!.artistName),
            _buildInfoRow(
              'Requested',
              _formatDateTime(_commission!.requestedAt),
            ),
            if (_commission!.deadline != null)
              _buildInfoRow(
                'Deadline',
                _formatDateTime(_commission!.deadline!),
              ),
            if (_commission!.totalPrice > 0)
              _buildInfoRow(
                'Total Price',
                '\$${_commission!.totalPrice.toStringAsFixed(2)}',
              ),
            if (_commission!.depositAmount > 0)
              _buildInfoRow(
                'Deposit',
                '\$${_commission!.depositAmount.toStringAsFixed(2)}',
              ),
          ]),
          const SizedBox(height: 16),

          // Description
          _buildInfoCard('Description', [
            Text(
              _commission!.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ]),
          const SizedBox(height: 16),

          // Specifications
          _buildInfoCard('Specifications', [
            _buildInfoRow('Size', _commission!.specs.size),
            _buildInfoRow('Medium', _commission!.specs.medium),
            _buildInfoRow('Style', _commission!.specs.style),
            _buildInfoRow('Color Scheme', _commission!.specs.colorScheme),
            _buildInfoRow('Revisions', _commission!.specs.revisions.toString()),
            _buildInfoRow(
              'Commercial Use',
              _commission!.specs.commercialUse ? 'Yes' : 'No',
            ),
            _buildInfoRow('Delivery Format', _commission!.specs.deliveryFormat),
            if (_commission!.specs.customRequirements.isNotEmpty)
              _buildInfoRow(
                'Custom Requirements',
                _commission!.specs.customRequirements['description']
                        ?.toString() ??
                    '',
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    return Column(
      children: [
        // Messages List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _commission!.messages.length,
            itemBuilder: (context, index) {
              final message = _commission!.messages[index];
              final isCurrentUser = message.senderId == _currentUserId;

              return Align(
                alignment: isCurrentUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? CommunityColors.primary
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isCurrentUser)
                        Text(
                          message.senderName,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(message.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isCurrentUser
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Message Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: CommunityColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _commission!.files.length,
      itemBuilder: (context, index) {
        final file = _commission!.files[index];
        return Card(
          child: ListTile(
            leading: Icon(_getFileIcon(file.name)),
            title: Text(file.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${file.type}'),
                Text(
                  'Uploaded by: ${file.uploadedBy == _currentUserId ? "You" : "Other party"}',
                ),
                Text('Size: ${_formatFileSize(file.sizeBytes)}'),
                if (file.description != null)
                  Text('Description: ${file.description}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadFile(file),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMilestonesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _commission!.milestones.length,
      itemBuilder: (context, index) {
        final milestone = _commission!.milestones[index];
        final statusColor = _getMilestoneStatusColor(milestone.status);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        milestone.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        milestone.status.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  milestone.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Amount: \$${milestone.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Due: ${_formatDateTime(milestone.dueDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (milestone.status == MilestoneStatus.pending && _isClient)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: () => _payMilestone(milestone),
                      child: const Text('Pay Milestone'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return Colors.orange;
      case CommissionStatus.quoted:
        return Colors.blue;
      case CommissionStatus.accepted:
        return Colors.green;
      case CommissionStatus.inProgress:
        return Colors.purple;
      case CommissionStatus.revision:
        return Colors.amber;
      case CommissionStatus.completed:
        return Colors.green;
      case CommissionStatus.delivered:
        return Colors.teal;
      case CommissionStatus.cancelled:
        return Colors.red;
      case CommissionStatus.disputed:
        return Colors.red.shade800;
    }
  }

  Color _getMilestoneStatusColor(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.pending:
        return Colors.orange;
      case MilestoneStatus.inProgress:
        return Colors.blue;
      case MilestoneStatus.completed:
        return Colors.green;
      case MilestoneStatus.paid:
        return Colors.teal;
    }
  }

  IconData _getStatusIcon(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return Icons.schedule;
      case CommissionStatus.quoted:
        return Icons.request_quote;
      case CommissionStatus.accepted:
        return Icons.handshake;
      case CommissionStatus.inProgress:
        return Icons.brush;
      case CommissionStatus.revision:
        return Icons.edit;
      case CommissionStatus.completed:
        return Icons.check_circle;
      case CommissionStatus.delivered:
        return Icons.local_shipping;
      case CommissionStatus.cancelled:
        return Icons.cancel;
      case CommissionStatus.disputed:
        return Icons.warning;
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getStatusDescription(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return _isArtist
            ? 'Review the request and provide a quote'
            : 'Waiting for artist to review and quote';
      case CommissionStatus.quoted:
        return _isClient
            ? 'Review the quote and accept to proceed'
            : 'Waiting for client to accept quote';
      case CommissionStatus.accepted:
        return 'Quote accepted. Waiting for deposit payment';
      case CommissionStatus.inProgress:
        return 'Work is in progress';
      case CommissionStatus.revision:
        return 'Revisions requested';
      case CommissionStatus.completed:
        return 'Work completed. Awaiting client review';
      case CommissionStatus.delivered:
        return 'Commission delivered successfully';
      case CommissionStatus.cancelled:
        return 'Commission has been cancelled';
      case CommissionStatus.disputed:
        return 'Commission is under dispute';
    }
  }

  bool _shouldShowActionButton() {
    final status = _commission!.status;
    return (status == CommissionStatus.pending && _isArtist) ||
        (status == CommissionStatus.quoted && _isClient) ||
        (status == CommissionStatus.accepted &&
            _isClient &&
            _commission!.depositAmount > 0) ||
        (status == CommissionStatus.inProgress && _isArtist);
  }

  String _getPrimaryActionText() {
    final status = _commission!.status;
    if (status == CommissionStatus.pending && _isArtist) {
      return 'Provide Quote';
    } else if (status == CommissionStatus.quoted && _isClient) {
      return 'Accept Quote';
    } else if (status == CommissionStatus.accepted &&
        _isClient &&
        _commission!.depositAmount > 0) {
      return 'Pay Deposit (\$${_commission!.depositAmount.toStringAsFixed(2)})';
    } else if (status == CommissionStatus.inProgress && _isArtist) {
      return 'Mark Complete';
    }
    return '';
  }

  void _handlePrimaryAction() {
    final status = _commission!.status;
    if (status == CommissionStatus.pending && _isArtist) {
      _provideQuote();
    } else if (status == CommissionStatus.quoted && _isClient) {
      _acceptQuote();
    } else if (status == CommissionStatus.accepted &&
        _isClient &&
        _commission!.depositAmount > 0) {
      _payDeposit();
    } else if (status == CommissionStatus.inProgress && _isArtist) {
      _markComplete();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'provide_quote':
        _provideQuote();
        break;
      case 'accept_quote':
        _acceptQuote();
        break;
      case 'pay_deposit':
        _payDeposit();
        break;
      case 'mark_complete':
        _markComplete();
        break;
      case 'cancel':
        _cancelCommission();
        break;
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await _commissionService.addMessage(
        _commission!.id,
        _messageController.text.trim(),
      );
      _messageController.clear();
      await _loadCommissionDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    }
  }

  void _provideQuote() {
    // TODO: Implement quote provision dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote provision coming soon!')),
    );
  }

  Future<void> _acceptQuote() async {
    try {
      await _commissionService.acceptCommission(_commission!.id);
      await _loadCommissionDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote accepted! Proceed to payment.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error accepting quote: $e')));
      }
    }
  }

  Future<void> _payDeposit() async {
    try {
      await _stripeService.processCommissionDeposit(
        commissionId: _commission!.id,
        amount: _commission!.depositAmount,
        message: 'Deposit payment for commission: ${_commission!.title}',
      );

      await _loadCommissionDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit payment processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing deposit payment: $e')),
        );
      }
    }
  }

  Future<void> _markComplete() async {
    try {
      await _commissionService.completeCommission(_commission!.id);
      await _loadCommissionDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commission marked as completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing commission: $e')),
        );
      }
    }
  }

  void _cancelCommission() {
    // TODO: Implement cancellation dialog with reason
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commission cancellation coming soon!')),
    );
  }

  void _payMilestone(CommissionMilestone milestone) async {
    try {
      await _stripeService.processCommissionMilestone(
        commissionId: _commission!.id,
        milestoneId: milestone.id,
        amount: milestone.amount,
        message: 'Milestone payment for ${milestone.description}',
      );

      await _loadCommissionDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Milestone payment processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing milestone payment: $e')),
        );
      }
    }
  }

  void _downloadFile(CommissionFile file) {
    // TODO: Implement file download
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Downloading ${file.name}...')));
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
