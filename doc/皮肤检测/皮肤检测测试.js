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
  log.step('检查测试图片文件');
  
  if (!fs.existsSync(TEST_IMAGE_PATH)) {
    log.error(`测试图片不存在: ${TEST_IMAGE_PATH}`);
    process.exit(1);
  }
  
  const stats = fs.statSync(TEST_IMAGE_PATH);
  log.success(`找到测试图片: ${TEST_IMAGE_PATH}`);
  log.info(`图片大小: ${(stats.size / 1024).toFixed(2)} KB`);
  
  return true;
};

/**
 * 注册测试用户
 */
const registerTestUser = async () => {
  log.step('注册测试用户');
  
  try {
    const response = await axios.post(`${BASE_URL}/users/register`, testUser);
    
    if (response.data.success) {
      authToken = response.data.token;
      userId = response.data.data.user._id;
      log.success('用户注册成功');
      log.info(`用户ID: ${userId}`);
      log.info(`Token: ${authToken.substring(0, 20)}...`);
      return true;
    } else {
      log.error('用户注册失败: ' + response.data.message);
      return false;
    }
  } catch (error) {
    if (error.response?.status === 400 && error.response.data.message?.includes('已被注册')) {
      log.warning('用户已存在，尝试登录...');
      return await loginTestUser();
    }
    log.error('注册请求失败: ' + (error.response?.data?.message || error.message));
    return false;
  }
};

/**
 * 登录测试用户
 */
const loginTestUser = async () => {
  log.step('登录测试用户');
  
  try {
    const response = await axios.post(`${BASE_URL}/users/login`, {
      phone: testUser.phone,
      password: testUser.password
    });
    
    if (response.data.success) {
      authToken = response.data.token;
      userId = response.data.data.user._id;
      log.success('用户登录成功');
      log.info(`用户ID: ${userId}`);
      log.info(`Token: ${authToken.substring(0, 20)}...`);
      return true;
    } else {
      log.error('用户登录失败: ' + response.data.message);
      return false;
    }
  } catch (error) {
    log.error('登录请求失败: ' + (error.response?.data?.message || error.message));
    return false;
  }
};

/**
 * 测试图片上传到OSS并分析皮肤状态（快速JSON输出版本）
 */
const testSkinAnalysis = async () => {
  log.step('测试皮肤状态分析 (qwen2.5-vl-72b-instruct 模型)');
  
  try {
    // 创建表单数据
    const formData = new FormData();
    formData.append('faceImage', fs.createReadStream(TEST_IMAGE_PATH));
    
    log.info('开始上传图片并分析...');
    log.info('模型: qwen2.5-vl-72b-instruct (快速JSON响应)');
    
    const startTime = Date.now();
    
    // 发送分析请求
    const response = await axios.post(`${BASE_URL}/skin-analysis/analyze`, formData, {
      headers: {
        ...formData.getHeaders(),
        'Authorization': `Bearer ${authToken}`
      },
      timeout: 60000 // 1分钟超时（比之前的2分钟更短）
    });
    
    const endTime = Date.now();
    const duration = endTime - startTime;
    
    if (response.data.success) {
      log.success(`皮肤分析完成！耗时: ${duration}ms`);
      
      const data = response.data.data;
      
      // 以JSON格式输出完整结果
      log.json('完整分析结果 (JSON格式)', {
        analysisId: data.analysisId,
        imageUrl: data.imageUrl,
        model: data.analysisConfig.model,
        processingTime: data.analysisConfig.processingTime,
        analysisResults: {
          skinType: data.skinType,
          blackheads: data.blackheads,
          acne: data.acne,
          pores: data.pores,
          otherIssues: data.otherIssues,
          overallAssessment: data.overallAssessment
        }
      });
      
      // 快速总结输出
      console.log('\n' + '='.repeat(50).yellow);
      log.result(`模型: ${data.analysisConfig.model}`);
      log.result(`分析耗时: ${data.analysisConfig.processingTime}ms`);
      log.result(`皮肤类型: ${data.skinType.type} (${data.skinType.subtype})`);
      log.result(`健康评分: ${data.overallAssessment.healthScore}/100`);
      log.result(`皮肤状况: ${data.overallAssessment.skinCondition}`);
      console.log('='.repeat(50).yellow);
      
      return data.analysisId;
    } else {
      log.error('皮肤分析失败: ' + response.data.message);
      return null;
    }
  } catch (error) {
    log.error('分析请求失败: ' + (error.response?.data?.message || error.message));
    if (error.response?.data) {
      log.json('错误详情', error.response.data);
    }
    return null;
  }
};

/**
 * 测试获取分析历史（JSON格式输出）
 */
const testGetAnalysisHistory = async () => {
  log.step('测试获取分析历史');
  
  try {
    const response = await axios.get(`${BASE_URL}/skin-analysis`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
    
    if (response.data.success) {
      const analyses = response.data.data.analyses;
      const pagination = response.data.data.pagination;
      
      log.success(`获取到 ${analyses.length} 条分析记录`);
      
      // JSON格式输出历史记录
      log.json('分析历史记录', {
        totalRecords: pagination.total,
        currentPage: pagination.page,
        totalPages: pagination.pages,
        records: analyses.map(analysis => ({
          id: analysis._id,
          skinType: analysis.skinType.type,
          healthScore: analysis.overallAssessment.healthScore,
          skinCondition: analysis.overallAssessment.skinCondition,
          model: analysis.analysisConfig.model,
          createdAt: analysis.createdAt
        }))
      });
      
      return analyses.length > 0 ? analyses[0]._id : null;
    } else {
      log.error('获取分析历史失败: ' + response.data.message);
      return null;
    }
  } catch (error) {
    log.error('获取历史请求失败: ' + (error.response?.data?.message || error.message));
    return null;
  }
};

/**
 * 测试获取统计数据（JSON格式输出）
 */
const testGetStats = async () => {
  log.step('测试获取统计数据');
  
  try {
    const response = await axios.get(`${BASE_URL}/skin-analysis/stats`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
    
    if (response.data.success) {
      const stats = response.data.data.stats;
      log.success('获取统计数据成功');
      
      // JSON格式输出统计数据
      log.json('用户统计数据', stats);
      
    } else {
      log.error('获取统计数据失败: ' + response.data.message);
    }
  } catch (error) {
    log.error('获取统计请求失败: ' + (error.response?.data?.message || error.message));
  }
};

const testGetLatestAnalysis = async () => {
  log.step('测试获取最新分析');
  try {
    const response = await axios.get(`${BASE_URL}/skin-analysis/latest`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
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
    log.error('获取最新分析请求失败: ' + (error.response?.data?.message || error.message));
    return null;
  }
};

const testGetAnalysisDetailAndDelete = async (analysisId) => {
  log.step('测试分析详情与删除');
  try {
    const detailRes = await axios.get(`${BASE_URL}/skin-analysis/${analysisId}`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
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

    const delRes = await axios.delete(`${BASE_URL}/skin-analysis/${analysisId}`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
    if (delRes.data.success) {
      log.success('删除分析记录成功');
    } else {
      log.error('删除分析记录失败: ' + delRes.data.message);
    }
  } catch (error) {
    log.error('分析详情或删除请求失败: ' + (error.response?.data?.message || error.message));
  }
};

/**
 * 性能测试 - 多次分析测试
 */
const performanceTest = async () => {
  log.step('性能测试 - 连续分析测试');
  
  const testCount = 3;
  const results = [];
  
  for (let i = 1; i <= testCount; i++) {
    log.info(`执行第 ${i}/${testCount} 次分析...`);
    
    try {
      const formData = new FormData();
      formData.append('faceImage', fs.createReadStream(TEST_IMAGE_PATH));
      
      const startTime = Date.now();
      const response = await axios.post(`${BASE_URL}/skin-analysis/analyze`, formData, {
        headers: {
          ...formData.getHeaders(),
          'Authorization': `Bearer ${authToken}`
        },
        timeout: 60000
      });
      const endTime = Date.now();
      
      const duration = endTime - startTime;
      const processingTime = response.data.data.analysisConfig.processingTime;
      
      results.push({
        test: i,
        totalTime: duration,
        processingTime: processingTime,
        success: response.data.success
      });
      
      log.success(`第 ${i} 次分析完成，耗时: ${duration}ms`);
      
    } catch (error) {
      log.error(`第 ${i} 次分析失败: ${error.message}`);
      results.push({
        test: i,
        totalTime: 0,
        processingTime: 0,
        success: false,
        error: error.message
      });
    }
    
    await delay(2000); // 间隔2秒
  }
  
  // 性能统计
  const successCount = results.filter(r => r.success).length;
  const avgTime = results.filter(r => r.success).reduce((sum, r) => sum + r.totalTime, 0) / successCount || 0;
  const avgProcessingTime = results.filter(r => r.success).reduce((sum, r) => sum + r.processingTime, 0) / successCount || 0;
  
  log.json('性能测试结果', {
    totalTests: testCount,
    successCount: successCount,
    successRate: `${(successCount / testCount * 100).toFixed(1)}%`,
    averageTotalTime: `${avgTime.toFixed(0)}ms`,
    averageProcessingTime: `${avgProcessingTime.toFixed(0)}ms`,
    results: results
  });
};

/**
 * 主测试函数
 */
const runTests = async () => {
  console.log('🧪'.rainbow + ' AI皮肤分析功能测试 (qwen2.5-vl-72b-instruct)'.rainbow.bold);
  console.log('='.repeat(80).gray);
  
  try {
    // 1. 检查测试图片
    checkTestImage();
    
    // 2. 用户认证
    const authSuccess = await registerTestUser();
    if (!authSuccess) {
      log.error('用户认证失败，测试中止');
      return;
    }
    
    await delay(1000);
    
    // 3. 测试皮肤分析
    const analysisId = await testSkinAnalysis();
    
    await delay(2000);
    
    // 4. 测试获取分析历史
    const historyAnalysisId = await testGetAnalysisHistory();
    
    await delay(1000);
    
    // 5. 测试获取统计数据
    await testGetStats();
    
    await delay(1000);

    // 6. 测试获取最新分析
    const latestId = await testGetLatestAnalysis();
    
    await delay(1000);

    // 7. 测试分析详情与删除
    const targetId = historyAnalysisId || latestId;
    if (targetId) {
      await testGetAnalysisDetailAndDelete(targetId);
    } else {
      log.warning('未找到可用于详情/删除的分析ID');
    }
    
    await delay(1000);
    
    // 8. 性能测试
    await performanceTest();
    
    console.log('\n' + '='.repeat(80).gray);
    log.success('皮肤分析功能测试完成！');
    
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
  registerTestUser,
  loginTestUser,
  testSkinAnalysis,
  testGetAnalysisHistory,
  testGetStats,
  performanceTest
};