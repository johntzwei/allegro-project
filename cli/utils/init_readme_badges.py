"""Set README badges for the current GitHub repository."""

import argparse
import re
from pathlib import Path
from urllib.parse import quote, urlsplit

START = "<!-- project-badges:start -->"
END = "<!-- project-badges:end -->"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", required=True, metavar="OWNER/REPO")
    parser.add_argument("--readme", type=Path, default=Path("README.md"))
    parser.add_argument("--branch")
    parser.add_argument(
        "--codecov-badge-url",
        help="The repository's badge image URL from Codecov, if needed.",
    )
    args = parser.parse_args()
    if not re.fullmatch(r"[\w.-]+/[\w.-]+", args.repository, flags=re.ASCII):
        parser.error("--repository must be a GitHub OWNER/REPO slug")

    github = f"https://github.com/{args.repository}"
    codecov = f"https://codecov.io/gh/{args.repository}"
    ci_image = f"{github}/actions/workflows/ci.yml/badge.svg"
    coverage_image = f"{codecov}/graph/badge.svg"
    if args.branch:
        branch = quote(args.branch, safe="")
        ci_image += f"?branch={branch}"
        coverage_image = f"{codecov}/branch/{branch}/graph/badge.svg"
    if args.codecov_badge_url:
        url = urlsplit(args.codecov_badge_url)
        if (
            url.scheme != "https"
            or url.netloc != "codecov.io"
            or not url.path.startswith(f"/gh/{args.repository}/")
            or not url.path.endswith("/badge.svg")
        ):
            parser.error(
                "the Codecov badge URL must belong to this repository"
            )
        coverage_image = args.codecov_badge_url

    block = "\n".join(
        [
            START,
            f"[![CI]({ci_image})]({github}/actions/workflows/ci.yml)",
            f"[![codecov]({coverage_image})]({codecov})",
            END,
        ]
    )
    content = args.readme.read_text(encoding="utf-8")
    if START in content or END in content:
        if (
            content.count(START) != 1
            or content.count(END) != 1
            or content.index(START) > content.index(END)
        ):
            parser.error("README must contain one complete badge block")
        before, rest = content.split(START, 1)
        _, after = rest.split(END, 1)
        content = before + block + after
    else:
        title, separator, rest = content.partition("\n")
        if not title.startswith("# "):
            parser.error("README must start with a Markdown title")
        content = title + "\n\n" + block + "\n" + separator + rest
    args.readme.write_text(content, encoding="utf-8")
    print(f"Updated CI and Codecov badges for {args.repository}")


if __name__ == "__main__":
    main()
