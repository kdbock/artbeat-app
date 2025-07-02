import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ticket_type.dart';

/// Widget for building and editing individual ticket types
class TicketTypeBuilder extends StatefulWidget {
  final TicketType ticketType;
  final Function(TicketType) onChanged;
  final VoidCallback onRemove;

  const TicketTypeBuilder({
    super.key,
    required this.ticketType,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<TicketTypeBuilder> createState() => _TicketTypeBuilderState();
}

class _TicketTypeBuilderState extends State<TicketTypeBuilder> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TicketCategory _selectedCategory;
  List<String> _benefits = [];
  final TextEditingController _benefitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ticketType.name);
    _descriptionController =
        TextEditingController(text: widget.ticketType.description);
    _priceController =
        TextEditingController(text: widget.ticketType.price.toString());
    _quantityController =
        TextEditingController(text: widget.ticketType.quantity.toString());
    _selectedCategory = widget.ticketType.category;
    _benefits = List.from(widget.ticketType.benefits);

    // Listen to changes and update the ticket type
    _nameController.addListener(_updateTicketType);
    _descriptionController.addListener(_updateTicketType);
    _priceController.addListener(_updateTicketType);
    _quantityController.addListener(_updateTicketType);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _benefitController.dispose();
    super.dispose();
  }

  void _updateTicketType() {
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;

    final updatedTicket = widget.ticketType.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      price: _selectedCategory == TicketCategory.free ? 0.0 : price,
      quantity: quantity,
      benefits: _benefits,
    );

    widget.onChanged(updatedTicket);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with remove button
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ticket Type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove ticket type',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ticket category selection
            DropdownButtonFormField<TicketCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Ticket Category',
                border: OutlineInputBorder(),
              ),
              items: TicketCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (category) {
                if (category != null) {
                  setState(() {
                    _selectedCategory = category;
                    if (category == TicketCategory.free) {
                      _priceController.text = '0.0';
                    }
                  });
                  _updateTicketType();
                }
              },
            ),
            const SizedBox(height: 16),

            // Ticket name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ticket Name',
                hintText: 'e.g., General Admission, VIP Access',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter ticket name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Ticket description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of this ticket type',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Price and quantity row
            Row(
              children: [
                // Price field
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: r'Price ($)',
                      border: const OutlineInputBorder(),
                      enabled: _selectedCategory != TicketCategory.free,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (_selectedCategory != TicketCategory.free) {
                        final price = double.tryParse(value ?? '');
                        if (price == null || price < 0) {
                          return 'Enter valid price';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Quantity field
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final quantity = int.tryParse(value ?? '');
                      if (quantity == null || quantity <= 0) {
                        return 'Enter valid quantity';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Benefits section (especially for VIP tickets)
            if (_selectedCategory == TicketCategory.vip ||
                _benefits.isNotEmpty) ...[
              Text(
                'Benefits & Inclusions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // Benefits list
              if (_benefits.isNotEmpty)
                Column(
                  children: _benefits.asMap().entries.map((entry) {
                    final index = entry.key;
                    final benefit = entry.value;
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      title: Text(benefit),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _benefits.removeAt(index);
                          });
                          _updateTicketType();
                        },
                      ),
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),

              // Add benefit field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _benefitController,
                      decoration: const InputDecoration(
                        hintText: 'Add a benefit or inclusion',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onFieldSubmitted: _addBenefit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _addBenefit(_benefitController.text),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Quick benefit suggestions for VIP tickets
            if (_selectedCategory == TicketCategory.vip) ...[
              const Text('Quick add:',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  'Early entry',
                  'Meet & greet with artist',
                  'Complimentary drinks',
                  'Exclusive merchandise',
                  'Private viewing area',
                  'Artist workshop access',
                ].map((benefit) {
                  return ActionChip(
                    label: Text(benefit, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      if (!_benefits.contains(benefit)) {
                        setState(() {
                          _benefits.add(benefit);
                        });
                        _updateTicketType();
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addBenefit(String benefit) {
    if (benefit.trim().isNotEmpty && !_benefits.contains(benefit.trim())) {
      setState(() {
        _benefits.add(benefit.trim());
        _benefitController.clear();
      });
      _updateTicketType();
    }
  }
}
