// @ts-check
// Todo teste grava vídeo com a legenda do cenário BDD, em videos/<projeto>/.
// Os de leitor de tela também levam a voz do NVDA simulado (macOS).
const { defineConfig, devices } = require('@playwright/test');

const PORTA = 8091;
// Continente Shopping, São José/SC
const GPS = { latitude: -27.585531, longitude: -48.614722, accuracy: 12 };
// Espera antes de cada clique, tecla e navegação, no ritmo de uma pessoa
// (npm run test:ao-vivo usa 1500 ms). Padrão: sem espera.
const SLOW_MO = Number(process.env.SLOW_MO || 0);

const CELULAR = devices['Pixel 7'];
const COMPUTADOR = devices['Desktop Chrome'];

module.exports = defineConfig({
  testDir: './testes',
  // Os cenários de leitor de tela esperam cada frase ser falada: são longos de propósito.
  timeout: 5 * 60_000,
  expect: { timeout: 15_000 },
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: process.env.BASE_URL || `http://127.0.0.1:${PORTA}`,
    locale: 'pt-BR',
    geolocation: GPS,
    permissions: ['geolocation'],
    launchOptions: { slowMo: SLOW_MO },
    trace: 'retain-on-failure',
  },
  projects: [
    { name: 'celular', use: { ...CELULAR, video: { mode: 'on', size: CELULAR.viewport } } },
    { name: 'computador', use: { ...COMPUTADOR, video: { mode: 'on', size: COMPUTADOR.viewport } } },
  ],
  webServer: process.env.BASE_URL
    ? undefined
    : {
        command: `node servidor.js ${PORTA}`,
        url: `http://127.0.0.1:${PORTA}`,
        reuseExistingServer: true,
        // O servidor gera o build do Flutter quando precisa; isso leva alguns minutos.
        timeout: 300_000,
      },
});
