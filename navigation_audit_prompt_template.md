# Package Navigation Routing Audit Prompt Template

## 🔍 Package Navigation Routing Audit Prompt

```
Please perform a comprehensive navigation routing audit for the packages/artbeat_core/lib/src/screens/fluid_dashboard_screen.dart. I need you to:

## 1. **Navigation Discovery Phase**
- Scan all sections and widgets in `packages/artbeat_core/lib/src/screens/fluid_dashboard_screen.dart`
- Find ALL navigation actions including:
  - `Navigator.push()`, `Navigator.pushNamed()`, `Navigator.pushReplacement()`
  - `onTap`, `onPressed`, `onChanged` callbacks that trigger navigation
  - Any route strings or navigation constants
  - Deep links or external navigation triggers

## 2. **Destination Verification Phase**
For each navigation action found:
- Verify the destination screen/widget exists
- Check if the destination is properly exported from the package
- Identify any broken or missing navigation targets
- Document the expected navigation flow

## 3. **Main App Routing Integration Phase**
- Review `/lib/app.dart` routing configuration
- Identify which routes from this package are missing from main app routing
- Check for route naming conflicts or inconsistencies
- Verify route parameters and data passing

## 4. **Route Completeness Check**
Create a comprehensive list of ALL routes this package needs:
- Entry point routes (how users access this package's features)
- Internal navigation routes (between screens within the package)
- External routes (to other packages or main app features)
- Deep link support routes

## 5. **Fix Implementation**
- Add any missing routes to main app routing
- Fix any broken navigation actions
- Update any inconsistent route naming
- Ensure proper parameter passing between routes

## 6. **Testing & Verification**
- Verify all navigation paths work end-to-end
- Test back navigation behavior
- Check integration with main app navigation patterns
- Ensure no circular dependencies or navigation conflicts

## Expected Output Format:
### 📋 Navigation Inventory
- List all found navigation actions with source location
- Document expected destinations and current status

### 🔧 Required Fixes
- Missing routes to add to main app
- Broken navigation to fix
- Inconsistencies to resolve

### 🧪 Verification Plan
- Test cases to verify navigation works
- Integration points to validate

Please start with the packages/artbeat_core/lib/src/screens/fluid_dashboard_screen.dart and provide a detailed analysis.
```

---

## 🎯 Usage Instructions

### For each package, replace `[PACKAGE_NAME]` with:

- `artbeat_auth` (already done)
- `artbeat_profile` (already done)
- `artbeat_artist` (already done)
- `artbeat_artwork` (already done)
- `artbeat_art_walk`(already done)
- `artbeat_community`(already done)
- `artbeat_messaging` (already done)
- `artbeat_events`
- `artbeat_capture` (already done)

### Example for next package:

```
Please perform a comprehensive navigation routing audit for the artbeat_auth package. I need you to:
[... rest of prompt template above ...]
```

### Recommended Order:

1. **artbeat_auth** (foundational - other packages depend on it)
2. **artbeat_profile** (core user functionality)
3. **artbeat_artwork** (content features)
4. **artbeat_community** (social features)
5. **artbeat_art_walk** (location features)
6. **artbeat_messaging** (communication features)
7. **artbeat_events** (event features)
8. **artbeat_artist** (specialized features)

## Expected Benefits

This systematic approach will ensure:

- ✅ **Complete navigation coverage** across all packages
- ✅ **Consistent routing patterns** throughout the app
- ✅ **No broken navigation links**
- ✅ **Proper integration** between packages and main app
- ✅ **Testable navigation flows** for quality assurance

## Progress Tracking

### Completed Packages:

- [x] **artbeat_capture** - Navigation audit completed and fixes implemented

### Pending Packages:

- [ ] **artbeat_auth**
- [ ] **artbeat_profile**
- [ ] **artbeat_artwork**
- [ ] **artbeat_community**
- [ ] **artbeat_art_walk**
- [ ] **artbeat_messaging**
- [ ] **artbeat_events**
- [ ] **artbeat_artist**

---

_Created: $(date)_
_Purpose: Systematic navigation routing audit across all ARTbeat packages_
