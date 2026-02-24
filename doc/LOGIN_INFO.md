# Login Information for Product Service Testing

**Last Updated:** February 24, 2026  
**Environment:** Production (Railway)  
**Database:** Railway PostgreSQL

---

## Important Discovery 🔍

The Product Service uses **TWO types of tokens**:

1. **Client Token** - For READ operations (GET /product)
2. **User Token** - For WRITE operations (POST/PUT/DELETE)

## Available Test Accounts

### Test Coffee Shop (Client ID: 3)

**Client Information:**
- Company: Test Coffee Shop
- Email: test@coffeeshop.com
- **Client Token:** `test-token-12345` (for GET /product)

**User Accounts:**

#### Admin Account
- **Username:** `coffeeshop_admin`
- **Password:** `password123` (hashed in DB)
- **Full Name:** Coffee Shop Admin
- **Role:** 1 (Admin)
- **Token:** `coffeeshop-admin-token-123` ✅ **Use this for POST/PUT/DELETE**
- **Token Expired:** 2026-03-30
- **Status:** Active

#### Staff Account
- **Username:** `coffeeshop_staff`
- **Password:** `password123` (hashed in DB)
- **Full Name:** Coffee Shop Staff
- **Role:** 2 (Staff)
- **Token:** `coffeeshop-staff-token-456`
- **Token Expired:** 2026-03-30
- **Status:** Active

---

### Demo Restaurant (Client ID: 4)

**Client Information:**
- Company: Demo Restaurant
- Email: demo@restaurant.com
- **Client Token:** `demo-token-67890`

**User Accounts:**

#### Admin Account
- **Username:** `restaurant_admin`
- **Password:** `password123` (hashed in DB)
- **Full Name:** Restaurant Admin
- **Role:** 1 (Admin)
- **Token:** `restaurant-admin-token-789` ✅ **Use this for POST/PUT/DELETE**
- **Token Expired:** 2026-03-30
- **Status:** Active

---

### Test Company (Client ID: 2)

**Client Information:**
- Company: Test Company
- Email: test@company.com
- **Client Token:** `client_token_test_12345`

**Available Users:**
1. **admin** - Admin User (Role: 1, Token: `GzyDuNnWtAtsPgX4`)
2. **staff** - Staff User (Role: 2, Token: `uAKo7fReGtBjQmAS`)
3. **loginuser** - Login Test User (Role: 3, Token: `loginuser_token_12345`)
4. **inactiveadmin** - Inactive Admin User (Role: 1, Token: `dDiA3QWHb4xl52GF`)
5. **expiredadmin** - Expired Admin User (Role: 1, Token: `expiredadmin_token_12345`)
6. **newuser** - New User (Role: 3, Token: `newuser_token_12345`)

---

## Role Types

- **Role 1:** Admin (Full access to all operations)
- **Role 2:** Staff (Limited access)
- **Role 3:** Regular User (Basic access)

---

## Testing Recommendations

### For GET Operations (Read-only)
Use **Client Token**:
```bash
curl -X GET "https://maqha-be-product-service-production.up.railway.app/product" \
  -H "Token: test-token-12345"
```

### For POST/PUT/DELETE Operations (Write)
Use **User Token** (must be Admin role):
```bash
# Add Category
curl -X POST "https://maqha-be-product-service-production.up.railway.app/category" \
  -H "Token: coffeeshop-admin-token-123" \
  -H "Content-Type: application/json" \
  -d '{"category": "New Category"}'

# Add Product
curl -X POST "https://maqha-be-product-service-production.up.railway.app/product" \
  -H "Token: coffeeshop-admin-token-123" \
  -H "Content-Type: application/json" \
  -d '{
    "category_id": 1,
    "name": "Product Name",
    "description": "Product Description",
    "image": "base64_encoded_image",
    "price": 50000.00
  }'
```

---

## Password Information

All test accounts use the same hashed password:
- **Plain Password:** `password123`
- **Bcrypt Hash:** `$2b$12$vn6/FSLdnCzS8wqJWAjiWOmxhzf5U1LlLdOJdAVM3jGcjilK/8Is.`

---

## Database Connection Info

```
Host: maglev.proxy.rlwy.net
Port: 22459
User: postgres
Password: lkZoqenENptXOFAIPkOnNVniFEBWaUNc
Database: railway
```

---

## Quick Test Commands

### Test 1: Get Products (Client Token)
```bash
curl -X GET "https://maqha-be-product-service-production.up.railway.app/product" \
  -H "Token: test-token-12345" | jq '.'
```

### Test 2: Add Category (User Token - Admin)
```bash
curl -X POST "https://maqha-be-product-service-production.up.railway.app/category" \
  -H "Token: coffeeshop-admin-token-123" \
  -H "Content-Type: application/json" \
  -d '{"category": "Hot Drinks"}' | jq '.'
```

### Test 3: Add Product (User Token - Admin)
```bash
curl -X POST "https://maqha-be-product-service-production.up.railway.app/product" \
  -H "Token: coffeeshop-admin-token-123" \
  -H "Content-Type: application/json" \
  -d '{
    "category_id": 1,
    "name": "Mocha",
    "description": "Chocolate flavored coffee",
    "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
    "price": 40000.00
  }' | jq '.'
```
