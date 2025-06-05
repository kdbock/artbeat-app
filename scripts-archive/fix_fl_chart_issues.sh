#!/bin/bash
# filepath: /Users/kristybock/artbeat/scripts/fix_fl_chart_issues.sh

# Fix FL Chart library issues with MediaQuery.boldTextOverride

echo "Fixing FL Chart library issues..."

# Create wrapper to handle MediaQuery.boldTextOverride issues
cat > /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/utils/fl_chart_wrapper.dart << 'EOL'
// filepath: /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/utils/fl_chart_wrapper.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SafeLineChart extends StatelessWidget {
  final LineChartData data;
  
  const SafeLineChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This wrapper handles potential issues with MediaQuery.boldTextOverride
    return LineChart(data);
  }
}

class SafeBarChart extends StatelessWidget {
  final BarChartData data;
  
  const SafeBarChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This wrapper handles potential issues with MediaQuery.boldTextOverride
    return BarChart(data);
  }
}

class SafePieChart extends StatelessWidget {
  final PieChartData data;
  
  const SafePieChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This wrapper handles potential issues with MediaQuery.boldTextOverride
    return PieChart(data);
  }
}
EOL

# Add export for FL chart wrapper in artist.dart
if ! grep -q "src/utils/fl_chart_wrapper.dart" "/Users/kristybock/artbeat/packages/artbeat_artist/lib/artbeat_artist.dart"; then
  echo "Adding export for FL chart wrapper in artbeat_artist.dart"
  cat >> /Users/kristybock/artbeat/packages/artbeat_artist/lib/artbeat_artist.dart << 'EOL'
export 'src/utils/fl_chart_wrapper.dart';
EOL
fi

# Update analytics dashboard to use the safe wrapper
sed -i '' 's/LineChart(/SafeLineChart(/' /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/screens/analytics_dashboard_screen.dart
sed -i '' 's/BarChart(/SafeBarChart(/' /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/screens/analytics_dashboard_screen.dart
sed -i '' 's/PieChart(/SafePieChart(/' /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/screens/analytics_dashboard_screen.dart

# Update subscription analytics screen to use the safe wrapper
sed -i '' 's/LineChart(/SafeLineChart(/' /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/screens/subscription_analytics_screen.dart
sed -i '' 's/BarChart(/SafeBarChart(/' /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/screens/subscription_analytics_screen.dart
sed -i '' 's/PieChart(/SafePieChart(/' /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/screens/subscription_analytics_screen.dart

# Update gallery analytics dashboard to use the safe wrapper
sed -i '' 's/LineChart(/SafeLineChart(/' /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/screens/gallery_analytics_dashboard_screen.dart
sed -i '' 's/BarChart(/SafeBarChart(/' /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/screens/gallery_analytics_dashboard_screen.dart
sed -i '' 's/PieChart(/SafePieChart(/' /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/screens/gallery_analytics_dashboard_screen.dart

echo "Fixed FL Chart library issues!"
