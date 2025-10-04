#!/bin/bash

# Quick setup script for .env.local

echo "🔧 Setting up .env.local for secure configuration..."
echo ""

if [ -f ".env.local" ]; then
    echo "⚠️  .env.local already exists!"
    read -p "Do you want to overwrite it? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
fi

cat > .env.local << 'ENVLOCAL'
# Local Environment Variables
# This file is gitignored - safe to store your actual keys here

# Environment
export ENVIRONMENT=development

# Google Maps API Key
# TODO: Get from https://console.cloud.google.com/apis/credentials
export GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Stripe Publishable Key (Rotated October 3, 2025)
# Current key expires in 8 days
export STRIPE_PUBLISHABLE_KEY=pk_live_51QpJ6iAO5ulTKoALLtQFut6aQIyhLvrcUWRgA8RINvB6xwa37NeKymcV5lM96Yg6oOXvMQuwjPzP5LbE6I5ktHWG00Xk24gmn2

# Firebase Region
export FIREBASE_REGION=us-central1

# API Base URL
export API_BASE_URL=https://api.artbeat.app
ENVLOCAL

chmod 600 .env.local

echo "✅ .env.local created!"
echo ""
echo "⚠️  IMPORTANT: You still need to update GOOGLE_MAPS_API_KEY"
echo ""
echo "To edit:"
echo "  nano .env.local"
echo ""
echo "To use:"
echo "  source .env.local"
echo "  ./scripts/build_secure.sh run"
echo ""
