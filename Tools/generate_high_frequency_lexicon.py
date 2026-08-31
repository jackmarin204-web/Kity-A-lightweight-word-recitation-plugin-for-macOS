#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path

HANZI = re.compile(r"^[\u4e00-\u9fff]{2,12}$")
CEDICT = re.compile(r"^\S+\s+(\S+)\s+\[[^]]+\]\s+/(.+)/$")
PARENS = re.compile(r"\([^)]*\)")


def clean_gloss(raw: str) -> str | None:
    value = PARENS.sub("", raw).split(";")[0].strip()
    lower = value.lower()
    if lower.startswith(("abbr.", "variant of", "see ")):
        return None
    value = value.replace("’", "'").strip(" ,.-")
    if (
        not value
        or len(value) > 32
        or not value.isascii()
        or any(char.isdigit() for char in value)
        or "/" in value
    ):
        return None
    return value


def parse_jieba(path: Path) -> list[tuple[str, int]]:
    rows: list[tuple[str, int]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        fields = line.split()
        if len(fields) < 2 or not HANZI.fullmatch(fields[0]):
            continue
        try:
            rows.append((fields[0], int(fields[1])))
        except ValueError:
            continue
    return sorted(rows, key=lambda row: (-row[1], row[0]))


def parse_cedict(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("#"):
            continue
        match = CEDICT.match(line)
        if not match or match.group(1) in result:
            continue
        gloss = clean_gloss(match.group(2).split("/")[0])
        if gloss:
            result[match.group(1)] = gloss
    return result


def validate_hint(word: str, hint: str) -> None:
    if not HANZI.fullmatch(word):
        raise ValueError(f"Invalid Hanzi override: {word}")
    if not hint or len(hint) > 32 or not hint.isascii():
        raise ValueError(f"Invalid English override for {word}")


def parse_overrides(path: Path) -> dict[str, str]:
    values = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(values, dict):
        raise ValueError("Overrides must be a JSON object")
    for word, hint in values.items():
        if not isinstance(word, str) or not isinstance(hint, str):
            raise ValueError("Overrides must map strings to strings")
        validate_hint(word, hint)
    return values


def build_entries(
    words: list[tuple[str, int]],
    glosses: dict[str, str],
    overrides: dict[str, str],
    limit: int,
) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    seen: set[str] = set()
    if len(overrides) > limit:
        raise SystemExit(f"{len(overrides)} overrides exceed limit {limit}.")

    for word in sorted(overrides):
        entries.append(
            {
                "hanzi": word,
                "englishHint": overrides[word],
                "partOfSpeech": "word",
                "confidence": 0.95,
            }
        )
        seen.add(word)

    for word, _ in words:
        gloss = glosses.get(word)
        if not gloss or word in seen:
            continue
        entries.append(
            {
                "hanzi": word,
                "englishHint": gloss,
                "partOfSpeech": "word",
                "confidence": 0.95,
            }
        )
        seen.add(word)
        if len(entries) == limit:
            return entries
    raise SystemExit(f"Only {len(entries)} entries survived; need {limit}.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jieba-source", type=Path, required=True)
    parser.add_argument("--cedict-source", type=Path, required=True)
    parser.add_argument("--overrides", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--limit", type=int, default=3000)
    args = parser.parse_args()

    entries = build_entries(
        parse_jieba(args.jieba_source),
        parse_cedict(args.cedict_source),
        parse_overrides(args.overrides),
        args.limit,
    )
    args.output.write_text(
        json.dumps(entries, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"{len(entries)} entries written to {args.output}")


if __name__ == "__main__":
    main()
