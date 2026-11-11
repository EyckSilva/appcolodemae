// Read-only audit. Reuses the Firebase CLI session; never prints/stores key strings or tokens.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const project = 'colo-de-mae-3510f';
const number = '4621666263';
const hash = value => crypto.createHash('sha256').update(value).digest('hex');
(async () => {
  const root = path.resolve(__dirname, '..');
  const cli = path.dirname(require.resolve('firebase-tools/package.json', {paths: [path.join(process.env.APPDATA, 'npm/node_modules'), root]}));
  const auth = require(path.join(cli, 'lib/auth.js'));
  const {requireAuth} = require(path.join(cli, 'lib/requireAuth.js'));
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw Error('Firebase CLI login required.');
  const options = {project, nonInteractive: true};
  auth.setActiveAccount(options, account);
  await requireAuth(options);
  const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  async function get(url) {
    const response = await fetch(url, {headers: {Authorization: `Bearer ${token.access_token}`}});
    const body = await response.json();
    if (!response.ok) return {httpStatus: response.status, errorCode: body.error?.status};
    return body;
  }
  const config = fs.readFileSync(path.join(root, 'lib/firebase_options.dart'), 'utf8');
  const local = [...config.matchAll(/static const FirebaseOptions (\w+) = FirebaseOptions\(\s*apiKey: '([^']+)'/g)]
    .map(m => ({platform: m[1], sha256: hash(m[2])}));
  const keys = [];
  let next = '';
  do {
    const list = await get(`https://apikeys.googleapis.com/v2/projects/${number}/locations/global/keys?pageSize=100${next ? '&pageToken='+encodeURIComponent(next) : ''}`);
    if (list.httpStatus) { keys.push(list); break; }
    for (const key of list.keys || []) {
      const value = await get(`https://apikeys.googleapis.com/v2/${key.name}/keyString`);
      const sha256 = value.keyString ? hash(value.keyString) : null;
      keys.push({name:key.name, displayName:key.displayName, sha256,
        platforms:local.filter(l => l.sha256 === sha256).map(l => l.platform),
        restrictions:key.restrictions || {}, createTime:key.createTime, updateTime:key.updateTime,
        keyStringReadError:value.httpStatus ? value : undefined});
    }
    next = list.nextPageToken || '';
  } while (next);
  const services = [];
  let page = '';
  do {
    const data = await get(`https://serviceusage.googleapis.com/v1/projects/${number}/services?filter=state:ENABLED&pageSize=200${page ? '&pageToken='+encodeURIComponent(page) : ''}`);
    if (data.httpStatus) { services.push(data); break; }
    services.push(...(data.services || []).map(s => s.config.name));
    page = data.nextPageToken || '';
  } while (page);
  const apps = [];
  for (const [platform, group] of [['web','webApps'],['android','androidApps'],['ios','iosApps']]) {
    const block = config.match(new RegExp(`static const FirebaseOptions ${platform} = FirebaseOptions\\(([\\s\\S]*?)\\);`))?.[1];
    const appId = block?.match(/appId: '([^']+)'/)?.[1];
    const app = await get(`https://firebase.googleapis.com/v1beta1/projects/${project}/${group}/${appId}`);
    apps.push({platform, appId, apiKeyId:app.apiKeyId, packageName:app.packageName, bundleId:app.bundleId,
      registered:app.name != null, errorCode:app.errorCode,
      localKeyMatches:keys.some(k => k.platforms?.includes(platform) && k.name?.endsWith('/'+app.apiKeyId))});
  }
  const output = path.join(root, 'data/security/google-key-restrictions.json');
  fs.mkdirSync(path.dirname(output), {recursive:true});
  fs.writeFileSync(output, JSON.stringify({project, queriedAt:new Date().toISOString(), readOnly:true, local, keys, apps, enabledServices:services}, null, 2)+'\n');
  console.log(JSON.stringify({report:'data/security/google-key-restrictions.json',
    apps, keys:keys.map(k=>({platforms:k.platforms, apiTargets:k.restrictions?.apiTargets?.length,
      restrictions:k.httpStatus ? k : Object.keys(k.restrictions || {})})),
    generativeLanguageEnabled:services.includes('generativelanguage.googleapis.com'),
    generativeLanguageAllowed:keys.some(k=>k.restrictions?.apiTargets?.some(t=>t.service==='generativelanguage.googleapis.com'))}, null, 2));
})().catch(() => { console.error('Read-only key audit failed; no credentials printed and no cloud changes made.'); process.exitCode=1; });
