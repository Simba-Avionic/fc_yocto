#!/usr/bin/env bash
set -euo pipefail

err() {
    echo "[build-yocto] $*" >&2
}

require_var() {
    local name="$1"
    local value="${!name:-}"
    if [[ -z "${value}" ]]; then
        err "Missing required environment variable: ${name}"
        exit 1
    fi
}

append_conf_line() {
    local line="$1"
    local conf_file="$2"

    if ! grep -qsF "${line}" "${conf_file}"; then
        printf '\n%s\n' "${line}" >>"${conf_file}"
    fi
}

main() {
    require_var "YOCTO_IMAGE"

    local source_dir="${YOCTO_SOURCE_DIR:-/workspace}"
    local build_dir="${YOCTO_BUILD_DIR:-${source_dir}/build}"
    local dl_dir="${YOCTO_DL_DIR:-}"
    local sstate_dir="${YOCTO_SSTATE_DIR:-}"
    local env_setup="${YOCTO_ENV_SETUP:-oe-init-build-env}"
    local extra_conf="${YOCTO_EXTRA_CONF:-}"

    if [[ ! -d "${source_dir}" ]]; then
        err "YOCTO_SOURCE_DIR (${source_dir}) is not a directory."
        exit 1
    fi

    if [[ ! -f "${source_dir}/${env_setup}" ]]; then
        err "Cannot find ${env_setup} inside ${source_dir}."
        exit 1
    fi

    mkdir -p "${build_dir}"

    cd "${source_dir}"
    # shellcheck source=/dev/null
    set +u
    source "${env_setup}" "${build_dir}"
    set -u

    local conf_file="${BUILDDIR}/conf/local.conf"

    if [[ -n "${dl_dir}" ]]; then
        mkdir -p "${dl_dir}"
        append_conf_line "DL_DIR ?= \"${dl_dir}\"" "${conf_file}"
    fi

    if [[ -n "${sstate_dir}" ]]; then
        mkdir -p "${sstate_dir}"
        append_conf_line "SSTATE_DIR ?= \"${sstate_dir}\"" "${conf_file}"
    fi

    if [[ -n "${extra_conf}" ]]; then
        printf '\n%s\n' "${extra_conf}" >>"${conf_file}"
    fi

    bitbake virtual/kernel -c compile

    err "Starting bitbake ${YOCTO_IMAGE}"
    bitbake "${YOCTO_IMAGE}"
}



main "$@"