-- ============================================================================
-- Seed Data for Product Service Testing
-- ============================================================================
-- Created: February 24, 2026
-- Purpose: Initialize test data for development and testing
-- Database: PostgreSQL (Railway Production)
-- 
-- Usage:
--   psql -h HOST -p PORT -U USER -d DATABASE -f seed_data.sql
-- 
-- Example:
--   PGPASSWORD="password" psql -h maglev.proxy.rlwy.net -p 22459 \
--     -U postgres -d railway -f migrations/seed_data.sql
--
-- WARNING: This will insert test data. Review before running in production!
-- ============================================================================

-- Clean existing data (optional - UNCOMMENT WITH CAUTION in production!)
-- TRUNCATE TABLE product CASCADE;
-- TRUNCATE TABLE product_category CASCADE;
-- TRUNCATE TABLE client CASCADE;

-- Insert test client
INSERT INTO client (company_name, email, phone_number, address, owner_name, is_active, token, created_at)
VALUES 
    ('Test Coffee Shop', 'test@coffeeshop.com', '+62812345678', 'Jl. Test No. 123, Jakarta', 'John Doe', true, 'test-token-12345', NOW()),
    ('Demo Restaurant', 'demo@restaurant.com', '+62898765432', 'Jl. Demo No. 456, Bandung', 'Jane Smith', true, 'demo-token-67890', NOW())
ON CONFLICT (token) DO NOTHING;

-- Get client IDs (using the tokens we just created)
DO $$
DECLARE
    client_id_1 BIGINT;
    client_id_2 BIGINT;
    category_id_1 BIGINT;
    category_id_2 BIGINT;
    category_id_3 BIGINT;
    category_id_4 BIGINT;
BEGIN
    -- Get first client ID
    SELECT id INTO client_id_1 FROM client WHERE token = 'test-token-12345';
    SELECT id INTO client_id_2 FROM client WHERE token = 'demo-token-67890';

    -- Insert product categories for client 1
    INSERT INTO product_category (client_id, name, is_active, created_at)
    VALUES 
        (client_id_1, 'Coffee', true, NOW()),
        (client_id_1, 'Snacks', true, NOW()),
        (client_id_1, 'Desserts', true, NOW())
    ON CONFLICT DO NOTHING;

    -- Insert product categories for client 2
    INSERT INTO product_category (client_id, name, is_active, created_at)
    VALUES 
        (client_id_2, 'Main Course', true, NOW()),
        (client_id_2, 'Beverages', true, NOW())
    ON CONFLICT DO NOTHING;

    -- Get category IDs
    SELECT id INTO category_id_1 FROM product_category WHERE client_id = client_id_1 AND name = 'Coffee';
    SELECT id INTO category_id_2 FROM product_category WHERE client_id = client_id_1 AND name = 'Snacks';
    SELECT id INTO category_id_3 FROM product_category WHERE client_id = client_id_1 AND name = 'Desserts';
    SELECT id INTO category_id_4 FROM product_category WHERE client_id = client_id_2 AND name = 'Main Course';

    -- Insert products for Coffee category
    INSERT INTO product (category_id, name, description, image, price, is_active, created_at)
    VALUES 
        (category_id_1, 'Espresso', 'Strong Italian coffee', 'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04', 25000.00, true, NOW()),
        (category_id_1, 'Cappuccino', 'Espresso with steamed milk foam', 'https://images.unsplash.com/photo-1572442388796-11668a67e53d', 35000.00, true, NOW()),
        (category_id_1, 'Latte', 'Espresso with steamed milk', 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735', 38000.00, true, NOW()),
        (category_id_1, 'Americano', 'Espresso with hot water', 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd', 28000.00, true, NOW());

    -- Insert products for Snacks category
    INSERT INTO product (category_id, name, description, image, price, is_active, created_at)
    VALUES 
        (category_id_2, 'Croissant', 'French butter croissant', 'https://images.unsplash.com/photo-1555507036-ab1f4038808a', 22000.00, true, NOW()),
        (category_id_2, 'Chocolate Chip Cookie', 'Homemade chocolate chip cookie', 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e', 15000.00, true, NOW()),
        (category_id_2, 'Sandwich', 'Club sandwich with fries', 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af', 45000.00, true, NOW());

    -- Insert products for Desserts category
    INSERT INTO product (category_id, name, description, image, price, is_active, created_at)
    VALUES 
        (category_id_3, 'Tiramisu', 'Italian coffee-flavored dessert', 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9', 42000.00, true, NOW()),
        (category_id_3, 'Cheesecake', 'New York style cheesecake', 'https://images.unsplash.com/photo-1533134242443-d4db0c78c93a', 38000.00, true, NOW());

    -- Insert products for Main Course category (client 2)
    INSERT INTO product (category_id, name, description, image, price, is_active, created_at)
    VALUES 
        (category_id_4, 'Nasi Goreng', 'Indonesian fried rice', 'https://images.unsplash.com/photo-1603133872878-684f208fb84b', 35000.00, true, NOW()),
        (category_id_4, 'Mie Goreng', 'Indonesian fried noodles', 'https://images.unsplash.com/photo-1585032226651-759b368d7246', 32000.00, true, NOW());

END $$;

-- Verify the inserted data
SELECT 'Clients:' as info;
SELECT id, company_name, email, token FROM client ORDER BY id;

SELECT '' as break;
SELECT 'Product Categories:' as info;
SELECT pc.id, pc.name, c.company_name, pc.is_active 
FROM product_category pc 
JOIN client c ON pc.client_id = c.id 
ORDER BY pc.id;

SELECT '' as break;
SELECT 'Products:' as info;
SELECT p.id, p.name, pc.name as category, p.price, p.is_active 
FROM product p 
JOIN product_category pc ON p.category_id = pc.id 
ORDER BY p.id;
