# Database Migrations

**Last Updated:** February 24, 2026

This folder contains database migration scripts and seed data for the Product Service.

## Migration Files

### Schema Migrations

- **[0001_create_product_tables.up.sql](0001_create_product_tables.up.sql)**  
  Initial schema creation for:
  - `client` table
  - `product_category` table
  - `product` table
  
- **[0001_create_product_tables.down.sql](0001_create_product_tables.down.sql)**  
  Rollback script for initial schema.

### Seed Data

- **[seed_data.sql](seed_data.sql)**  
  Test data initialization script.
  
  **Contents:**
  - 3 test clients (Test Coffee Shop, Demo Restaurant, Test Company)
  - 5 product categories
  - 11 sample products
  
  **Usage:**
  ```bash
  PGPASSWORD="your_password" psql -h HOST -p PORT -U USER -d DATABASE \
    -f migrations/seed_data.sql
  ```
  
  **Example (Railway Production):**
  ```bash
  PGPASSWORD="lkZoqenENptXOFAIPkOnNVniFEBWaUNc" psql \
    -h maglev.proxy.rlwy.net -p 22459 -U postgres -d railway \
    -f migrations/seed_data.sql
  ```

## Running Migrations

### Manual Migration

```bash
# Apply migration
psql -h HOST -p PORT -U USER -d DATABASE -f migrations/0001_create_product_tables.up.sql

# Rollback migration
psql -h HOST -p PORT -U USER -d DATABASE -f migrations/0001_create_product_tables.down.sql
```

### Using Migration Tools

If using a migration tool like `golang-migrate`:

```bash
# Install migrate
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Run migrations
migrate -path migrations -database "postgresql://USER:PASSWORD@HOST:PORT/DATABASE?sslmode=disable" up

# Rollback
migrate -path migrations -database "postgresql://USER:PASSWORD@HOST:PORT/DATABASE?sslmode=disable" down
```

## Database Schema

### Tables Overview

#### client
Stores client/company information.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| company_name | VARCHAR(255) | Company name |
| email | VARCHAR(255) | Contact email |
| phone_number | VARCHAR(50) | Contact phone |
| address | TEXT | Company address |
| owner_name | VARCHAR(255) | Owner name |
| is_active | BOOLEAN | Active status |
| token | VARCHAR(255) | Authentication token (unique) |
| created_at | TIMESTAMPTZ | Creation timestamp |

#### product_category
Stores product categories per client.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| client_id | BIGINT | Foreign key to client |
| name | VARCHAR(255) | Category name |
| is_active | BOOLEAN | Active status |
| created_at | TIMESTAMPTZ | Creation timestamp |

#### product
Stores product information.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| category_id | BIGINT | Foreign key to product_category |
| name | VARCHAR(255) | Product name |
| description | TEXT | Product description |
| image | VARCHAR(512) | Image URL/path |
| price | NUMERIC(12,2) | Product price |
| is_active | BOOLEAN | Active status |
| created_at | TIMESTAMPTZ | Creation timestamp |

## Best Practices

1. **Always backup before migrations**  
   ```bash
   pg_dump -h HOST -U USER -d DATABASE > backup_$(date +%Y%m%d).sql
   ```

2. **Test migrations locally first**  
   Never run untested migrations in production.

3. **Use transactions**  
   Wrap migrations in BEGIN/COMMIT for atomicity.

4. **Document changes**  
   Add comments explaining what each migration does.

5. **Version control**  
   Always commit migration files to git.

## Seed Data Warning

⚠️ **Important:** Review seed data before running in production!

The seed data script includes:
- Test clients with known tokens
- Sample products with public image URLs

These are intended for development/testing only.

## Connection Information

### Local Development
```bash
host: localhost
port: 5432
user: admin
password: password123
database: appdb_test
```

### Production (Railway)
Stored in environment variables:
- `PRODUCT_DATABASE_HOST`
- `PRODUCT_DATABASE_PORT`
- `PRODUCT_DATABASE_USER`
- `PRODUCT_DATABASE_PASSWORD`
- `PRODUCT_DATABASE_DBNAME`

---

For more information, see:
- [Main Documentation](../doc/)
- [Main README](../README.md)
