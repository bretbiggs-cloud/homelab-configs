#!/usr/bin/env bash
# ============================================================================
# Script: .scripts/platform.sh
# Purpose: Identify Synology DSM and define the DSM command allowlist used by
#          the shared management entrypoint and test harness.
# Usage:   Source this file from manage.sh or a harness test suite.
# Behavior: Read-only. It does not inspect or modify host configuration beyond
#          reading the DSM VERSION file.
# ============================================================================
set -euo pipefail

is_synology_dsm() {
  local version_file="${1:-/etc.defaults/VERSION}"
  [[ -r "${version_file}" ]] && grep -qE '^[[:space:]]*productversion=' "${version_file}"
}

synology_command_allowed() {
  case "${1:-}" in
    help|-h|--help|test|synology) return 0 ;;
    *) return 1 ;;
  esac
}

guard_synology_command() {
  local command="${1:-}"
  local version_file="${2:-/etc.defaults/VERSION}"
  if is_synology_dsm "${version_file}" && ! synology_command_allowed "${command}"; then
    printf "[ERROR] Command '%s' is disabled on Synology DSM because its host workflow targets the reference UGREEN/Linux deployment. Use 'test synology' or 'synology status'.\n" "${command}" >&2
    return 2
  fi
}
