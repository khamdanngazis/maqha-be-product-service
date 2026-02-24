# Product Service - Final Testing Documentation
**Date:** February 24, 2026  
**Status:** ✅ ALL ENDPOINTS WORKING  
**Environment:** Railway Production  
**Architecture:** Railway Private Networking

---

## 🎉 Success Summary

✅ Product Service deployed on Railway  
✅ Auth Service deployed on Railway  
✅ Railway Private Networking configured  
✅ gRPC authentication working  
✅ All HTTP endpoints tested and working  
✅ Database connectivity confirmed

---

## Working Credentials

### Client Token (for GET /product)

```
Token: test-token-12345
Client: Test Coffee Shop (ID: 3)
Database: Product Service (client table)
```

### Admin Token (for POST/PUT/DELETE)

```
Token: test_admin_token_999
Username: testadmin
Password: password123
Full Name: Test Admin
Client ID: 3
Role: 1 (Admin)
Token Expiry: 2027-12-31
Database: Auth Service (user table)
```

---

## Railway Configuration

### Product Service Environment Variables

```bash
PRODUCT_APPPORT=":8012"
PRODUCT_DATABASE_DBNAME="railway"
PRODUCT_DATABASE_DEBUG="true"
PRODUCT_DATABASE_HOST="maglev.proxy.rlwy.net"
PRODUCT_DATABASE_PASSWORD="lkZoqenENptXOFAIPkOnNVniFEBWaUNc"
PRODUCT_DATABASE_PORT="22459"
PRODUCT_DATABASE_USER="postgres"
PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_HOST="maqha-be-auth-service.railway.internal:8011"
PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS="false"
PRODUCT_GRPCPORT=":50054"
PRODUCT_IMAGEPATH="/app/images"
PRODUCT_LOG_TO_STDOUT="true"
```

### Key Configuration Points

1. **Auth Service Host:** `maqha-be-auth-service.railway.internal:8011`
   - Service name: `maqha-be-auth-service` (no `-production` suffix)
   - Port: `8011` (internal port where Auth Service listens)
   - Domain: `.railway.internal` (Railway private network)

2. **TLS Setting:** `false`
   - Railway private network doesn't require TLS
   - Reduces overhead and complexity
   - More secure than public internet

3. **Private Networking:**
   - Must be enabled in Railway project settings
   - Allows direct service-to-service communication
   - Bypasses public internet routing

---

## API Endpoints

### Base URL
```
https://maqha-be-product-service-production.up.railway.app
```

### Endpoint Summary

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/ping` | None | Health check |
| GET | `/product` | Client Token | Get all products by category |
| POST | `/category` | User Token | Create category |
| PUT | `/category/{categoryID}` | User Token | Update category |
| DELETE | `/category/{categoryID}` | User Token | Delete category |
| POST | `/product` | User Token | Create product |
| PUT | `/product/{productID}` | User Token | Update product |
| DELETE | `/product/{productID}` | User Token | Delete product |

---

## Testing Examples

### 1. Health Check

```bash
curl https://maqha-be-product-service-production.up.railway.app/ping
```

**Expected Response:**
```
Pong!
```

### 2. Get Products (Client Token)

```bash
curl -X GET https://maqha-be-product-service-production.up.railway.app/product \
  -H "Token: test-token-12345"
```

**Expected Response:**
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
      "products": [...]
    }
  ]
}
```

### 3. Create Category (Admin Token)

```bash
curl -X POST https://maqha-be-product-service-production.up.railway.app/category \
  -H "Content-Type: application/json" \
  -H "Token: test_admin_token_999" \
  -d '{"category":"Beverages"}'
```

**Expected Response:**
```json
{
  "code": 0,
  "message": "Success"
}
```

### 4. Update Product (Admin Token + Base64 Image)

```bash
# Convert image to base64
IMG_BASE64=$(base64 -w 0 image.jpg)

curl -X PUT https://maqha-be-product-service-production.up.railway.app/product/1 \
  -H "Content-Type: application/json" \
  -H "Token: test_admin_token_999" \
  -d "{
    \"category_id\": 1,
    \"name\": \"Espresso Premium\",
    \"description\": \"Premium Italian espresso\",
    \"image\": \"$IMG_BASE64\",
    \"price\": 28000
  }"
```

**Expected Response:**
```json
{
  "code": 0,
  "message": "Success"
}
```

---

## Important Notes

### ⚠️ Image Upload

The `image` field **MUST be base64-encoded**, not a URL:

❌ **Wrong:**
```json
{
  "image": "https://example.com/image.jpg"
}
```

✅ **Correct:**
```json
{
  "image": "iVBORw0KGgoAAAANS..." // base64 string
}
```

**How to encode:**
```bash
# Linux/Mac
base64 -w 0 image.jpg

# Use in curl
curl -X POST .../product \
  -d "{\"image\": \"$(base64 -w 0 image.jpg)\", ...}"
```

### 🔐 Authentication

- **GET /product** → Uses `test-token-12345` (client token)
- **POST/PUT/DELETE** → Uses `test_admin_token_999` (user/admin token)
- Token validation happens via gRPC to Auth Service
- Auth Service checks user role (must be admin for write operations)

### 🌐 Railway Private Networking

- Services communicate via `.railway.internal` domain
- No TLS required (internal network is secure)
- Faster and more reliable than public URLs
- Must be enabled in Railway project settings

---

## Troubleshooting

### "Invalid Token" Error

**Possible causes:**
1. Token doesn't exist in Auth Service database
2. Token expired
3. User not admin (for POST/PUT/DELETE)
4. Wrong token type (client vs user token)

**Solution:**
- Use `test_admin_token_999` for write operations
- Check token expiration (current: 2027-12-31)
- Verify user role in database

### "404 Not Found" on PUT/DELETE

**Cause:** Route registration missing path parameters

**Solution:** Routes must include `{id}`:
```go
// ❌ Wrong
PUT /product
DELETE /category

// ✅ Correct  
PUT /product/{productID}
DELETE /category/{categoryID}
```

### "Connection Refused" to Auth Service

**Possible causes:**
1. Wrong service name in Railway
2. Wrong port number
3. Auth Service not running
4. Private networking not enabled

**Solution:**
- Verify service name: `maqha-be-auth-service`
- Verify port: `8011`
- Enable private networking in Railway
- Check Auth Service logs

### Base64 Decode Error

**Cause:** Sending URL instead of base64 string

**Error:**
```
illegal base64 data at input byte 5
```

**Solution:** Convert image to base64 first:
```bash
base64 -w 0 image.jpg
```

---

## Running Tests

### Automated Test Script

```bash
cd /home/azis/p/maqha/maqha-be-product-service
chmod +x tests/test_api_production.sh
./tests/test_api_production.sh
```

### Manual Tests

See examples in [Testing Examples](#testing-examples) section above.

---

## Architecture Diagram

```
┌─────────────────────┐
│   Client/Browser    │
└──────────┬──────────┘
           │ HTTPS
           ▼
┌─────────────────────┐
│   Railway Edge      │
│   (Load Balancer)   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────────┐
│  Product Service                │
│  maqha-be-product-service       │
│  Port: 8012 (HTTP + gRPC)       │
└──────────┬──────────────────────┘
           │ gRPC (private network)
           │ maqha-be-auth-service.railway.internal:8011
           ▼
┌─────────────────────────────────┐
│  Auth Service                   │
│  maqha-be-auth-service          │
│  Port: 8011 (HTTP + gRPC)       │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│  PostgreSQL Database            │
│  Railway PostgreSQL             │
│  Port: 22459                    │
└─────────────────────────────────┘
```

---

## Files Reference

- **Test Script:** `/tests/test_api_production.sh`
- **Configuration:** `/cmd/config/config-test.yaml`
- **Seed Data:** `/migrations/seed_data.sql`
- **Documentation:** `/doc/` folder
- **Main Entry:** `/cmd/main.go`

---

## Success Metrics

✅ GET /ping → 200 OK  
✅ GET /product → 200 OK (2422 bytes of data)  
✅ POST /category → 200 OK  
✅ PUT /category/{id} → 200 OK  
✅ POST /product → 200 OK (with base64 image)  
✅ PUT /product/{id} → 200 OK  
✅ DELETE /product/{id} → 200 OK  
✅ DELETE /category/{id} → 200 OK  
✅ gRPC Auth validation → Working  
✅ Railway Private Network → Connected  

---

**Status:** All endpoints tested and confirmed working on February 24, 2026 ✅
