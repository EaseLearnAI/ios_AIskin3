/**
 * 产品分析前后端交互测试脚本
 * 测试账号: phone=15691887650, password=12345678
 */

const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'https://www.lunzo.site/api';
const TEST_PHONE = '15691887650';
const TEST_PASSWORD = '12345678';

// 颜色输出工具
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m'
};

function log(emoji, message, color = colors.reset) {
  console.log(`${color}${emoji} ${message}${colors.reset}`);
}

function logSection(title) {
  console.log(`\n${colors.bright}${colors.cyan}${'='.repeat(60)}${colors.reset}`);
  console.log(`${colors.bright}${colors.cyan}${title}${colors.reset}`);
  console.log(`${colors.bright}${colors.cyan}${'='.repeat(60)}${colors.reset}\n`);
}

// HTTP请求封装
function makeRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const protocol = options.hostname.includes('localhost') ? http : https;
    
    const req = protocol.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = JSON.parse(responseData);
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: parsed,
            raw: responseData
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: responseData,
            raw: responseData
          });
        }
      });
    });
    
    req.on('error', (error) => {
      reject(error);
    });
    
    if (data) {
      req.write(data);
    }
    
    req.end();
  });
}

// 解析URL
function parseURL(url) {
  const urlObj = new URL(url);
  return {
    protocol: urlObj.protocol,
    hostname: urlObj.hostname,
    port: urlObj.port || (urlObj.protocol === 'https:' ? 443 : 80),
    path: urlObj.pathname + urlObj.search
  };
}

// 登录获取Token
async function login() {
  logSection('🔐 步骤1: 用户登录');
  
  const url = `${BASE_URL}/users/login`;
  const urlParts = parseURL(url);
  
  log('📡', '发起登录请求', colors.blue);
  log('🔗', `URL: ${url}`, colors.cyan);
  log('📋', `Method: POST`, colors.cyan);
  log('📦', `Body: { phone: "${TEST_PHONE}", password: "******" }`, colors.cyan);
  
  const postData = JSON.stringify({
    phone: TEST_PHONE,
    password: TEST_PASSWORD
  });
  
  const options = {
    hostname: urlParts.hostname,
    port: urlParts.port,
    path: urlParts.path,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };
  
  try {
    const response = await makeRequest(options, postData);
    
    log('✅', '收到响应', colors.green);
    log('📊', `Status Code: ${response.statusCode}`, colors.cyan);
    log('📦', `Response Body: ${JSON.stringify(response.data, null, 2)}`, colors.cyan);
    
    if (response.statusCode === 200 && response.data.success && response.data.token) {
      log('✅', `登录成功！Token: ${response.data.token.substring(0, 20)}...`, colors.green);
      return response.data.token;
    } else {
      log('❌', `登录失败: ${response.data.message || '未知错误'}`, colors.red);
      throw new Error(response.data.message || '登录失败');
    }
  } catch (error) {
    log('❌', `登录错误: ${error.message}`, colors.red);
    throw error;
  }
}

// 创建产品
async function createProduct(token) {
  logSection('📦 步骤2: 创建产品');
  
  const url = `${BASE_URL}/products`;
  const urlParts = parseURL(url);
  
  log('📡', '发起创建产品请求', colors.blue);
  log('🔗', `URL: ${url}`, colors.cyan);
  log('📋', `Method: POST`, colors.cyan);
  
  const productData = {
    name: '测试产品 - ' + new Date().toISOString(),
    description: '这是一个用于测试的产品',
    label: '洁面'
  };
  
  log('📦', `Request Body: ${JSON.stringify(productData, null, 2)}`, colors.cyan);
  
  const postData = JSON.stringify(productData);
  
  const options = {
    hostname: urlParts.hostname,
    port: urlParts.port,
    path: urlParts.path,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      'Content-Length': Buffer.byteLength(postData)
    }
  };
  
  try {
    const response = await makeRequest(options, postData);
    
    log('✅', '收到响应', colors.green);
    log('📊', `Status Code: ${response.statusCode}`, colors.cyan);
    log('📦', `Response Body: ${JSON.stringify(response.data, null, 2)}`, colors.cyan);
    
    if (response.statusCode === 200 || response.statusCode === 201) {
      if (response.data.success && response.data.data && response.data.data.product) {
        const productId = response.data.data.product._id || response.data.data.product.id;
        log('✅', `产品创建成功！产品ID: ${productId}`, colors.green);
        return productId;
      }
    }
    
    log('❌', `创建产品失败: ${response.data.message || '未知错误'}`, colors.red);
    throw new Error(response.data.message || '创建产品失败');
  } catch (error) {
    log('❌', `创建产品错误: ${error.message}`, colors.red);
    throw error;
  }
}

// 上传产品图片（模拟，使用一个占位图片URL）
async function uploadProductImage(token, productId) {
  logSection('📷 步骤3: 上传产品图片');
  
  // 注意：实际实现需要使用multipart/form-data上传真实图片
  // 这里我们模拟一个上传过程，实际应该使用form-data库
  log('📡', '发起上传图片请求', colors.blue);
  log('🔗', `URL: ${BASE_URL}/products/${productId}/upload-image`, colors.cyan);
  log('📋', `Method: POST (multipart/form-data)`, colors.cyan);
  log('⚠️', '注意：实际实现需要使用multipart/form-data格式上传真实图片文件', colors.yellow);
  
  // 创建一个简单的测试图片数据（1x1像素的PNG）
  const testImageData = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    'base64'
  );
  
  const boundary = '----WebKitFormBoundary' + Date.now();
  const url = `${BASE_URL}/products/${productId}/upload-image`;
  const urlParts = parseURL(url);
  
  let formData = '';
  formData += `--${boundary}\r\n`;
  formData += `Content-Disposition: form-data; name="productImage"; filename="test.png"\r\n`;
  formData += `Content-Type: image/png\r\n\r\n`;
  
  const bodyBuffer = Buffer.concat([
    Buffer.from(formData, 'utf8'),
    testImageData,
    Buffer.from(`\r\n--${boundary}--\r\n`, 'utf8')
  ]);
  
  const options = {
    hostname: urlParts.hostname,
    port: urlParts.port,
    path: urlParts.path,
    method: 'POST',
    headers: {
      'Content-Type': `multipart/form-data; boundary=${boundary}`,
      'Authorization': `Bearer ${token}`,
      'Content-Length': bodyBuffer.length
    }
  };
  
  try {
    const response = await makeRequest(options, bodyBuffer);
    
    log('✅', '收到响应', colors.green);
    log('📊', `Status Code: ${response.statusCode}`, colors.cyan);
    log('📦', `Response Body: ${JSON.stringify(response.data, null, 2)}`, colors.cyan);
    
    if (response.statusCode === 200 && response.data.success && response.data.data) {
      const imageUrl = response.data.data.imageUrl;
      log('✅', `图片上传成功！图片URL: ${imageUrl}`, colors.green);
      return imageUrl;
    } else {
      log('❌', `上传图片失败: ${response.data.message || '未知错误'}`, colors.red);
      throw new Error(response.data.message || '上传图片失败');
    }
  } catch (error) {
    log('❌', `上传图片错误: ${error.message}`, colors.red);
    throw error;
  }
}

// 提取产品成分
async function extractIngredients(token, productId) {
  logSection('🔬 步骤4: 提取产品成分');
  
  const url = `${BASE_URL}/products/${productId}/extract-ingredients`;
  const urlParts = parseURL(url);
  
  log('📡', '发起提取成分请求', colors.blue);
  log('🔗', `URL: ${url}`, colors.cyan);
  log('📋', `Method: POST`, colors.cyan);
  
  const postData = JSON.stringify({});
  
  const options = {
    hostname: urlParts.hostname,
    port: urlParts.port,
    path: urlParts.path,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      'Content-Length': Buffer.byteLength(postData)
    }
  };
  
  try {
    const response = await makeRequest(options, postData);
    
    log('✅', '收到响应', colors.green);
    log('📊', `Status Code: ${response.statusCode}`, colors.cyan);
    log('📦', `Response Body: ${JSON.stringify(response.data, null, 2)}`, colors.cyan);
    
    if (response.statusCode === 200 && response.data.success && response.data.data) {
      const ingredients = response.data.data.ingredients || [];
      log('✅', `成分提取成功！`, colors.green);
      log('📋', `产品名称: ${response.data.data.name || '未知'}`, colors.cyan);
      log('📋', `成分数量: ${ingredients.length}`, colors.cyan);
      log('📋', `成分列表: ${ingredients.join(', ')}`, colors.cyan);
      return ingredients;
    } else {
      log('❌', `提取成分失败: ${response.data.message || '未知错误'}`, colors.red);
      throw new Error(response.data.message || '提取成分失败');
    }
  } catch (error) {
    log('❌', `提取成分错误: ${error.message}`, colors.red);
    throw error;
  }
}

// 分析产品成分
async function analyzeIngredients(token, productId) {
  logSection('🧪 步骤5: 分析产品成分');
  
  const url = `${BASE_URL}/products/${productId}/analyze-ingredients`;
  const urlParts = parseURL(url);
  
  log('📡', '发起分析成分请求', colors.blue);
  log('🔗', `URL: ${url}`, colors.cyan);
  log('📋', `Method: POST`, colors.cyan);
  
  const postData = JSON.stringify({});
  
  const options = {
    hostname: urlParts.hostname,
    port: urlParts.port,
    path: urlParts.path,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      'Content-Length': Buffer.byteLength(postData)
    }
  };
  
  try {
    const response = await makeRequest(options, postData);
    
    log('✅', '收到响应', colors.green);
    log('📊', `Status Code: ${response.statusCode}`, colors.cyan);
    log('📦', `Response Body: ${JSON.stringify(response.data, null, 2)}`, colors.cyan);
    
    if (response.statusCode === 200 && response.data.success && response.data.data) {
      const analysis = response.data.data.ingredientAnalysis;
      log('✅', `成分分析成功！`, colors.green);
      log('📋', `安全性指数: ${analysis.safetyIndex || 0}`, colors.cyan);
      log('📋', `功效评分: ${analysis.efficacyScore || 0}`, colors.cyan);
      log('📋', `活性成分数: ${analysis.activeIngredients || 0}`, colors.cyan);
      log('📋', `整体评级: ${analysis.overallRating || 0}/5.0`, colors.cyan);
      return analysis;
    } else {
      log('❌', `分析成分失败: ${response.data.message || '未知错误'}`, colors.red);
      throw new Error(response.data.message || '分析成分失败');
    }
  } catch (error) {
    log('❌', `分析成分错误: ${error.message}`, colors.red);
    throw error;
  }
}

// 获取用户产品列表
async function getUserProducts(token, userId) {
  logSection('📚 步骤6: 获取用户产品列表');
  
  const url = `${BASE_URL}/products/user/${userId}`;
  const urlParts = parseURL(url);
  
  log('📡', '发起获取产品列表请求', colors.blue);
  log('🔗', `URL: ${url}`, colors.cyan);
  log('📋', `Method: GET`, colors.cyan);
  
  const options = {
    hostname: urlParts.hostname,
    port: urlParts.port,
    path: urlParts.path,
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    }
  };
  
  try {
    const response = await makeRequest(options);
    
    log('✅', '收到响应', colors.green);
    log('📊', `Status Code: ${response.statusCode}`, colors.cyan);
    log('📦', `Response Body: ${JSON.stringify(response.data, null, 2)}`, colors.cyan);
    
    if (response.statusCode === 200 && response.data.success && response.data.data) {
      const products = response.data.data.products || [];
      log('✅', `获取产品列表成功！`, colors.green);
      log('📋', `产品总数: ${products.length}`, colors.cyan);
      products.forEach((product, index) => {
        log('📦', `${index + 1}. ${product.name} (ID: ${product._id || product.id})`, colors.cyan);
      });
      return products;
    } else {
      log('❌', `获取产品列表失败: ${response.data.message || '未知错误'}`, colors.red);
      throw new Error(response.data.message || '获取产品列表失败');
    }
  } catch (error) {
    log('❌', `获取产品列表错误: ${error.message}`, colors.red);
    throw error;
  }
}

// 分析产品冲突
async function analyzeConflict(token, productIds) {
  logSection('⚠️ 步骤7: 分析产品冲突');
  
  const url = `${BASE_URL}/conflicts`;
  const urlParts = parseURL(url);
  
  log('📡', '发起冲突分析请求', colors.blue);
  log('🔗', `URL: ${url}`, colors.cyan);
  log('📋', `Method: POST`, colors.cyan);
  
  const conflictData = {
    productIds: productIds
  };
  
  log('📦', `Request Body: ${JSON.stringify(conflictData, null, 2)}`, colors.cyan);
  
  const postData = JSON.stringify(conflictData);
  
  const options = {
    hostname: urlParts.hostname,
    port: urlParts.port,
    path: urlParts.path,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      'Content-Length': Buffer.byteLength(postData)
    }
  };
  
  try {
    const response = await makeRequest(options, postData);
    
    log('✅', '收到响应', colors.green);
    log('📊', `Status Code: ${response.statusCode}`, colors.cyan);
    log('📦', `Response Body: ${JSON.stringify(response.data, null, 2)}`, colors.cyan);
    
    if ((response.statusCode === 200 || response.statusCode === 201) && response.data.success && response.data.data) {
      const conflictData = response.data.data;
      log('✅', `冲突分析成功！`, colors.green);
      log('📋', `冲突记录ID: ${conflictData.conflictId || '未知'}`, colors.cyan);
      log('📋', `发现冲突数: ${conflictData.conflicts?.length || 0}`, colors.cyan);
      log('📋', `安全组合数: ${conflictData.safeCombo?.length || 0}`, colors.cyan);
      
      if (conflictData.conflicts && conflictData.conflicts.length > 0) {
        log('⚠️', '检测到的冲突:', colors.yellow);
        conflictData.conflicts.forEach((conflict, index) => {
          log('🔴', `${index + 1}. ${conflict.components?.join(' + ') || '未知成分'} - ${conflict.severity || '未知'}风险`, colors.red);
          log('   ', `描述: ${conflict.description || '无'}`, colors.cyan);
        });
      }
      
      if (conflictData.recommendations) {
        log('💡', '使用建议:', colors.yellow);
        if (conflictData.recommendations.productPairings) {
          if (conflictData.recommendations.productPairings.cannotUseTogether) {
            log('🚫', '不能一起使用:', colors.red);
            conflictData.recommendations.productPairings.cannotUseTogether.forEach((item, index) => {
              log('   ', `${index + 1}. ${item.products?.join(' + ') || '未知产品'}`, colors.red);
              log('   ', `   原因: ${item.reason || '无'}`, colors.cyan);
            });
          }
          if (conflictData.recommendations.productPairings.canUseTogether) {
            log('✅', '可以一起使用:', colors.green);
            conflictData.recommendations.productPairings.canUseTogether.forEach((item, index) => {
              log('   ', `${index + 1}. ${item.products?.join(' + ') || '未知产品'}`, colors.green);
              log('   ', `   原因: ${item.reason || '无'}`, colors.cyan);
            });
          }
        }
      }
      
      return conflictData;
    } else {
      log('❌', `冲突分析失败: ${response.data.message || '未知错误'}`, colors.red);
      throw new Error(response.data.message || '冲突分析失败');
    }
  } catch (error) {
    log('❌', `冲突分析错误: ${error.message}`, colors.red);
    throw error;
  }
}

// 获取当前用户信息
async function getCurrentUser(token) {
  logSection('👤 获取当前用户信息');
  
  const url = `${BASE_URL}/users/me`;
  const urlParts = parseURL(url);
  
  log('📡', '发起获取用户信息请求', colors.blue);
  log('🔗', `URL: ${url}`, colors.cyan);
  log('📋', `Method: GET`, colors.cyan);
  
  const options = {
    hostname: urlParts.hostname,
    port: urlParts.port,
    path: urlParts.path,
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    }
  };
  
  try {
    const response = await makeRequest(options);
    
    log('✅', '收到响应', colors.green);
    log('📊', `Status Code: ${response.statusCode}`, colors.cyan);
    log('📦', `Response Body: ${JSON.stringify(response.data, null, 2)}`, colors.cyan);
    
    if (response.statusCode === 200 && response.data.success && response.data.data) {
      const user = response.data.data.user;
      log('✅', `获取用户信息成功！`, colors.green);
      log('📋', `用户ID: ${user._id || user.id}`, colors.cyan);
      log('📋', `用户名: ${user.name}`, colors.cyan);
      log('📋', `手机号: ${user.phone}`, colors.cyan);
      return user;
    } else {
      log('❌', `获取用户信息失败: ${response.data.message || '未知错误'}`, colors.red);
      throw new Error(response.data.message || '获取用户信息失败');
    }
  } catch (error) {
    log('❌', `获取用户信息错误: ${error.message}`, colors.red);
    throw error;
  }
}

// 主测试流程
async function runTests() {
  console.log(`\n${colors.bright}${colors.magenta}`);
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║    产品分析前后端交互测试脚本                              ║');
  console.log('║    测试账号: phone=15691887650, password=12345678          ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log(colors.reset);
  
  try {
    // 1. 登录
    const token = await login();
    
    // 2. 获取用户信息
    const user = await getCurrentUser(token);
    const userId = user._id || user.id;
    
    // 3. 创建产品
    const productId1 = await createProduct(token);
    
    // 4. 上传产品图片
    try {
      await uploadProductImage(token, productId1);
    } catch (error) {
      log('⚠️', `图片上传失败，继续测试: ${error.message}`, colors.yellow);
    }
    
    // 5. 提取产品成分
    try {
      await extractIngredients(token, productId1);
    } catch (error) {
      log('⚠️', `成分提取失败，继续测试: ${error.message}`, colors.yellow);
    }
    
    // 6. 分析产品成分
    try {
      await analyzeIngredients(token, productId1);
    } catch (error) {
      log('⚠️', `成分分析失败，继续测试: ${error.message}`, colors.yellow);
    }
    
    // 7. 创建第二个产品用于冲突检测
    const productId2 = await createProduct(token);
    
    // 8. 获取用户产品列表
    const products = await getUserProducts(token, userId);
    
    // 9. 如果有至少2个产品，进行冲突分析
    if (products.length >= 2) {
      const productIdsForConflict = products.slice(0, 2).map(p => p._id || p.id);
      await analyzeConflict(token, productIdsForConflict);
    } else {
      log('⚠️', '产品数量不足2个，跳过冲突分析测试', colors.yellow);
    }
    
    logSection('✅ 测试完成');
    log('🎉', '所有测试步骤执行完毕！', colors.green);
    
  } catch (error) {
    logSection('❌ 测试失败');
    log('❌', `测试过程中出现错误: ${error.message}`, colors.red);
    console.error(error);
    process.exit(1);
  }
}

// 运行测试
runTests();

