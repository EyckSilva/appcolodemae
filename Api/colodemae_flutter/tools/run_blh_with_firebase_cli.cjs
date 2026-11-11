// Conveniência local: Firebase CLI autenticado -> token efêmero -> Admin SDK.
// Não grava credenciais, não altera o login e não imprime tokens.
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');

(async () => {
  const args = process.argv.slice(2);
  const publication = args[0] === '--publication';
  if (publication) args.shift();
  const demas = args[0] === '--demas';
  if (demas) args.shift();
  const projectIndex = args.indexOf('--project');
  if (projectIndex < 0 || !args[projectIndex + 1]) throw Error('Informe --project explicitamente.');
  const project = args[projectIndex + 1];
  const workspace = path.resolve(__dirname, '..');
  const python = process.env.BLH_PYTHON || path.join(workspace, '.venv-blh', process.platform === 'win32' ? 'Scripts/python.exe' : 'bin/python');
  if (!fs.existsSync(python)) throw Error('Prepare .venv-blh com tools/requirements-blh.txt antes de executar.');
  const globalModules = process.env.APPDATA ? path.join(process.env.APPDATA, 'npm/node_modules') : '';
  const cliRoot = path.dirname(require.resolve('firebase-tools/package.json', { paths: [globalModules, workspace] }));
  const auth = require(path.join(cliRoot, 'lib/auth.js'));
  const { requireAuth } = require(path.join(cliRoot, 'lib/requireAuth.js'));
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw Error('Execute firebase login antes de usar este helper.');
  const options = { project, nonInteractive: true };
  auth.setActiveAccount(options, account);
  await requireAuth(options);
  const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  if (!token?.access_token) throw Error('Não foi possível obter autenticação temporária.');
  const child = spawn(python, [path.join(__dirname, publication ? 'publish_blh.py' : demas ? 'demas_blh.py' : 'import_blh.py'), ...args, '--firebase-cli-auth'], {
    cwd: workspace,
    env: { ...process.env, BLH_FIREBASE_ACCESS_TOKEN: token.access_token, PYTHONUTF8: '1' },
    stdio: 'inherit', windowsHide: true,
  });
  child.on('error', error => { console.error(error.message); process.exitCode = 1; });
  child.on('exit', code => { process.exitCode = code ?? 1; });
})().catch(error => { console.error(error.message); process.exitCode = 1; });
