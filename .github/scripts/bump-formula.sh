#!/usr/bin/env bash
set -euo pipefail

# Обновляет url и sha256 в формуле тапа, когда в основной репе вышел новый релиз.

REPO="${REPO:-AMEST/mongo-tui}"
FORMULA="${FORMULA:-Formula/mongo-tui.rb}"
BRANCH="${BRANCH:-master}"

if [[ -n "${RELEASE_JSON_FILE:-}" ]]; then
  release_json=$(<"$RELEASE_JSON_FILE")
else
  auth=()
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  release_json=$(curl -fsSL "${auth[@]}" "https://api.github.com/repos/${REPO}/releases/latest")
fi

tag=$(python3 -c 'import json, sys; print(json.loads(sys.argv[1])["tag_name"])' "$release_json")
version="${tag#v}"

decision=$(python3 - "$FORMULA" "$version" <<'PY'
import re
import sys

formula_path, new_version = sys.argv[1], sys.argv[2]
text = open(formula_path, encoding="utf-8").read()
match = re.search(r"archive/refs/tags/v([0-9]+(?:\.[0-9]+)*)\.tar\.gz", text)
if not match:
    print("error: cannot find current version in the formula", file=sys.stderr)
    sys.exit(2)

def key(value):
    return tuple(int(part) for part in value.split("."))

action = "skip" if key(new_version) <= key(match.group(1)) else "bump"
print(f"{match.group(1)} {action}")
PY
)

read -r current decision <<< "$decision"

if [[ "$decision" == "skip" ]]; then
  echo "Nothing to do: formula is at ${current}, latest release is ${version}."
  exit 0
fi

if [[ "${PR:-1}" == "1" ]]; then
  bump_branch="bump/mongo-tui-${version}"

  # Не плодим дубликаты PR (проверяем до изменения файлов).
  if command -v gh >/dev/null 2>&1 &&
     gh pr list --head "$bump_branch" --state open --limit 1 --json number -q '.[0].number' 2>/dev/null | grep -qE '^[0-9]+$'; then
    echo "A PR for ${tag} already exists, skipping."
    exit 0
  fi
fi

if [[ -n "${TARBALL_FILE:-}" ]]; then
  sha256=$(shasum -a 256 "$TARBALL_FILE" | awk '{print $1}')
else
  sha256=$(curl -fsSL "https://github.com/${REPO}/archive/refs/tags/${tag}.tar.gz" | shasum -a 256 | awk '{print $1}')
fi

python3 - "$FORMULA" "$REPO" "$tag" "$sha256" <<'PY'
import re
import sys

formula_path, repo, tag, sha256 = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
text = open(formula_path, encoding="utf-8").read()

text, url_count = re.subn(
    r'url "https://github\.com/[^"]+/archive/refs/tags/v[0-9.]+\.tar\.gz"',
    f'url "https://github.com/{repo}/archive/refs/tags/{tag}.tar.gz"',
    text,
)
text, sha_count = re.subn(
    r'sha256 "[0-9a-f]{64}"',
    f'sha256 "{sha256}"',
    text,
)
if url_count != 1 or sha_count != 1:
    print("error: expected exactly one url and one sha256 line", file=sys.stderr)
    sys.exit(2)

open(formula_path, "w", encoding="utf-8").write(text)
PY

echo "Bumping formula to ${tag} (sha256 ${sha256})."

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  git diff -- "$FORMULA"
  echo "DRY_RUN: nothing committed."
  exit 0
fi

if [[ "${PR:-1}" == "1" ]]; then
  git checkout -b "$bump_branch"
  git add "$FORMULA"
  git commit -m "chore: bump mongo-tui to ${version}"
  # force-with-lease: повторный прогон должен пережить ветку, оставшуюся
  # от прошлой попытки (например, когда PR не удалось создать).
  git push -u --force-with-lease origin "$bump_branch"
  gh pr create \
    --base "$BRANCH" \
    --head "$bump_branch" \
    --title "chore: bump mongo-tui to ${version}" \
    --body "Автоматический бамп до ${tag}."
  echo "PR created: ${bump_branch} -> ${BRANCH}."
else
  git add "$FORMULA"
  git commit -m "chore: bump mongo-tui to ${version}"
  git push origin "HEAD:${BRANCH}"
  echo "Pushed to ${BRANCH}."
fi
