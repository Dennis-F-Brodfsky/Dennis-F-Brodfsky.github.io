#!/usr/bin/env python3
import re
import sys
import unicodedata
import xml.etree.ElementTree as ET


def normalize(value: str) -> str:
    return " ".join(unicodedata.normalize("NFKC", value).casefold().split())


def arxiv_id(value: str) -> str:
    match = re.search(r"/abs/([^?#]+)", value)
    return match.group(1) if match else value.rsplit("/", 1)[-1]


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <title> <Atom XML file>", file=sys.stderr)
        return 2

    requested = normalize(sys.argv[1])
    try:
        root = ET.parse(sys.argv[2]).getroot()
    except (ET.ParseError, OSError) as error:
        print(f"Could not parse arXiv search response: {error}", file=sys.stderr)
        return 1

    namespace = {"atom": "http://www.w3.org/2005/Atom"}
    candidates = []
    for entry in root.findall("atom:entry", namespace):
        title = " ".join((entry.findtext("atom:title", "", namespace)).split())
        identifier = arxiv_id(entry.findtext("atom:id", "", namespace))
        if title and identifier:
            candidates.append((identifier, title))

    exact = [item for item in candidates if normalize(item[1]) == requested]
    if len(exact) == 1:
        print(exact[0][0])
        return 0

    if not candidates:
        print(f"No arXiv results found for title: {sys.argv[1]}", file=sys.stderr)
        return 4

    reason = "Multiple exact title matches" if exact else "No exact title match"
    print(f"{reason}; candidate papers:", file=sys.stderr)
    for identifier, title in (exact or candidates):
        print(f"  {identifier}  {title}", file=sys.stderr)
    return 3


if __name__ == "__main__":
    raise SystemExit(main())
