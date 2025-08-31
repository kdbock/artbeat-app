#!/bin/bash

# Script to update remaining admin screens to use MainLayout + EnhancedUniversalHeader

ADMIN_SCREENS=(
    "/Users/kristybock/artbeat/packages/artbeat_admin/lib/src/screens/admin_advanced_user_management_screen.dart"
    "/Users/kristybock/artbeat/packages/artbeat_admin/lib/src/screens/admin_settings_screen.dart"
    "/Users/kristybock/artbeat/packages/artbeat_admin/lib/src/screens/admin_user_detail_screen.dart"
    "/Users/kristybock/artbeat/packages/artbeat_admin/lib/src/screens/admin_advanced_content_management_screen.dart"
    "/Users/kristybock/artbeat/packages/artbeat_admin/lib/src/screens/admin_content_review_screen.dart"
    "/Users/kristybock/artbeat/packages/artbeat_admin/lib/src/screens/admin_financial_analytics_screen.dart"
)

for file in "${ADMIN_SCREENS[@]}"; do
    echo "Updating $file..."
    
    # Add artbeat_core import and remove admin_header import
    sed -i '' 's|import '\''package:flutter/material.dart'\'';|import '\''package:flutter/material.dart'\'';\nimport '\''package:artbeat_core/artbeat_core.dart'\'';|' "$file"
    sed -i '' '/import.*admin_header.dart/d' "$file"
    
    # Replace Scaffold with MainLayout structure
    sed -i '' 's|return Scaffold(|return MainLayout(|' "$file"
    sed -i '' 's|key: _scaffoldKey,|currentIndex: -1, // Admin screens don'\''t use bottom navigation\n      scaffoldKey: _scaffoldKey,|' "$file"
    sed -i '' 's|backgroundColor: Colors.white,||' "$file"
    
    # Replace AdminHeader with EnhancedUniversalHeader
    sed -i '' 's|appBar: AdminHeader(|appBar: const EnhancedUniversalHeader(|' "$file"
    sed -i '' '/onMenuPressed:/d' "$file"
    sed -i '' '/onSearchPressed:/d' "$file"
    sed -i '' '/onChatPressed:/d' "$file"
    sed -i '' '/showChat:/d' "$file"
    sed -i '' 's|showDeveloper: true,|showDeveloperTools: true,|' "$file"
    sed -i '' 's|body: Container(|child: Container(|' "$file"
    
    echo "Updated $file"
done

echo "All admin screens updated!"