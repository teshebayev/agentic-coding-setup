"""Каждый плагин из base.yml должен быть и в dwh.yml: списки слоёв заменяются целиком (.claude/rules/plugins.md)."""
from __future__ import annotations

import sys
from pathlib import Path

import yaml

CONFIG = Path(__file__).resolve().parents[2] / "harness" / "config"


def plugin_paths(layer: str) -> list[str]:
    items = (yaml.safe_load((CONFIG / layer).read_text(encoding="utf-8")) or {}).get("plugins") or []
    return [item["path"] if isinstance(item, dict) else item for item in items]


def main() -> int:
    missing = [p for p in plugin_paths("base.yml") if p not in set(plugin_paths("dwh.yml"))]
    if not missing:
        return 0
    print("Плагины есть в base.yml, но не в dwh.yml — в боевом профиле их не будет:")
    print("\n".join(f"  - {p}" for p in missing))
    return 1


if __name__ == "__main__":
    sys.exit(main())
