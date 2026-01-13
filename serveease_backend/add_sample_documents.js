import { query } from './config/database.js';

async function addSampleDocuments() {
  try {
    console.log('Adding sample documents to approved providers...\n');

    // Get approved providers
    const providersResult = await query(
      `SELECT id, business_name, user_id FROM provider_profiles WHERE status = 'approved'`
    );

    if (providersResult.rows.length === 0) {
      console.log('No approved providers found');
      return;
    }

    for (const provider of providersResult.rows) {
      console.log(`Adding documents for ${provider.business_name}...`);

      // Sample documents for each provider
      const sampleDocuments = {
        business_license: {
          name: `Business License - ${provider.business_name}.pdf`,
          url: `/documents/business_license_${provider.id}.pdf`,
          size: 1536000,
          uploadDate: new Date().toISOString()
        },
        insurance_policy: {
          name: `Insurance Policy - ${provider.business_name}.pdf`,
          url: `/documents/insurance_${provider.id}.pdf`,
          size: 2048000,
          uploadDate: new Date().toISOString()
        }
      };

      // Sample certificates
      const sampleCertificates = {
        professional_cert: {
          name: `Professional Certificate - ${provider.business_name}.pdf`,
          url: `/certificates/prof_cert_${provider.id}.pdf`,
          size: 1024000,
          uploadDate: new Date().toISOString()
        },
        safety_cert: {
          name: `Safety Certification - ${provider.business_name}.jpg`,
          url: `/certificates/safety_${provider.id}.jpg`,
          size: 512000,
          uploadDate: new Date().toISOString()
        }
      };

      // Update provider with documents and certificates
      await query(
        `UPDATE provider_profiles 
         SET documents = $1, certificates = $2, updated_at = NOW()
         WHERE id = $3`,
        [JSON.stringify(sampleDocuments), JSON.stringify(sampleCertificates), provider.id]
      );

      console.log(`✅ Added documents and certificates for ${provider.business_name}`);
    }

    console.log('\n🎉 Sample documents added successfully!');

    // Verify the data
    const verifyResult = await query(
      `SELECT business_name, documents, certificates 
       FROM provider_profiles 
       WHERE status = 'approved' AND (documents IS NOT NULL OR certificates IS NOT NULL)`
    );

    console.log(`\nVerification: Found ${verifyResult.rows.length} providers with documents:`);
    verifyResult.rows.forEach(provider => {
      const docCount = provider.documents ? Object.keys(provider.documents).length : 0;
      const certCount = provider.certificates ? Object.keys(provider.certificates).length : 0;
      console.log(`- ${provider.business_name}: ${docCount} documents, ${certCount} certificates`);
    });

  } catch (error) {
    console.error('Error adding sample documents:', error);
  } finally {
    process.exit(0);
  }
}

addSampleDocuments();