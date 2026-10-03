// Servidor estático mínimo para ../build/web (sem dependências).
// Antes de servir, gera o build se ele não existe ou é mais velho que o código:
// assim qualquer "npm run test..." testa o app de agora, sem passo manual.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const porta = Number(process.argv[2] || 8091);
const app = path.resolve(__dirname, '..');
const raiz = path.join(app, 'build', 'web');
const tipos = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png',
  '.svg': 'image/svg+xml', '.css': 'text/css', '.otf': 'font/otf', '.ttf': 'font/ttf',
};

/** Data de alteração mais recente dentro de `caminho` (0 se não existe). */
function maisRecente(caminho) {
  if (!fs.existsSync(caminho)) return 0;
  const info = fs.statSync(caminho);
  if (!info.isDirectory()) return info.mtimeMs;
  return fs.readdirSync(caminho).reduce((max, nome) => Math.max(max, maisRecente(path.join(caminho, nome))), 0);
}

function garantirBuild() {
  const build = maisRecente(path.join(raiz, 'main.dart.js'));
  const codigo = Math.max(...['lib', 'assets', 'web', 'pubspec.yaml', 'pubspec.lock'].map((c) => maisRecente(path.join(app, c))));
  if (build > codigo) return;

  // stderr: é o que o Playwright mostra com o prefixo [WebServer].
  console.error(build ? 'build/web está desatualizado. Gerando de novo…' : 'build/web não existe. Gerando…');
  const r = spawnSync('make', ['build-web'], { cwd: app, stdio: ['ignore', 2, 2] });
  if (r.error || r.status !== 0 || !fs.existsSync(path.join(raiz, 'index.html'))) {
    console.error(`Não foi possível gerar o build (${r.error?.message ?? `saída ${r.status}`}). Rode "make build-web" na pasta do app e veja o erro.`);
    process.exit(1);
  }
}

garantirBuild();

http.createServer((req, res) => {
  const caminho = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let arquivo = path.join(raiz, caminho);
  if (!arquivo.startsWith(raiz)) { res.writeHead(403).end(); return; }
  if (!fs.existsSync(arquivo) || fs.statSync(arquivo).isDirectory()) arquivo = path.join(raiz, 'index.html');
  res.writeHead(200, { 'Content-Type': tipos[path.extname(arquivo)] || 'application/octet-stream' });
  fs.createReadStream(arquivo).pipe(res);
}).listen(porta, '127.0.0.1', () => console.log(`Servindo build/web em http://127.0.0.1:${porta}`));
