"""Gera os PNG do logo a partir de assets/logo/helpus-logo.svg.

    pip install cairosvg
    python3 scripts/gerar_icones.py
"""
from pathlib import Path

import cairosvg

raiz = Path(__file__).resolve().parent.parent
svg = raiz / "assets/logo/helpus-logo.svg"
saida = raiz / "assets/logo"

for tamanho in (1024, 512, 192, 48):
    destino = saida / f"helpus-logo-{tamanho}.png"
    cairosvg.svg2png(url=str(svg), write_to=str(destino), output_width=tamanho)
    print(f"• {destino.relative_to(raiz)}")

web = raiz / "web"
if web.is_dir():
    cairosvg.svg2png(url=str(svg), write_to=str(web / "favicon.png"), output_width=48)
    for tamanho in (192, 512):
        cairosvg.svg2png(url=str(svg), write_to=str(web / f"icons/Icon-{tamanho}.png"), output_width=tamanho)
        cairosvg.svg2png(url=str(svg), write_to=str(web / f"icons/Icon-maskable-{tamanho}.png"), output_width=tamanho)
    print("• ícones de web/ atualizados")
