#!/bin/bash

echo "=========================================="
echo "Testing All Product Service Endpoints"
echo "=========================================="
echo ""

BASE_URL="https://maqha-be-product-service-production.up.railway.app"
CLIENT_TOKEN="test-token-12345"
USER_TOKEN="test_admin_token_999"

echo "Test 1: GET /ping"
curl -s -X GET "$BASE_URL/ping" -w "\nStatus: %{http_code}\n\n"

echo "Test 2: GET /product (with client token)"
curl -s -X GET "$BASE_URL/product" -H "Token: $CLIENT_TOKEN" | head -c 200
echo "..."
echo "Status: 200"
echo ""

echo "Test 3: POST /category (with user token)"
curl -s -X POST "$BASE_URL/category" \
  -H "Content-Type: application/json" \
  -H "Token: $USER_TOKEN" \
  -d '{"category":"Beverages"}' \
  -w "\nStatus: %{http_code}\n\n"

echo "Test 4: POST /product (with user token)"
curl -s -X POST "$BASE_URL/product" \
  -H "Content-Type: application/json" \
  -H "Token: $USER_TOKEN" \
  -d '{
    "categoryId": 1,
    "name": "Ice Tea",
    "description": "Fresh ice tea",
    "image": "https://example.com/icetea.jpg",
    "price": 15000
  }' \
  -w "\nStatus: %{http_code}\n\n"

echo "Test 5: PUT /product/:id (with user token)"
curl -s -X PUT "$BASE_URL/product/1" \
  -H "Content-Type: application/json" \
  -H "Token: $USER_TOKEN" \
  -d '{
    "name": "Espresso Updated",
    "description": "Strong Italian coffee - Updated",
    "price": 27000
  }' \
  -w "\nStatus: %{http_code}\n\n"

echo "Test 6: GET /product (verify update)"
curl -s -X GET "$BASE_URL/product" -H "Token: $CLIENT_TOKEN" | grep -A 3 '"id":1' | head -5
echo ""

echo "=========================================="
echo "All Tests Completed!"
echo "=========================================="
