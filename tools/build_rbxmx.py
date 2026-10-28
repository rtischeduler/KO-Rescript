import sys
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "EditedScripts"
OUT = ROOT / "build"
MODEL = sys.argv[2] if len(sys.argv) > 2 else "KO-Rescript.rbxmx"

SKIP_TOP = {"tests", "Migration"}
STRIP_TOP = {"BeamCombat"}


def cdata(text):
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def folder(name):
    return {"class": "Folder", "name": name, "source": None, "children": []}


def classify(filename):
    if filename.endswith(".server.lua"):
        return filename[: -len(".server.lua")], "Script"
    if filename.endswith(".client.lua"):
        return filename[: -len(".client.lua")], "LocalScript"
    return filename[: -len(".lua")], "ModuleScript"


def child(parent, name):
    found = next((c for c in parent["children"] if c["name"] == name), None)
    if found is None:
        found = folder(name)
        parent["children"].append(found)
    return found


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
    for sub in node["children"]:
        lines.extend(emit(sub, counter, depth + 1))
    lines.append(f"{pad}</Item>")
    return lines


def main():
    root = folder("KO-Rescript")
    manifest = ROOT / "tools" / (sys.argv[1] if len(sys.argv) > 1 else "model_files.txt")
    names = [l.strip() for l in manifest.read_text(encoding="utf-8").splitlines() if l.strip()]
    files = []
    for rel in names:
        path = SRC / rel
        if not path.is_file():
            raise SystemExit(f"missing source: {path}")
        files.append(path)
    count = 0
    for path in files:
        parts = list(path.relative_to(SRC).parts)
        if parts[0] in SKIP_TOP:
            continue
        if parts[0] in STRIP_TOP:
            parts = parts[1:]
        name, class_name = classify(parts[-1])
        cursor = root
        for part in parts[:-1]:
            cursor = child(cursor, part)
        source = path.read_text(encoding="utf-8")
        if name == "init":
            cursor["class"] = class_name
            cursor["source"] = source
        else:
            node = child(cursor, name)
            node["class"] = class_name
            node["source"] = source
        count += 1
    counter = [0]
    lines = ['<roblox version="4">']
    lines.extend(emit(root, counter, 1))
    lines.append("</roblox>")
    OUT.mkdir(exist_ok=True)
    (OUT / MODEL).write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{MODEL}: {count} scripts, {counter[0]} instances")
    return 0


sys.exit(main())
