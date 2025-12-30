const axios = require('axios');

const BASE = 'https://www.lunzo.site/api';
const PHONE = '15691887650';
const PASSWORD = '12345678';

let token = null;
let planId = null;
let userId = null;
let analysisId = null;

// 打印分隔线
function printSeparator(title) {
    console.log('\n' + '='.repeat(60));
    console.log(`  ${title}`);
    console.log('='.repeat(60) + '\n');
}

// 打印请求信息
function printRequest(method, url, headers = {}, body = null) {
    console.log(`📡 ${method} ${url}`);
    console.log('📦 Headers:', JSON.stringify(headers, null, 2));
    if (body) {
        console.log('📋 Request Body:', JSON.stringify(body, null, 2));
    }
}

// 打印响应信息
function printResponse(status, data) {
    console.log(`✅ Response Status: ${status}`);
    console.log('📦 Response Body:', JSON.stringify(data, null, 2));
}

// 打印错误信息
function printError(error) {
    const status = error.response ? error.response.status : 0;
    const data = error.response ? error.response.data : { message: error.message };
    console.log(`❌ Error Status: ${status}`);
    console.log('📦 Error Body:', JSON.stringify(data, null, 2));
}

async function pingHome() {
    printSeparator('1. 测试站点连通性');
    try {
        const res = await axios.get('https://www.lunzo.site/');
        printRequest('GET', 'https://www.lunzo.site/');
        printResponse(res.status, { message: 'Site is reachable' });
        return { step: 'home', status: res.status, success: true };
    } catch (err) {
        printError(err);
        return { step: 'home', status: err.response?.status || 0, success: false };
    }
}

async function unauthorizedMe() {
    printSeparator('2. 测试未授权访问');
    try {
        await axios.get(`${BASE}/users/me`);
    } catch (err) {
        const status = err.response ? err.response.status : 0;
        printRequest('GET', `${BASE}/users/me`);
        printError(err);
        return { step: 'me_unauth', status, success: status === 401 };
    }
}

async function login() {
    printSeparator('3. 用户登录');
    try {
        const body = { phone: PHONE, password: PASSWORD };
        printRequest('POST', `${BASE}/users/login`, {}, body);
        
        const res = await axios.post(`${BASE}/users/login`, body);
        token = res.data.token;
        userId = res.data.data.user._id;
        
        printResponse(res.status, {
            tokenPrefix: token.slice(0, 16) + '...',
            userId: userId,
            userName: res.data.data.user.name
        });
        
        return { step: 'login', status: res.status, tokenPrefix: token.slice(0, 16), userId, success: true };
    } catch (err) {
        printError(err);
        return { step: 'login', status: err.response?.status || 0, success: false };
    }
}

function authHeaders() {
    return { Authorization: `Bearer ${token}` };
}

async function me() {
    printSeparator('4. 获取当前用户信息');
    try {
        const headers = authHeaders();
        printRequest('GET', `${BASE}/users/me`, headers);
        
        const res = await axios.get(`${BASE}/users/me`, { headers });
        printResponse(res.status, {
            userId: res.data.data.user._id,
            phone: res.data.data.user.phone,
            name: res.data.data.user.name
        });
        
        return { step: 'me', status: res.status, user: res.data.data.user, success: true };
    } catch (err) {
        printError(err);
        return { step: 'me', status: err.response?.status || 0, success: false };
    }
}

async function stats() {
    printSeparator('5. 获取用户统计数据');
    try {
        const headers = authHeaders();
        printRequest('GET', `${BASE}/users/stats`, headers);
        
        const res = await axios.get(`${BASE}/users/stats`, { headers });
        printResponse(res.status, res.data);
        
        return { step: 'stats', status: res.status, data: res.data, success: true };
    } catch (err) {
        printError(err);
        return { step: 'stats', status: err.response?.status || 0, success: false };
    }
}

async function getLatestSkinAnalysis() {
    printSeparator('6. 获取最新皮肤分析');
    try {
        const headers = authHeaders();
        printRequest('GET', `${BASE}/skin-analysis/latest`, headers);
        
        const res = await axios.get(`${BASE}/skin-analysis/latest`, { headers });
        
        if (res.data.success && res.data.data?.analysis) {
            const analysis = res.data.data.analysis;
            analysisId = analysis._id;
            printResponse(res.status, {
                analysisId: analysis._id,
                healthScore: analysis.overallAssessment?.healthScore,
                skinType: analysis.skinType?.type,
                skinCondition: analysis.overallAssessment?.skinCondition,
                createdAt: analysis.createdAt
            });
            return { step: 'get_latest_analysis', status: res.status, analysis: analysis, success: true };
        } else {
            printResponse(res.status, { message: 'No analysis found' });
            return { step: 'get_latest_analysis', status: res.status, success: false, message: 'No analysis found' };
        }
    } catch (err) {
        if (err.response?.status === 404) {
            printResponse(404, { message: 'No analysis found' });
            return { step: 'get_latest_analysis', status: 404, success: false, message: 'No analysis found' };
        }
        printError(err);
        return { step: 'get_latest_analysis', status: err.response?.status || 0, success: false };
    }
}

async function generatePlan() {
    printSeparator('7. 生成个性化护肤方案');
    try {
        const body = {
            requirement: '修护屏障并淡化痘印',
            skinConcerns: ['痘痘', '痘印', '敏感'],
            customRequirements: '尽量使用已有产品',
            age: 26
        };
        const headers = { ...authHeaders(), 'Content-Type': 'application/json' };
        printRequest('POST', `${BASE}/plans`, headers, body);
        
        const res = await axios.post(`${BASE}/plans`, body, { headers });
        planId = res.data.data.plan._id;
        const name = res.data.data.plan.name;
        const morningLen = (res.data.data.plan.morning || []).length;
        const eveningLen = (res.data.data.plan.evening || []).length;
        
        printResponse(res.status, {
            planId: planId,
            name: name,
            morningSteps: morningLen,
            eveningSteps: eveningLen,
            recommendations: res.data.data.plan.recommendations?.length || 0
        });
        
        return {
            step: 'generate_plan',
            status: res.status,
            id: planId,
            name,
            morningLen,
            eveningLen,
            success: true
        };
    } catch (err) {
        printError(err);
        return { step: 'generate_plan', status: err.response?.status || 0, success: false };
    }
}

async function listPlans() {
    printSeparator('8. 获取用户所有护肤方案列表');
    try {
        const headers = authHeaders();
        printRequest('GET', `${BASE}/plans`, headers);
        
        const res = await axios.get(`${BASE}/plans`, { headers });
        const count = res.data.count;
        const firstId = res.data.data.plans[0]?._id;
        
        printResponse(res.status, {
            count: count,
            firstPlanId: firstId,
            plans: res.data.data.plans.map(p => ({
                id: p._id,
                name: p.name,
                createdAt: p.createdAt
            }))
        });
        
        if (!planId && firstId) planId = firstId;
        
        return { step: 'list_plans', status: res.status, count, firstId, success: true };
    } catch (err) {
        printError(err);
        return { step: 'list_plans', status: err.response?.status || 0, success: false };
    }
}

async function patchStep() {
    printSeparator('9. 更新方案步骤完成状态');
    try {
        if (!planId) {
            console.log('⚠️ 没有可用的方案ID，跳过此步骤');
            return { step: 'patch_step', status: 0, success: false, message: 'No plan ID' };
        }
        
        const body = { period: 'morning', step: 1, completed: true };
        const headers = { ...authHeaders(), 'Content-Type': 'application/json' };
        printRequest('PATCH', `${BASE}/plans/${planId}/step`, headers, body);
        
        const res = await axios.patch(`${BASE}/plans/${planId}/step`, body, { headers });
        
        printResponse(res.status, {
            success: res.data.success,
            planId: planId,
            updatedStep: body
        });
        
        return { step: 'patch_step', status: res.status, success: res.data.success, success: true };
    } catch (err) {
        printError(err);
        return { step: 'patch_step', status: err.response?.status || 0, success: false };
    }
}

async function getPlan() {
    printSeparator('10. 获取单个方案详情');
    try {
        if (!planId) {
            console.log('⚠️ 没有可用的方案ID，跳过此步骤');
            return { step: 'get_plan', status: 0, success: false, message: 'No plan ID' };
        }
        
        const headers = authHeaders();
        printRequest('GET', `${BASE}/plans/${planId}`, headers);
        
        const res = await axios.get(`${BASE}/plans/${planId}`, { headers });
        const morningFirst = res.data.data.plan.morning && res.data.data.plan.morning[0];
        
        printResponse(res.status, {
            planId: res.data.data.plan._id,
            name: res.data.data.plan.name,
            morningFirstStep: morningFirst,
            morningSteps: res.data.data.plan.morning?.length || 0,
            eveningSteps: res.data.data.plan.evening?.length || 0
        });
        
        return {
            step: 'get_plan',
            status: res.status,
            id: res.data.data.plan._id,
            morningFirst,
            success: true
        };
    } catch (err) {
        printError(err);
        return { step: 'get_plan', status: err.response?.status || 0, success: false };
    }
}

async function createCustom() {
    printSeparator('11. 创建自定义护肤方案');
    try {
        const body = {
            name: '自定义修护方案X',
            requirement: '敏感修护',
            skinConcerns: ['敏感'],
            customRequirements: '只用已有产品',
            userAge: 26,
            userGender: 'female',
            morning: [
                { step: 1, product: '控油炭爽净亮洁面膏', reason: '温和清洁', completed: false }
            ],
            evening: [
                { step: 1, product: '雅诗兰黛特润修护肌透精华露', reason: '修护保湿', completed: false }
            ],
            recommendations: ['避免高浓度酸'],
            skinAnalysisSummary: '近期轻度敏感',
            tags: ['敏感肌']
        };
        const headers = { ...authHeaders(), 'Content-Type': 'application/json' };
        printRequest('POST', `${BASE}/plans/custom`, headers, body);
        
        const res = await axios.post(`${BASE}/plans/custom`, body, { headers });
        
        printResponse(res.status, {
            planId: res.data.data.plan._id,
            name: res.data.data.plan.name,
            createdAt: res.data.data.plan.createdAt
        });
        
        return {
            step: 'create_custom',
            status: res.status,
            id: res.data.data.plan._id,
            name: res.data.data.plan.name,
            success: true
        };
    } catch (err) {
        printError(err);
        return { step: 'create_custom', status: err.response?.status || 0, success: false };
    }
}

async function run() {
    console.log('\n\n');
    console.log('╔════════════════════════════════════════════════════════════╗');
    console.log('║    个性化护肤方案完整功能测试                              ║');
    console.log('║    测试账号: ' + PHONE.padEnd(45) + '║');
    console.log('╚════════════════════════════════════════════════════════════╝');
    console.log('\n');
    
    const results = [];
    
    try {
        // 基础连通性测试
        results.push(await pingHome());
        results.push(await unauthorizedMe());
        
        // 认证流程
        const loginResult = await login();
        results.push(loginResult);
        
        if (!loginResult.success) {
            console.log('\n❌ 登录失败，无法继续测试');
            return;
        }
        
        // 用户信息
        results.push(await me());
        results.push(await stats());
        
        // 皮肤分析
        results.push(await getLatestSkinAnalysis());
        
        // 方案生成（如果失败则尝试获取已有方案）
        const planResult = await generatePlan();
        results.push(planResult);
        
        if (!planResult.success) {
            console.log('\n⚠️ 生成方案失败，尝试获取已有方案列表...');
            await listPlans();
        }
        
        // 方案管理
        results.push(await listPlans());
        results.push(await patchStep());
        results.push(await getPlan());
        results.push(await createCustom());
        
        // 测试总结
        printSeparator('测试总结');
        const successCount = results.filter(r => r.success).length;
        const totalCount = results.length;
        
        console.log(`✅ 成功: ${successCount}/${totalCount}`);
        console.log(`❌ 失败: ${totalCount - successCount}/${totalCount}`);
        console.log('\n详细结果:');
        results.forEach((r, index) => {
            const icon = r.success ? '✅' : '❌';
            console.log(`  ${icon} ${r.step}: ${r.status} ${r.success ? '(成功)' : '(失败)'}`);
        });
        
    } catch (e) {
        printSeparator('测试异常');
        const status = e.response ? e.response.status : 0;
        const data = e.response ? e.response.data : { message: e.message };
        printError(e);
        console.log('\n❌ 测试过程中发生异常，已终止');
        process.exit(1);
    }
}

run();

