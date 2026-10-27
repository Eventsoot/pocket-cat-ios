"""Check source layout before moving this project to a Mac. No iOS build implied."""
from pathlib import Path
import re

root = Path(__file__).resolve().parent
config = (root / "project.yml").read_text(encoding="utf-8")
for folder in ("App", "Shared", "Widgets"):
    assert (root / folder).is_dir(), folder
    assert list((root / folder).glob("*.swift")), folder
group = "group.com.example.PocketCat"
assert config.count(group) == 2
assert group in (root / "Shared/Pet.swift").read_text(encoding="utf-8")
assert "NSSupportsLiveActivities: true" in config
app_main = sum("@main" in f.read_text(encoding="utf-8") for f in (root / "App").glob("*.swift"))
widget_main = sum("@main" in f.read_text(encoding="utf-8") for f in (root / "Widgets").glob("*.swift"))
assert app_main == widget_main == 1
assert not any("@main" in f.read_text(encoding="utf-8") for f in (root / "Shared").glob("*.swift"))
intents = (root / "Shared/CareIntents.swift").read_text(encoding="utf-8")
widgets = (root / "Widgets/CatWidgets.swift").read_text(encoding="utf-8")
for name in re.findall(r"Button\(intent: (\w+)\(\)\)", widgets):
    assert f"struct {name}: LiveActivityIntent" in intents, name
print("OK: source layout, shared App Group, entry points, Live Activity flag and intent references.")
basic = (root / "project-basic.yml").read_text(encoding="utf-8")
assert "BASIC_BUILD" in basic
assert "entitlements:" not in basic
assert "PocketCatWidgets:" not in basic
assert "NSSupportsLiveActivities" not in basic
assert "#if BASIC_BUILD" in (root / "Shared/Pet.swift").read_text(encoding="utf-8")
assert "#if !BASIC_BUILD" in (root / "App/HomeView.swift").read_text(encoding="utf-8")
workflow = (root / ".github/workflows/build-ios.yml").read_text(encoding="utf-8")
assert "runs-on: macos-15" in workflow
assert "flavor: [basic, widgets]" in workflow
assert "workflow_dispatch:" in workflow
assert "secrets." not in workflow
assert "contents: read" in workflow
print("OK: basic build avoids extension entitlements; cloud workflow needs no signing secrets.")
print("Swift compilation and device checks require Xcode on macOS.")
