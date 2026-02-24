# Test Scripts

**Last Updated:** February 24, 2026

This folder contains automated test scripts and integration tests for the Product Service.

## Test Scripts

### API Testing

- **[test_api.sh](test_api.sh)**  
  Comprehensive API endpoint testing script.
  
  **Usage:**
  ```bash
  chmod +x tests/test_api.sh
  ./tests/test_api.sh
  ```
  
  **Requirements:**
  - curl
  - jq (optional, for JSON formatting)
  
  **Tests:**
  - ✅ GET /ping
  - ✅ GET /product
  - ⚠️ POST /category (requires valid user token)
  - ⚠️ POST /product (requires valid user token)
  - ⚠️ PUT /product/{id} (route registration issue)
  - ⚠️ PUT /category/{id} (route registration issue)
  - ⚠️ DELETE /product/{id} (route registration issue)
  - ⚠️ DELETE /category/{id} (route registration issue)

## Integration Tests

### Unit Tests

- **[unit/repository/](unit/repository/)**  
  Repository layer unit tests.

### Integration Tests

- **[integration/](integration/)**  
  End-to-end integration tests.

## Test Configuration

### Environment Variables

For testing, ensure the following are set:

```bash
export PRODUCT_DATABASE_HOST="localhost"
export PRODUCT_DATABASE_PORT="5432"
export PRODUCT_DATABASE_USER="admin"
export PRODUCT_DATABASE_PASSWORD="password123"
export PRODUCT_DATABASE_DBNAME="appdb_test"
export PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_HOST="localhost:50051"
export PRODUCT_EXTERNALCONNECTION_AUTHSERVICE_USETLS="false"
```

### Running Unit Tests

```bash
# Run all tests
go test ./tests/unit/...

# Run with coverage
go test -cover ./tests/unit/...

# Run specific test
go test ./tests/unit/repository/image_repo_test.go
```

### Running Integration Tests

```bash
# Ensure test database is running
docker-compose -f docker-compose.test.yml up -d

# Run integration tests
go test ./tests/integration/...

# Stop test database
docker-compose -f docker-compose.test.yml down
```

## Test Results

Test results and reports are documented in:
- [../doc/TEST_RESULTS.md](../doc/TEST_RESULTS.md)

## Known Issues

1. **Route Registration Bug**  
   PUT and DELETE endpoints missing path parameters in main.go
   
2. **Auth Service Connection**  
   POST/PUT/DELETE operations require valid user token from Auth Service
   
3. **Token Validation**  
   Tokens in Product Service database not synced with Auth Service

## Contributing

When adding new tests:

1. Follow existing test structure
2. Add clear comments and descriptions
3. Update this README with new test information
4. Ensure tests are idempotent (can run multiple times)
5. Clean up test data after test completion

---

For more information, see:
- [Testing Documentation](../doc/TEST_RESULTS.md)
- [Main README](../README.md)
