#!/usr/bin/env python3
import sys, json, subprocess, time

BASE = (1, 3, 6, 1, 4, 1, 99999, 1)   # private subtree, change if you like
# command whose stdout is the JSON to expose, taken from this script's args
# (e.g. `pass_persist <OID> snmp-sysmon.py /usr/local/bin/python3 /root/system-monitor.py`)
CMD = sys.argv[1:]
if not CMD:
    sys.exit(
        f"error: no command given\n"
        f"usage: {sys.argv[0]} <command> [args...]\n"
        f"\n"
        f"<command> is run on each refresh and must print a JSON object to stdout;\n"
        f"its values are exposed under OID .{'.'.join(map(str, BASE))}.\n"
        f"\n"
        f"example snmpd.conf entry:\n"
        f"  pass_persist .{'.'.join(map(str, BASE))} {sys.argv[0]} /usr/local/bin/python3 /root/system-monitor.py"
    )
CACHE_TTL = 10                         # seconds; a walk hits many OIDs

_cache = {"t": 0, "table": {}}

def flatten(obj, prefix=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            yield from flatten(v, f"{prefix}.{k}" if prefix else str(k))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from flatten(v, f"{prefix}.{i}")
    elif obj is not None:              # nulls are skipped
        yield prefix, obj

def typed(v):
    if isinstance(v, bool):
        return "integer", str(int(v))
    if isinstance(v, int):
        return "integer", str(v)
    return "string", str(v)            # floats/strings: SNMP has no float type

def build():
    out = subprocess.run(CMD, capture_output=True, text=True, timeout=20).stdout
    items = sorted(flatten(json.loads(out)), key=lambda x: x[0])
    table = {BASE + (0,): ("integer", str(len(items)))}
    for i, (path, val) in enumerate(items, 1):
        t, v = typed(val)
        table[BASE + (1, i)] = ("string", path)          # name by index
        table[BASE + (2, i)] = (t, v)                    # value by index
        name = tuple([len(path)] + [ord(c) for c in path])
        table[BASE + (3,) + name] = (t, v)               # value by name (stable)
    return table

def get_table():
    if time.time() - _cache["t"] > CACHE_TTL:
        try:
            _cache["table"] = build()
        except Exception:
            pass                       # keep last good data
        _cache["t"] = time.time()
    return _cache["table"]

def parse(s):
    return tuple(int(x) for x in s.strip().strip(".").split(".") if x)

def reply(oid, t, v):
    sys.stdout.write("." + ".".join(map(str, oid)) + f"\n{t}\n{v}\n")

def main():
    while True:
        line = sys.stdin.readline()
        if not line:
            break
        cmd = line.strip()
        if cmd == "PING":
            sys.stdout.write("PONG\n")
        elif cmd in ("get", "getnext"):
            oid = parse(sys.stdin.readline())
            table = get_table()
            if cmd == "get":
                key = oid if oid in table else None
            else:
                key = next((k for k in sorted(table) if k > oid), None)
            if key is None:
                sys.stdout.write("NONE\n")
            else:
                reply(key, *table[key])
        elif cmd == "set":
            sys.stdin.readline(); sys.stdin.readline()
            sys.stdout.write("not-writable\n")
        sys.stdout.flush()

main()
