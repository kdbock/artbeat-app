import 'package:flutter/material.dart';
import 'package:artbeat/data/nc_zip_code_db.dart';
import 'package:artbeat/models/nc_region_model.dart';
import 'package:artbeat/utils/nc_location_helper.dart';

/// A widget that displays counties for a selected NC region
class NCRegionCountiesWidget extends StatelessWidget {
  /// The region name to display counties for
  final String regionName;

  /// Callback when a county is selected
  final Function(String county)? onCountySelected;

  /// Whether to show a compact version of the list
  final bool isCompact;

  /// Maximum number of counties to display
  final int? maxCounties;

  const NCRegionCountiesWidget({
    super.key,
    required this.regionName,
    this.onCountySelected,
    this.isCompact = false,
    this.maxCounties,
  });

  @override
  Widget build(BuildContext context) {
    final NCZipCodeDatabase db = NCZipCodeDatabase();

    try {
      final region = db.getRegionByName(regionName);
      if (region == null) {
        return const Center(child: Text('Region not found'));
      }

      final counties = region.counties;
      final displayCounties =
          maxCounties != null && counties.length > maxCounties!
              ? counties.take(maxCounties!).toList()
              : counties;

      return isCompact
          ? _buildCompactList(context, displayCounties)
          : _buildFullList(context, displayCounties);
    } catch (e) {
      return Center(child: Text('Error loading counties: $e'));
    }
  }

  Widget _buildCompactList(BuildContext context, List<NCCountyModel> counties) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          counties.map((county) => _buildCountyChip(context, county)).toList(),
    );
  }

  Widget _buildFullList(BuildContext context, List<NCCountyModel> counties) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: counties.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final county = counties[index];
        return ListTile(
          title: Text(county.name),
          subtitle: Text('${county.zipCodes.length} ZIP codes'),
          onTap: () => onCountySelected?.call(county.name),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }

  Widget _buildCountyChip(BuildContext context, NCCountyModel county) {
    final helper = NCLocationHelper();
    final color = helper.getColorForRegion(regionName);

    return GestureDetector(
      onTap: () => onCountySelected?.call(county.name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          county.name.replaceAll(' County', ''),
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
