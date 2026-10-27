import sys
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "EditedScripts"
OUT = ROOT / "build"

TARGETS = {
    "Shared.rbxmx": [
        SRC / "ReplicatedStorage" / "Shared",
    ],
    "Server.rbxmx": [
        SRC / "ServerScriptService" / "Server",
    ],
    "BeamCombat.rbxmx": [
        SRC / "BeamCombat",
    ],
    "Client.rbxmx": [
        SRC / "StarterPlayer" / "StarterPlayerScripts" / "Client",
        SRC / "StarterPlayer" / "StarterPlayerScripts" / "RbxCharacterSounds.client.lua",
    ],
}

INIT_NAMES = ("init.lua", "init.server.lua", "init.client.lua")


def classify(filename):
    if filename.endswith(".client.lua"):
        return "LocalScript", filename[: -len(".client.lua")]
    if filename.endswith(".server.lua"):
        return "Script", filename[: -len(".server.lua")]
    return "ModuleScript", filename[: -len(".lua")]


def build_node(path):
    if path.is_dir():
        init = next((path / n for n in INIT_NAMES if (path / n).is_file()), None)
        children = [
            build_node(child)
            for child in sorted(path.iterdir())
            if child != init and (child.is_dir() or child.suffix == ".lua")
        ]
        if init:
            class_name, _ = classify(init.name)
            return {
                "class": class_name,
                "name": path.name,
                "source": init.read_text(),
                "children": children,
            }
        return {"class": "Folder", "name": path.name, "source": None, "children": children}
    class_name, name = classify(path.name)
    return {"class": class_name, "name": name, "source": path.read_text(), "children": []}


def cdata(text):
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


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


def build_file(filename, paths):
    counter = [0]
    lines = ['<roblox version="4">']
    for path in paths:
        if not path.exists():
            raise SystemExit(f"missing source: {path}")
        lines.extend(emit(build_node(path), counter, 1))
    lines.append("</roblox>")
    OUT.mkdir(exist_ok=True)
    (OUT / filename).write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{filename}: {counter[0]} instances")


def main():
    for filename, paths in TARGETS.items():
        build_file(filename, paths)
    return 0


sys.exit(main())
