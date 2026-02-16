# Maqha Product Service - Dokumentasi

## Daftar Isi
1. [Overview](#overview)
2. [Arsitektur](#arsitektur)
3. [Setup & Installation](#setup--installation)
4. [Database](#database)
5. [API Endpoints](#api-endpoints)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

---

## Overview

**Maqha Product Service** adalah microservice yang mengelola data produk, kategori produk, dan klien dalam sistem Maqha. Service ini menyediakan REST API dan gRPC interface untuk operasi CRUD pada produk dan kategorinya.

### Fitur Utama
- Manajemen kategori produk (Create, Read, Update, Delete)
- Manajemen produk (Create, Read, Update, Delete)
- Manajemen klien
- Upload dan manajemen gambar produk
- Autentikasi berbasis token
- Logging terstruktur
- Unit tests dan integration tests
- gRPC support untuk komunikasi inter-service

### Tech Stack
- **Language**: Go 1.22
- **Database**: PostgreSQL 16
- **API Framework**: Gorilla Mux (HTTP), gRPC
- **ORM**: GORM
- **Logging**: Logrus
- **Testing**: testify, standard Go testing

---

## Arsitektur

### Struktur Direktori
```
maqha-product-service/
├── cmd/
│   ├── main.go                 # Entry point aplikasi
│   └── config/                 # Configuration files
│       ├── config.yaml         # Development config
│       ├── config-test.yaml    # Testing config
│       └── config-prod.yaml    # Production config
├── internal/
│   ├── app/
│   │   ├── entity/             # Domain models
│   │   │   ├── client.go
│   │   │   ├── product.go
│   │   │   └── product_category.go
│   │   ├── model/              # Request/response models
│   │   │   ├── product_model.go
│   │   │   └── response.go
│   │   ├── repository/         # Data access layer
│   │   │   ├── product_repo.go
│   │   │   ├── images_repo.go
│   │   │   └── mock/
│   │   ├── service/            # Business logic
│   │   │   ├── product_service.go
│   │   │   └── errors_utils.go
│   ├── config/                 # Configuration management
│   ├── database/               # Database connection
│   └── interface/              # External interfaces
│       ├── http/               # HTTP handlers & routing
│       │   ├── handler/
│       │   └── router/
│       └── grpc/               # gRPC handlers
├── external/                   # External service integration
│   └── repository/             # User service integration
├── migrations/                 # Database migrations
├── tests/                      # Test files
│   ├── integration/            # Integration tests
│   └── unit/                   # Unit tests
├── go.mod & go.sum             # Dependencies
└── README.md

```

### Alur Data
```
HTTP/gRPC Request
    ↓
Handler (HTTP/gRPC)
    ↓
Service Layer (Business Logic)
    ↓
Repository Layer (Data Access)
    ↓
Database (PostgreSQL)
```

---

## Setup & Installation

### Prerequisites
- Go 1.22+
- PostgreSQL 16+
- Docker (opsional, untuk database)
- Git

### Clone Repository
```bash
git clone https://github.com/khamdanngazis/maqha-product-service.git
cd maqha-product-service
```

### Install Dependencies
```bash
go mod download
go mod tidy
```

### Setup Database

#### Menggunakan Docker
```bash
docker run -d \
  --name postgresql \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=password123 \
  -e POSTGRES_DB=appdb \
  -p 5432:5432 \
  -v postgresql_data:/var/lib/postgresql/data \
  postgres:16
```

#### Create Database & Run Migrations
```bash
# Create test database
docker exec postgresql createdb -U admin appdb_test

# Run migrations untuk development database
docker exec -i postgresql psql -U admin -d appdb < migrations/0001_create_product_tables.up.sql

# Run migrations untuk test database
docker exec -i postgresql psql -U admin -d appdb_test < migrations/0001_create_product_tables.up.sql
```

### Configuration
Edit `cmd/config/config.yaml`:
```yaml
database:
  host: localhost
  port: 5432
  user: admin
  password: password123
  dbname: appdb
  debug: true
externalconnection:
  authservice:
    host: localhost:50051
appport: :8012
grpcport: :50052  # Deprecated - gRPC now uses AppPort
imagepath: "../../public/images"
```

### Run Server
```bash
cd cmd
go run main.go -config config/config.yaml -log.file ../logs
```

Server akan listening di:
- HTTP: `http://localhost:8012`
- gRPC: `localhost:8012` (same port via HTTP/2 multiplexing with cmux)

---

## Database

### Schema

#### Client Table
```sql
CREATE TABLE client (
    id BIGSERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    owner_name VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    token VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

#### Product Category Table
```sql
CREATE TABLE product_category (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_product_category_client
        FOREIGN KEY (client_id)
        REFERENCES client (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);
```

#### Product Table
```sql
CREATE TABLE product (
    id BIGSERIAL PRIMARY KEY,
    category_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    image VARCHAR(512) NOT NULL,
    price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id)
        REFERENCES product_category (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);
```

### Insert Sample Data
```sql
-- Insert client
INSERT INTO client (company_name, email, phone_number, address, owner_name, is_active, token, created_at)
VALUES ('Test Coffee', 'info@testcoffee.com', '+1234567890', '123 Main St', 'John Doe', true, 'JYA60sj03G6ii0LR3BfF', NOW());

-- Insert product categories
INSERT INTO product_category (client_id, name, is_active, created_at)
VALUES (1, 'Coffee', true, NOW());

INSERT INTO product_category (client_id, name, is_active, created_at)
VALUES (1, 'Tea', true, NOW());

-- Insert products
INSERT INTO product (category_id, name, description, image, price, is_active, created_at)
VALUES (1, 'Espresso', 'Strong coffee', '', 2.50, true, NOW());

INSERT INTO product (category_id, name, description, image, price, is_active, created_at)
VALUES (1, 'Latte', 'Coffee with milk', '', 3.00, true, NOW());

INSERT INTO product (category_id, name, description, image, price, is_active, created_at)
VALUES (2, 'Green Tea', 'Healthy tea', '', 2.00, true, NOW());
```

---

## API Endpoints

### Authentication
Semua endpoint (kecuali `/ping`) memerlukan header:
```
Token: <client_token>
```

### 1. Ping
```
GET /ping
Response: Pong!
```

### 2. Product Endpoints

#### Get Products by Category
```
GET /product
Headers: Token: <token>

Response (200):
{
  "code": 0,
  "message": "Success",
  "data": [
    {
      "id": 1,
      "clientId": 1,
      "name": "Coffee",
      "isActive": true,
      "createdAt": "2026-02-15T15:00:00+07:00",
      "products": [
        {
          "id": 1,
          "categoryId": 1,
          "name": "Espresso",
          "description": "Strong coffee",
          "image": "",
          "price": 2.5,
          "isActive": true,
          "createdAt": "2026-02-15T15:00:00+07:00"
        }
      ]
    }
  ]
}

Response (202):
{
  "code": 202,
  "message": "Invalid Token",
  "data": null
}
```

**cURL Example:**
```bash
curl -X GET http://localhost:8011/product \
  -H "Token: JYA60sj03G6ii0LR3BfF"
```

#### Add Product
```
POST /product
Headers: 
  - Token: <token>
  - Content-Type: application/json

Body:
{
  "name": "Cappuccino",
  "description": "Coffee with foam",
  "categoryId": 1,
  "price": 3.50,
  "image": "<base64_encoded_image>"
}

Response (200): Success
Response (400): Invalid request
Response (503): Server error
```

**cURL Example:**
```bash
curl -X POST http://localhost:8011/product \
  -H "Token: JYA60sj03G6ii0LR3BfF" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Cappuccino",
    "description": "Coffee with foam",
    "categoryId": 1,
    "price": 3.50
  }'
```

#### Edit Product
```
PUT /product
Headers: Token: <token>

Body:
{
  "id": 1,
  "name": "Updated Name",
  "description": "Updated description",
  "categoryId": 1,
  "price": 4.00
}
```

#### Delete Product
```
DELETE /product?id=1
Headers: Token: <token>

Response (200): Success
```

### 3. Category Endpoints

#### Add Category
```
POST /category
Headers: Token: <token>

Body:
{
  "category": "Snacks"
}
```

#### Edit Category
```
PUT /category
Headers: Token: <token>

Body:
{
  "id": 1,
  "category": "Updated Category Name"
}
```

#### Delete Category
```
DELETE /category?id=1
Headers: Token: <token>
```

---

## Testing

### HTTP API Testing

#### Run All Tests
```bash
go test ./...
```

#### Run Specific Test
```bash
# Integration tests
go test ./tests/integration -v

# Unit tests
go test ./tests/unit/repository -v
```

#### Test Coverage
```bash
go test -cover ./...
```

#### Manual HTTP Testing with curl
```bash
# Ping
curl http://localhost:8012/ping

# Get products
curl -H "Token: JYA60sj03G6ii0LR3BfF" http://localhost:8012/product

# Add product
curl -X POST http://localhost:8012/product \
  -H "Token: JYA60sj03G6ii0LR3BfF" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": 1,
    "categoryId": 1,
    "name": "Espresso",
    "description": "Strong coffee",
    "price": 2.5
  }'
```

### gRPC API Testing

#### Install grpcurl
```bash
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
```

#### Test gRPC Services
```bash
# List available services
grpcurl -plaintext -import-path internal/interface/grpc/proto -proto product.proto \
  localhost:8012 list

# Get product
grpcurl -plaintext -import-path internal/interface/grpc/proto -proto product.proto \
  -d '{"product_id":1,"token":""}' \
  localhost:8012 model.Product/GetProduct

# Get product with valid token
grpcurl -plaintext -import-path internal/interface/grpc/proto -proto product.proto \
  -d '{"product_id":1,"token":"JYA60sj03G6ii0LR3BfF"}' \
  localhost:8012 model.Product/GetProduct
```

### Test Results (Current Status)
```
ok      maqhaa/product_service/tests/integration        1.646s
ok      maqhaa/product_service/tests/unit/repository    0.256s
```

### Integration Tests
Test coverage mencakup:
- ✅ Get products by category (positive case)
- ✅ Get products with invalid token
- ✅ Add product (positive case)
- ✅ Add product with invalid category
- ✅ Edit product
- ✅ Delete product
- ✅ Add category
- ✅ Edit category
- ✅ Delete category

### Unit Tests
- ✅ Image repository operations

### gRPC Tests
- ✅ Service listing via reflection
- ✅ GetProduct with empty token
- ✅ GetProduct with valid token

---

## Dual-Protocol Server (HTTP + gRPC)

### Overview
Server sekarang menjalankan **HTTP dan gRPC di port yang sama (8012)** menggunakan HTTP/2 connection multiplexing dengan `cmux`.

### Keuntungan:
- ✅ Satu port untuk kedua protokol
- ✅ Kompatibel dengan Railway (single port exposure)
- ✅ Seamless integration antara HTTP dan gRPC

### Cara Kerja:
1. **Single TCP Listener** pada port 8012
2. **Connection Multiplexer (cmux)** menginspeksi incoming connections
3. **Protocol Detection** berdasarkan HTTP/2 headers:
   - HTTP/1.x atau HTTP/2 tanpa gRPC → HTTP handler
   - HTTP/2 dengan `content-type: application/grpc` → gRPC handler

---

## Troubleshooting

### Error: Database Connection Failed
**Solusi:**
1. Pastikan PostgreSQL running: `docker ps | grep postgresql`
2. Cek konfigurasi di `cmd/config/config.yaml`
3. Cek credentials: user=admin, password=password123

### Error: Log File Not Found
**Solusi:**
```bash
mkdir -p /path/to/logs
```

### Error: Invalid Token
**Solusi:**
1. Pastikan token ada di database
2. Pastikan client dengan token tersebut ada di `client` table
3. Test dengan token yang benar: `JYA60sj03G6ii0LR3BfF`

### Error: Port Already in Use
**Solusi:**
```bash
# Kill process di port 8011
lsof -ti:8011 | xargs kill -9

# Atau ganti port di config
appport: :8012
```

### Error: Cannot Create Image
**Solusi:**
```bash
mkdir -p public/images
chmod 755 public/images
```

---

## Development

### Adding New Endpoint
1. **Define Model** di `internal/app/model/`
2. **Create Handler** di `internal/interface/http/handler/`
3. **Add Route** di `internal/interface/http/router/router.go`
4. **Write Tests** di `tests/integration/`

### Database Migration
1. Create migration file: `migrations/0002_add_new_column.up.sql`
2. Create rollback file: `migrations/0002_add_new_column.down.sql`
3. Apply: `docker exec -i postgresql psql -U admin -d appdb < migrations/0002_add_new_column.up.sql`

### Dependencies Update
```bash
go get -u ./...
go mod tidy
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| POSTGRES_USER | admin | Database user |
| POSTGRES_PASSWORD | password123 | Database password |
| POSTGRES_DB | appdb | Database name |
| DATABASE_HOST | localhost | Database host |
| DATABASE_PORT | 5432 | Database port |
| APP_PORT | 8011 | HTTP server port |
| GRPC_PORT | 50052 | gRPC server port |
| LOG_FILE | ../logs | Log file directory |

---

## References

- [Go Documentation](https://golang.org/doc/)
- [GORM Documentation](https://gorm.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [gRPC Documentation](https://grpc.io/docs/)
- [Gorilla Mux Documentation](https://github.com/gorilla/mux)

---

## License
Proprietary - Maqha

## Support
Untuk pertanyaan atau bug report, hubungi tim development.

---

**Last Updated:** February 15, 2026
**Version:** 1.0.0
