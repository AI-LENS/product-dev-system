#!/bin/sh
# POSIX-compliant pre-tool-use hook for Bash tool
# If inside a Git *worktree checkout*, prefix the incoming command with:
#   cd '<worktree_root>' && <original_command>
# No sh -c. No tokenization. Quoting preserved. Robust worktree detection.

DEBUG_MODE="${CLAUDE_HOOK_DEBUG:-false}"

debug_log() {
    case "${DEBUG_MODE:-}" in
        true|TRUE|1|yes|YES)
            printf '%s\n' "DEBUG [bash-worktree-fix]: $*" >&2
            ;;
    esac
}

# Safely single-quote a string for shell usage: foo'bar -> 'foo'"'"'bar'
shell_squote() {
    printf "%s" "$1" | sed "s/'/'\"'\"'/g"
}

# Detect if CWD is inside a *linked worktree* and print the worktree root.
# Returns 0 with path on stdout if yes; 1 otherwise.
get_worktree_path() {
    check_dir="$(pwd)"

    if [ ! -d "${check_dir}" ]; then
        debug_log "pwd is not a directory: ${check_dir}"
        return 1
    fi

    while [ "${check_dir}" != "/" ]; do
        if [ -f "${check_dir}/.git" ]; then
            gitdir_content=""
            if [ -r "${check_dir}/.git" ]; then
                IFS= read -r gitdir_content < "${check_dir}/.git" || gitdir_content=""
                gitdir_content=$(printf %s "$gitdir_content" | tr -d '\r')
            else
                debug_log "Unreadable .git file at: ${check_dir}"
            fi

            case "${gitdir_content}" in
                gitdir:*)
                    gitdir_path=${gitdir_content#gitdir:}
                    while [ "${gitdir_path# }" != "${gitdir_path}" ]; do
                        gitdir_path=${gitdir_path# }
                    done
                    case "${gitdir_path}" in
                        /*) abs_gitdir="${gitdir_path}" ;;
                        *)  abs_gitdir="${check_dir}/${gitdir_path}" ;;
                    esac
                    if [ -d "${abs_gitdir}" ]; then
                        case "${abs_gitdir}" in
                            */worktrees/*)
                                debug_log "Detected worktree root: ${check_dir} (gitdir: ${abs_gitdir})"
                                printf '%s\n' "${check_dir}"
                                return 0
                                ;;
                            *)
                                debug_log "Non-worktree .git indirection at: ${check_dir}"
                                return 1
                                ;;
                        esac
                    else
                        debug_log "gitdir path does not exist: ${abs_gitdir}"
                        return 1
                    fi
                    ;;
                *)
                    debug_log "Unknown .git file format at: ${check_dir}"
                    return 1
                    ;;
            esac

        elif [ -d "${check_dir}/.git" ]; then
            debug_log "Found regular git repo at: ${check_dir}"
            return 1
        fi

        check_dir=$(dirname "${check_dir}")
    done

    debug_log "No git repository found"
    return 1
}

should_skip_command() {
    cmd=$1

    if [ -z "${cmd##*[![:space:]]*}" ]; then
        debug_log "Skipping: empty/whitespace-only command"
        return 0
    fi

    case "${cmd}" in
        [[:space:]]cd|cd|[[:space:]]cd[[:space:]]*|cd[[:space:]]*)
            debug_log "Skipping: command already begins with cd"
            return 0
            ;;
    esac

    case "${cmd}" in
        :|[[:space:]]:|true|[[:space:]]true|false|[[:space:]]false|\
        pwd|[[:space:]]pwd*|\
        echo|[[:space:]]echo*|\
        export|[[:space:]]export*|\
        alias|[[:space:]]alias*|\
        unalias|[[:space:]]unalias*|\
        set|[[:space:]]set*|\
        unset|[[:space:]]unset*|\
        readonly|[[:space:]]readonly*|\
        umask|[[:space:]]umask*|\
        times|[[:space:]]times*|\
        .|[[:space:]].[[:space:]]*)
            debug_log "Skipping: trivial/builtin command"
            return 0
            ;;
    esac

    return 1
}

inject_prefix() {
    worktree_path=$1
    command=$2

    qpath=$(shell_squote "${worktree_path}")

    trimmed=${command}
    while [ "${trimmed% }" != "${trimmed}" ]; do
        trimmed=${trimmed% }
    done

    case "${trimmed}" in
        *"&")
            cmd_without_bg=${trimmed%&}
            while [ "${cmd_without_bg% }" != "${cmd_without_bg}" ]; do
                cmd_without_bg=${cmd_without_bg% }
            done
            printf '%s\n' "cd '${qpath}' && ${cmd_without_bg} &"
            ;;
        *)
            printf '%s\n' "cd '${qpath}' && ${command}"
            ;;
    esac
}

main() {
    original_command="$*"

    debug_log "Processing command: ${original_command}"

    if ! worktree_path="$(get_worktree_path)"; then
        debug_log "Not in worktree, passing through unchanged"
        printf '%s\n' "${original_command}"
        exit 0
    fi

    if should_skip_command "${original_command}"; then
        debug_log "Passing through unchanged"
        printf '%s\n' "${original_command}"
    else
        modified_command="$(inject_prefix "${worktree_path}" "${original_command}")"
        debug_log "Modified command: ${modified_command}"
        printf '%s\n' "${modified_command}"
    fi
}

main "$@"
