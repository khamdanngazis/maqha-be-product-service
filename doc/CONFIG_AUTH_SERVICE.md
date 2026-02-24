# Auth Service Configuration Guide

**Last Updated:** February 24, 2026  
**Author:** Development Team  
**Version:** 1.0

---

## Overview

Product Service connects to Auth Service via gRPC for user authentication and authorization. This guide explains how to configure the connection for both local development and production deployment.

## Configuration Parameters

### 1. Auth Service Host
**Config Key:** `externalconnection.authservice.host`  
**Environment Variable:** `PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_HOST`

The host and port where Auth Service is accessible.

**Examples:**
- Local: `localhost:50051`
- Production (Railway): `maqha-be-auth-service-production.up.railway.app:443`

### 2. Use TLS
**Config Key:** `externalconnection.authservice.usetls`  
**Environment Variable:** `PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS`

Whether to use TLS/SSL for the gRPC connection.

**Values:**
- `false` - Use insecure connection (for local development)
- `true` - Use TLS connection (required for production HTTPS endpoints)

## Configuration Examples

### Local Development (config.yaml)

```yaml
externalconnection:
  authservice:
    host: localhost:50051
    usetls: false  # No TLS for local development
```

**Or using environment variables:**
```bash
export PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_HOST="localhost:50051"
export PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS="false"
```

### Production (Railway - Environment Variables)

Set these in Railway dashboard or deployment config:

```bash
PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_HOST="maqha-be-auth-service-production.up.railway.app:443"
PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS="true"
```

### Production (Railway - Internal Network)

If both services are in the same Railway project, you can use Railway's internal networking:

```bash
PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_HOST="maqha-be-auth-service.railway.internal:8080"
PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS="false"
```

*Note: Railway internal network doesn't require TLS.*

## How It Works

The Product Service uses the `useTLS` configuration to determine the gRPC connection type:

```go
// When useTLS = true (Production)
tlsConfig := &tls.Config{}
creds := credentials.NewTLS(tlsConfig)
conn, err := grpc.Dial(host, grpc.WithTransportCredentials(creds))

// When useTLS = false (Development)
conn, err := grpc.Dial(host, grpc.WithTransportCredentials(insecure.NewCredentials()))
```

## Testing the Configuration

### 1. Check if Auth Service is Reachable

**HTTP Test:**
```bash
curl https://maqha-be-auth-service-production.up.railway.app/ping
```

Expected: `Pong!`

### 2. Test gRPC Connection

Run the product service and check the logs:
```bash
go run cmd/main.go
```

Look for log messages:
- `Using TLS for gRPC connection` (when useTLS=true)
- `Using insecure gRPC connection` (when useTLS=false)

### 3. Test End-to-End

Try to create a category (requires valid user token):
```bash
curl -X POST "https://maqha-be-product-service-production.up.railway.app/category" \
  -H "Token: YOUR_VALID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"category": "Test Category"}'
```

If gRPC connection works, you should get either:
- Success response (if token is valid)
- `Invalid Token` (if token is invalid, but connection worked)

If you get connection errors, check the configuration.

## Troubleshooting

### Error: "connection error: desc = error reading server preface: EOF"

**Cause:** Trying to use insecure connection (useTLS=false) on a TLS-required endpoint (port 443).

**Solution:** Set `PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS="true"`

### Error: "code = Unimplemented desc = unexpected HTTP status code received"

**Cause:** Auth Service is not properly exposing gRPC endpoint, or wrong host/port.

**Solution:** 
1. Verify Auth Service is running and accessible
2. Check the host:port configuration
3. Try using Railway internal network if available

### Error: "Invalid Token" (but connection works)

**Cause:** The token exists in the Product Service database but not in Auth Service database.

**Solution:** Ensure users are synced between services, or create users in Auth Service via the `/user` endpoint.

## Best Practices

1. **Always use TLS in production** (useTLS=true for public HTTPS endpoints)
2. **Use environment variables** instead of hardcoding in config files for production secrets
3. **Use internal networking** when available (Railway, Kubernetes) to avoid external traffic costs
4. **Log connection type** on startup to verify configuration is correct
5. **Test authentication** after any configuration changes

## Migration Notes

### Upgrading from Old Code

If you're upgrading from code that used `grpc.WithInsecure()` without configuration:

**Old:**
```go
conn, err := grpc.Dial(host, grpc.WithInsecure())
```

**New:**
```go
// Now controlled by config
userRepository := exRepo.NewUserRepository(host, useTLS)
```

Make sure to:
1. Add `usetls` to your config file
2. Set `PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS` environment variable in production
3. Test both local and production deployments

## Related Files

- `/internal/config/config.go` - Config structure and loading
- `/external/repository/user_repo.go` - gRPC connection implementation
- `/cmd/main.go` - Repository initialization
- `/cmd/config/config-test.yaml` - Example config for local development

---

**Change Log:**

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-24 | 1.0 | Initial documentation with TLS configuration support |
