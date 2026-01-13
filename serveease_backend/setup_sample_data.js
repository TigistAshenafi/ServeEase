import { query } from './config/database.js';

async function setupSampleData() {
  try {
    console.log('Setting up sample data for testing...\n');

    // Create sample user
    await query(
      `INSERT INTO users (id, name, email, password_hash, role, email_verified) 
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (email) DO NOTHING`,
      ['550e8400-e29b-41d4-a716-446655440001', 'Tigist Ashenafi', 'tigist@example.com', '$2a$10$rOzJC8r.KH1n8Zx9xO9Ue.Q3Q8wJc8wJc8wJc8wJc8wJc8wJc8wJc', 'provider', true]
    );

    // Create approved provider profile
    await query(
      `INSERT INTO provider_profiles (id, user_id, provider_type, business_name, description, category, location, phone, status, is_approved, approval_date)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, CURRENT_TIMESTAMP)
       ON CONFLICT (id) DO UPDATE SET
         status = 'approved',
         is_approved = true,
         approval_date = CURRENT_TIMESTAMP`,
      ['550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'individual', 'Tigist Professional Services', 'Experienced provider offering quality home services', 'Home Repair', 'Addis Ababa, Ethiopia', '+251911234567', 'approved', true]
    );

    // Get first category
    const categoryResult = await query('SELECT id FROM service_categories LIMIT 1');
    const categoryId = categoryResult.rows[0]?.id;

    if (categoryId) {
      // Create sample services
      const services = [
        ['550e8400-e29b-41d4-a716-446655440010', 'Professional Plumbing Services', 'Expert plumbing repairs and installations', true],
        ['550e8400-e29b-41d4-a716-446655440011', 'Electrical Repair Services', 'Licensed electrical work and troubleshooting', true],
        ['550e8400-e29b-41d4-a716-446655440012', 'House Cleaning Service', 'Deep cleaning for homes and offices', false]
      ];

      for (const [id, title, description, isActive] of services) {
        await query(
          `INSERT INTO services (id, provider_id, category_id, title, description, is_active)
           VALUES ($1, $2, $3, $4, $5, $6)
           ON CONFLICT (id) DO UPDATE SET
             title = EXCLUDED.title,
             description = EXCLUDED.description,
             is_active = EXCLUDED.is_active`,
          [id, '550e8400-e29b-41d4-a716-446655440002', categoryId, title, description, isActive]
        );
      }
    }

    console.log('✅ Sample data setup complete!');
    
    // Verify data
    const result = await query(
      `SELECT s.title, s.is_active, pp.business_name, pp.status
       FROM services s
       JOIN provider_profiles pp ON s.provider_id = pp.id
       WHERE pp.status = 'approved'`
    );
    
    console.log(`Found ${result.rows.length} services from approved providers:`);
    result.rows.forEach(row => {
      console.log(`- ${row.title} (${row.is_active ? 'Active' : 'Inactive'}) - ${row.business_name}`);
    });

  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

setupSampleData();