-- Settings table for application configuration
CREATE TABLE IF NOT EXISTS app_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(255) UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    category VARCHAR(100) DEFAULT 'general',
    is_public BOOLEAN DEFAULT FALSE, -- Whether setting can be accessed by non-admin users
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin preferences table
CREATE TABLE IF NOT EXISTS admin_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES users(id) ON DELETE CASCADE,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(admin_id)
);

-- Insert default application settings
INSERT INTO app_settings (key, value, description, category, is_public) VALUES
('app_name', 'ServeEase', 'Application name', 'general', true),
('app_version', '1.0.0', 'Application version', 'general', true),
('maintenance_mode', 'false', 'Enable maintenance mode', 'system', false),
('registration_enabled', 'true', 'Allow new user registrations', 'user_management', false),
('provider_auto_approval', 'false', 'Automatically approve new providers', 'provider_management', false),
('max_file_upload_size', '10485760', 'Maximum file upload size in bytes (10MB)', 'system', false),
('email_notifications_enabled', 'true', 'Enable email notifications', 'notifications', false),
('admin_email', 'admin@serveease.com', 'Admin contact email', 'notifications', false),
('support_email', 'support@serveease.com', 'Support contact email', 'notifications', true),
('terms_of_service_url', '', 'Terms of service URL', 'legal', true),
('privacy_policy_url', '', 'Privacy policy URL', 'legal', true),
('default_language', 'en', 'Default application language', 'localization', true),
('supported_languages', '["en", "am"]', 'Supported languages (JSON array)', 'localization', true),
('currency', 'ETB', 'Default currency', 'localization', true),
('timezone', 'Africa/Addis_Ababa', 'Default timezone', 'localization', true)
ON CONFLICT (key) DO NOTHING;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_app_settings_category ON app_settings(category);
CREATE INDEX IF NOT EXISTS idx_app_settings_public ON app_settings(is_public);
CREATE INDEX IF NOT EXISTS idx_admin_preferences_admin_id ON admin_preferences(admin_id);