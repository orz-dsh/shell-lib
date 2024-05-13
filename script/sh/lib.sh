#!/bin/sh

if [ -z "${_DSH_SHELL_LIB_LOG_LEVEL}" ]; then
  export _DSH_SHELL_LIB_LOG_LEVEL="DEBUG"
fi

if [ -z "${_DSH_SHELL_LIB_LOG_INDENT}" ]; then
  export _DSH_SHELL_LIB_LOG_INDENT="-"
fi

if [ -z "${_DSH_SHELL_LIB_LOG_SENSITIVES}" ]; then
  export _DSH_SHELL_LIB_LOG_SENSITIVES=""
fi

_dsh_shell_lib_log_level_num() {
  case "$1" in
    "DEBUG")
      printf "0"
      ;;
    "INFO")
      printf "1"
      ;;
    "WARN")
      printf "2"
      ;;
    "ERROR")
      printf "3"
      ;;
    "FATAL")
      printf "4"
      ;;
    "TASK" | "CMD" | "VALUE")
      printf "9"
      ;;
    *)
      printf "0"
      ;;
  esac
}

_dsh_shell_lib_log() {
  __dsh_shell_lib_log_level="$1"
  __dsh_shell_lib_log_text="$2"

  if [ "$(_dsh_shell_lib_log_level_num "${__dsh_shell_lib_log_level}")" -lt "$(_dsh_shell_lib_log_level_num "${_DSH_SHELL_LIB_LOG_LEVEL}")" ]; then
    return 0
  fi
  
  __dsh_shell_lib_log_color=""
  case "${__dsh_shell_lib_log_level}" in
    "DEBUG")
      __dsh_shell_lib_log_color="\033[90m"
      ;;
    "INFO")
      __dsh_shell_lib_log_color="\033[94m"
      ;;
    "WARN")
      __dsh_shell_lib_log_color="\033[93m"
      ;;
    "ERROR")
      __dsh_shell_lib_log_color="\033[91m"
      ;;
    "FATAL")
      __dsh_shell_lib_log_color="\033[91m"
      ;;
    "TASK")
      __dsh_shell_lib_log_color="\033[95m"
      ;;
    "CMD")
      __dsh_shell_lib_log_color="\033[90m"
      ;;
    "VALUE")
      __dsh_shell_lib_log_color="\033[94m"
      ;;
  esac

  for __dsh_shell_lib_log_sensitive in ${_DSH_SHELL_LIB_LOG_SENSITIVES}; do
    __dsh_shell_lib_log_sensitive="$(LC_ALL=C awk -v str="${__dsh_shell_lib_log_sensitive}" 'BEGIN {gsub(/<\{\[dsh_escape_space]}>/, " ", str); gsub(/<\{\[dsh_escape_tab]}>/, "\t", str); gsub(/<\{\[dsh_escape_newline]}>/, "\n", str); gsub(/<\{\[dsh_escape_return]}>/, "\r", str); print str;}')"
    __dsh_shell_lib_log_text="$(LC_ALL=C awk -v str="${__dsh_shell_lib_log_text}" -v sen="${__dsh_shell_lib_log_sensitive}" 'BEGIN {gsub(sen, "[MASKED]", str); print str;}')"
  done

  __dsh_shell_lib_log_time=""
  if [ "${DSH_SHELL_LIB_LOG_WITH_TIME}" != "false" ]; then
    __dsh_shell_lib_log_time="$(date +%H:%M:%S)"
  fi

  __dsh_shell_lib_log_indent=""
  if [ -n "${_DSH_SHELL_LIB_LOG_INDENT}" ]; then
    __dsh_shell_lib_log_indent=" ${_DSH_SHELL_LIB_LOG_INDENT}"
  fi

  if [ "${DSH_SHELL_LIB_LOG_WITH_COLOR}" != "false" ]; then
    printf "${__dsh_shell_lib_log_color}[%s] [%-5s]%s %s\033[0m\n" "${__dsh_shell_lib_log_time}" "${__dsh_shell_lib_log_level}" "${__dsh_shell_lib_log_indent}" "${__dsh_shell_lib_log_text}"
  else
    printf "[%s] [%-5s]%s %s\n" "${__dsh_shell_lib_log_time}" "${__dsh_shell_lib_log_level}" "${__dsh_shell_lib_log_indent}" "${__dsh_shell_lib_log_text}"
  fi
}

_dsh_shell_lib_join_cmd() {
  __dsh_shell_lib_join_cmd=""
  for __dsh_shell_lib_join_cmd_part in "$@"; do
    case "${__dsh_shell_lib_join_cmd_part}" in
      *" "* | *"\t"* | *"\n"* | *"\r"*)
        __dsh_shell_lib_join_cmd_part="\"${__dsh_shell_lib_join_cmd_part}\""
        ;;
    esac
    if [ -z "${__dsh_shell_lib_join_cmd}" ]; then
      __dsh_shell_lib_join_cmd="${__dsh_shell_lib_join_cmd_part}"
    else
      __dsh_shell_lib_join_cmd="${__dsh_shell_lib_join_cmd} ${__dsh_shell_lib_join_cmd_part}"
    fi
  done
  printf "%s" "${__dsh_shell_lib_join_cmd}"
}

_dsh_shell_lib_disable_errexit() {
  case "$-" in
    *e*)
      set +o errexit
      _DSH_SHELL_LIB_ERREXIT_DISABLED="true"
      ;;
  esac
}

_dsh_shell_lib_reset_errexit() {
  if [ "${_DSH_SHELL_LIB_ERREXIT_DISABLED}" = "true" ]; then
    set -o errexit
    unset _DSH_SHELL_LIB_ERREXIT_DISABLED
  fi
}

dsh_set_log_level() {
  case "$1" in
    "DEBUG" | "INFO" | "WARN" | "ERROR" | "FATAL")
      export _DSH_SHELL_LIB_LOG_LEVEL="$1"
      ;;
    *)
      export _DSH_SHELL_LIB_LOG_LEVEL="DEBUG"
      ;;
  esac
}

dsh_add_log_sensitive() {
  __dsh_add_log_sensitive_value=""
  for __dsh_add_log_sensitive_value in "$@"; do
    if [ -z "${__dsh_add_log_sensitive_value}" ]; then
      continue
    fi
    __dsh_add_log_sensitive_value="$(LC_ALL=C awk -v str="${__dsh_add_log_sensitive_value}" 'BEGIN {gsub(" ", "<{[dsh_escape_space]}>", str); gsub("\t", "<{[dsh_escape_tab]}>", str); gsub("\n", "<{[dsh_escape_newline]}>", str); gsub("\r", "<{[dsh_escape_return]}>", str); print str;}')"
    case "${_DSH_SHELL_LIB_LOG_SENSITIVES}" in
      "$__dsh_add_log_sensitive_value" | *" ${__dsh_add_log_sensitive_value}"* | *"${__dsh_add_log_sensitive_value} "*)
        continue
        ;;
    esac
    if [ -z "${_DSH_SHELL_LIB_LOG_SENSITIVES}" ]; then
      export _DSH_SHELL_LIB_LOG_SENSITIVES="${__dsh_add_log_sensitive_value}"
    else
      export _DSH_SHELL_LIB_LOG_SENSITIVES="${_DSH_SHELL_LIB_LOG_SENSITIVES} ${__dsh_add_log_sensitive_value}"
    fi
  done
}

dsh_log_debug(){
  _dsh_shell_lib_log "DEBUG" "$1"
}

dsh_log_info(){
  _dsh_shell_lib_log "INFO" "$1"
}

dsh_log_warn(){
  _dsh_shell_lib_log "WARN" "$1"
}

dsh_log_error(){
  _dsh_shell_lib_log "ERROR" "$1"
}

dsh_log_fatal(){
  _dsh_shell_lib_log "FATAL" "$1"
  exit 1
}

dsh_log_task_start() {
  _dsh_shell_lib_log "TASK" "$1"
  export _DSH_SHELL_LIB_LOG_INDENT="${_DSH_SHELL_LIB_LOG_INDENT} -"
}

dsh_log_task_finish() {
  __dsh_log_task_finish_indent_count="${#_DSH_SHELL_LIB_LOG_INDENT}"
  if [ "${__dsh_log_task_finish_indent_count}" -ge "2" ]; then
    __dsh_log_task_finish_indent="$(LC_ALL=C awk -v str="${_DSH_SHELL_LIB_LOG_INDENT}" -v len="${__dsh_log_task_finish_indent_count}" -- 'BEGIN {str=substr(str, 0, len-2); print str;}')"
    export _DSH_SHELL_LIB_LOG_INDENT="${__dsh_log_task_finish_indent}"
  fi
}

dsh_log_value() {
  __dsh_log_value_name="$1"
  __dsh_log_value="$2"
  _dsh_shell_lib_log "VALUE" "${__dsh_log_value_name} = \`${__dsh_log_value}\`"
}

dsh_log_values() {
  __dsh_log_value_name=""
  for __dsh_log_value_name in "$@"; do
    __dsh_log_value=""
    eval "__dsh_log_value=\"\${${__dsh_log_value_name}}\""
    _dsh_shell_lib_log "VALUE" "${__dsh_log_value_name} = \`${__dsh_log_value}\`"
  done
}

dsh_log_cmd() {
  _dsh_shell_lib_log "CMD" "$1"
}

dsh_log_check_value() {
  dsh_log_value "$1" "$2"
  dsh_check_value "$1" "$2"
}

dsh_log_check_values() {
  dsh_log_values "$@"
  dsh_check_values "$@"
}

dsh_check_value() {
  __dsh_check_value_name="$1"
  __dsh_check_value="$2"
  if [ -z "${__dsh_check_value}" ]; then
    dsh_log_fatal "${__dsh_check_value_name} value empty"
  fi
}

dsh_check_values() {
  __dsh_check_value_name=""
  for __dsh_check_value_name in "$@"; do
    __dsh_check_value=""
    eval "__dsh_check_value=\"\${${__dsh_check_value_name}}\""
    if [ -z "${__dsh_check_value}" ]; then
      dsh_log_fatal "${__dsh_check_value_name} value empty"
    fi
  done
}

dsh_exec_task() {
  __dsh_exec_task="$(_dsh_shell_lib_join_cmd "$@")"
  dsh_log_task_start "${__dsh_exec_task}"
  eval "${__dsh_exec_task}"
  __dsh_exec_task_result=$?
  dsh_log_task_finish
  return ${__dsh_exec_task_result}
}

dsh_exec_cmd() {
  __dsh_exec_cmd="$(_dsh_shell_lib_join_cmd "$@")"
  dsh_log_cmd "${__dsh_exec_cmd}"
  eval "${__dsh_exec_cmd}"
  return $?
}

dsh_try_source() {
  __dsh_try_source_file="$1"
  if [ -f "${__dsh_try_source_file}" ]; then
    # shellcheck source=/dev/null
    . "${__dsh_try_source_file}"
    DSH_TRY_SOURCE_SUCCESS="true"
  else
    # shellcheck disable=SC2034
    DSH_TRY_SOURCE_SUCCESS="false"
  fi
}

dsh_curl_download() {
  __dsh_curl_download_url="$1"
  __dsh_curl_download_output="$2"
  dsh_log_check_value "curl_download_url" "${__dsh_curl_download_url}"
  dsh_log_check_value "curl_download_output" "${__dsh_curl_download_output}"
  __dsh_curl_download_output_dir="$(dirname "${__dsh_curl_download_output}")"
  if [ ! -d "${__dsh_curl_download_output_dir}" ]; then
    dsh_exec_cmd mkdir -p "${__dsh_curl_download_output_dir}"
  fi
  shift 2
  __dsh_curl_download_option="$(_dsh_shell_lib_join_cmd "$@")"
  if [ -n "${__dsh_curl_download_option}" ]; then
    __dsh_curl_download_option="${__dsh_curl_download_option} "
  fi
  __dsh_curl_download_command="curl -sL -w \"%{http_code}\" -o \"${__dsh_curl_download_output}\" ${__dsh_curl_download_option}${__dsh_curl_download_url}"
  dsh_log_cmd "${__dsh_curl_download_command}"
  _dsh_shell_lib_disable_errexit
  __dsh_curl_download_http_code="$(eval "${__dsh_curl_download_command}")"
  __dsh_curl_download_exit_code=$?
  _dsh_shell_lib_reset_errexit
  dsh_log_check_value "curl_download_http_code" "${__dsh_curl_download_http_code}"
  dsh_log_check_value "curl_download_exit_code" "${__dsh_curl_download_exit_code}"
  if [ "${__dsh_curl_download_exit_code}" -ne "0" ]; then
    dsh_log_error "curl download exit code error"
    return 1
  fi
  if [ "${__dsh_curl_download_http_code}" -lt "200" ] || [ "${__dsh_curl_download_http_code}" -ge "300" ]; then
    dsh_log_error "curl download http code error"
    return 1
  fi
}

dsh_curl_upload() {
  __dsh_curl_upload_url="$1"
  __dsh_curl_upload_input="$2"
  dsh_log_check_value "curl_upload_url" "${__dsh_curl_upload_url}"
  dsh_log_check_value "curl_upload_input" "${__dsh_curl_upload_input}"
  if [ ! -f "${__dsh_curl_upload_input}" ]; then
    dsh_log_error "curl upload input file not exists"
    return 1
  fi
  shift 2
  __dsh_curl_upload_option="$(_dsh_shell_lib_join_cmd "$@")"
  if [ -n "${__dsh_curl_upload_option}" ]; then
    __dsh_curl_upload_option="${__dsh_curl_upload_option} "
  fi
  __dsh_curl_upload_command="curl -sL -w \"%{http_code}\" -o /dev/null ${__dsh_curl_upload_option}-T \"${__dsh_curl_upload_input}\" ${__dsh_curl_upload_url}"
  dsh_log_cmd "${__dsh_curl_upload_command}"
  _dsh_shell_lib_disable_errexit
  __dsh_curl_upload_http_code="$(eval "${__dsh_curl_upload_command}")"
  __dsh_curl_upload_exit_code=$?
  _dsh_shell_lib_reset_errexit
  dsh_log_check_value "curl_upload_http_code" "${__dsh_curl_upload_http_code}"
  dsh_log_check_value "curl_upload_exit_code" "${__dsh_curl_upload_exit_code}"
  if [ "${__dsh_curl_download_exit_code}" -ne "0" ]; then
    dsh_log_error "curl upload exit code error"
    return 1
  fi
  if [ "${__dsh_curl_upload_http_code}" -lt "200" ] || [ "${__dsh_curl_upload_http_code}" -ge "300" ]; then
    dsh_log_error "curl upload http code error"
    return 1
  fi
}
