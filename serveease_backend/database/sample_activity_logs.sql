-- Insert sample activity logs for demonstration
INSERT INTO activity_logs (type, description, severity, metadata, created_at) VALUES
('user_registration', 'New user registered as service seeker', 'info', '{"role": "seeker", "source": "web"}', NOW() - INTERVAL '2 hours'),
('user_registration', 'New user registered as service provider', 'info', '{"role": "provider", "source": "mobile"}', NOW() - INTERVAL '4 hours'),
('provider_approval', 'Provider application approved for cleaning services', 'success', '{"business_name": "Clean Pro Services", "category": "cleaning"}', NOW() - INTERVAL '6 hours'),
('service_creation', 'New cleaning service added to marketplace', 'info', '{"service_title": "Deep House Cleaning", "price": 150}', NOW() - INTERVAL '8 hours'),
('request_completion', 'Service request completed successfully - Plumbing repair', 'success', '{"service_type": "plumbing", "rating": 5}', NOW() - INTERVAL '10 hours'),
('payment_processed', 'Payment of $150 processed successfully', 'success', '{"amount": 150, "method": "credit_card"}', NOW() - INTERVAL '12 hours'),
('system_alert', 'High server load detected - Auto-scaling initiated', 'warning', '{"cpu_usage": 85, "memory_usage": 78}', NOW() - INTERVAL '14 hours'),
('provider_approval', 'New provider application submitted', 'info', '{"business_name": "Fix It Fast", "category": "home_repair"}', NOW() - INTERVAL '16 hours'),
('user_registration', 'New user registered as service seeker', 'info', '{"role": "seeker", "source": "referral"}', NOW() - INTERVAL '18 hours'),
('service_creation', 'New electrical service added to marketplace', 'info', '{"service_title": "Electrical Wiring", "price": 200}', NOW() - INTERVAL '20 hours'),
('request_completion', 'Service request completed successfully - Garden maintenance', 'success', '{"service_type": "gardening", "rating": 4}', NOW() - INTERVAL '22 hours'),
('provider_approval', 'Provider application approved for electrical services', 'success', '{"business_name": "Spark Electric", "category": "electrical"}', NOW() - INTERVAL '1 day'),
('payment_processed', 'Payment of $75 processed successfully', 'success', '{"amount": 75, "method": "paypal"}', NOW() - INTERVAL '1 day 2 hours'),
('system_alert', 'Database backup completed successfully', 'info', '{"backup_size": "2.5GB", "duration": "15 minutes"}', NOW() - INTERVAL '1 day 4 hours'),
('user_registration', 'New user registered as service provider', 'info', '{"role": "provider", "source": "web"}', NOW() - INTERVAL '1 day 6 hours');