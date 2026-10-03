# HelpUS — atalhos. `make ajuda` lista tudo.
VERSAO ?=
NUMERO ?=
VERSAO_FLAGS := $(if $(VERSAO),--build-name=$(VERSAO)) $(if $(NUMERO),--build-number=$(NUMERO))

.PHONY: ajuda bootstrap prepare format lint test e2e e2e-web check run build-android build-ios build-web icones qr

ajuda: ## lista os comandos
	@grep -E '^[a-z0-9-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-14s %s\n", $$1, $$2}'

bootstrap: ## cria android/ ios/ web/ com permissões de GPS e câmera
	@bash scripts/bootstrap.sh
	@$(MAKE) prepare

prepare: ## dependências + hook de pre-commit
	flutter pub get
	git config core.hooksPath .githooks 2>/dev/null || true

format: ## formata
	dart format .

lint: ## analisador
	flutter analyze

test: ## unitários + tela + acessibilidade
	flutter test

e2e: ## ponta a ponta num aparelho/emulador
	flutter test integration_test

e2e-web: build-web ## axe-core, árvore ARIA, leitor virtual e teclado no navegador
	cd acessibilidade-web && npm install && npx playwright install chromium && npm test

check: ## o que o pre-commit roda
	dart format --output=none --set-exit-if-changed .
	flutter analyze
	flutter test

run: ## roda o app
	flutter run

build-android: ## .apk + .aab
	flutter build apk --release $(VERSAO_FLAGS)
	flutter build appbundle --release $(VERSAO_FLAGS)

build-ios: ## iOS sem assinatura
	flutter build ios --release --no-codesign $(VERSAO_FLAGS)

build-web: ## site em build/web, com CanvasKit incluído (roda sem CDN)
	flutter build web --release --no-web-resources-cdn $(VERSAO_FLAGS)

icones: ## PNG do logo a partir do SVG
	python3 scripts/gerar_icones.py

qr: ## QR code de cada evento em docs/qr/
	python3 scripts/gerar_qr_eventos.py
