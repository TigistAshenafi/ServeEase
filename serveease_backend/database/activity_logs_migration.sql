-- Activity Logs Migration
-- Add activity logging table to track admin and system events

-- Activity logs table
CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) NOT NULL CHECK (type IN (
        'user_registration', 
        'provider_approval', 
        'provider_rejection',
        'service_creation', 
        'service_approval',
        'service_rejection',
        'request_completion', 
        'payment_processed', 
        'system_alert',
        'user_suspension',
        'user_activation',
        'admin_login'
    )),
    description TEXT NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    severity VARCHAR(20) DEFAULT 'info' CHECK (severity IN ('info', 'success', 'warning', 'error')),
    metadata JSONB, -- Store additional context data
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for activity logs
CREATE INDEX IF NOT EXISTS idx_activity_logs_type ON activity_logs(type);
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_admin_id ON activity_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_severity ON activity_logs(severity);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at);

-- Function to log activity
CREATE OR REPLACE FUNCTION log_activity(
    p_type VARCHAR(50),
    p_description TEXT,
    p_user_id UUID DEFAULT NULL,
    p_admin_id UUID DEFAULT NULL,
    p_severity VARCHAR(20) DEFAULT 'info',
    p_metadata JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO activity_logs (
        type, description, user_id, admin_id, severity, 
        metadata, ip_address, user_agent
    ) VALUES (
        p_type, p_description, p_user_id, p_admin_id, p_severity,
        p_metadata, p_ip_address, p_user_agent
    ) RETURNING id INTO log_id;
    
    RETURN log_id;
END;
$$ LANGUAGE plpgsql;

-- Insert some sample activity logs for demonstration
INSERT INTO activity_logs (type, description, user_id, severity, metadata) 
SELECT 
    'user_registration',
    'New user registered as ' || role,
    id,
    'info',
    jsonb_build_object('role', role, 'email_verified', email_verified)
FROM users 
WHERE role != 'admin' 
AND created_at >= NOW() - INTERVAL '30 days'
LIMIT 10;

INSERT INTO activity_logs (type, description, user_id, severity, metadata)
SELECT 
    CASE 
        WHEN pp.is_approved THEN 'provider_approval'
        ELSE 'provider_registration'
    END,
    CASE 
        WHEN pp.is_approved THEN 'Provider application approved for ' || COALESCE(pp.business_name, u.name)
        ELSE 'New provider application submitted by ' || COALESCE(pp.business_name, u.name)
    END,
    pp.user_id,
    CASE 
        WHEN pp.is_approved THEN 'success'
        ELSE 'info'
    END,
    jsonb_build_object(
        'provider_type', pp.provider_type,
        'business_name', pp.business_name,
        'category', pp.category,
        'is_approved', pp.is_approved
    )
FROM provider_profiles pp
JOIN users u ON pp.user_id = u.id
WHERE pp.created_at >= NOW() - INTERVAL '30 days'
LIMIT 10;

INSERT INTO activity_logs (type, description, user_id, severity, metadata)
SELECT 
    'service_creation',
    'New service created: ' || s.title,
    pp.user_id,
    'info',
    jsonb_build_object(
        'service_id', s.id,
        'title', s.title,
        'price', s.price,
        'category', sc.name,
        'is_active', s.is_active
    )
FROM services s
JOIN provider_profiles pp ON s.provider_id = pp.id
LEFT JOIN service_categories sc ON s.category_id = sc.id
WHERE s.created_at >= NOW() - INTERVAL '30 days'
LIMIT 10;

INSERT INTO activity_logs (type, description, user_id, severity, metadata)
SELECT 
    'request_completion',
    'Service request completed: ' || s.title,
    sr.seeker_id,
    'success',
    jsonb_build_object(
        'request_id', sr.id,
        'service_title', s.title,
        'provider_id', sr.provider_id,
        'rating', sr.seeker_rating,
        'completion_date', sr.completion_date
    )
FROM service_requests sr
JOIN services s ON sr.service_id = s.id
WHERE sr.status = 'completed' 
AND sr.completion_date >= NOW() - INTERVAL '30 days'
LIMIT 10;