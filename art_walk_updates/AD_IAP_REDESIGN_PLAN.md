# Advertisement IAP Redesign - Fixed Tier System

## Problem

Current dynamic pricing system (Zone: $10-25/day + Size: $1-10/day × Duration) creates hundreds of price combinations incompatible with Apple's IAP fixed pricing model.

## Solution: Fixed Package System

Create predefined IAP packages that combine Zone + Size + Duration into fixed prices.

## New IAP Product Structure

### Tier 1: Basic Packages (7 days)

- `ad_basic_premium_small`: $14.99 - Small ad in Premium zones (Home/Community) - 7 days
- `ad_basic_premium_medium`: $24.99 - Medium ad in Premium zones - 7 days
- `ad_basic_premium_large`: $34.99 - Large ad in Premium zones - 7 days
- `ad_basic_standard_small`: $9.99 - Small ad in Standard zones (Art/Events) - 7 days
- `ad_basic_standard_medium`: $19.99 - Medium ad in Standard zones - 7 days
- `ad_basic_standard_large`: $29.99 - Large ad in Standard zones - 7 days
- `ad_basic_budget_small`: $4.99 - Small ad in Budget zone (Artist Profiles) - 7 days
- `ad_basic_budget_medium`: $14.99 - Medium ad in Budget zone - 7 days
- `ad_basic_budget_large`: $24.99 - Large ad in Budget zone - 7 days

### Tier 2: Standard Packages (14 days)

- `ad_standard_premium_small`: $29.99 - Small ad in Premium zones - 14 days
- `ad_standard_premium_medium`: $49.99 - Medium ad in Premium zones - 14 days
- `ad_standard_premium_large`: $69.99 - Large ad in Premium zones - 14 days
- `ad_standard_standard_small`: $19.99 - Small ad in Standard zones - 14 days
- `ad_standard_standard_medium`: $39.99 - Medium ad in Standard zones - 14 days
- `ad_standard_standard_large`: $59.99 - Large ad in Standard zones - 14 days
- `ad_standard_budget_small`: $9.99 - Small ad in Budget zone - 14 days
- `ad_standard_budget_medium`: $29.99 - Medium ad in Budget zone - 14 days
- `ad_standard_budget_large`: $49.99 - Large ad in Budget zone - 14 days

### Tier 3: Premium Packages (30 days)

- `ad_premium_premium_small`: $59.99 - Small ad in Premium zones - 30 days
- `ad_premium_premium_medium`: $99.99 - Medium ad in Premium zones - 30 days
- `ad_premium_premium_large`: $139.99 - Large ad in Premium zones - 30 days
- `ad_premium_standard_small`: $39.99 - Small ad in Standard zones - 30 days
- `ad_premium_standard_medium`: $79.99 - Medium ad in Standard zones - 30 days
- `ad_premium_standard_large`: $119.99 - Large ad in Standard zones - 30 days
- `ad_premium_budget_small`: $19.99 - Small ad in Budget zone - 30 days
- `ad_premium_budget_medium`: $59.99 - Medium ad in Budget zone - 30 days
- `ad_premium_budget_large`: $99.99 - Large ad in Budget zone - 30 days

## Zone Groupings

- **Premium Zones**: Home & Discovery ($25/day), Community & Social ($20/day)
- **Standard Zones**: Art & Walks ($15/day), Events & Experiences ($15/day)
- **Budget Zone**: Artist Profiles ($10/day)

## Implementation Plan

1. Update `InAppAdService` with new product definitions
2. Modify `AdPackage` enum to include zone/size/duration combinations
3. Update ad creation screen to show package selection instead of individual options
4. Create package selection UI with clear pricing
5. Update payment processing to use fixed packages
6. Maintain backward compatibility for existing ads

## Benefits

- ✅ Apple IAP compliant with fixed pricing
- ✅ Simplified user experience with clear packages
- ✅ Maintains zone and size targeting options
- ✅ Professional tiered pricing structure
- ✅ Easier for advertisers to understand costs upfront
