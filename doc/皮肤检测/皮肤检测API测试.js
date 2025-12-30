require('dotenv').config();
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
const colors = require('colors');

const BASE_URL = process.env.API_BASE_URL || 'https://www.lunzo.site/api';
const TEST_IMAGE_PATH = path.join(__dirname, 'face.jpg');

const testUser = {
  name: '测试用户',
  phone: '15691887650',
  password: '12345678',
  gender: 'female'
};

let authToken = '';
let userId = '';

/**
 * 输出带颜色的日志
 */
const log = {
  info: (msg) => console.log('ℹ️'.blue + ' ' + msg),
  success: (msg) => console.log('✅'.green + ' ' + msg.green),
  error: (msg) => console.log('❌'.red + ' ' + msg.red),
  warning: (msg) => console.log('⚠️'.yellow + ' ' + msg.yellow),
  step: (msg) => console.log('\n' + '🚀'.cyan + ' ' + msg.cyan.bold),
  result: (msg) => console.log('📋'.magenta + ' ' + msg.magenta),
  json: (msg, obj) => {
    console.log('📄'.blue + ' ' + msg.blue.bold);
    console.log(JSON.stringify(obj, null, 2).gray);
  },
  request: (method, url, headers, body) => {
    console.log('\n' + '='.repeat(80).cyan);
    console.log('📤'.cyan.bold + ' API请求'.cyan.bold);
    console.log('='.repeat(80).cyan);
    console.log('🔗 Method:'.yellow, method);
    console.log('🌐 URL:'.yellow, url);
    console.log('📦 Headers:'.yellow);
    Object.keys(headers).forEach(key => {
      const value = key === 'Authorization' ? headers[key].substring(0, 30) + '...' : headers[key];
      console.log(`   ${key}: ${value}`);
    });
    if (body) {
      console.log('📤 Request Body:'.yellow);
      if (typeof body === 'string') {
        console.log(body.substring(0, 500) + (body.length > 500 ? '...' : ''));
      } else {
        console.log(JSON.stringify(body, null, 2).substring(0, 500));
      }
    }
    console.log('='.repeat(80).cyan);
  },
  response: (statusCode, headers, body, duration) => {
    console.log('\n' + '='.repeat(80).green);
    console.log('📥'.green.bold + ' API响应'.green.bold);
    console.log('='.repeat(80).green);
    console.log('📊 Status Code:'.yellow, statusCode.toString().cyan);
    console.log('⏱️  耗时:'.yellow, `${duration}ms`.cyan);
    console.log('📦 Response Headers:'.yellow);
    Object.keys(headers).forEach(key => {
      console.log(`   ${key}: ${headers[key]}`);
    });
    console.log('📥 Response Body:'.yellow);
    if (typeof body === 'string') {
      try {
        const parsed = JSON.parse(body);
        console.log(JSON.stringify(parsed, null, 2));
      } catch {
        console.log(body.substring(0, 1000) + (body.length > 1000 ? '...' : ''));
      }
    } else {
      console.log(JSON.stringify(body, null, 2));
    }
    console.log('='.repeat(80).green);
  }
};

/**
 * 延迟函数
 */
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

/**
 * 检查图片文件是否存在
 */
const checkTestImage = () => {
  log.step('步骤 1: 检查测试图片文件');
  
  if (!fs.existsSync(TEST_IMAGE_PATH)) {
    log.error(`测试图片不存在: ${TEST_IMAGE_PATH}`);
    log.warning('请将测试图片命名为 face.jpg 并放在 doc 目录下');
    return false;
  }
  
  const stats = fs.statSync(TEST_IMAGE_PATH);
  log.success(`找到测试图片: ${TEST_IMAGE_PATH}`);
  log.info(`图片大小: ${(stats.size / 1024).toFixed(2)} KB`);
  
  return true;
};

/**
 * 登录测试用户
 */
const loginTestUser = async () => {
  log.step('步骤 2: 用户登录');
  
  const loginData = {
    phone: testUser.phone,
    password: testUser.password
  };
  
  const headers = {
    'Content-Type': 'application/json'
  };
  
  log.request('POST', `${BASE_URL}/users/login`, headers, loginData);
  
  const startTime = Date.now();
  
  try {
    const response = await axios.post(`${BASE_URL}/users/login`, loginData, { headers });
    const duration = Date.now() - startTime;
    
    log.response(response.status, response.headers, JSON.stringify(response.data), duration);
    
    if (response.data.success) {
      authToken = response.data.token;
      userId = response.data.data.user._id;
      log.success('用户登录成功');
      log.info(`用户ID: ${userId}`);
      log.info(`Token: ${authToken.substring(0, 30)}...`);
      return true;
    } else {
      log.error('用户登录失败: ' + response.data.message);
      return false;
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    log.response(
      error.response?.status || 'ERROR',
      error.response?.headers || {},
      error.response?.data || error.message,
      duration
    );
    log.error('登录请求失败: ' + (error.response?.data?.message || error.message));
    return false;
  }
};

/**
 * 测试图片上传到OSS并分析皮肤状态
 */
const testSkinAnalysis = async () => {
  log.step('步骤 3: 皮肤状态分析');
  
  try {
    // 创建表单数据
    const formData = new FormData();
    formData.append('faceImage', fs.createReadStream(TEST_IMAGE_PATH));
    
    const headers = {
      ...formData.getHeaders(),
      'Authorization': `Bearer ${authToken}`
    };
    
    log.request('POST', `${BASE_URL}/skin-analysis/analyze`, headers, `[文件上传: ${TEST_IMAGE_PATH}]`);
    log.info('开始上传图片并分析...');
    log.info('模型: qwen2.5-vl-72b-instruct');
    
    const startTime = Date.now();
    
    // 发送分析请求
    const response = await axios.post(`${BASE_URL}/skin-analysis/analyze`, formData, {
      headers: headers,
      timeout: 120000 // 2分钟超时
    });
    
    const endTime = Date.now();
    const duration = endTime - startTime;
    
    log.response(response.status, response.headers, JSON.stringify(response.data), duration);
    
    if (response.data.success) {
      log.success(`皮肤分析完成！耗时: ${duration}ms`);
      
      const data = response.data.data;
      
      // 详细输出分析结果
      log.json('完整分析结果', {
        analysisId: data.analysisId || data._id,
        imageUrl: data.imageUrl,
        model: data.analysisConfig?.model,
        processingTime: data.analysisConfig?.processingTime,
        healthScore: data.overallAssessment?.healthScore,
        skinCondition: data.overallAssessment?.skinCondition,
        skinType: data.skinType?.type,
        recommendations: data.overallAssessment?.recommendations
      });
      
      // 快速总结输出
      console.log('\n' + '='.repeat(50).yellow);
      log.result(`模型: ${data.analysisConfig?.model || '未知'}`);
      log.result(`分析耗时: ${data.analysisConfig?.processingTime || duration}ms`);
      log.result(`皮肤类型: ${data.skinType?.type || '未知'} ${data.skinType?.subtype ? `(${data.skinType.subtype})` : ''}`);
      log.result(`健康评分: ${data.overallAssessment?.healthScore || 0}/100`);
      log.result(`皮肤状况: ${data.overallAssessment?.skinCondition || '未知'}`);
      console.log('='.repeat(50).yellow);
      
      return data.analysisId || data._id;
    } else {
      log.error('皮肤分析失败: ' + response.data.message);
      return null;
    }
  } catch (error) {
    const duration = Date.now() - (Date.now());
    log.response(
      error.response?.status || 'ERROR',
      error.response?.headers || {},
      error.response?.data || error.message,
      duration
    );
    log.error('分析请求失败: ' + (error.response?.data?.message || error.message));
    if (error.response?.data) {
      log.json('错误详情', error.response.data);
    }
    return null;
  }
};

/**
 * 测试获取分析历史
 */
const testGetAnalysisHistory = async () => {
  log.step('步骤 4: 获取分析历史');
  
  const headers = {
    'Authorization': `Bearer ${authToken}`
  };
  
  log.request('GET', `${BASE_URL}/skin-analysis?page=1&limit=10`, headers);
  
  const startTime = Date.now();
  
  try {
    const response = await axios.get(`${BASE_URL}/skin-analysis`, {
      headers: headers,
      params: { page: 1, limit: 10 }
    });
    
    const duration = Date.now() - startTime;
    log.response(response.status, response.headers, JSON.stringify(response.data), duration);
    
    if (response.data.success) {
      const analyses = response.data.data.analyses;
      const pagination = response.data.data.pagination;
      
      log.success(`获取到 ${analyses.length} 条分析记录`);
      
      // JSON格式输出历史记录
      log.json('分析历史记录', {
        totalRecords: pagination?.total || 0,
        currentPage: pagination?.page || 1,
        totalPages: pagination?.pages || 0,
        records: analyses.map(analysis => ({
          id: analysis._id,
          skinType: analysis.skinType?.type,
          healthScore: analysis.overallAssessment?.healthScore,
          skinCondition: analysis.overallAssessment?.skinCondition,
          model: analysis.analysisConfig?.model,
          createdAt: analysis.createdAt
        }))
      });
      
      return analyses.length > 0 ? analyses[0]._id : null;
    } else {
      log.error('获取分析历史失败: ' + response.data.message);
      return null;
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    log.response(
      error.response?.status || 'ERROR',
      error.response?.headers || {},
      error.response?.data || error.message,
      duration
    );
    log.error('获取历史请求失败: ' + (error.response?.data?.message || error.message));
    return null;
  }
};

/**
 * 测试获取统计数据
 */
const testGetStats = async () => {
  log.step('步骤 5: 获取统计数据');
  
  const headers = {
    'Authorization': `Bearer ${authToken}`
  };
  
  log.request('GET', `${BASE_URL}/skin-analysis/stats`, headers);
  
  const startTime = Date.now();
  
  try {
    const response = await axios.get(`${BASE_URL}/skin-analysis/stats`, {
      headers: headers
    });
    
    const duration = Date.now() - startTime;
    log.response(response.status, response.headers, JSON.stringify(response.data), duration);
    
    if (response.data.success) {
      const stats = response.data.data.stats;
      log.success('获取统计数据成功');
      
      // JSON格式输出统计数据
      log.json('用户统计数据', stats);
      
    } else {
      log.error('获取统计数据失败: ' + response.data.message);
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    log.response(
      error.response?.status || 'ERROR',
      error.response?.headers || {},
      error.response?.data || error.message,
      duration
    );
    log.error('获取统计请求失败: ' + (error.response?.data?.message || error.message));
  }
};

/**
 * 测试获取最新分析
 */
const testGetLatestAnalysis = async () => {
  log.step('步骤 6: 获取最新分析');
  
  const headers = {
    'Authorization': `Bearer ${authToken}`
  };
  
  log.request('GET', `${BASE_URL}/skin-analysis/latest`, headers);
  
  const startTime = Date.now();
  
  try {
    const response = await axios.get(`${BASE_URL}/skin-analysis/latest`, {
      headers: headers
    });
    
    const duration = Date.now() - startTime;
    log.response(response.status, response.headers, JSON.stringify(response.data), duration);
    
    if (response.data.success) {
      const latest = response.data.data.analysis;
      log.success('获取最新分析成功');
      log.json('最新分析摘要', {
        id: latest._id,
        skinType: latest.skinType?.type,
        healthScore: latest.overallAssessment?.healthScore,
        createdAt: latest.createdAt
      });
      return latest._id;
    } else {
      log.error('获取最新分析失败: ' + response.data.message);
      return null;
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    log.response(
      error.response?.status || 'ERROR',
      error.response?.headers || {},
      error.response?.data || error.message,
      duration
    );
    log.error('获取最新分析请求失败: ' + (error.response?.data?.message || error.message));
    return null;
  }
};

/**
 * 测试分析详情与删除
 */
const testGetAnalysisDetailAndDelete = async (analysisId) => {
  log.step('步骤 7: 分析详情与删除');
  
  const headers = {
    'Authorization': `Bearer ${authToken}`
  };
  
  // 获取详情
  log.request('GET', `${BASE_URL}/skin-analysis/${analysisId}`, headers);
  const startTime1 = Date.now();
  
  try {
    const detailRes = await axios.get(`${BASE_URL}/skin-analysis/${analysisId}`, {
      headers: headers
    });
    
    const duration1 = Date.now() - startTime1;
    log.response(detailRes.status, detailRes.headers, JSON.stringify(detailRes.data), duration1);
    
    if (detailRes.data.success) {
      const analysis = detailRes.data.data.analysis;
      log.success('获取分析详情成功');
      log.json('分析详情摘要', {
        id: analysis._id,
        model: analysis.analysisConfig?.model,
        skinType: analysis.skinType?.type,
        healthScore: analysis.overallAssessment?.healthScore
      });
    } else {
      log.error('获取分析详情失败: ' + detailRes.data.message);
    }
  } catch (error) {
    const duration1 = Date.now() - startTime1;
    log.response(
      error.response?.status || 'ERROR',
      error.response?.headers || {},
      error.response?.data || error.message,
      duration1
    );
    log.error('获取分析详情失败: ' + (error.response?.data?.message || error.message));
  }

  // 删除分析
  log.request('DELETE', `${BASE_URL}/skin-analysis/${analysisId}`, headers);
  const startTime2 = Date.now();
  
  try {
    const delRes = await axios.delete(`${BASE_URL}/skin-analysis/${analysisId}`, {
      headers: headers
    });
    
    const duration2 = Date.now() - startTime2;
    log.response(delRes.status, delRes.headers, JSON.stringify(delRes.data), duration2);
    
    if (delRes.data.success) {
      log.success('删除分析记录成功');
    } else {
      log.error('删除分析记录失败: ' + delRes.data.message);
    }
  } catch (error) {
    const duration2 = Date.now() - startTime2;
    log.response(
      error.response?.status || 'ERROR',
      error.response?.headers || {},
      error.response?.data || error.message,
      duration2
    );
    log.error('删除分析记录失败: ' + (error.response?.data?.message || error.message));
  }
};

/**
 * 主测试函数
 */
const runTests = async () => {
  console.log('\n' + '🧪'.rainbow + ' AI皮肤分析功能完整测试'.rainbow.bold);
  console.log('='.repeat(80).gray);
  console.log('📱 测试账号:'.yellow, `${testUser.phone}`.cyan);
  console.log('🌐 API地址:'.yellow, `${BASE_URL}`.cyan);
  console.log('='.repeat(80).gray);
  
  try {
    // 1. 检查测试图片
    if (!checkTestImage()) {
      log.warning('跳过图片分析测试，继续其他测试...');
    }
    
    await delay(1000);
    
    // 2. 用户登录
    const authSuccess = await loginTestUser();
    if (!authSuccess) {
      log.error('用户认证失败，测试中止');
      return;
    }
    
    await delay(1000);
    
    // 3. 测试皮肤分析（如果有图片）
    let analysisId = null;
    if (fs.existsSync(TEST_IMAGE_PATH)) {
      analysisId = await testSkinAnalysis();
      await delay(2000);
    } else {
      log.warning('未找到测试图片，跳过分析测试');
    }
    
    // 4. 测试获取分析历史
    const historyAnalysisId = await testGetAnalysisHistory();
    await delay(1000);
    
    // 5. 测试获取统计数据
    await testGetStats();
    await delay(1000);

    // 6. 测试获取最新分析
    const latestId = await testGetLatestAnalysis();
    await delay(1000);

    // 7. 测试分析详情与删除（使用历史记录ID或最新ID）
    const targetId = historyAnalysisId || latestId || analysisId;
    if (targetId) {
      await testGetAnalysisDetailAndDelete(targetId);
    } else {
      log.warning('未找到可用于详情/删除的分析ID');
    }
    
    console.log('\n' + '='.repeat(80).gray);
    log.success('皮肤分析功能测试完成！');
    console.log('='.repeat(80).gray);
    
  } catch (error) {
    console.log('\n' + '='.repeat(80).gray);
    log.error('测试过程中发生未处理的错误: ' + error.message);
    console.error(error);
  }
};

// 运行测试
if (require.main === module) {
  runTests();
}

module.exports = {
  runTests,
  checkTestImage,
  loginTestUser,
  testSkinAnalysis,
  testGetAnalysisHistory,
  testGetStats,
  testGetLatestAnalysis,
  testGetAnalysisDetailAndDelete
};

