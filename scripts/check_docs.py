#!/usr/bin/env python3
"""Check this repository's inline Markdown links; refresh marked code regions."""
import argparse
import json
import re
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
CODE_LINKS = json.loads((ROOT / "scripts/code_links.json").read_text())
LINK = re.compile(r'\[[^\]\n]*\]\(([^)\s]+)\)')
REGION = re.compile(
    r'(\[[^\]\n]+\]\()([^\s)#]+)(?:#[^\s)]+)?'
    r'(\)<!-- region:([\w-]+) -->)'
)


def headings(path):
    """GitHub-style slugs for the simple headings used by these guides."""
    seen = {}
    result = set()
    for line in path.read_text().splitlines():
        match = re.match(r'^#{1,6}\s+(.+)', line)
        if not match:
            continue
        text = match[1].strip().rstrip('#').strip().lower()
        slug = re.sub(r'[^\w\- ]', '', text).replace(' ', '-')
        count = seen.get(slug, 0)
        seen[slug] = count + 1
        result.add(f'{slug}-{count}' if count else slug)
    return result


def code_region(path, region):
    """Resolve external anchors without adding documentation markers to HDL."""
    relative = path.resolve().relative_to(ROOT).as_posix()
    try:
        anchor = CODE_LINKS[relative][region]
    except KeyError:
        raise ValueError(f'{relative}: no code_links.json entry for {region}') from None
    lines = path.read_text().splitlines()
    starts = [i for i, line in enumerate(lines) if re.search(anchor['start'], line)]
    if len(starts) != 1:
        raise ValueError(f'{relative}: {region} start anchor must match exactly once')
    ends = [i for i in range(starts[0], len(lines))
            if re.search(anchor['end'], lines[i])]
    if not ends:
        raise ValueError(f'{relative}: {region} end anchor not found after start')
    first = starts[0] + anchor.get('start_offset', 0)
    last = ends[0] + anchor.get('end_offset', 0)
    if not 0 <= first <= last < len(lines):
        raise ValueError(f'{relative}: invalid range for {region}')
    # Exclude surrounding blank lines, including around a student's implementation.
    while first <= last and not lines[first].strip():
        first += 1
    while last >= first and not lines[last].strip():
        last -= 1
    if first > last:
        raise ValueError(f'{relative}: empty range for {region}')
    return f'#L{first + 1}-L{last + 1}'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fix', action='store_true', help='refresh marked code line ranges')
    args = parser.parse_args()
    errors = []
    paths = sorted(p for p in ROOT.rglob('*.md')
                   if not {'.git', 'build'} & set(p.relative_to(ROOT).parts))
    for doc in paths:
        original = doc.read_text()
        code_spans = [(m.start(), m.end()) for m in re.finditer(
            r'```[^\n]*\n.*?```|`[^`\n]*`', original, flags=re.S)]
        def refresh(match):
            if any(start <= match.start() < end for start, end in code_spans):
                return match[0]
            try:
                fragment = code_region(doc.parent / match[2], match[4])
            except (OSError, ValueError) as exc:
                errors.append(f'{doc.relative_to(ROOT)}: {exc}')
                return match[0]
            replacement = f'{match[1]}{match[2]}{fragment}{match[3]}'
            if replacement != match[0] and not args.fix:
                errors.append(f'{doc.relative_to(ROOT)}: stale {match[4]} link; run with --fix')
            return replacement
        updated = REGION.sub(refresh, original)
        if args.fix and updated != original:
            doc.write_text(updated)
        # Fenced and inline snippets illustrate syntax; they are not links.
        visible = re.sub(r'^```[^\n]*\n.*?^```\s*$', '', updated, flags=re.M | re.S)
        visible = re.sub(r'`[^`\n]*`', '', visible)
        for match in LINK.finditer(visible):
            raw = match[1]
            url = urlsplit(raw)
            if url.scheme or url.netloc:
                continue
            target = (doc.parent / unquote(url.path)).resolve() if url.path else doc
            location = f'{doc.relative_to(ROOT)}: {raw}'
            if not target.is_relative_to(ROOT):
                errors.append(f'{location}: points outside repository')
            elif not target.exists():
                errors.append(f'{location}: missing target')
            elif url.fragment and target.is_file():
                fragment = unquote(url.fragment)
                line_range = re.fullmatch(r'L(\d+)(?:-L(\d+))?', fragment)
                if line_range:
                    first = int(line_range[1])
                    last = int(line_range[2] or first)
                    if not 1 <= first <= last <= len(target.read_text().splitlines()):
                        errors.append(f'{location}: invalid line range')
                elif target.suffix == '.md' and fragment not in headings(target):
                    errors.append(f'{location}: missing heading')
    if errors:
        print('\n'.join(errors))
        return 1
    print(f'PASS: local links and code regions in {len(paths)} Markdown files')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
