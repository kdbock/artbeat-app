import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
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

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48 + 4),
        child: Container(
          decoration: const BoxDecoration(
            gradient: CommunityColors.communityGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(_commission!.status),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _commission!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Commission Details',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  if (_isArtist &&
                      _commission!.status == CommissionStatus.pending)
                    const PopupMenuItem(
                      value: 'provide_quote',
                      child: Text('Provide Quote'),
                    ),
                  if (_isClient &&
                      _commission!.status == CommissionStatus.quoted)
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
        ),
      ),
      backgroundColor: CommunityColors.background,
      body: Column(
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
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const QuoteProvisionDialog(),
    ).then((result) {
      if (result != null) {
        _submitQuote(
          result['price'] as double,
          result['description'] as String,
          result['timeline'] as String,
          result['milestones'] as List<Map<String, dynamic>>,
        );
      }
    });
  }

  Future<void> _submitQuote(
    double price,
    String description,
    String timeline,
    List<Map<String, dynamic>> milestoneMaps,
  ) async {
    // Convert milestone maps to CommissionMilestone objects
    final milestones = milestoneMaps
        .map(
          (m) => CommissionMilestone(
            id:
                DateTime.now().millisecondsSinceEpoch.toString() +
                m['title'].hashCode.toString(),
            title: m['title'] as String,
            description: m['description'] as String,
            amount: m['amount'] as double,
            dueDate: m['dueDate'] as DateTime,
            status: MilestoneStatus.pending,
          ),
        )
        .toList();

    try {
      await _commissionService.provideQuote(
        commissionId: _commission!.id,
        totalPrice: price,
        depositPercentage: 50.0, // Default 50% deposit
        milestones: milestones,
        estimatedCompletion: _parseTimeline(timeline),
        quoteMessage: description,
      );
      await _loadCommissionDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting quote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    showDialog<String>(
      context: context,
      builder: (context) => const CancellationDialog(),
    ).then((reason) {
      if (reason != null && reason.isNotEmpty) {
        _submitCancellation(reason);
      }
    });
  }

  Future<void> _submitCancellation(String reason) async {
    try {
      await _commissionService.cancelCommission(_commission!.id, reason);
      await _loadCommissionDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commission cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling commission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _downloadFile(CommissionFile file) async {
    try {
      // Show initial progress
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Downloading ${file.name}...')));

      // Download the file
      final response = await http.get(Uri.parse(file.url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      // Get the downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/Downloads');

      // Create downloads directory if it doesn't exist
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Create file with appropriate extension based on content type or filename
      final fileExtension = _getFileExtension(file.name);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${file.name}_$timestamp$fileExtension';
      final localFile = File('${downloadsDir.path}/$fileName');

      // Write file to disk
      await localFile.writeAsBytes(response.bodyBytes);

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File downloaded successfully: ${localFile.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              // Note: Opening files would require additional platform-specific code
              // For now, just show the path
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('File saved at: ${localFile.path}')),
              );
            },
          ),
        ),
      );
    } catch (e) {
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getFileExtension(String fileName) {
    // Extract extension from filename if present
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot);
    }

    // Default extension if none found
    return '.file';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  DateTime _parseTimeline(String timeline) {
    final now = DateTime.now();
    final lowerTimeline = timeline.toLowerCase().trim();

    // Handle various timeline formats
    if (lowerTimeline.contains('week')) {
      // Extract number from "2-3 weeks", "1 week", etc.
      final weekMatch = RegExp(
        r'(\d+)(?:\s*-\s*\d+)?\s*week',
      ).firstMatch(lowerTimeline);
      if (weekMatch != null) {
        final weeks = int.tryParse(weekMatch.group(1) ?? '1') ?? 1;
        return now.add(Duration(days: weeks * 7));
      }
    } else if (lowerTimeline.contains('month')) {
      // Extract number from "2-3 months", "1 month", etc.
      final monthMatch = RegExp(
        r'(\d+)(?:\s*-\s*\d+)?\s*month',
      ).firstMatch(lowerTimeline);
      if (monthMatch != null) {
        final months = int.tryParse(monthMatch.group(1) ?? '1') ?? 1;
        return DateTime(now.year, now.month + months, now.day);
      }
    } else if (lowerTimeline.contains('day')) {
      // Extract number from "5-7 days", "1 day", etc.
      final dayMatch = RegExp(
        r'(\d+)(?:\s*-\s*\d+)?\s*day',
      ).firstMatch(lowerTimeline);
      if (dayMatch != null) {
        final days = int.tryParse(dayMatch.group(1) ?? '1') ?? 1;
        return now.add(Duration(days: days));
      }
    }

    // Default fallback: assume 30 days for unrecognized formats
    return now.add(const Duration(days: 30));
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class QuoteProvisionDialog extends StatefulWidget {
  const QuoteProvisionDialog({super.key});

  @override
  State<QuoteProvisionDialog> createState() => _QuoteProvisionDialogState();
}

class _QuoteProvisionDialogState extends State<QuoteProvisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timelineController = TextEditingController();

  // Milestones
  final List<Map<String, dynamic>> _milestones = [];

  void _addMilestone() {
    setState(() {
      _milestones.add({
        'title': '',
        'description': '',
        'amount': 0.0,
        'dueDate': DateTime.now().add(const Duration(days: 7)),
      });
    });
  }

  void _removeMilestone(int index) {
    setState(() {
      _milestones.removeAt(index);
    });
  }

  void _updateMilestone(int index, String field, dynamic value) {
    setState(() {
      _milestones[index][field] = value;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Invalid date format
    }
    return null;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Provide Quote'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (USD)',
                  prefixText: '\$',
                  hintText: 'Enter your quote amount',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Quote Description',
                  hintText: 'Describe your work and approach',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timelineController,
                decoration: const InputDecoration(
                  labelText: 'Timeline',
                  hintText: 'e.g., 2-3 weeks, 1 month',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please specify a timeline';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Milestones',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addMilestone,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Milestone'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_milestones.isEmpty)
                const Text(
                  'No milestones added. Add milestones to break down the work and payments.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _milestones.length,
                  itemBuilder: (context, index) {
                    final milestone = _milestones[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: milestone['title'] as String,
                                    decoration: const InputDecoration(
                                      labelText: 'Milestone Title',
                                      hintText: 'e.g., Initial sketch',
                                    ),
                                    onChanged: (value) =>
                                        _updateMilestone(index, 'title', value),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeMilestone(index),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: milestone['description'] as String,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                hintText: 'Describe this milestone',
                              ),
                              maxLines: 2,
                              onChanged: (value) =>
                                  _updateMilestone(index, 'description', value),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: milestone['amount']
                                        .toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Amount (USD)',
                                      prefixText: '\$',
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final amount =
                                          double.tryParse(value) ?? 0.0;
                                      _updateMilestone(index, 'amount', amount);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _formatDate(
                                      milestone['dueDate'] as DateTime,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Due Date',
                                      hintText: 'MM/DD/YYYY',
                                    ),
                                    onChanged: (value) {
                                      final date = _parseDate(value);
                                      if (date != null) {
                                        _updateMilestone(
                                          index,
                                          'dueDate',
                                          date,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Submit Quote')),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final price = double.parse(_priceController.text);
      final description = _descriptionController.text;
      final timeline = _timelineController.text;

      // Validate milestones
      for (final milestone in _milestones) {
        if ((milestone['title'] as String).isEmpty ||
            (milestone['description'] as String).isEmpty ||
            (milestone['amount'] as double) <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete all milestone details'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      Navigator.of(context).pop({
        'price': price,
        'description': description,
        'timeline': timeline,
        'milestones': _milestones,
      });
    }
  }
}

class CancellationDialog extends StatefulWidget {
  const CancellationDialog({super.key});

  @override
  State<CancellationDialog> createState() => _CancellationDialogState();
}

class _CancellationDialogState extends State<CancellationDialog> {
  final _reasonController = TextEditingController();
  String _selectedReason = '';

  final List<String> _predefinedReasons = [
    'Changed my mind',
    'Found another artist',
    'Budget constraints',
    'Timeline issues',
    'Communication problems',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Commission'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this commission? This action cannot be undone.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text('Reason for cancellation:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _predefinedReasons
                  .map(
                    (reason) => SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedReason = reason;
                            if (reason != 'Other') {
                              _reasonController.clear();
                            }
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _selectedReason == reason
                              ? Colors.red.withValues(alpha: 0.1)
                              : null,
                          side: BorderSide(
                            color: _selectedReason == reason
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                        child: Text(reason),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (_selectedReason == 'Other')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Please specify...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep Commission'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancel Commission'),
        ),
      ],
    );
  }

  void _submit() {
    String reason;
    if (_selectedReason == 'Other') {
      reason = _reasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide a reason')),
        );
        return;
      }
    } else if (_selectedReason.isNotEmpty) {
      reason = _selectedReason;
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a reason')));
      return;
    }

    Navigator.of(context).pop(reason);
  }
}
