#!/bin/bash

# ArtBeat - Android Keystore Setup Script
# This script helps you create a production keystore for Android app signing

set -e

echo "🔐 ArtBeat Android Keystore Setup"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo -e "${RED}❌ Error: keytool not found${NC}"
    echo "keytool is part of the Java Development Kit (JDK)"
    echo "Please install JDK and try again"
    exit 1
fi

echo -e "${GREEN}✅ keytool found${NC}"
echo ""

# Get keystore details
echo "Please provide the following information:"
echo ""

read -p "Keystore filename (default: upload-keystore.jks): " KEYSTORE_NAME
KEYSTORE_NAME=${KEYSTORE_NAME:-upload-keystore.jks}

read -p "Key alias (default: upload): " KEY_ALIAS
KEY_ALIAS=${KEY_ALIAS:-upload}

read -sp "Keystore password: " KEYSTORE_PASSWORD
echo ""
read -sp "Confirm keystore password: " KEYSTORE_PASSWORD_CONFIRM
echo ""

if [ "$KEYSTORE_PASSWORD" != "$KEYSTORE_PASSWORD_CONFIRM" ]; then
    echo -e "${RED}❌ Passwords do not match${NC}"
    exit 1
fi

read -sp "Key password (press Enter to use same as keystore): " KEY_PASSWORD
echo ""
if [ -z "$KEY_PASSWORD" ]; then
    KEY_PASSWORD=$KEYSTORE_PASSWORD
fi

echo ""
echo "Certificate Information:"
read -p "Your name (First and Last): " CERT_NAME
read -p "Organization (e.g., WordNerd): " CERT_ORG
read -p "Organization Unit (e.g., Development): " CERT_OU
read -p "City: " CERT_CITY
read -p "State/Province: " CERT_STATE
read -p "Country Code (2 letters, e.g., US): " CERT_COUNTRY

# Create secure directory
SECURE_DIR="$HOME/secure-keys/artbeat"
mkdir -p "$SECURE_DIR"

echo ""
echo -e "${YELLOW}Creating keystore...${NC}"

# Generate keystore
keytool -genkey -v \
    -keystore "$SECURE_DIR/$KEYSTORE_NAME" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=$CERT_NAME, OU=$CERT_OU, O=$CERT_ORG, L=$CERT_CITY, ST=$CERT_STATE, C=$CERT_COUNTRY"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Keystore created successfully!${NC}"
    echo ""
    echo "Keystore location: $SECURE_DIR/$KEYSTORE_NAME"
    echo ""
    
    # Create key.properties file
    KEY_PROPERTIES_PATH="$(dirname "$0")/../android/key.properties"
    
    echo -e "${YELLOW}Creating key.properties file...${NC}"
    
    cat > "$KEY_PROPERTIES_PATH" << EOF
storeFile=$SECURE_DIR/$KEYSTORE_NAME
storePassword=$KEYSTORE_PASSWORD
keyAlias=$KEY_ALIAS
keyPassword=$KEY_PASSWORD
mapsApiKey=YOUR_GOOGLE_MAPS_API_KEY_HERE
EOF
    
    echo -e "${GREEN}✅ key.properties created${NC}"
    echo ""
    
    # Security reminders
    echo -e "${YELLOW}⚠️  IMPORTANT SECURITY REMINDERS:${NC}"
    echo ""
    echo "1. 🔒 BACK UP YOUR KEYSTORE NOW!"
    echo "   Location: $SECURE_DIR/$KEYSTORE_NAME"
    echo "   Store it in a secure, encrypted location (e.g., password manager, encrypted cloud storage)"
    echo ""
    echo "2. 🔑 Update key.properties with your Google Maps API key:"
    echo "   File: android/key.properties"
    echo ""
    echo "3. ❌ NEVER commit key.properties to git (it's already in .gitignore)"
    echo ""
    echo "4. 📝 Save these credentials securely:"
    echo "   - Keystore password: [HIDDEN]"
    echo "   - Key alias: $KEY_ALIAS"
    echo "   - Key password: [HIDDEN]"
    echo ""
    echo "5. ⚠️  If you lose the keystore, you CANNOT publish updates to your app!"
    echo ""
    
    # Verify keystore
    echo -e "${YELLOW}Verifying keystore...${NC}"
    keytool -list -v -keystore "$SECURE_DIR/$KEYSTORE_NAME" -storepass "$KEYSTORE_PASSWORD" | head -20
    
    echo ""
    echo -e "${GREEN}✅ Setup complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Back up your keystore to a secure location"
    echo "2. Update android/key.properties with your Google Maps API key"
    echo "3. Test a release build: flutter build apk --release"
    echo ""
    
else
    echo -e "${RED}❌ Failed to create keystore${NC}"
    exit 1
fi