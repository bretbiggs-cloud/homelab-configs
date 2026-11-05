#!/usr/bin/env bash
# ==============================================================================
# Suite: test_conventions
# Purpose: Verifies agent harness structural invariants, multi-agent entrypoints,
#          memory bank persistence, modular rules, and secrets hygiene.
# ==============================================================================
set -euo pipefail

# Sourced by test runner; REPO_DIR is set in test environment

test_conventions_entrypoint() {
  [[ -s "${REPO_DIR}/AGENTS.md" ]]
}

test_skills_portable_copy() {
  local source="${REPO_DIR}/.agents/skills"
  local copy="${REPO_DIR}/.skills"
  local source_count copy_count source_file relative_path
  [[ -d "${source}" && -d "${copy}" && ! -L "${copy}" ]] || return 1

  source_count="$(find "${source}" -type f | wc -l | tr -d '[:space:]')"
  copy_count="$(find "${copy}" -type f | wc -l | tr -d '[:space:]')"
  [[ "${source_count}" == "${copy_count}" ]] || return 1

  while IFS= read -r -d '' source_file; do
    relative_path="${source_file#"${source}/"}"
    cmp -s "${source_file}" "${copy}/${relative_path}" || return 1
  done < <(find "${source}" -type f -print0)
}

test_agent_instruction_copies() {
  local relative_path
  for relative_path in agent.md CLAUDE.md GEMINI.md .cursorrules; do
    [[ -f "${REPO_DIR}/${relative_path}" && ! -L "${REPO_DIR}/${relative_path}" ]] || return 1
    cmp -s "${REPO_DIR}/AGENTS.md" "${REPO_DIR}/${relative_path}" || return 1
  done

  relative_path=".agents/rules/project-conventions.md"
  [[ -f "${REPO_DIR}/${relative_path}" && ! -L "${REPO_DIR}/${relative_path}" ]] || return 1
  cmp -s <(sed -E 's#\]\((\.agents/|\.docs/|\.skills/)#](../../\1#g' "${REPO_DIR}/AGENTS.md") \
    "${REPO_DIR}/${relative_path}"
}

test_agent_copy_sync_script() {
  [[ -s "${REPO_DIR}/.scripts/sync-agent-entrypoints.sh" ]] && \
    bash -n "${REPO_DIR}/.scripts/sync-agent-entrypoints.sh"
}

test_manage_executable() {
  [[ -x "${REPO_DIR}/manage.sh" ]]
}

test_env_example_presence() {
  [[ -s "${REPO_DIR}/.env.example" ]]
}

test_gitignore_secrets() {
  grep -q "\.env" "${REPO_DIR}/.gitignore"
}

test_subagents_presence() {
  [[ -s "${REPO_DIR}/.agents/subagents/architect-critic.md" ]] && \
  [[ -s "${REPO_DIR}/.agents/subagents/code-auditor.md" ]]
}

test_memory_bank_presence() {
  [[ -s "${REPO_DIR}/.agents/memory/activeContext.md" ]] && \
  [[ -s "${REPO_DIR}/.agents/memory/systemPatterns.md" ]] && \
  [[ -s "${REPO_DIR}/.agents/memory/progress.md" ]]
}

test_modular_rules_presence() {
  [[ -s "${REPO_DIR}/.agents/rules/shell-scripting.md" ]] && \
  [[ -s "${REPO_DIR}/.agents/rules/containers-and-env.md" ]]
}

test_ci_workflow_presence() {
  [[ -s "${REPO_DIR}/.github/workflows/ci.yml" ]]
}

suite_conventions() {
  init_suite "Agentic Harness & Structural Invariants"
  run_test test_conventions_entrypoint "Canonical AGENTS.md entrypoint exists"
  run_test test_skills_portable_copy ".skills portable copy matches canonical .agents/skills"
  run_test test_agent_instruction_copies "Agent entrypoint files contain the canonical full instructions"
  run_test test_agent_copy_sync_script "Portable agent-copy synchronization script exists and parses"
  run_test test_manage_executable "manage.sh master entrypoint is executable"
  run_test test_env_example_presence "Root .env.example configuration template exists"
  run_test test_gitignore_secrets ".gitignore properly protects .env credentials"
  run_test test_subagents_presence ".agents/subagents/ prompt specifications exist"
  run_test test_memory_bank_presence ".agents/memory/ session memory bank exists and is populated"
  run_test test_modular_rules_presence ".agents/rules/ glob-scoped rules exist"
  run_test test_ci_workflow_presence ".github/workflows/ci.yml continuous integration workflow exists"
}
