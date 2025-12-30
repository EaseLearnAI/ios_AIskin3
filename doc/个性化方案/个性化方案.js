const axios = require('axios');

const BASE = 'https://www.lunzo.site/api';
const PHONE = '15691887650';
const PASSWORD = '12345678';

let token = null;
let planId = null;
let userId = null;

async function pingHome() {
  const res = await axios.get('https://www.lunzo.site/');
  console.log(JSON.stringify({ step: 'home', status: res.status }));
}

async function unauthorizedMe() {
  try {
    await axios.get(`${BASE}/users/me`);
  } catch (err) {
    const status = err.response ? err.response.status : 0;
    console.log(JSON.stringify({ step: 'me_unauth', status }));
  }
}

async function login() {
  const res = await axios.post(`${BASE}/users/login`, { phone: PHONE, password: PASSWORD });
  token = res.data.token;
  userId = res.data.data.user._id;
  console.log(JSON.stringify({ step: 'login', status: res.status, tokenPrefix: token.slice(0,16), userId }));
}

function authHeaders() {
  return { Authorization: `Bearer ${token}` };
}

async function me() {
  const res = await axios.get(`${BASE}/users/me`, { headers: authHeaders() });
  console.log(JSON.stringify({ step: 'me', status: res.status, user: res.data.data.user }));
}

async function stats() {
  const res = await axios.get(`${BASE}/users/stats`, { headers: authHeaders() });
  console.log(JSON.stringify({ step: 'stats', status: res.status, data: res.data }));
}

async function generatePlan() {
  const body = { requirement: '修护屏障并淡化痘印', skinConcerns: ['痘痘','痘印','敏感'], customRequirements: '尽量使用已有产品', age: 26 };
  const res = await axios.post(`${BASE}/plans`, body, { headers: { ...authHeaders(), 'Content-Type': 'application/json' } });
  planId = res.data.data.plan._id;
  const name = res.data.data.plan.name;
  const morningLen = (res.data.data.plan.morning || []).length;
  const eveningLen = (res.data.data.plan.evening || []).length;
  console.log(JSON.stringify({ step: 'generate_plan', status: res.status, id: planId, name, morningLen, eveningLen }));
}

async function listPlans() {
  const res = await axios.get(`${BASE}/plans`, { headers: authHeaders() });
  const count = res.data.count;
  const firstId = res.data.data.plans[0]?._id;
  console.log(JSON.stringify({ step: 'list_plans', status: res.status, count, firstId }));
  if (!planId && firstId) planId = firstId;
}

async function patchStep() {
  const body = { period: 'morning', step: 1, completed: true };
  const res = await axios.patch(`${BASE}/plans/${planId}/step`, body, { headers: { ...authHeaders(), 'Content-Type': 'application/json' } });
  console.log(JSON.stringify({ step: 'patch_step', status: res.status, success: res.data.success }));
}

async function getPlan() {
  const res = await axios.get(`${BASE}/plans/${planId}`, { headers: authHeaders() });
  const morningFirst = res.data.data.plan.morning && res.data.data.plan.morning[0];
  console.log(JSON.stringify({ step: 'get_plan', status: res.status, id: res.data.data.plan._id, morningFirst }));
}

async function createCustom() {
  const body = { name: '自定义修护方案X', requirement: '敏感修护', skinConcerns: ['敏感'], customRequirements: '只用已有产品', userAge: 26, userGender: 'female', morning: [{ step: 1, product: '控油炭爽净亮洁面膏', reason: '温和清洁', completed: false }], evening: [{ step: 1, product: '雅诗兰黛特润修护肌透精华露', reason: '修护保湿', completed: false }], recommendations: ['避免高浓度酸'], skinAnalysisSummary: '近期轻度敏感', tags: ['敏感肌'] };
  const res = await axios.post(`${BASE}/plans/custom`, body, { headers: { ...authHeaders(), 'Content-Type': 'application/json' } });
  console.log(JSON.stringify({ step: 'create_custom', status: res.status, id: res.data.data.plan._id, name: res.data.data.plan.name }));
}

async function run() {
  try {
    await pingHome();
    await unauthorizedMe();
    await login();
    await me();
    await stats();
    await generatePlan().catch(async () => { await listPlans(); });
    await listPlans();
    await patchStep();
    await getPlan();
    await createCustom();
  } catch (e) {
    const status = e.response ? e.response.status : 0;
    const data = e.response ? e.response.data : { message: e.message };
    console.log(JSON.stringify({ step: 'error', status, data }));
    process.exit(1);
  }
}

run();