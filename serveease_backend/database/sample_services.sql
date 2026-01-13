-- Sample services for approved provider testing
-- This script assumes there's an approved provider in the system

-- First, let's create a sample approved provider if it doesn't exist
INSERT INTO users (id, name, email, password_hash, role, email_verified) 
VALUES ('550e8400-e29b-41d4-a716-446655440001', 'Tigist Ashenafi', 'tigist@example.com', '$2a$10$rOzJC8r.KH1n8Zx9xO9Ue.Q3Q8wJc8wJc8wJc8wJc8wJc8wJc8wJc', 'provider', true)
ON CONFLICT (email) DO NOTHING;

-- Create provider profile with approved status
INSERT INTO provider_profiles (id, user_id, provider_type, business_name, description, category, location, phone, status, is_approved, approval_date)
VALUES (
    '550e8400-e29b-41d4-a716-446655440002',
    '550e8400-e29b-41d4-a716-446655440001',
    'individual',
    'Tigist Professional Services',
    'Experienced provider offering quality home services',
    'Home Repair',
    'Addis Ababa, Ethiopia',
    '+251911234567',
    'approved',
    true,
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO UPDATE SET
    status = 'approved',
    is_approved = true,
    approval_date = CURRENT_TIMESTAMP;

-- Get category IDs for our sample services
-- We'll use the existing categories from the schema

-- Insert sample services for the approved provider
INSERT INTO services (id, provider_id, category_id, title, description, is_active, created_at, updated_at) VALUES
(
    '550e8400-e29b-41d4-a716-446655440010',
    '550e8400-e29b-41d4-a716-446655440002',
    (SELECT id FROM service_categories WHERE name = 'Home Repair' LIMIT 1),
    'Professional Plumbing Services',
    'Expert plumbing repairs, installations, and maintenance. Available for emergency calls 24/7.',
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    '550e8400-e29b-41d4-a716-446655440011',
    '550e8400-e29b-41d4-a716-446655440002',
    (SELECT id FROM service_categories WHERE name = 'Home Repair' LIMIT 1),
    'Electrical Repair & Installation',
    'Licensed electrical work including wiring, outlet installation, and electrical troubleshooting.',
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    '550e8400-e29b-41d4-a716-446655440012',
    '550e8400-e29b-41d4-a716-446655440002',
    (SELECT id FROM service_categories WHERE name = 'Cleaning' LIMIT 1),
    'Deep House Cleaning',
    'Comprehensive house cleaning service including all rooms, bathrooms, and kitchen deep clean.',
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    '550e8400-e29b-41d4-a716-446655440013',
    '550e8400-e29b-41d4-a716-446655440002',
    (SELECT id FROM service_categories WHERE name = 'Beauty & Wellness' LIMIT 1),
    'Mobile Hair Styling',
    'Professional hair styling services at your location. Specializing in traditional and modern styles.',
    false,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    '550e8400-e29b-41d4-a716-446655440014',
    '550e8400-e29b-41d4-a716-446655440002',
    (SELECT id FROM service_categories WHERE name = 'Tutoring' LIMIT 1),
    'Mathematics Tutoring',
    'Expert math tutoring for high school and college students. Flexible scheduling available.',
    false,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Verify the data was inserted
SELECT 
    s.id,
    s.title,
    s.description,
    s.is_active,
    pp.business_name,
    pp.status as provider_status,
    u.name as provider_name,
    sc.name as category_name
FROM services s
JOIN provider_profiles pp ON s.provider_id = pp.id
JOIN users u ON pp.user_id = u.id
LEFT JOIN service_categories sc ON s.category_id = sc.id
WHERE pp.status = 'approved'
ORDER BY s.created_at DESC;