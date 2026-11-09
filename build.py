import pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent
parts = sorted(ROOT.joinpath("src").glob("[0-9]*.lua"))
out = []
out.append('local Env = (getgenv and getgenv()) or _G\n')
out.append('if type(Env.SaturnLibrary) == "table" and Env.SaturnLibrary.Unloaded == false and type(Env.SaturnLibrary.Unload) == "function" then\n\tpcall(Env.SaturnLibrary.Unload, Env.SaturnLibrary)\nend\n')
for i, part in enumerate(parts):
    text = part.read_text(encoding="utf-8")
    if not text.endswith("\n"):
        text += "\n"
    if i == 0:
        out.append(text)
    else:
        out.append("do\n" + text + "end\n")
out.append("Env.SaturnLibrary = Library\nreturn Library\n")
target = ROOT / (sys.argv[1] if len(sys.argv) > 1 else "Saturn.lua")
target.write_text("".join(out), encoding="utf-8")
print("built", target.name, sum(t.count("\n") for t in out), "lines")
