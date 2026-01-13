import { getAllDocuments } from './controllers/adminController.js';

// Mock request and response for testing
const mockReq = {
  query: { page: 1, limit: 20 },
  user: { id: 'admin-id', name: 'Admin' }
};

let apiResponse = null;

const mockRes = {
  json: (data) => {
    apiResponse = data;
    console.log('✅ Documents API Response:');
    console.log(`Documents found: ${data.documents?.length || 0}`);
    
    if (data.documents && data.documents.length > 0) {
      console.log('\nDocuments from approved providers:');
      data.documents.forEach((doc, index) => {
        console.log(`${index + 1}. ${doc.name}`);
        console.log(`   Provider: ${doc.uploadedBy.name} (${doc.businessName || 'N/A'})`);
        console.log(`   Category: ${doc.category}`);
        console.log(`   Size: ${(doc.size / 1024).toFixed(1)} KB`);
        console.log('');
      });
      
      console.log(`Pagination: Page ${data.pagination.page} of ${data.pagination.pages}`);
      console.log(`Total: ${data.pagination.total} documents`);
    } else {
      console.log('❌ No documents found');
    }
  },
  status: (code) => ({
    json: (data) => {
      console.log(`❌ Error ${code}:`, data);
    }
  })
};

async function testDocumentsAPI() {
  try {
    console.log('🧪 Testing Documents API...\n');
    await getAllDocuments(mockReq, mockRes);
    
    if (apiResponse && apiResponse.success) {
      console.log('\n✅ Documents API is working correctly!');
      console.log('The admin documents page should now display these documents.');
    } else {
      console.log('\n❌ Documents API test failed');
    }
    
  } catch (error) {
    console.error('❌ Documents API test error:', error);
  } finally {
    process.exit(0);
  }
}

testDocumentsAPI();