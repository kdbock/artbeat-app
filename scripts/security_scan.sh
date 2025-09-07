#!/bin/bash

# Security Scanner for ARTbeat Flutter App
# Scans for potential secrets and security issues

echo "🔍 ARTbeat Security Scanner"
echo "============================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize counters
secrets_found=0
warnings_found=0
files_scanned=0

# Function to check if a match is in a legitimate context
is_legitimate_context() {
    local file="$1"
    local line_content="$2"

    # Skip legitimate authentication code
    if [[ "$file" == *"auth"* ]] || [[ "$file" == *"login"* ]] || [[ "$file" == *"register"* ]]; then
        if [[ "$line_content" == *"password"* ]] || [[ "$line_content" == *"Password"* ]]; then
            return 0  # legitimate
        fi
    fi

    # Skip legitimate token handling code
    if [[ "$file" == *"firebase"* ]] || [[ "$file" == *"app_check"* ]] || [[ "$file" == *"notification"* ]]; then
        if [[ "$line_content" == *"token"* ]] || [[ "$line_content" == *"Token"* ]]; then
            return 0  # legitimate
        fi
    fi

    # Skip legitimate validation code
    if [[ "$file" == *"validator"* ]] || [[ "$file" == *"validation"* ]]; then
        if [[ "$line_content" == *"password"* ]] || [[ "$line_content" == *"secret"* ]]; then
            return 0  # legitimate
        fi
    fi

    # Skip legitimate configuration files
    if [[ "$file" == *"config"* ]] || [[ "$file" == *"settings"* ]]; then
        if [[ "$line_content" == *"key"* ]] || [[ "$line_content" == *"token"* ]]; then
            return 0  # legitimate
        fi
    fi

    # Skip test files
    if [[ "$file" == *"test"* ]] || [[ "$file" == *"_test"* ]]; then
        return 0  # legitimate
    fi

    # Skip documentation and comments
    if [[ "$line_content" == *"//"* ]] || [[ "$line_content" == *"/*"* ]] || [[ "$line_content" == *"///"* ]]; then
        return 0  # legitimate
    fi

    return 1  # potentially problematic
}

echo -e "${BLUE}Scanning for potential secrets...${NC}"

# Scan for hardcoded secrets
while IFS= read -r -d '' file; do
    ((files_scanned++))
    echo -e "${BLUE}Scanning: $file${NC}"

    # Check for potential API keys
    if grep -n "AIza[0-9A-Za-z-_]\{35\}" "$file" > /dev/null 2>&1; then
        echo -e "${RED}❌ POTENTIAL API KEY FOUND in $file${NC}"
        grep -n "AIza[0-9A-Za-z-_]\{35\}" "$file"
        ((secrets_found++))
    fi

    # Check for potential private keys
    if grep -n "-----BEGIN.*PRIVATE KEY-----" "$file" > /dev/null 2>&1; then
        echo -e "${RED}❌ POTENTIAL PRIVATE KEY FOUND in $file${NC}"
        ((secrets_found++))
    fi

    # Check for potential tokens (more selective)
    while IFS=: read -r line_num line_content; do
        if [[ "$line_content" =~ token|Token ]] && [[ "$line_content" =~ [A-Za-z0-9]{20,} ]]; then
            if ! is_legitimate_context "$file" "$line_content"; then
                echo -e "${YELLOW}⚠️  POTENTIAL TOKEN in $file:$line_num${NC}"
                echo "   $line_content"
                ((warnings_found++))
            fi
        fi
    done < <(grep -n "token\|Token" "$file")

    # Check for potential passwords (more selective)
    while IFS=: read -r line_num line_content; do
        if [[ "$line_content" =~ password|Password|secret|Secret ]] && [[ "$line_content" =~ [A-Za-z0-9]{8,} ]]; then
            if ! is_legitimate_context "$file" "$line_content"; then
                echo -e "${YELLOW}⚠️  POTENTIAL PASSWORD/SECRET in $file:$line_num${NC}"
                echo "   $line_content"
                ((warnings_found++))
            fi
        fi
    done < <(grep -n "password\|Password\|secret\|Secret" "$file")

done < <(find . -type f \( -name "*.dart" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.js" \) -not -path "./.git/*" -not -path "./build/*" -not -path "./.dart_tool/*" -print0)

echo ""
echo -e "${BLUE}Security Scan Complete${NC}"
echo "========================"
echo -e "${BLUE}Files scanned: $files_scanned${NC}"
echo -e "${RED}Critical secrets found: $secrets_found${NC}"
echo -e "${YELLOW}Warnings: $warnings_found${NC}"

if [ $secrets_found -eq 0 ] && [ $warnings_found -eq 0 ]; then
    echo -e "${GREEN}✅ No security issues found!${NC}"
    exit 0
elif [ $secrets_found -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Only warnings found (likely false positives)${NC}"
    exit 0
else
    echo -e "${RED}❌ Security issues found!${NC}"
    exit 1
fi
