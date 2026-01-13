import { getAllServices } from './controllers/adminController.js';

// Mock request and response for testing
const mockReq = {
  query: { page: 1, limit: 10 },
  user: { id: 'admin-id', name: 'Admin' }
};

let apiResponse = null;

const mockRes = {
  json: (data) => {
    apiResponse = data;
    console.log('✅ API Response received:');
    console.log(`Services found: ${data.services?.length || 0}`);
    
    if (data.services && data.services.length > 0) {
      console.log('\nServices from approved providers:');
      data.services.forEach((service, index) => {
        console.log(`${index + 1}. ${service.title}`);
        console.log(`   Provider: ${service.provider.businessName}`);
        console.log(`   Status: ${service.isActive ? 'Active' : 'Inactive'}`);
        console.log(`   Category: ${service.category.name || 'Uncategorized'}`);
        console.log('');
      });
      
      console.log(`Pagination: Page ${data.pagination.page} of ${data.pagination.pages}`);
      console.log(`Total: ${data.pagination.total} services`);
    } else {
      console.log('❌ No services found from approved providers');
    }
  },
  status: (code) => ({
    json: (data) => {
      console.log(`❌ Error ${code}:`, data);
    }
  })
};

async function testAPI() {
  try {
    console.log('🧪 Testing Services API...\n');
    await getAllServices(mockReq, mockRes);
    
    if (apiResponse && apiResponse.success) {
      console.log('\n✅ Services API is working correctly!');
      console.log('The admin services page should now display these services.');
    } else {
      console.log('\n❌ API test failed');
    }
    
  } catch (error) {
    console.error('❌ API test error:', error);
  } finally {
    process.exit(0);
  }
}

testAPI();