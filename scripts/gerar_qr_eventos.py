"""Gera o QR code oficial de cada evento de assets/dados/eventos.json.

    pip install qrcode[pil]
    python3 scripts/gerar_qr_eventos.py

A organização imprime e cola na entrada do evento. Embaixo do QR vai o
número escrito, para quem não consegue usar a câmera digitar no app.
"""
import json
from pathlib import Path

import qrcode

raiz = Path(__file__).resolve().parent.parent
eventos = json.loads((raiz / "assets/dados/eventos.json").read_text(encoding="utf-8"))
saida = raiz / "docs/qr"
saida.mkdir(parents=True, exist_ok=True)

for e in eventos:
    conteudo = json.dumps(
        {"helpus": "evento", "id": e["id"], "nome": e["nome"], "cidade": e["cidade"], "whatsapp": e["whatsappCentral"]},
        ensure_ascii=False,
        separators=(",", ":"),
    )
    qrcode.make(conteudo, box_size=10, border=4).save(saida / f"{e['id']}.png")
    print(f"• docs/qr/{e['id']}.png")

qrcode.make("https://wa.me/5548999990002", box_size=10, border=4).save(saida / "contato-exemplo.png")
print("• docs/qr/contato-exemplo.png")
