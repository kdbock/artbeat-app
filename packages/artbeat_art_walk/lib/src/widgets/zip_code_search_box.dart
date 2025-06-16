import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZipCodeSearchBox extends StatelessWidget {
  final String initialValue;
  final Function(String) onZipCodeSubmitted;
  final bool isLoading;

  const ZipCodeSearchBox({
    super.key,
    required this.initialValue,
    required this.onZipCodeSubmitted,
    this.isLoading = false,
  });

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
      child: TextField(
        controller: TextEditingController(text: initialValue),
        decoration: InputDecoration(
          hintText: 'Enter ZIP code',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: isLoading
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(5),
        ],
        onSubmitted: onZipCodeSubmitted,
      ),
    );
  }
}
