#!/bin/bash

################################################################################
# Product Service API Test Script
################################################################################
# Created: February 24, 2026
# Purpose: Automated testing of all Product Service API endpoints
# Server: maqha-be-product-service-production.up.railway.app
#
# Usage:
#   chmod +x tests/test_api.sh
#   ./tests/test_api.sh
#
# Tokens Used:
#   - Client Token: test-token-12345 (for GET operations)
#   - Admin Token: coffeeshop-admin-token-123 (for POST/PUT/DELETE operations)
#
# Requirements:
#   - curl
#   - jq (optional, for JSON formatting)
################################################################################

SERVER="https://maqha-be-product-service-production.up.railway.app"
CLIENT_TOKEN="test-token-12345"
ADMIN_TOKEN="coffeeshop-admin-token-123"

echo "========================================="
echo "Testing Product Service API"
echo "Server: $SERVER"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Ping endpoint
echo -e "${YELLOW}Test 1: GET /ping${NC}"
echo "curl -X GET \"$SERVER/ping\""
curl -X GET "$SERVER/ping"
echo -e "\n"
sleep 1

# Test 2: Get all products
echo -e "${YELLOW}Test 2: GET /product (Get All Products)${NC}"
echo "curl -X GET \"$SERVER/product\" -H \"Token: $CLIENT_TOKEN\""
curl -X GET "$SERVER/product" -H "Token: $CLIENT_TOKEN" | jq '.'
echo -e "\n"
sleep 1

# Test 3: Add a new category
echo -e "${YELLOW}Test 3: POST /category (Add Category) - Using Admin Token${NC}"
CATEGORY_PAYLOAD='{
  "category": "Beverages"
}'
echo "Payload: $CATEGORY_PAYLOAD"
echo "Token: $ADMIN_TOKEN"
curl -X POST "$SERVER/category" \
  -H "Token: $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$CATEGORY_PAYLOAD" | jq '.'
echo -e "\n"
sleep 1

# Test 4: Add another category
echo -e "${YELLOW}Test 4: POST /category (Add Another Category) - Using Admin Token${NC}"
CATEGORY_PAYLOAD2='{
  "category": "Pastries"
}'
echo "Payload: $CATEGORY_PAYLOAD2"
echo "Token: $ADMIN_TOKEN"
curl -X POST "$SERVER/category" \
  -H "Token: $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$CATEGORY_PAYLOAD2" | jq '.'
echo -e "\n"
sleep 1

# Test 5: Add a new product
echo -e "${YELLOW}Test 5: POST /product (Add Product) - Using Admin Token${NC}"
# Using a simple base64 placeholder for image
PRODUCT_PAYLOAD='{
  "category_id": 1,
  "name": "Iced Coffee",
  "description": "Cold brewed coffee served with ice",
  "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
  "price": 30000.00
}'
echo "Payload: $PRODUCT_PAYLOAD"
echo "Token: $ADMIN_TOKEN"
curl -X POST "$SERVER/product" \
  -H "Token: $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PRODUCT_PAYLOAD" | jq '.'
echo -e "\n"
sleep 1

# Test 6: Edit a category (Category ID 1)
echo -e "${YELLOW}Test 6: PUT /category/{categoryID} (Edit Category) - Using Admin Token${NC}"
EDIT_CATEGORY_PAYLOAD='{
  "category": "Premium Coffee"
}'
echo "Payload: $EDIT_CATEGORY_PAYLOAD"
echo "Token: $ADMIN_TOKEN"
echo "Note: This will fail with 404 - route registration bug in main.go"
# According to API spec, it should be /category/{categoryID}
curl -X PUT "$SERVER/category/1" \
  -H "Token: $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$EDIT_CATEGORY_PAYLOAD" | jq '.'
echo -e "\n"
sleep 1

# Test 7: Edit a product (Product ID 1)
echo -e "${YELLOW}Test 7: PUT /product/{productID} (Edit Product) - Using Admin Token${NC}"
EDIT_PRODUCT_PAYLOAD='{
  "category_id": 1,
  "name": "Double Espresso",
  "description": "Extra strong Italian coffee - double shot",
  "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
  "price": 32000.00
}'
echo "Payload: $EDIT_PRODUCT_PAYLOAD"
echo "Token: $ADMIN_TOKEN"
echo "Note: This will fail with 404 - route registration bug in main.go"
# According to API spec, it should be /product/{productID}
curl -X PUT "$SERVER/product/1" \
  -H "Token: $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$EDIT_PRODUCT_PAYLOAD" | jq '.'
echo -e "\n"
sleep 1

# Test 8: Get all products again to see changes
echo -e "${YELLOW}Test 8: GET /product (Get All Products After Changes)${NC}"
curl -X GET "$SERVER/product" -H "Token: $CLIENT_TOKEN" | jq '.'
echo -e "\n"
sleep 1

# Test 9: Test without token (should fail)
echo -e "${YELLOW}Test 9: GET /product (Without Token - Should Fail)${NC}"
curl -X GET "$SERVER/product"
echo -e "\n"
sleep 1

# Test 10: Test with invalid token (should fail)
echo -e "${YELLOW}Test 10: GET /product (Invalid Token - Should Fail)${NC}"
curl -X GET "$SERVER/product" -H "Token: invalid-token-xyz"
echo -e "\n"
sleep 1

# Test 11: Deactivate a product (Product ID 11)
echo -e "${YELLOW}Test 11: DELETE /product/{productID} (Deactivate Product) - Using Admin Token${NC}"
echo "Token: $ADMIN_TOKEN"
echo "Note: This will fail with 404 - route registration bug in main.go"
# According to API spec, it should be /product/{productID}
curl -X DELETE "$SERVER/product/11" \
  -H "Token: $ADMIN_TOKEN" | jq '.'
echo -e "\n"
sleep 1

# Test 12: Deactivate a category (Category ID 5)
echo -e "${YELLOW}Test 12: DELETE /category/{categoryID} (Deactivate Category) - Using Admin Token${NC}"
echo "Token: $ADMIN_TOKEN"
echo "Note: This will fail with 404 - route registration bug in main.go"
# According to API spec, it should be /category/{categoryID}
curl -X DELETE "$SERVER/category/5" \
  -H "Token: $ADMIN_TOKEN" | jq '.'
echo -e "\n"
sleep 1

# Test 13: Get all products to verify deactivation
echo -e "${YELLOW}Test 13: GET /product (Verify Deactivated Items)${NC}"
curl -X GET "$SERVER/product" -H "Token: $CLIENT_TOKEN" | jq '.'
echo -e "\n"

echo "========================================="
echo "All tests completed!"
echo "========================================="
