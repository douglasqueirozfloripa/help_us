#!/usr/bin/env bash
# Cria android/, ios/ e web/ sem tocar em lib/, pubspec.yaml e testes,
# e já configura permissões de GPS e câmera, idioma e nome do app.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v flutter >/dev/null || { echo "Flutter não encontrado. Veja o README." >&2; exit 1; }

temporario="$(mktemp -d)"
trap 'rm -rf "$temporario"' EXIT
flutter create --platforms=android,ios,web --org br.org.garapuvu --project-name helpus "$temporario/app" >/dev/null

for pasta in android ios web; do
  if [ -d "$pasta" ]; then echo "• $pasta/ já existe, mantida."; else cp -R "$temporario/app/$pasta" "$pasta"; echo "• $pasta/ criada."; fi
done

python3 scripts/configurar_plataformas.py
