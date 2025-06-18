#!/bin/bash

# Fix remaining model type casting issues in artbeat_community

# Fix sponsor_model.dart
find /Users/kristybock/updated_artbeat_app/packages/artbeat_community/lib/models -name "sponsor_model.dart" -exec sed -i '' \
  -e 's/data\[\x27companyName\x27\]/\(data\[\x27companyName\x27\] as String?\)/g' \
  -e 's/data\[\x27sponsorshipType\x27\]/\(data\[\x27sponsorshipType\x27\] as String?\)/g' \
  -e 's/data\[\x27sponsorshipAmount\x27\]/\(data\[\x27sponsorshipAmount\x27\] as String?\)/g' \
  -e 's/data\[\x27contactEmail\x27\]/\(data\[\x27contactEmail\x27\] as String?\)/g' \
  -e 's/data\[\x27createdAt\x27\]/\(data\[\x27createdAt\x27\] as Timestamp?\)/g' \
  -e 's/data\[\x27updatedAt\x27\]/\(data\[\x27updatedAt\x27\] as Timestamp?\)/g' \
  {} \;

echo "Fixed sponsor_model.dart"

# Fix studio_model.dart  
find /Users/kristybock/updated_artbeat_app/packages/artbeat_community/lib/models -name "studio_model.dart" -exec sed -i '' \
  -e 's/data\[\x27name\x27\]/\(data\[\x27name\x27\] as String?\)/g' \
  -e 's/data\[\x27description\x27\]/\(data\[\x27description\x27\] as String?\)/g' \
  -e 's/data\[\x27location\x27\]/\(data\[\x27location\x27\] as String?\)/g' \
  -e 's/List<String>\.from(data\[\x27amenities\x27\])/List<String>\.from\(data\[\x27amenities\x27\] as Iterable? ?? \[\]\)/g' \
  -e 's/List<String>\.from(data\[\x27availabilitySlots\x27\])/List<String>\.from\(data\[\x27availabilitySlots\x27\] as Iterable? ?? \[\]\)/g' \
  -e 's/data\[\x27createdAt\x27\]/\(data\[\x27createdAt\x27\] as Timestamp?\)/g' \
  -e 's/data\[\x27updatedAt\x27\]/\(data\[\x27updatedAt\x27\] as Timestamp?\)/g' \
  {} \;

echo "Fixed studio_model.dart"

# Fix user_model.dart
find /Users/kristybock/updated_artbeat_app/packages/artbeat_community/lib/models -name "user_model.dart" -exec sed -i '' \
  -e 's/data\[\x27userId\x27\]/\(data\[\x27userId\x27\] as String?\)/g' \
  -e 's/data\[\x27email\x27\]/\(data\[\x27email\x27\] as String?\)/g' \
  -e 's/data\[\x27displayName\x27\]/\(data\[\x27displayName\x27\] as String?\)/g' \
  -e 's/data\[\x27bio\x27\]/\(data\[\x27bio\x27\] as String?\)/g' \
  -e 's/data\[\x27location\x27\]/\(data\[\x27location\x27\] as String?\)/g' \
  -e 's/data\[\x27createdAt\x27\]/\(data\[\x27createdAt\x27\] as Timestamp?\)/g' \
  {} \;

echo "Fixed user_model.dart"

echo "Type casting fixes complete!"
