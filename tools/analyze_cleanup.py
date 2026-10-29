import glob
import io
import json
import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

EVENT_CLASSES = {"RemoteEvent", "RemoteFunction", "UnreliableRemoteEvent", "BindableEvent", "BindableFunction"}
SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}
RUNNING_ROOTS = {
    "Workspace", "ServerScriptService", "StarterPlayer", "StarterGui", "StarterPack",
    "ReplicatedFirst", "Players", "Chat", "TextChatService",
}
WANTED = {"Name", "Disabled", "RunContext", "Source", "Value"}
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
STRING = re.compile(r'"((?:[^"\\\n]|\\.)*)"|\'((?:[^\'\\\n]|\\.)*)\'')
SPLIT = re.compile(r"[./\\]")


class Concat(io.RawIOBase):
    def __init__(self, paths):
        self.paths = list(paths)
        self.cur = None

    def readable(self):
        return True

    def readinto(self, buf):
        while True:
            if self.cur is None:
                if not self.paths:
                    return 0
                self.cur = open(self.paths.pop(0), "rb")
            data = self.cur.read(len(buf))
            if data:
                buf[: len(data)] = data
                return len(data)
            self.cur.close()
            self.cur = None


def open_place(arg):
    if Path(arg).is_file():
        return open(arg, "rb")
    parts = sorted(glob.glob(arg + ".part*"))
    if not parts:
        raise SystemExit(f"no place file at {arg}")
    return io.BufferedReader(Concat(parts), 1 << 20)


def parse(stream):
    items = {}
    stack = []
    for event, el in ET.iterparse(stream, events=("start", "end")):
        tag = el.tag
        if event == "start":
            if tag == "Item":
                node = {"class": el.get("class"), "ref": el.get("referent"), "name": "", "props": {}, "parent": stack[-1] if stack else None}
                stack.append(node)
            continue
        if tag == "Properties" and stack:
            node = stack[-1]
            for p in el:
                pname = p.get("name")
                if pname in WANTED:
                    node["props"][pname] = p.text or ""
                    if pname == "Name":
                        node["name"] = p.text or ""
            el.clear()
        elif tag == "Item":
            node = stack.pop()
            if node["ref"]:
                items[node["ref"]] = node
            el.clear()
    return items


def path_of(node):
    names = []
    cur = node
    while cur is not None:
        names.append(cur["name"])
        cur = cur["parent"]
    return "/".join(reversed(names))


def ancestors(node):
    cur = node["parent"]
    while cur is not None:
        yield cur
        cur = cur["parent"]


def tokens(source):
    found = set(IDENT.findall(source))
    for m in STRING.finditer(source):
        text = m.group(1) if m.group(1) is not None else m.group(2)
        if not text or len(text) > 200:
            continue
        found.add(text)
        for piece in SPLIT.split(text):
            if piece:
                found.add(piece)
    return found


def main():
    place, outdir = sys.argv[1], Path(sys.argv[2])
    outdir.mkdir(parents=True, exist_ok=True)
    items = parse(open_place(place))

    scripts, events, linked = [], [], set()
    for node in items.values():
        cls = node["class"]
        if cls in SCRIPT_CLASSES:
            scripts.append(node)
        elif cls in EVENT_CLASSES:
            events.append(node)
        elif cls == "ObjectValue":
            target = items.get(node["props"].get("Value", "").strip())
            if target:
                linked.add(target["ref"])

    index = defaultdict(set)
    loaders = set()
    iterators = set()
    for s in scripts:
        source = s["props"].get("Source", "")
        s["paths"] = path_of(s)
        s["tokens"] = tokens(source)
        for t in s["tokens"]:
            index[t].add(s["ref"])
        if "GetChildren" in source or "GetDescendants" in source:
            iterators.add(s["ref"])
        if "require" in source and ("GetChildren" in source or "GetDescendants" in source):
            loaders.add(s["ref"])

    def referrers(node):
        refs = index.get(node["name"], set()) - {node["ref"]}
        return sorted(path_of(items[r]) for r in refs)

    def dynamic(node):
        for a in ancestors(node):
            if a["ref"] in loaders:
                return True
            if a["class"] in SCRIPT_CLASSES or a["parent"] is None:
                continue
            if index.get(a["name"], set()) & loaders - {a["ref"]}:
                return True
        return False

    def running_container(node):
        root = path_of(node).split("/")[0]
        cls = node["class"]
        if root in RUNNING_ROOTS:
            return True
        if root == "ReplicatedStorage" and cls == "Script" and node["props"].get("RunContext", "0").strip() != "0":
            return True
        return False

    def flag_disabled(node):
        return node["props"].get("Disabled", "false").strip() == "true"

    def dynamic_event(node):
        for a in ancestors(node):
            if a["parent"] is None:
                continue
            if index.get(a["name"], set()) & iterators:
                return True
        return False

    events_out = []
    dead_events = []
    dynamic_events = []
    for e in sorted(events, key=path_of):
        refs = referrers(e)
        row = {"path": path_of(e), "class": e["class"], "referenced_by": refs[:10], "reference_count": len(refs)}
        events_out.append(row)
        if not refs and e["ref"] not in linked:
            (dynamic_events if dynamic_event(e) else dead_events).append(row["path"])

    modules_dead, modules_dynamic, scripts_dead, scripts_empty = [], [], [], []
    for s in sorted(scripts, key=lambda n: n["paths"]):
        source = s["props"].get("Source", "")
        refs = referrers(s)
        used = bool(refs) or s["ref"] in linked
        if s["class"] == "ModuleScript":
            if used:
                continue
            (modules_dynamic if dynamic(s) else modules_dead).append(s["paths"])
        else:
            running = running_container(s) and not flag_disabled(s)
            if not running and not used:
                reason = "disabled" if flag_disabled(s) else "sits in a container where it never runs"
                scripts_dead.append({"path": s["paths"], "class": s["class"], "reason": reason})
            elif running and not source.strip() and not used:
                scripts_empty.append(s["paths"])

    trees = defaultdict(int)
    for x in scripts_dead:
        trees["/".join(x["path"].split("/")[:2])] += 1
    dead_trees = []
    for tree, count in sorted(trees.items(), key=lambda kv: -kv[1]):
        name = tree.split("/")[-1]
        outside = sorted(path_of(items[r]) for r in index.get(name, set()) if not path_of(items[r]).startswith(tree + "/"))
        dead_trees.append({"path": tree, "scripts_inside": count, "name_referenced_by": outside[:5]})

    (outdir / "events.json").write_text(json.dumps({"count": len(events_out), "events": events_out}, indent=2), encoding="utf-8")

    report = {
        "totals": {
            "scripts": len(scripts),
            "events": len(events),
            "modules_never_required": len(modules_dead),
            "modules_maybe_loaded_dynamically": len(modules_dynamic),
            "scripts_that_never_run": len(scripts_dead),
            "empty_running_scripts": len(scripts_empty),
            "events_never_referenced": len(dead_events),
            "events_maybe_fired_dynamically": len(dynamic_events),
            "unused_trees_holding_dead_scripts": len(dead_trees),
        },
        "safe_to_delete": {
            "events_never_referenced": dead_events,
            "modules_never_required": modules_dead,
            "scripts_that_never_run": scripts_dead,
            "trees_holding_dead_scripts": dead_trees,
            "empty_running_scripts": scripts_empty,
        },
        "check_before_deleting": {"modules_maybe_loaded_dynamically": modules_dynamic, "events_maybe_fired_dynamically": dynamic_events},
    }
    (outdir / "cleanup-report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    lines = ["# Cleanup report", "", "Names are matched against every script's identifiers and string literals. Anything below has no match anywhere.", ""]
    for key, value in report["totals"].items():
        lines.append(f"- {key.replace('_', ' ')}: {value}")
    sections = [
        ("Events never referenced", dead_events),
        ("ModuleScripts never required", modules_dead),
        ("Trees holding scripts that never run", [f"{t['path']} ({t['scripts_inside']} dead scripts, referenced by: {', '.join(t['name_referenced_by']) or 'nothing'})" for t in dead_trees]),
        ("Scripts that never run", [f"{x['path']} ({x['class']}, {x['reason']})" for x in scripts_dead]),
        ("Empty running scripts", scripts_empty),
        ("Modules maybe loaded dynamically (check first)", modules_dynamic),
        ("Events maybe fired dynamically (check first)", dynamic_events),
    ]
    for title, rows in sections:
        lines += ["", f"## {title} ({len(rows)})", ""]
        counts = {}
        for r in rows:
            counts[r] = counts.get(r, 0) + 1
        lines += [f"- `{r}`" + (f" x{n}" if n > 1 else "") for r, n in counts.items()] or ["- none"]
    (outdir / "CLEANUP.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps(report["totals"]))


main()
