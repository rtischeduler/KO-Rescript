import sys
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "EditedScripts"
OUT = ROOT / "build"
MODEL = "KO-Rescript.rbxmx"

SERVICES = {
    "ReplicatedStorage": [SRC / "BeamCombat" / "ReplicatedStorage", SRC / "ReplicatedStorage"],
    "ServerScriptService": [SRC / "BeamCombat" / "ServerScriptService", SRC / "ServerScriptService"],
    "StarterGui": [SRC / "BeamCombat" / "StarterGui", SRC / "StarterGui"],
    "StarterPlayer": [SRC / "StarterPlayer"],
    "Migration": [SRC / "Migration"],
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
            return {"class": class_name, "name": path.name, "source": init.read_text(), "children": children}
        return {"class": "Folder", "name": path.name, "source": None, "children": children}
    class_name, name = classify(path.name)
    return {"class": class_name, "name": name, "source": path.read_text(), "children": []}


def merge(parent, node):
    for existing in parent["children"]:
        if existing["name"] == node["name"]:
            if existing["class"] == "Folder" and node["class"] == "Folder":
                for child in node["children"]:
                    merge(existing, child)
                return
            raise SystemExit(f"collision: {node['name']}")
    parent["children"].append(node)


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


def main():
    root = {"class": "Folder", "name": "KO-Rescript", "source": None, "children": []}
    for service, dirs in SERVICES.items():
        folder = {"class": "Folder", "name": service, "source": None, "children": []}
        for d in dirs:
            if not d.is_dir():
                continue
            for child in sorted(d.iterdir()):
                if child.is_dir() or child.suffix == ".lua":
                    merge(folder, build_node(child))
        root["children"].append(folder)
    counter = [0]
    lines = ['<roblox version="4">']
    lines.extend(emit(root, counter, 1))
    lines.append("</roblox>")
    OUT.mkdir(exist_ok=True)
    (OUT / MODEL).write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{MODEL}: {counter[0]} instances")
    return 0


sys.exit(main())
