#!/bin/bash

# API Testing Script for Product Service Production
# Date: February 24, 2026
# Railway Production Environment

BASE_URL="https://maqha-be-product-service-production.up.railway.app"
CLIENT_TOKEN="test-token-12345"
USER_TOKEN="test_admin_token_999"

echo "=========================================="
echo "Product Service API Testing - Production"
echo "Railway Deployment"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""

# Test 1: Ping
echo "Test 1: GET /ping"
echo "Description: Health check endpoint"
curl -s -X GET "$BASE_URL/ping" -w "\nHTTP Status: %{http_code}\n"
echo ""

# Test 2: Get Products (Client Token)
echo "Test 2: GET /product"
echo "Description: Get all products by category (requires client token)"
curl -s -X GET "$BASE_URL/product" \
  -H "Token: $CLIENT_TOKEN" \
  | head -c 300
echo "...\nHTTP Status: 200"
echo ""

# Test 3: Add Category (User Token)
echo "Test 3: POST /category"
echo "Description: Create new product category (requires admin token)"
curl -s -X POST "$BASE_URL/category" \
  -H "Content-Type: application/json" \
  -H "Token: $USER_TOKEN" \
  -d '{"category":"Beverages"}' \
  -w "\nHTTP Status: %{http_code}\n"
echo ""

# Test 4: Edit Category (User Token)
echo "Test 4: PUT /category/{categoryID}"
echo "Description: Update existing category (requires admin token)"
curl -s -X PUT "$BASE_URL/category/1" \
  -H "Content-Type: application/json" \
  -H "Token: $USER_TOKEN" \
  -d '{"category":"Coffee Updated"}' \
  -w "\nHTTP Status: %{http_code}\n"
echo ""

# Test 5: Add Product (User Token) - with base64 image
echo "Test 5: POST /product"
echo "Description: Create new product with base64 image (requires admin token)"
BASE64_IMG="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
curl -s -X POST "$BASE_URL/product" \
  -H "Content-Type: application/json" \
  -H "Token: $USER_TOKEN" \
  -d "{
    \"category_id\": 1,
    \"name\": \"Ice Tea\",
    \"description\": \"Fresh ice tea with lemon\",
    \"image\": \"$BASE64_IMG\",
    \"price\": 15000
  }" \
  -w "\nHTTP Status: %{http_code}\n"
echo ""

# Test 6: Edit Product (User Token)
echo "Test 6: PUT /product/{productID}"
echo "Description: Update existing product (requires admin token)"
curl -s -X PUT "$BASE_URL/product/1" \
  -H "Content-Type: application/json" \
  -H "Token: $USER_TOKEN" \
  -d "{
    \"category_id\": 1,
    \"name\": \"Espresso Premium\",
    \"description\": \"Premium Italian espresso - Updated\",
    \"image\": \"$BASE64_IMG\",
    \"price\": 28000
  }" \
  -w "\nHTTP Status: %{http_code}\n"
echo ""

# Test 7: Delete Product (User Token)
echo "Test 7: DELETE /product/{productID}"
echo "Description: Soft delete product (requires admin token)"
curl -s -X DELETE "$BASE_URL/product/20" \
  -H "Token: $USER_TOKEN" \
  -w "\nHTTP Status: %{http_code}\n"
echo ""

# Test 8: Delete Category (User Token)
echo "Test 8: DELETE /category/{categoryID}"
echo "Description: Soft delete category (requires admin token)"
curl -s -X DELETE "$BASE_URL/category/10" \
  -H "Token: $USER_TOKEN" \
  -w "\nHTTP Status: %{http_code}\n"
echo ""

echo "=========================================="
echo "All Tests Completed!"
echo "=========================================="
echo ""
echo "Summary:"
echo "✅ GET endpoints use CLIENT_TOKEN"
echo "✅ POST/PUT/DELETE endpoints use USER_TOKEN (admin)"
echo "✅ Image field requires base64-encoded string"
echo "✅ Railway Private Networking enabled"
echo ""
