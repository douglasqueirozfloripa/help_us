"""Ajusta android/, ios/ e web/ para o HelpUS. Pode rodar mais de uma vez."""
from pathlib import Path
import re

raiz = Path(__file__).resolve().parent.parent
NOME = "HelpUS"


def ajustar(caminho: Path, funcao):
    if not caminho.exists():
        print(f"• {caminho.relative_to(raiz)} não existe, pulei")
        return
    antes = caminho.read_text(encoding="utf-8")
    depois = funcao(antes)
    if depois != antes:
        caminho.write_text(depois, encoding="utf-8")
        print(f"• {caminho.relative_to(raiz)} ajustado")


def android(xml: str) -> str:
    xml = re.sub(r'android:label="[^"]*"', f'android:label="{NOME}"', xml, count=1)
    permissoes = [
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.ACCESS_COARSE_LOCATION",
        "android.permission.CAMERA",
    ]
    novas = "".join(
        f'    <uses-permission android:name="{p}" />\n' for p in permissoes if p not in xml
    )
    if novas:
        xml = re.sub(r"\n[ \t]*<application", "\n" + novas + "    <application", xml, count=1)
    if "android.intent.action.SENDTO" not in xml:
        consultas = """
        <!-- url_launcher (Android 11+): abrir WhatsApp/links, SMS e ligação -->
        <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="https" /></intent>
        <intent><action android:name="android.intent.action.SENDTO" /><data android:scheme="sms" /></intent>
        <intent><action android:name="android.intent.action.DIAL" /><data android:scheme="tel" /></intent>
        <package android:name="com.whatsapp" />
        <package android:name="com.whatsapp.w4b" />"""
        if "<queries>" in xml:
            xml = xml.replace("<queries>", "<queries>" + consultas, 1)
        else:
            xml = xml.replace("</manifest>", f"    <queries>{consultas}\n    </queries>\n</manifest>", 1)
    return xml


def ios(plist: str) -> str:
    entradas = {
        "CFBundleDisplayName": f"<string>{NOME}</string>",
        "NSLocationWhenInUseUsageDescription":
            "<string>Sua localização vai junto no pedido de ajuda, para quem for te socorrer saber onde você está.</string>",
        "NSCameraUsageDescription":
            "<string>A câmera lê o QR code do evento ou de um contato.</string>",
        "LSApplicationQueriesSchemes":
            "<array><string>whatsapp</string><string>https</string><string>sms</string><string>tel</string></array>",
    }
    for chave, valor in entradas.items():
        padrao = re.compile(rf"<key>{chave}</key>\s*(<string>.*?</string>|<array>.*?</array>)", re.S)
        if padrao.search(plist):
            plist = padrao.sub(f"<key>{chave}</key>\n\t{valor}", plist, count=1)
        else:
            plist = plist.replace("</dict>\n</plist>", f"\t<key>{chave}</key>\n\t{valor}\n</dict>\n</plist>", 1)
    return plist


def web(html: str) -> str:
    html = re.sub(r"<html[^>]*>", '<html lang="pt-BR">', html, count=1)
    return re.sub(r"<title>.*?</title>", f"<title>{NOME}</title>", html, count=1)


ajustar(raiz / "android/app/src/main/AndroidManifest.xml", android)
ajustar(raiz / "ios/Runner/Info.plist", ios)
ajustar(raiz / "web/index.html", web)
print("Pronto.")
