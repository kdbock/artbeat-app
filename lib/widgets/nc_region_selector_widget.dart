import 'package:flutter/material.dart';
import 'package:artbeat/data/nc_zip_code_db.dart';

/// A widget that provides a dropdown to select a North Carolina region
/// This can be used for filtering artwork, artists, or events by region
class NCRegionSelectorWidget extends StatefulWidget {
  /// Function called when a region is selected
  final Function(String) onRegionSelected;

  /// Currently selected region (optional)
  final String? initialRegion;

  /// Widget title (optional)
  final String title;

  /// Whether to show a 'All Regions' option
  final bool showAllOption;

  const NCRegionSelectorWidget({
    super.key,
    required this.onRegionSelected,
    this.initialRegion,
    this.title = 'Select Region',
    this.showAllOption = true,
  });

  @override
  State<NCRegionSelectorWidget> createState() => _NCRegionSelectorWidgetState();
}

class _NCRegionSelectorWidgetState extends State<NCRegionSelectorWidget> {
  final NCZipCodeDatabase _db = NCZipCodeDatabase();
  late String _selectedRegion;

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialRegion ??
        (widget.showAllOption ? 'All Regions' : _db.getAllRegions().first.name);
  }

  @override
  Widget build(BuildContext context) {
    List<String> regionNames =
        _db.getAllRegions().map((region) => region.name).toList();

    if (widget.showAllOption) {
      regionNames.insert(0, 'All Regions');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedRegion,
              items: regionNames.map((String region) {
                return DropdownMenuItem<String>(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRegion = newValue;
                  });
                  widget.onRegionSelected(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
