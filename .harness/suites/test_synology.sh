#!/usr/bin/env bash
# ============================================================================
# Suite: test_synology
# Purpose: Validate the Synology platform guard and run bounded, read-only
#          checks against the active deployment when executed on DSM.
# Usage:   ./manage.sh test synology
# ============================================================================
set -euo pipefail

test_synology_docs_present() {
  [[ -s "${REPO_DIR}/.docs/synology.md" ]] && \
  grep -q 'DSM' "${REPO_DIR}/.docs/synology.md"
}

test_synology_platform_gate() {
  source "${REPO_DIR}/.scripts/platform.sh"
  local fixture
  fixture="$(mktemp)" || return 1
  printf 'productversion="7.2.1"\n' > "${fixture}"
  if ! is_synology_dsm "${fixture}" || is_synology_dsm "${fixture}.missing"; then
    rm -f "${fixture}" "${fixture}.missing"
    return 1
  fi
  if ! guard_synology_command test "${fixture}" || ! guard_synology_command help "${fixture}"; then
    rm -f "${fixture}" "${fixture}.missing"
    return 1
  fi
  local command
  for command in setup startup backup restore hook; do
    if guard_synology_command "${command}" "${fixture}" >/dev/null 2>&1; then
      rm -f "${fixture}" "${fixture}.missing"
      return 1
    fi
  done
  rm -f "${fixture}" "${fixture}.missing"
  grep -q 'guard_synology_command "${subcmd}"' "${REPO_DIR}/manage.sh"
}

test_synology_monitor_syntax() {
  local script
  for script in synology-health-check.sh synology-monitor-run.sh synology-monitor-test.sh; do
    [[ -s "${REPO_DIR}/.scripts/${script}" ]] || return 1
    bash -n "${REPO_DIR}/.scripts/${script}" || return 1
  done
}

test_synology_backup_script_syntax() {
  local python_bin
  python_bin="$(synology_test_python)" || return 1
  "${python_bin}" -c 'from pathlib import Path; p=Path(".scripts/synology-backup-verify.py"); compile(p.read_text(), str(p), "exec")'
}

test_synology_backup_regressions() {
  local python_bin
  python_bin="$(synology_test_python)" || return 1
  PYTHONDONTWRITEBYTECODE=1 "${python_bin}" "${REPO_DIR}/.harness/suites/test_synology_backup.py"
}

test_synology_app_health_syntax() {
  local python_bin
  python_bin="$(synology_test_python)" || return 1
  PYTHONDONTWRITEBYTECODE=1 "${python_bin}" -c 'from pathlib import Path; [compile(Path(path).read_text(), path, "exec") for path in (".scripts/synology-app-health.py", ".scripts/test-synology-app-health.py")]'
}

test_synology_app_health_regressions() {
  local python_bin
  python_bin="$(synology_test_python)" || return 1
  PYTHONDONTWRITEBYTECODE=1 "${python_bin}" "${REPO_DIR}/.scripts/test-synology-app-health.py"
}

synology_test_python() {
  if [[ -n "${PYTHON3:-}" ]] && [[ -x "${PYTHON3}" ]]; then
    printf '%s\n' "${PYTHON3}"
  elif command -v python3 >/dev/null 2>&1 && python3 --version >/dev/null 2>&1; then
    command -v python3
  elif command -v python >/dev/null 2>&1 && python --version >/dev/null 2>&1; then
    command -v python
  else
    return 1
  fi
}

test_synology_live_containers() {
  local name state
  local names=(
    homelab-v2-jellyfin homelab-v2-tailscale homelab-v2-vpn
    homelab-v2-qbittorrent homelab-v2-prowlarr homelab-v2-flaresolverr
    homelab-v2-radarr homelab-v2-sonarr homelab-v2-seerr
  )
  for name in "${names[@]}"; do
    state="$(docker inspect --format '{{.State.Running}} {{.State.OOMKilled}} {{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "${name}")" || return 1
    [[ "${state}" == "true false healthy" || "${state}" == "true false none" ]] || return 1
  done
}

suite_synology() {
  init_suite "Synology DSM Adaptation"
  run_test test_synology_docs_present "Synology production reference exists"
  run_test test_synology_platform_gate "DSM command allowlist blocks inherited mutations"
  run_test test_synology_monitor_syntax "NAS monitoring scripts pass shell syntax checks"
  run_test test_synology_backup_script_syntax "Synology backup helper parses without executing"
  run_test test_synology_backup_regressions "Backup symlink, path traversal, and SQLite-sidecar fixtures pass"
  run_test test_synology_app_health_syntax "Authenticated application health helper and tests parse without contacting services"
  run_test test_synology_app_health_regressions "Authenticated application health warning and failure fixtures pass"
  if is_synology_dsm; then
    run_test test_synology_live_containers "Active homelab-v2 containers are running without OOM state"
  else
    printf 'SKIP: live DSM container check (host is not Synology DSM)\n'
  fi
}
