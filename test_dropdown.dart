import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TestDropdownScreen(),
    );
  }
}

class TestDropdownScreen extends StatefulWidget {
  @override
  _TestDropdownScreenState createState() => _TestDropdownScreenState();
}

class _TestDropdownScreenState extends State<TestDropdownScreen> {
  String? _selectedArtType;
  String? _selectedArtMedium;

  static const List<String> _artTypes = [
    'Mural',
    'Street Art',
    'Sculpture',
    'Statue',
    'Graffiti',
    'Monument',
    'Memorial',
    'Fountain',
    'Installation',
    'Mosaic',
    'Public Art',
    'Wall Art',
    'Building Art',
    'Bridge Art',
    'Park Art',
    'Garden Art',
    'Plaza Art',
    'Architecture',
    'Relief',
    'Transit Art',
    'Playground Art',
    'Community Art',
    'Cultural Art',
    'Historical Marker',
    'Signage Art',
    'Other',
    'I don\'t know',
  ];

  static const List<String> _artMediums = [
    'Paint',
    'Spray Paint',
    'Acrylic',
    'Oil Paint',
    'Watercolor',
    'Bronze',
    'Steel',
    'Iron',
    'Aluminum',
    'Copper',
    'Stone',
    'Marble',
    'Granite',
    'Limestone',
    'Concrete',
    'Brick',
    'Wood',
    'Glass',
    'Stained Glass',
    'Ceramic',
    'Tile',
    'Mosaic Tile',
    'Metal',
    'Plaster',
    'Fiberglass',
    'Resin',
    'Mixed Media',
    'Digital/LED',
    'Neon',
    'Chalk',
    'Charcoal',
    'Fabric',
    'Plastic',
    'Vinyl',
    'Paper',
    'Canvas',
    'Other',
    'Unknown',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Dropdowns')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Art Types: ${_artTypes.length}'),
            Text('Art Mediums: ${_artMediums.length}'),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedArtType,
              decoration: InputDecoration(
                labelText: 'Art Type',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _artTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedArtType = value;
                });
              },
              hint: Text('Select art type'),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedArtMedium,
              decoration: InputDecoration(
                labelText: 'Art Medium',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _artMediums.map((String medium) {
                return DropdownMenuItem<String>(
                  value: medium,
                  child: Text(medium),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedArtMedium = value;
                });
              },
              hint: Text('Select art medium'),
            ),
            SizedBox(height: 20),
            Text('Selected Art Type: $_selectedArtType'),
            Text('Selected Art Medium: $_selectedArtMedium'),
          ],
        ),
      ),
    );
  }
}
