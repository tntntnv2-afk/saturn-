import pathlib, re, shutil, subprocess, sys, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
problems = []

with tempfile.TemporaryDirectory() as tmp:
    fresh = pathlib.Path(tmp) / "Saturn.lua"
    subprocess.run([sys.executable, str(ROOT / "build.py"), str(fresh)], check=True, capture_output=True)
    built = ROOT / "Saturn.lua"
    if not built.exists() or built.read_text(encoding="utf-8") != fresh.read_text(encoding="utf-8"):
        problems.append("Saturn.lua is out of date, run build.py")
    compiler = shutil.which("luau-compile") or next((str(p) for p in [pathlib.Path.home() / "tools" / "luau-compile", pathlib.Path("/home/claude/tools/luau-compile")] if p.exists()), None)
    if compiler:
        for level in ("-O0", "-O2"):
            r = subprocess.run([compiler, level, "--binary", str(fresh)], capture_output=True)
            if r.returncode != 0:
                problems.append("compile " + level + ": " + r.stderr.decode(errors="replace").strip()[:400])
    else:
        print("luau-compile not found, skipped compile check")

for path in sorted((ROOT / "src").glob("*.lua")) + [ROOT / "loader.lua"]:
    for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = re.sub(r'"(?:\\.|[^"\\])*"', '""', line)
        if "--" in stripped:
            problems.append(f"{path.relative_to(ROOT)}:{n} has a comment")

for name in ["saturn_logo_anim.png", "icons.png", "orbit_ring.png", "glide.png"]:
    if not (ROOT / "assets" / name).exists():
        problems.append("missing assets/" + name)

if problems:
    print("\n".join(problems))
    sys.exit(1)
print("ok")
