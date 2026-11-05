#!/usr/bin/env bash
# Refresh portable copies of the canonical agent instructions and skills.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CANONICAL="${REPO_DIR}/AGENTS.md"

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

[[ -s "${CANONICAL}" ]] || fail "Canonical instructions not found: ${CANONICAL}"

sync_instruction_copy() {
  local relative_path="$1"
  local expected_target="$2"
  local destination="${REPO_DIR}/${relative_path}"

  if [[ -L "${destination}" ]]; then
    [[ "$(readlink "${destination}")" == "${expected_target}" ]] || \
      fail "Refusing unexpected symlink at ${relative_path}"
    rm -- "${destination}"
  elif [[ -f "${destination}" ]]; then
    if [[ "$(cat "${destination}")" == "${expected_target}" ]]; then
      rm -- "${destination}"
    fi
  elif [[ -e "${destination}" ]]; then
    fail "Expected a regular file or known alias at ${relative_path}"
  fi

  cp "${CANONICAL}" "${destination}"
}

sync_instruction_copy agent.md AGENTS.md
sync_instruction_copy CLAUDE.md AGENTS.md
sync_instruction_copy GEMINI.md AGENTS.md
sync_instruction_copy .cursorrules AGENTS.md

RULE_COPY="${REPO_DIR}/.agents/rules/project-conventions.md"
if [[ -L "${RULE_COPY}" ]]; then
  [[ "$(readlink "${RULE_COPY}")" == "../../AGENTS.md" ]] || \
    fail "Refusing unexpected symlink at .agents/rules/project-conventions.md"
  rm -- "${RULE_COPY}"
elif [[ -f "${RULE_COPY}" ]] && [[ "$(cat "${RULE_COPY}")" == "../../AGENTS.md" ]]; then
  rm -- "${RULE_COPY}"
elif [[ -e "${RULE_COPY}" && ! -f "${RULE_COPY}" ]]; then
  fail "Expected a regular file or known alias at .agents/rules/project-conventions.md"
fi
sed -E 's#\]\((\.agents/|\.docs/|\.skills/)#](../../\1#g' "${CANONICAL}" > "${RULE_COPY}"

SKILLS_SOURCE="${REPO_DIR}/.agents/skills"
SKILLS_COPY="${REPO_DIR}/.skills"
[[ -d "${SKILLS_SOURCE}" ]] || fail "Canonical skills directory not found: ${SKILLS_SOURCE}"

if [[ -L "${SKILLS_COPY}" ]]; then
  [[ "$(readlink "${SKILLS_COPY}")" == ".agents/skills" ]] || \
    fail "Refusing unexpected symlink at .skills"
  rm -- "${SKILLS_COPY}"
elif [[ -f "${SKILLS_COPY}" ]]; then
  [[ "$(cat "${SKILLS_COPY}")" == ".agents/skills" ]] || \
    fail "Refusing to replace modified file at .skills"
  rm -- "${SKILLS_COPY}"
elif [[ -e "${SKILLS_COPY}" && ! -d "${SKILLS_COPY}" ]]; then
  fail "Expected a directory or known alias at .skills"
fi

mkdir -p "${SKILLS_COPY}"
cp -R "${SKILLS_SOURCE}/." "${SKILLS_COPY}/"

while IFS= read -r -d '' copied_file; do
  relative_path="${copied_file#"${SKILLS_COPY}/"}"
  if [[ ! -f "${SKILLS_SOURCE}/${relative_path}" ]]; then
    rm -- "${copied_file}"
  fi
done < <(find "${SKILLS_COPY}" -type f -print0)

find "${SKILLS_COPY}" -depth -type d -empty ! -path "${SKILLS_COPY}" -exec rmdir -- {} \;
printf 'Synchronized portable agent instruction and skill copies.\n'
