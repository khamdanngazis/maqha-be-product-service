# API Testing Results - Product Service

**Test Date:** February 24, 2026  
**Server:** https://maqha-be-product-service-production.up.railway.app  
**Token Used:** test-token-12345 (Client Token)  
**Status:** Partial Success - Authentication Issues Found  

---

## Test Summary

### ✅ Working Endpoints

#### 1. GET /ping
**Status:** ✅ **SUCCESS**
```bash
curl -X GET "https://maqha-be-product-service-production.up.railway.app/ping"
```
**Response:**
```
Pong!
```

#### 2. GET /product (Get All Products)
**Status:** ✅ **SUCCESS**
```bash
curl -X GET "https://maqha-be-product-service-production.up.railway.app/product" \
  -H "Token: test-token-12345"
```
**Response:**
```json
{
  "code": 0,
  "message": "Success",
  "data": [
    {
      "id": 1,
      "clientId": 3,
      "name": "Coffee",
      "isActive": true,
      "createdAt": "2026-02-24T06:30:02.80459Z",
      "products": [
        {
          "id": 1,
          "categoryId": 1,
          "name": "Espresso",
          "description": "Strong Italian coffee",
          "image": "https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04",
          "price": 25000,
          "isActive": true,
          "createdAt": "2026-02-24T06:30:02.80459Z"
        },
        ... (more products)
      ]
    },
    ... (more categories)
  ]
}
```

**Retrieved data:**
- 3 categories: Coffee, Snacks, Desserts
- 9 products total
- All products are active
- All tied to client_id 3 (Test Coffee Shop)

#### 3. Authentication Validation
**Status:** ✅ **SUCCESS**

**Test without token:**
```bash
curl -X GET "https://maqha-be-product-service-production.up.railway.app/product"
```
**Response:**
```json
{"code":202,"message":"Invalid Token"}
```

**Test with invalid token:**
```bash
curl -X GET "https://maqha-be-product-service-production.up.railway.app/product" \
  -H "Token: invalid-token-xyz"
```
**Response:**
```json
{"code":202,"message":"Invalid Token","data":null}
```

---

### ❌ Issues Found

#### 4. POST /category (Add Category)
**Status:** ❌ **FAILED - Invalid Token**
```bash
curl -X POST "https://maqha-be-product-service-production.up.railway.app/category" \
  -H "Token: test-token-12345" \
  -H "Content-Type: application/json" \
  -d '{"category": "Beverages"}'
```
**Response:**
```json
{
  "code": 202,
  "message": "Invalid Token"
}
```
**Root Cause:** The endpoint validates the token against an external auth service via gRPC. The token "test-token-12345" exists in the product database but not in the external auth service.

#### 5. POST /product (Add Product)
**Status:** ❌ **FAILED - Invalid Token**
```bash
curl -X POST "https://maqha-be-product-service-production.up.railway.app/product" \
  -H "Token: test-token-12345" \
  -H "Content-Type: application/json" \
  -d '{
    "category_id": 1,
    "name": "Iced Coffee",
    "description": "Cold brewed coffee served with ice",
    "image": "base64_image_string",
    "price": 30000.00
  }'
```
**Response:**
```json
{
  "code": 202,
  "message": "Invalid Token"
}
```
**Root Cause:** Same as above - token not registered in external auth service.

#### 6. PUT /product/{productID} (Edit Product)
**Status:** ❌ **FAILED - 404 Not Found**
```bash
curl -X PUT "https://maqha-be-product-service-production.up.railway.app/product/1" \
  -H "Token: test-token-12345" \
  -H "Content-Type: application/json" \
  -d '{
    "category_id": 1,
    "name": "Double Espresso",
    "description": "Extra strong Italian coffee",
    "image": "base64_image_string",
    "price": 32000.00
  }'
```
**Response:**
```
404
```
**Root Cause:** The route is registered as `PUT /product` without path parameter `{productID}` in main.go, but the handler expects the path parameter via `mux.Vars(r)`.

**Code Issue in main.go:**
```go
httpRouter.PUT("/product", productHandler.EditProductHandler)  // ❌ Wrong
// Should be:
httpRouter.PUT("/product/{productID}", productHandler.EditProductHandler)  // ✅ Correct
```

#### 7. PUT /category/{categoryID} (Edit Category)
**Status:** ❌ **FAILED - 404 Not Found**
```bash
curl -X PUT "https://maqha-be-product-service-production.up.railway.app/category/1" \
  -H "Token: test-token-12345" \
  -H "Content-Type: application/json" \
  -d '{"category": "Premium Coffee"}'
```
**Response:**
```
404
```
**Root Cause:** Same route registration issue as above.

**Code Issue in main.go:**
```go
httpRouter.PUT("/category", productHandler.EditCategoryHandler)  // ❌ Wrong
// Should be:
httpRouter.PUT("/category/{categoryID}", productHandler.EditCategoryHandler)  // ✅ Correct
```

#### 8. DELETE /product/{productID} (Deactivate Product)
**Status:** ❌ **FAILED - 404 Not Found**
```bash
curl -X DELETE "https://maqha-be-product-service-production.up.railway.app/product/11" \
  -H "Token: test-token-12345"
```
**Response:**
```
404
```
**Root Cause:** Same route registration issue.

**Code Issue in main.go:**
```go
httpRouter.DELETE("/product", productHandler.DeactiveProductHandler)  // ❌ Wrong
// Should be:
httpRouter.DELETE("/product/{productID}", productHandler.DeactiveProductHandler)  // ✅ Correct
```

#### 9. DELETE /category/{categoryID} (Deactivate Category)
**Status:** ❌ **FAILED - 404 Not Found**
```bash
curl -X DELETE "https://maqha-be-product-service-production.up.railway.app/category/5" \
  -H "Token: test-token-12345"
```
**Response:**
```
404
```
**Root Cause:** Same route registration issue.

**Code Issue in main.go:**
```go
httpRouter.DELETE("/category", productHandler.DeactiveCategoryHandler)  // ❌ Wrong
// Should be:
httpRouter.DELETE("/category/{categoryID}", productHandler.DeactiveCategoryHandler)  // ✅ Correct
```

---

## Database Seed Data

Successfully inserted test data into production database:

### Clients
- **Test Coffee Shop** (ID: 3)
  - Email: test@coffeeshop.com
  - Token: test-token-12345
  - Active: Yes

- **Demo Restaurant** (ID: 4)
  - Email: demo@restaurant.com
  - Token: demo-token-67890
  - Active: Yes

### Product Categories
1. Coffee (Client: Test Coffee Shop)
2. Snacks (Client: Test Coffee Shop)
3. Desserts (Client: Test Coffee Shop)
4. Main Course (Client: Demo Restaurant) 
5. Beverages (Client: Demo Restaurant)

### Products (11 total)
- **Coffee Category:** Espresso, Cappuccino, Latte, Americano
- **Snacks Category:** Croissant, Chocolate Chip Cookie, Sandwich
- **Desserts Category:** Tiramisu, Cheesecake
- **Main Course Category:** Nasi Goreng, Mie Goreng

---

## Recommendations

### Critical Fixes Required

1. **Fix Route Registrations in main.go** (Lines 75-78)
   
   Current code:
   ```go
   httpRouter.PUT("/product", productHandler.EditProductHandler)
   httpRouter.DELETE("/product", productHandler.DeactiveProductHandler)
   httpRouter.PUT("/category", productHandler.EditCategoryHandler)
   httpRouter.DELETE("/category", productHandler.DeactiveCategoryHandler)
   ```
   
   Should be:
   ```go
   httpRouter.PUT("/product/{productID}", productHandler.EditProductHandler)
   httpRouter.DELETE("/product/{productID}", productHandler.DeactiveProductHandler)
   httpRouter.PUT("/category/{categoryID}", productHandler.EditCategoryHandler)
   httpRouter.DELETE("/category/{categoryID}", productHandler.DeactiveCategoryHandler)
   ```

2. **External Auth Service Token Registration**
   
   To make POST/PUT/DELETE operations work, tokens need to be registered in the external auth service. Current approach:
   - GET /product: Only validates token exists in product database
   - POST/PUT/DELETE: Validates token via gRPC call to external auth service
   
   Options:
   - Register tokens in external auth service
   - Create a bypass mechanism for testing
   - Use consistent token validation across all endpoints

### Test Again After Fixes

Once the route registration is fixed and tokens are properly registered in the auth service, re-run the test script:

```bash
chmod +x /home/azis/p/maqha/maqha-be-product-service/test_api.sh
/home/azis/p/maqha/maqha-be-product-service/test_api.sh
```

---

## API Documentation Comparison

The API spec (api-spec.json) correctly documents the endpoints with path parameters:
- PUT /product/{productID} ✅ 
- DELETE /product/{productID} ✅
- PUT /category/{categoryID} ✅ (note: spec has typo "caregory")
- DELETE /category/{categoryID} ✅

However, the implementation in main.go doesn't match the spec (missing path parameters).

---

## Conclusion

**Working:** 2/9 endpoints (22%)
**Failing:** 7/9 endpoints (78%)

**Primary Issues:**
1. Route registration bug (4 endpoints)
2. External auth service token validation (3 endpoints)

The database and core business logic appear to be working correctly. Issues are related to routing configuration and external service integration.
