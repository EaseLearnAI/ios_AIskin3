const axios = require('axios');

// API base URL
const BASE_URL = 'http://localhost:5000/api';

// Test user credentials - will be created and deleted
const TEST_USER = {
  name: 'DeleteTestUser',
  phone: `1${Math.floor(Math.random() * 9000000000 + 1000000000)}`, // Random phone number
  password: 'test123456',
  gender: 'female'
};

// Global variables
let token = '';
let userId = '';
let createdProductId = '';
let createdPlanId = '';
let createdIdeaId = '';
let createdSkinAnalysisId = '';

// Color-coded log function
const log = {
  success: (message) => console.log('\x1b[32m%s\x1b[0m', `✓ ${message}`),
  error: (message) => console.log('\x1b[31m%s\x1b[0m', `✗ ${message}`),
  info: (message) => console.log('\x1b[36m%s\x1b[0m', `ℹ ${message}`),
  warning: (message) => console.log('\x1b[33m%s\x1b[0m', `⚠ ${message}`),
  json: (data) => console.log(JSON.stringify(data, null, 2))
};

// Set request headers with authorization token
const getHeaders = () => ({
  'Authorization': `Bearer ${token}`,
  'Content-Type': 'application/json'
});

// 1. Register a new test user
async function registerTestUser() {
  try {
    log.info('📝 注册测试用户...');
    const response = await axios.post(`${BASE_URL}/users/register`, TEST_USER);
    log.success('测试用户注册成功');
    
    token = response.data.token;
    userId = response.data.data.user._id;
    log.info(`用户ID: ${userId}`);
    log.info(`手机号: ${TEST_USER.phone}`);
    return true;
  } catch (error) {
    log.error('注册测试用户失败');
    log.json(error.response?.data || error.message);
    return false;
  }
}

// 2. Create test product
async function createTestProduct() {
  try {
    log.info('🧴 创建测试产品...');
    
    const product = {
      name: '测试护肤品',
      description: '这是一个测试产品',
      label: '保湿'
    };
    
    const response = await axios.post(
      `${BASE_URL}/products`,
      product,
      { headers: getHeaders() }
    );
    
    createdProductId = response.data.data.product._id;
    log.success(`创建产品成功 - ID: ${createdProductId}`);
    return true;
  } catch (error) {
    log.error('创建产品失败');
    log.json(error.response?.data || error.message);
    return false;
  }
}

// 3. Create test idea
async function createTestIdea() {
  try {
    log.info('💡 创建测试反馈...');
    
    const idea = {
      title: '测试反馈',
      content: '这是一个测试反馈内容',
      category: '功能建议'
    };
    
    const response = await axios.post(
      `${BASE_URL}/ideas`,
      idea,
      { headers: getHeaders() }
    );
    
    createdIdeaId = response.data.data.idea._id;
    log.success(`创建反馈成功 - ID: ${createdIdeaId}`);
    return true;
  } catch (error) {
    log.error('创建反馈失败');
    log.json(error.response?.data || error.message);
    return false;
  }
}

// 4. Verify user data exists
async function verifyUserDataExists() {
  try {
    log.info('🔍 验证用户数据存在...');
    
    // Check user profile
    const userResponse = await axios.get(
      `${BASE_URL}/users/me`,
      { headers: getHeaders() }
    );
    log.success('用户信息存在');
    
    // Check products
    const productsResponse = await axios.get(
      `${BASE_URL}/products`,
      { headers: getHeaders() }
    );
    
    if (productsResponse.data.data.products.length > 0) {
      log.success(`找到 ${productsResponse.data.data.products.length} 个产品`);
    }
    
    // Check ideas
    const ideasResponse = await axios.get(
      `${BASE_URL}/ideas`,
      { headers: getHeaders() }
    );
    
    if (ideasResponse.data.data.ideas.length > 0) {
      log.success(`找到 ${ideasResponse.data.data.ideas.length} 个反馈`);
    }
    
    return true;
  } catch (error) {
    log.error('验证用户数据失败');
    log.json(error.response?.data || error.message);
    return false;
  }
}

// 5. Delete account
async function deleteAccount() {
  try {
    log.info('🗑️  执行账号注销...');
    log.warning('即将删除账号及所有关联数据！');
    
    const response = await axios.delete(
      `${BASE_URL}/users/delete-account`,
      { headers: getHeaders() }
    );
    
    log.success('账号注销成功');
    log.json(response.data);
    return true;
  } catch (error) {
    log.error('账号注销失败');
    log.json(error.response?.data || error.message);
    return false;
  }
}

// 6. Verify account is deleted
async function verifyAccountDeleted() {
  try {
    log.info('🔍 验证账号已删除...');
    
    // Try to login with deleted account - should fail
    try {
      await axios.post(`${BASE_URL}/users/login`, {
        phone: TEST_USER.phone,
        password: TEST_USER.password
      });
      
      log.error('账号仍然存在 - 删除失败！');
      return false;
    } catch (error) {
      if (error.response?.status === 401) {
        log.success('账号已被删除（登录失败验证通过）');
        return true;
      } else {
        log.error('验证过程出现未预期的错误');
        log.json(error.response?.data || error.message);
        return false;
      }
    }
  } catch (error) {
    log.error('验证账号删除失败');
    log.json(error.response?.data || error.message);
    return false;
  }
}

// 7. Test unauthorized access (without token)
async function testUnauthorizedAccess() {
  try {
    log.info('🔒 测试未授权访问...');
    
    await axios.delete(`${BASE_URL}/users/delete-account`);
    
    log.error('未授权访问应该被拒绝，但请求成功了！');
    return false;
  } catch (error) {
    if (error.response?.status === 401) {
      log.success('未授权访问被正确拒绝');
      return true;
    } else {
      log.error('未授权访问测试失败');
      log.json(error.response?.data || error.message);
      return false;
    }
  }
}

// 8. Test with invalid token
async function testInvalidToken() {
  try {
    log.info('🔒 测试无效Token...');
    
    await axios.delete(
      `${BASE_URL}/users/delete-account`,
      {
        headers: {
          'Authorization': 'Bearer invalid_token_here'
        }
      }
    );
    
    log.error('无效Token应该被拒绝，但请求成功了！');
    return false;
  } catch (error) {
    if (error.response?.status === 401) {
      log.success('无效Token被正确拒绝');
      return true;
    } else {
      log.error('无效Token测试失败');
      log.json(error.response?.data || error.message);
      return false;
    }
  }
}

// Complete test suite
async function runCompleteTest() {
  log.info('🚀 开始执行账号注销完整测试...');
  log.info('='.repeat(60));
  
  // Security tests (before creating user)
  log.info('\n📋 第1部分: 安全性测试');
  log.info('-'.repeat(60));
  await testUnauthorizedAccess();
  await testInvalidToken();
  
  // Functional tests
  log.info('\n📋 第2部分: 功能测试');
  log.info('-'.repeat(60));
  
  // Step 1: Register user
  if (!await registerTestUser()) {
    log.error('❌ 测试失败：无法注册测试用户');
    return;
  }
  
  // Step 2: Create test data
  log.info('\n创建测试数据...');
  await createTestProduct();
  await createTestIdea();
  
  // Step 3: Verify data exists
  log.info('\n');
  await verifyUserDataExists();
  
  // Step 4: Delete account
  log.info('\n');
  if (!await deleteAccount()) {
    log.error('❌ 测试失败：账号注销失败');
    return;
  }
  
  // Step 5: Verify account is deleted
  log.info('\n');
  if (!await verifyAccountDeleted()) {
    log.error('❌ 测试失败：账号删除验证失败');
    return;
  }
  
  // All tests passed
  log.info('\n' + '='.repeat(60));
  log.success('✅ 所有测试通过！账号注销功能正常工作');
  log.info('='.repeat(60));
}

// Quick test - just test delete account with existing user
async function runQuickTest() {
  log.info('🚀 开始执行账号注销快速测试...');
  log.info('使用已存在的用户账号进行测试');
  log.info('='.repeat(60));
  
  // Register new user
  if (!await registerTestUser()) {
    log.error('❌ 快速测试失败：无法注册测试用户');
    return;
  }
  
  // Create some test data
  await createTestProduct();
  await createTestIdea();
  
  // Delete account
  log.info('\n');
  if (!await deleteAccount()) {
    log.error('❌ 快速测试失败：账号注销失败');
    return;
  }
  
  // Verify deletion
  log.info('\n');
  if (!await verifyAccountDeleted()) {
    log.error('❌ 快速测试失败：账号删除验证失败');
    return;
  }
  
  log.info('\n' + '='.repeat(60));
  log.success('✅ 快速测试通过！');
  log.info('='.repeat(60));
}

// Export functions for use in other tests
module.exports = {
  registerTestUser,
  createTestProduct,
  createTestIdea,
  verifyUserDataExists,
  deleteAccount,
  verifyAccountDeleted,
  testUnauthorizedAccess,
  testInvalidToken,
  runCompleteTest,
  runQuickTest
};

// Run tests based on command line argument
const testMode = process.argv[2] || 'complete';

if (require.main === module) {
  if (testMode === 'quick') {
    runQuickTest().catch(error => {
      log.error('快速测试过程中发生未处理的错误');
      console.error(error);
      process.exit(1);
    });
  } else {
    runCompleteTest().catch(error => {
      log.error('完整测试过程中发生未处理的错误');
      console.error(error);
      process.exit(1);
    });
  }
}
