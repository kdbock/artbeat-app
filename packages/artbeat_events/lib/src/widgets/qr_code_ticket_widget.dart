import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show UniversalHeader, MainLayout;
import '../models/ticket_purchase.dart';
import '../models/artbeat_event.dart';
import '../utils/event_utils.dart';

/// Widget for displaying a QR code ticket
class QRCodeTicketWidget extends StatelessWidget {
  final TicketPurchase ticket;
  final ArtbeatEvent event;

  const QRCodeTicketWidget({
    super.key,
    required this.ticket,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: UniversalHeader(
          title: 'Event Ticket',
          showLogo: false,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: () => _shareTicket(context),
              icon: const Icon(Icons.share, color: Colors.white),
            ),
          ],
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            child: _buildTicketCard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTicketHeader(),
          _buildTicketDivider(),
          _buildTicketBody(),
          _buildTicketDivider(),
          _buildQRCodeSection(),
          _buildTicketFooter(),
        ],
      ),
    );
  }

  Widget _buildTicketHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.event, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ARTbeat Event',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today,
            'Date',
            EventUtils.formatEventDate(event.dateTime),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.access_time,
            'Time',
            EventUtils.formatEventTime(event.dateTime),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.location_on,
            'Location',
            event.location,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.confirmation_number,
            'Tickets',
            '${ticket.quantity} ticket${ticket.quantity > 1 ? 's' : ''}',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.person,
            'Name',
            ticket.userName,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Scan for Entry',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: ticket.qrCodeData,
              size: 200.0,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              eyeStyle: const QrEyeStyle(),
              dataModuleStyle: const QrDataModuleStyle(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ticket ID: ${_formatTicketId(ticket.id)}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Purchase Date',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, y').format(ticket.purchaseDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.status.displayName,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Text(
                  '⚠️ Important',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep this QR code safe and present it at the event entrance. Screenshots are acceptable.',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDivider() {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 2,
            child: Row(
              children: List.generate(
                50,
                (index) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTicketId(String id) {
    // Format the ticket ID to be more readable
    if (id.length > 8) {
      return '${id.substring(0, 4)}-${id.substring(4, 8)}-${id.substring(8, 12)}';
    }
    return id;
  }

  void _shareTicket(BuildContext context) {
    final shareText = 'Here is my ARTbeat event ticket for ${event.title} on '
        '${EventUtils.formatEventDate(event.dateTime)} at ${event.location}.\n'
        'Ticket ID: ${_formatTicketId(ticket.id)}\n'
        'Show this QR code at the entrance!';
    SharePlus.instance.share(
      ShareParams(text: shareText),
    );
  }
}
