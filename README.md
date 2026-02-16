# Maqha Product Service

Microservice untuk manajemen produk dan kategori dalam sistem Maqha.

## Quick Start

### Prerequisites
- Go 1.22+
- PostgreSQL 16+
- Docker (opsional)

### Setup Database
```bash
docker run -d \
  --name postgresql \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=password123 \
  -e POSTGRES_DB=appdb \
  -p 5432:5432 \
  -v postgresql_data:/var/lib/postgresql/data \
  postgres:16

# Run migrations
docker exec -i postgresql psql -U admin -d appdb < migrations/0001_create_product_tables.up.sql
```

### Run Server
```bash
cd cmd
go run main.go -config config/config.yaml -log.file ../logs
```

Server berjalan di:
- HTTP: http://localhost:8012
- gRPC: localhost:8012 (same port via HTTP/2 multiplexing)

### Test API

**HTTP Endpoints:**
```bash
# Ping
curl http://localhost:8012/ping

# Get products (requires valid token from auth service)
curl -H "Token: JYA60sj03G6ii0LR3BfF" http://localhost:8012/product
```

**gRPC Endpoints (using grpcurl):**
```bash
# Install grpcurl (if needed)
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

# List services
grpcurl -plaintext -import-path internal/interface/grpc/proto -proto product.proto localhost:8012 list

# Get product
grpcurl -plaintext -import-path internal/interface/grpc/proto -proto product.proto \
  -d '{"product_id":1,"token":""}' \
  localhost:8012 model.Product/GetProduct
```

### Run Tests
```bash
go test ./...
```

## Documentation

Untuk dokumentasi lengkap, lihat [DOCUMENTATION.md](DOCUMENTATION.md)

## Features
- ✅ REST API untuk manajemen produk & kategori
- ✅ gRPC interface
- ✅ PostgreSQL database
- ✅ Authentication berbasis token
- ✅ Image upload support
- ✅ Comprehensive testing
- ✅ Structured logging

## Architecture
```
Handler → Service → Repository → Database
           ↓
        External Services
```

## Project Structure
```
├── cmd/                    # Entry point
├── internal/               # Core business logic
│   ├── app/               # Domain logic
│   ├── config/            # Configuration
│   ├── database/          # DB connection
│   └── interface/         # HTTP & gRPC handlers
├── external/              # External integrations
├── migrations/            # Database migrations
├── tests/                 # Test suites
└── DOCUMENTATION.md       # Full documentation
```

## Status
- ✅ All tests passing
- ✅ Database migrations applied
- ✅ API endpoints functional
- ✅ gRPC server running

---

For detailed documentation, configuration, API endpoints, and troubleshooting, see [DOCUMENTATION.md](DOCUMENTATION.md)

# Dual-Protocol Server (HTTP + gRPC) Setup

## Overview

The auth service now runs both HTTP and gRPC protocols on the **same port (8011)** using HTTP/2 connection multiplexing with `cmux`.

This allows:
- ✅ HTTP endpoints accessible via `https://maqha-be-auth-service-production.up.railway.app`
- ✅ gRPC service accessible on the same domain and port
- ✅ Seamless integration with Railway's single HTTP port exposure

## Architecture

### Before (Separate Ports)
```
HTTP:  port 8011  → maqha-be-auth-service-production.up.railway.app
gRPC:  port 50053 → NOT accessible from Railway domain (internal only)
```

### After (Dual-Protocol)
```
Port 8011 (HTTP/2)
├─ HTTP Requests  → Mux routes to HTTP handler (Gorilla mux)
└─ gRPC Requests  → Mux routes to gRPC handler
```

## How It Works

1. **Single TCP Listener** on port 8011
2. **Connection Multiplexer (cmux)** inspects incoming connections
3. **Protocol Detection** based on HTTP/2 headers:
   - HTTP/1.x or HTTP/2 without gRPC → HTTP handler
   - HTTP/2 with `content-type: application/grpc` → gRPC handler

## Testing

### HTTP Endpoints

```bash
# Test ping
curl https://maqha-be-auth-service-production.up.railway.app/ping

# Test login
curl -X POST https://maqha-be-auth-service-production.up.railway.app/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"rahasia"}'
```

### gRPC Endpoints (Local Testing)

```bash
# Test with grpcurl locally
grpcurl -plaintext localhost:8011 model.User.GetUser \
  -d '{"token": "admin_token_12345"}'
```

### gRPC Endpoints (Railway Testing)

For testing gRPC on Railway:

```bash
# Option 1: Using grpcurl with TLS
grpcurl maqha-be-auth-service-production.up.railway.app:443 list

# Option 2: Deploy a gRPC client container to Railway
# Option 3: Test from another service in the same Railway environment
```

## Available APIs

### HTTP Endpoints
- `GET /ping` - Health check
- `POST /login` - User login
- `GET /user` - Get all users
- `POST /user` - Add new user
- `PUT /user` - Update user
- `DELETE /user/{userID}` - Deactivate user
- `DELETE /logout` - Logout user

### gRPC Endpoints
- `model.User/GetUser` - Validate token and get user info

## Configuration

### Port Configuration (AppPort)
- Default: `:8011`
- Environment variable: `AUTH_APPPORT` or `PORT` (Railway override)
- The GrpcPort configuration is now **ignored** since gRPC runs on the same port

### Old Configuration (Still in config.yaml but not used)
```yaml
grpcport: :50053  # Deprecated - gRPC now uses AppPort
```

## Deployment Changes

### Dockerfile
- Removed separate `EXPOSE 50053` (only `EXPOSE 8011` needed)
- Single port exposure simplifies Railway deployment

### Code Changes
- Added `cmux` dependency (connection multiplexer)
- Modified `cmd/main.go` to use dual-protocol server
- Added `GetRouter()` method to HTTP router interface

## Benefits

✅ **Simplified Railway Deployment** - Only one port needs to be exposed  
✅ **Unified Domain** - Both HTTP and gRPC accessible via same domain  
✅ **Cost Effective** - Single listener, no port forwarding needed  
✅ **Better Resource Usage** - Shared connection pool  
✅ **Production Ready** - HTTP/2 multiplexing is standard practice  

## Example Client Integration

### Go gRPC Client
```go
import (
    "context"
    pb "maqhaa/auth_service/internal/interface/grpc/model"
    "google.golang.org/grpc"
)

// For Railway (through internal network or another Railway service)
conn, _ := grpc.Dial("maqha-be-auth-service-production.up.railway.app:443", 
    grpc.WithTransportCredentials(credentials.NewClientTLSFromCert(nil, "")))

// For local testing
conn, _ := grpc.Dial("localhost:8011", grpc.WithInsecure())

client := pb.NewUserClient(conn)
resp, _ := client.GetUser(context.Background(), &pb.GetUserRequest{
    Token: "admin_token_12345",
})
```

### JavaScript gRPC Client (gRPC-Web)
For browser clients, use gRPC-Web with Envoy proxy or similar setup.

## Troubleshooting

### gRPC Connection Refused on Railway
- Railway exposes HTTPS on port 443
- gRPC needs proper TLS configuration
- Use internal Railway networking for gRPC calls

### gRPC Works Locally but Not on Railway
- Verify cmux is installed: `go get github.com/soheilhy/cmux`
- Check logs in Railway console
- Ensure rebuild triggers on next push

### Mixed Protocol Errors
- Make sure client sends correct HTTP/2 headers
- For gRPC: use proper gRPC client library (not plain HTTP)
- For HTTP: use standard curl or HTTP clients

## Rollback (if needed)

If issues occur, revert to separate ports:
```bash
git revert 6f0656d  # Revert the dual-protocol commit
git push origin main
```

## Future Enhancements

- [ ] Add gRPC-Web support for browser clients
- [ ] Implement gRPC-JSON transcoding
- [ ] Add health check endpoint for gRPC
- [ ] Metrics collection for both protocols
