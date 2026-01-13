-- ServeEase Database Schema

-- Create database
CREATE DATABASE serveease_db;
\c serveease_db;

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('seeker', 'provider', 'admin')),
    email_verified BOOLEAN DEFAULT FALSE,
    email_verification_code VARCHAR(6),
    email_verification_expires TIMESTAMP,
    password_reset_code VARCHAR(6),
    password_reset_expires TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    suspended_at TIMESTAMP,
    suspension_reason TEXT,
    refresh_token VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Provider profiles table
CREATE TABLE provider_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    provider_type VARCHAR(20) NOT NULL CHECK (provider_type IN ('individual', 'organization')),
    business_name VARCHAR(255),
    description TEXT,
    category VARCHAR(100),
    location VARCHAR(255),
    phone VARCHAR(20),
    profile_image_url VARCHAR(500),
    documents JSONB, -- Store document URLs or paths
    certificates JSONB, -- Store certificate URLs for individuals
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    is_approved BOOLEAN DEFAULT FALSE, -- Keep for backward compatibility
    approval_date TIMESTAMP,
    admin_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Employees table for organizations
CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES provider_profiles(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    employee_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(100), -- e.g., "Plumber", "Electrician", "Cleaner"
    skills TEXT[], -- Array of skills/specializations
    is_active BOOLEAN DEFAULT TRUE,
    hire_date DATE,
    documents JSONB, -- Store employee documents/certificates
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, user_id)
);

-- Service categories table
CREATE TABLE service_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Services table
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID REFERENCES provider_profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES service_categories(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Service requests table
CREATE TABLE service_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seeker_id UUID REFERENCES users(id) ON DELETE CASCADE,
    service_id UUID REFERENCES services(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES provider_profiles(id) ON DELETE CASCADE,
    assigned_employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'assigned', 'in_progress', 'completed', 'cancelled')),
    requested_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    scheduled_date TIMESTAMP,
    completion_date TIMESTAMP,
    notes TEXT,
    seeker_rating INTEGER CHECK (seeker_rating >= 1 AND seeker_rating <= 5),
    seeker_review TEXT,
    provider_rating INTEGER CHECK (provider_rating >= 1 AND provider_rating <= 5),
    provider_review TEXT,
    employee_rating INTEGER CHECK (employee_rating >= 1 AND employee_rating <= 5),
    employee_review TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Messages table for communication
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID REFERENCES service_requests(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_provider_profiles_user_id ON provider_profiles(user_id);
CREATE INDEX idx_provider_profiles_approved ON provider_profiles(is_approved);
CREATE INDEX idx_provider_profiles_type ON provider_profiles(provider_type);
CREATE INDEX idx_employees_organization_id ON employees(organization_id);
CREATE INDEX idx_employees_user_id ON employees(user_id);
CREATE INDEX idx_employees_active ON employees(is_active);
CREATE INDEX idx_services_provider_id ON services(provider_id);
CREATE INDEX idx_services_category_id ON services(category_id);
CREATE INDEX idx_service_requests_seeker_id ON service_requests(seeker_id);
CREATE INDEX idx_service_requests_provider_id ON service_requests(provider_id);
CREATE INDEX idx_service_requests_employee_id ON service_requests(assigned_employee_id);
CREATE INDEX idx_service_requests_status ON service_requests(status);
CREATE INDEX idx_messages_request_id ON messages(request_id);

-- Insert default service categories
INSERT INTO service_categories (name, description, icon) VALUES
('Home Repair', 'Plumbing, electrical, carpentry, and general home repairs', 'home_repair'),
('Cleaning', 'House cleaning, office cleaning, and specialized cleaning services', 'cleaning'),
('Gardening', 'Lawn care, landscaping, and garden maintenance', 'gardening'),
('Tutoring', 'Academic tutoring and educational support', 'education'),
('IT Support', 'Computer repair, software installation, and tech support', 'computer'),
('Automotive', 'Car repair, maintenance, and detailing services', 'car'),
('Beauty & Wellness', 'Hair styling, makeup, massage, and wellness services', 'spa'),
('Pet Care', 'Pet sitting, walking, grooming, and veterinary assistance', 'pets'),
('Moving & Delivery', 'Moving services, delivery, and transportation', 'truck'),
('Event Services', 'Event planning, catering, photography, and entertainment', 'party');

-- Create admin user (password: admin123 - should be changed in production)
INSERT INTO users (name, email, password_hash, role, email_verified) VALUES
('System Admin', 'admin@serveease.com', '$2a$10$rOzJC8r.KH1n8Zx9xO9Ue.Q3Q8wJc8wJc8wJc8wJc8wJc8wJc8wJc', 'admin', true);  
-- Admin@1234
