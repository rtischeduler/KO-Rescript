import sys
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "EditedScripts"
OUT = ROOT / "build"
MODEL = "KO-Rescript.rbxmx"

FILES = [
    (SRC / "ServerScriptService" / "Server" / "init.server.lua", "Server", "Script", ["ServerScriptService"]),
    (SRC / "ServerScriptService" / "Server" / "Services" / "IndicatorService.lua", "IndicatorService", "ModuleScript", ["ServerScriptService", "Server", "Services"]),
    (SRC / "BeamCombat" / "ServerScriptService" / "framework" / "modules" / "Combat.lua", "Combat", "ModuleScript", ["ServerScriptService", "framework", "modules"]),
    (SRC / "BeamCombat" / "ServerScriptService" / "framework" / "modules" / "World.lua", "World", "ModuleScript", ["ServerScriptService", "framework", "modules"]),
    (SRC / "BeamCombat" / "ReplicatedStorage" / "BeamSystem.lua", "BeamSystem", "ModuleScript", ["ReplicatedStorage"]),
    (SRC / "BeamCombat" / "ReplicatedStorage" / "DPSTemplate.server.lua", "DPSTemplate", "Script", ["ReplicatedStorage"]),
    (SRC / "ReplicatedStorage" / "PlayerScripts" / "Control" / "init.client.lua", "Control", "LocalScript", ["ReplicatedStorage", "PlayerScripts"]),
    (SRC / "StarterPlayer" / "StarterPlayerScripts" / "Client" / "init.client.lua", "Client", "LocalScript", ["StarterPlayer", "StarterPlayerScripts"]),
    (SRC / "StarterPlayer" / "StarterPlayerScripts" / "Client" / "Controllers" / "Indicators.lua", "Indicators", "ModuleScript", ["StarterPlayer", "StarterPlayerScripts", "Client", "Controllers"]),
]


def cdata(text):
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def folder(name):
    return {"class": "Folder", "name": name, "source": None, "children": []}


def emit(node, counter, depth):
    pad = "\t" * depth
    counter[0] += 1
    lines = [f'{pad}<Item class="{node["class"]}" referent="RBX{counter[0]}">', f"{pad}\t<Properties>"]
    lines.append(f'{pad}\t\t<string name="Name">{escape(node["name"])}</string>')
    if node["class"] == "Script":
        lines.append(f'{pad}\t\t<token name="RunContext">0</token>')
    if node["source"] is not None:
        lines.append(f'{pad}\t\t<ProtectedString name="Source">{cdata(node["source"])}</ProtectedString>')
    lines.append(f"{pad}\t</Properties>")
    for child in node["children"]:
        lines.extend(emit(child, counter, depth + 1))
    lines.append(f"{pad}</Item>")
    return lines


def main():
    root = folder("KO-Rescript")
    for path, name, class_name, parents in FILES:
        if not path.is_file():
            raise SystemExit(f"missing source: {path}")
        cursor = root
        for part in parents:
            nxt = next((c for c in cursor["children"] if c["name"] == part), None)
            if nxt is None:
                nxt = folder(part)
                cursor["children"].append(nxt)
            cursor = nxt
        existing = next((c for c in cursor["children"] if c["name"] == name), None)
        if existing is not None:
            existing["class"] = class_name
            existing["source"] = path.read_text()
        else:
            cursor["children"].append({"class": class_name, "name": name, "source": path.read_text(), "children": []})
    counter = [0]
    lines = ['<roblox version="4">']
    lines.extend(emit(root, counter, 1))
    lines.append("</roblox>")
    OUT.mkdir(exist_ok=True)
    (OUT / MODEL).write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{MODEL}: {counter[0]} instances")
    return 0


sys.exit(main())
