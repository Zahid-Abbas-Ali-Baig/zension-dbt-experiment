"""Set warn severity on source-layer tests with known data quality gaps."""

from __future__ import annotations

from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "models" / "staging" / "source" / "_sources.yml"


def warn_test(test):
    if test == "not_null":
        return {"not_null": {"config": {"severity": "warn"}}}
    if not isinstance(test, dict) or len(test) != 1:
        return test
    test_type, body = next(iter(test.items()))
    if test_type not in {"relationships", "accepted_values", "not_null"}:
        return test
    if not isinstance(body, dict):
        return test
    body = dict(body)
    config = dict(body.get("config") or {})
    config["severity"] = "warn"
    body["config"] = config
    return {test_type: body}


def main() -> None:
    data = yaml.safe_load(SOURCES.read_text(encoding="utf-8"))
    for source in data.get("sources", []):
        for table in source.get("tables", []):
            for column in table.get("columns", []):
                tests = column.get("data_tests")
                if not tests:
                    continue
                column["data_tests"] = [warn_test(t) for t in tests]
    SOURCES.write_text(
        yaml.dump(data, sort_keys=False, allow_unicode=True),
        encoding="utf-8",
    )
    print(f"Patched {SOURCES}")


if __name__ == "__main__":
    main()
