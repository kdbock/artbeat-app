import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZipCodeSearchBox extends StatefulWidget {
  final String initialValue;
  final void Function(String) onZipCodeSubmitted;
  final bool isLoading;
  final VoidCallback? onNavigateToMap;

  const ZipCodeSearchBox({
    super.key,
    required this.initialValue,
    required this.onZipCodeSubmitted,
    this.isLoading = false,
    this.onNavigateToMap,
  });

  @override
  State<ZipCodeSearchBox> createState() => _ZipCodeSearchBoxState();
}

class _ZipCodeSearchBoxState extends State<ZipCodeSearchBox> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant ZipCodeSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter ZIP code',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              onSubmitted: widget.onZipCodeSubmitted,
            ),
          ),
          if (!widget.isLoading)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    widget.onZipCodeSubmitted(_controller.text);
                    // Navigate to art walk map after submitting zip code
                    widget.onNavigateToMap?.call();
                  }
                },
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Go to Art Walk Map',
              ),
            ),
        ],
      ),
    );
  }
}
