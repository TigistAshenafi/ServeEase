import { getAppSettings, getSystemInfo } from './controllers/adminController.js';

// Mock request and response for testing
const mockReq = {
  query: {},
  user: { id: 'admin-id', name: 'Admin' }
};

let apiResponse = null;

const mockRes = {
  json: (data) => {
    apiResponse = data;
    console.log('✅ Settings API Response:');
    console.log(JSON.stringify(data, null, 2));
  },
  status: (code) => ({
    json: (data) => {
      console.log(`❌ Error ${code}:`, data);
    }
  })
};

async function testSettingsAPI() {
  try {
    console.log('🧪 Testing Settings API...\n');
    
    console.log('1. Testing App Settings:');
    await getAppSettings(mockReq, mockRes);
    
    console.log('\n2. Testing System Info:');
    await getSystemInfo(mockReq, mockRes);
    
    if (apiResponse && apiResponse.success) {
      console.log('\n✅ Settings API is working correctly!');
    } else {
      console.log('\n❌ Settings API test failed');
    }
    
  } catch (error) {
    console.error('❌ Settings API test error:', error);
  } finally {
    process.exit(0);
  }
}

testSettingsAPI();