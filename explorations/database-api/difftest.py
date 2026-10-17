"""Replays the exported DDL, seed rows and queries against SQLite and Postgres and compares the
rows with the Lean evaluator's expected results."""
import json, sqlite3, subprocess, sys

data = json.load(open(sys.argv[1]))
pg_socket = sys.argv[2]

def norm(v):
    return v if not isinstance(v, bool) else int(v)

def sqlite_run():
    con = sqlite3.connect(":memory:")
    for ddl in data["ddl"]["sqlite"]:
        con.execute(ddl)
    for row in data["seed"]:
        con.execute(row["sqlite"], row["params"])
    out = {}
    for q in data["queries"]:
        try:
            out[q["name"]] = [list(r) for r in con.execute(q["sqlite"]["sql"], q["sqlite"]["params"])]
        except Exception as e:
            out[q["name"]] = f"ERROR {e}"
    return out

def lit(v):
    if isinstance(v, bool):
        return "TRUE" if v else "FALSE"
    if isinstance(v, int):
        return str(v)
    return "'" + v.replace("'", "''") + "'"

def psql(db, script):
    r = subprocess.run(["psql", "-h", pg_socket, "-p", "5499", "-U", "postgres", "-d", db,
                        "-At", "-F", "\t", "-v", "ON_ERROR_STOP=0", "-q"],
                       input=script, capture_output=True, text=True)
    return r.stdout, r.stderr

def pg_run(db):
    setup = "DROP TABLE IF EXISTS schools, students, submissions;\n"
    setup += ";\n".join(data["ddl"]["postgres"]) + ";\n"
    for i, row in enumerate(data["seed"]):
        setup += f"PREPARE s{i} AS {row['postgres']};\nEXECUTE s{i}({', '.join(map(lit, row['params']))});\n"
    _, err = psql(db, setup)
    if err.strip():
        print("setup errors:", err)
    out = {}
    for q in data["queries"]:
        p = q["postgres"]
        args = f"({', '.join(map(lit, p['params']))})" if p["params"] else ""
        stdout, err = psql(db, f"PREPARE q AS {p['sql']};\nEXECUTE q{args};\n")
        if err.strip():
            out[q["name"]] = "ERROR " + err.strip().splitlines()[0]
            continue
        rows = []
        for line in stdout.splitlines():
            if line:
                rows.append([int(c) if c.lstrip("-").isdigit() else c for c in line.split("\t")])
        out[q["name"]] = rows
    return out

results = {"sqlite": sqlite_run(), "postgres (C collation)": pg_run("espal_c"),
           "postgres (ICU en-US)": pg_run("espal_icu")}
for q in data["queries"]:
    exp = [[norm(v) for v in r] for r in q["expected"]]
    line = [q["name"].ljust(28)]
    for name, res in results.items():
        got = res[q["name"]]
        line.append(f"{name}: {'match' if got == exp else 'DIFFERS ' + str(got)}")
    print(" | ".join(line))
    if any(res[q["name"]] != exp for res in results.values()):
        print("   lean evaluator:", exp)
