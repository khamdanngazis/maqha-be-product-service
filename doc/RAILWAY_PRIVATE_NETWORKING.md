# Railway Private Networking Configuration
**Date:** February 24, 2026  
**Purpose:** Configure Product Service to communicate with Auth Service via Railway internal network

---

## Overview

Railway provides private networking between services deployed in the same project. This allows secure inter-service communication without going through the public internet.

**Benefits:**
- ✅ Faster communication (no public internet routing)
- ✅ More secure (internal network only)
- ✅ No TLS overhead needed
- ✅ Lower latency
- ✅ Supports gRPC natively

---

## Configuration Steps

### 1. Find Auth Service Name in Railway

1. Open Railway dashboard
2. Go to your project
3. Click on Auth Service
4. Note the **Service Name** (usually shown at the top)
   - Example: `maqha-be-auth-service-production`

### 2. Set Environment Variables in Product Service

In Railway dashboard → Product Service → Variables:

```bash
PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_HOST=<AUTH_SERVICE_NAME>.railway.internal:8010
PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS=false
```

**Example:**
```bash
PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_HOST=maqha-be-auth-service-production.railway.internal:8010
PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS=false
```

**Important Notes:**
- Port `8010` is the internal port Auth Service listens on
- Use `false` for UseTLS since internal network doesn't need TLS
- Format: `<service-name>.railway.internal:<port>`

### 3. Redeploy Product Service

After setting environment variables:
1. Go to Deployments tab
2. Click three dots (⋮) on latest deployment
3. Click "Redeploy"

---

## Verification

After deployment, check logs for:

```
DEBUG: *** UseTLS RAW from Viper: false (IsSet: true) ***
DEBUG: *** UseTLS in Config: false ***
Using insecure gRPC connection
```

Then test POST endpoint:

```bash
curl -X POST https://maqha-be-product-service-production.up.railway.app/category \
  -H "Content-Type: application/json" \
  -H "Token: <VALID_TOKEN>" \
  -d '{"category":"Test Category"}'
```

**Expected Success Response:**
```json
{
  "code": 0,
  "message": "Success",
  "data": {
    "id": 10,
    "clientId": 3,
    "name": "Test Category",
    "isActive": true,
    "createdAt": "2026-02-24T..."
  }
}
```

**If Error:**
- Check service name is correct (must match Railway dashboard)
- Verify port 8010 is correct
- Check Auth Service is running
- Verify both services in same Railway project

---

## Troubleshooting

### Error: "connection refused"
- Auth Service might not be running
- Check Auth Service logs
- Verify service name in Railway

### Error: "no such host"
- Service name incorrect
- Both services must be in same Railway project
- Check spelling of service name

### Error: "Invalid Token"
- gRPC connection working! ✅
- Token doesn't exist in Auth Service database
- Create user with token in Auth Service

---

## Alternative: Public URL with TCP Proxy

If private networking doesn't work, Railway supports TCP proxy for gRPC:

1. Expose TCP port in Railway
2. Use TCP proxy URL
3. Set UseTLS=true

Contact Railway support for TCP proxy configuration.

---

## References

- Railway Private Networking: https://docs.railway.app/reference/private-networking
- Auth Service Port: 8010 (from config-prod.yaml)
- Product Service: maqha-be-product-service-production
- Auth Service: maqha-be-auth-service-production
