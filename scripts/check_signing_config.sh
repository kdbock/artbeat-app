#!/bin/bash

echo "========================================="
echo "ARTbeat Signing Configuration Check"
echo "========================================="

# Check if keystore file exists
KEYSTORE_FILE="android/app/signing/artbeat-upload-key.jks"
echo "Checking keystore file: $KEYSTORE_FILE"
if [ -f "$KEYSTORE_FILE" ]; then
  echo "✅ Keystore file exists"
  ls -la "$KEYSTORE_FILE"
else
  echo "❌ Keystore file not found!"
  exit 1
fi

# Check if key.properties file exists and contains required properties
KEY_PROPS="android/key.properties"
echo -e "\nChecking key.properties file: $KEY_PROPS"
if [ -f "$KEY_PROPS" ]; then
  echo "✅ key.properties file exists"
  
  # Check required properties (without showing passwords)
  grep -q "storeFile=" "$KEY_PROPS" && echo "✅ storeFile property found" || echo "❌ storeFile property missing!"
  grep -q "storePassword=" "$KEY_PROPS" && echo "✅ storePassword property found" || echo "❌ storePassword property missing!"
  grep -q "keyAlias=" "$KEY_PROPS" && echo "✅ keyAlias property found" || echo "❌ keyAlias property missing!"
  grep -q "keyPassword=" "$KEY_PROPS" && echo "✅ keyPassword property found" || echo "❌ keyPassword property missing!"
else
  echo "❌ key.properties file not found!"
  exit 1
fi

# Check if the keystore contains the expected key alias
echo -e "\nVerifying keystore contents:"
STORE_PASSWORD=$(grep "storePassword=" "$KEY_PROPS" | cut -d'=' -f2)
KEY_ALIAS=$(grep "keyAlias=" "$KEY_PROPS" | cut -d'=' -f2)

if keytool -list -keystore "$KEYSTORE_FILE" -storepass "$STORE_PASSWORD" | grep -q "$KEY_ALIAS"; then
  echo "✅ Keystore contains the expected key alias: $KEY_ALIAS"
else
  echo "❌ Key alias '$KEY_ALIAS' not found in keystore!"
fi

echo -e "\nKeystore details:"
keytool -list -v -keystore "$KEYSTORE_FILE" -storepass "$STORE_PASSWORD" | grep -E "Alias name:|Creation date:|Owner:|Valid from:|Certificate fingerprints:"

echo -e "\nConfiguration check complete!"
echo "========================================="
