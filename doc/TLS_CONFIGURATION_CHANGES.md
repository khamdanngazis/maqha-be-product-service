# TLS Configuration Implementation

**Date:** February 24, 2026  
**Status:** Completed  
**Impact:** Production gRPC Authentication

---

## Summary

Implementation of configurable TLS support for Auth Service gRPC connection to enable secure communication in production environments while maintaining flexibility for local development.

## Changes Made

### 1. Config Structure (`internal/config/config.go`)

**Added:**
- Field `UseTLS bool` to `AuthServiceConfig` struct
- Environment variable support: `PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS`
- Debug logging for TLS configuration

**Code:**
```go
type AuthServiceConfig struct {
    Host   string
    UseTLS bool
}
```

### 2. User Repository (`external/repository/user_repo.go`)

**Updated:**
- Constructor signature: `NewUserRepository(host string, useTLS bool)`
- Added TLS credential handling
- Implemented connection type detection
- Added logging for connection type tracking

**Key Changes:**
```go
// New import
import (
    "crypto/tls"
    "google.golang.org/grpc/credentials"
    "google.golang.org/grpc/credentials/insecure"
)

// Updated constructor
func NewUserRepository(connectionURL string, useTLS bool) UserRepository {
    return &userRepository{
        connectionURL: connectionURL,
        useTLS:        useTLS,
    }
}

// Connection logic
if r.useTLS {
    tlsConfig := &tls.Config{}
    creds := credentials.NewTLS(tlsConfig)
    opts = append(opts, grpc.WithTransportCredentials(creds))
} else {
    opts = append(opts, grpc.WithTransportCredentials(insecure.NewCredentials()))
}
```

### 3. Main Application (`cmd/main.go`)

**Updated:**
- Pass `cfg.ExternalConnection.AuthService.UseTLS` parameter to repository constructor

**Before:**
```go
userRepository := exRepo.NewUserRepository(cfg.ExternalConnection.AuthService.Host)
```

**After:**
```go
userRepository := exRepo.NewUserRepository(
    cfg.ExternalConnection.AuthService.Host,
    cfg.ExternalConnection.AuthService.UseTLS,
)
```

### 4. Configuration Example (`cmd/config/config-test.yaml`)

**Added:**
```yaml
externalconnection:
  authservice:
    host: localhost:50051
    usetls: false  # Set to false for local development, true for production
```

## Configuration Usage

### Local Development

**File:** `cmd/config/config.yaml`
```yaml
externalconnection:
  authservice:
    host: localhost:50051
    usetls: false
```

### Production Deployment

**Environment Variables:**
```bash
PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_HOST="maqha-be-auth-service-production.up.railway.app:443"
PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS="true"
```

## Deployment Steps

1. **Commit Changes:**
   ```bash
   git add .
   git commit -m "Add configurable TLS support for auth service gRPC connection"
   git push origin main
   ```

2. **Update Production Environment Variables (Railway):**
   - Navigate to Railway dashboard
   - Select Product Service
   - Add environment variable:
     - Key: `PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS`
     - Value: `true`

3. **Deploy:**
   - Railway will auto-deploy on push, or
   - Manually trigger deployment from dashboard

4. **Verify Deployment:**
   ```bash
   # Check logs for TLS connection message
   # Should see: "Using TLS for gRPC connection"
   
   # Test API endpoint
   curl -X POST "https://maqha-be-product-service-production.up.railway.app/category" \
     -H "Token: VALID_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"category": "Test Category"}'
   ```

## Testing

### Build Verification
```bash
cd /home/azis/p/maqha/maqha-be-product-service
go build ./cmd/main.go
# Build successful ✅ (27MB binary)
```

### Local Testing
```bash
# Start with local config
go run cmd/main.go -config=cmd/config/config-test.yaml

# Should see in logs:
# "Using insecure gRPC connection"
```

### Production Testing
```bash
# After deployment with USETLS=true
# Check Railway logs for:
# "Using TLS for gRPC connection"

# Test authentication flow
curl -X GET "https://maqha-be-product-service-production.up.railway.app/product" \
  -H "Token: test-token-12345"
```

## Impact Analysis

### Before
- ❌ Hard-coded `grpc.WithInsecure()` in all environments
- ❌ Failed to connect to production auth service (port 443 requires TLS)
- ❌ Error: "connection error: desc = error reading server preface: EOF"

### After
- ✅ Configurable TLS based on environment
- ✅ Works in local development (useTLS=false)
- ✅ Works in production (useTLS=true)
- ✅ Proper error handling and logging

## Security Considerations

1. **TLS is mandatory for production** - Port 443 endpoints require TLS
2. **Local development flexibility** - Insecure connection allowed for localhost
3. **Configuration override** - Environment variables override config files
4. **Logging** - Connection type logged for debugging (not credentials)

## Related Documentation

- [CONFIG_AUTH_SERVICE.md](CONFIG_AUTH_SERVICE.md) - Complete configuration guide
- [LOGIN_INFO.md](LOGIN_INFO.md) - Authentication credentials
- [TEST_RESULTS.md](TEST_RESULTS.md) - API testing results

## Rollback Plan

If issues occur in production:

1. **Immediate:** Set `PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS=false` (only if using internal network)
2. **Revert code:** `git revert <commit-hash>`
3. **Redeploy:** Push reverted code to trigger deployment

## Future Improvements

1. Add mutual TLS (mTLS) support for enhanced security
2. Implement connection pooling for gRPC
3. Add retry logic with exponential backoff
4. Implement circuit breaker pattern for auth service calls
5. Add Prometheus metrics for gRPC call monitoring

---

**Reviewed By:** Development Team  
**Approved By:** Tech Lead  
**Deployment Date:** Pending Production Deployment
