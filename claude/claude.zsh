# Claude Code: pick the account from the current directory.
#
# Personal uses the default config dir (~/.claude). Anything under
# $CLAUDE_BITHIPPIE_ROOT uses its own config dir, which carries its own
# login, settings, plugins, memory and history. Override the root in
# ~/.localrc if it ever moves.

: ${CLAUDE_BITHIPPIE_ROOT:=$HOME/projects/bithippie}
: ${CLAUDE_BITHIPPIE_CONFIG:=$HOME/.claude-bithippie}
# GitHub CLI follows the same profile: its own login lives here.
: ${GH_BITHIPPIE_CONFIG:=$HOME/.config/gh-bithippie}

# Prints "bithippie" or "personal" for a directory (default: $PWD).
_claude_profile_for() {
  local dir=${${1:-$PWD}:A}
  case "$dir/" in
    "${CLAUDE_BITHIPPIE_ROOT:A}"/*) print bithippie ;;
    *) print personal ;;
  esac
}

claude() {
  # An explicit CLAUDE_CONFIG_DIR always wins.
  if [[ -n $CLAUDE_CONFIG_DIR ]]; then
    command claude "$@"
  elif [[ $(_claude_profile_for) == bithippie ]]; then
    print -P "%F{244}→ claude: bithippie account%f" >&2
    claude-bithippie "$@"
  else
    command claude "$@"
  fi
}

# Force an account regardless of directory. The bithippie session also gets
# the bithippie gh login, so `gh` from Claude's own shell acts as bithippie.
claude-bithippie() {
  CLAUDE_CONFIG_DIR=$CLAUDE_BITHIPPIE_CONFIG \
    GH_CONFIG_DIR=${GH_CONFIG_DIR:-$GH_BITHIPPIE_CONFIG} command claude "$@"
}
claude-personal()  { env -u CLAUDE_CONFIG_DIR -u GH_CONFIG_DIR claude "$@" }

# Top-level gh subcommands (built-ins plus aliases), cached per config dir.
typeset -gA _gh_subcommands_cache
_gh_knows_subcommand() {
  local cfg=$1 word=$2 key=${1:-default}
  if [[ -z ${_gh_subcommands_cache[$key]} ]]; then
    local out
    if [[ -n $cfg ]]; then
      out=$(GH_CONFIG_DIR=$cfg command gh __complete "" 2>/dev/null)
    else
      out=$(command gh __complete "" 2>/dev/null)
    fi
    # __complete prints "name<TAB>description" plus trailing directive lines.
    _gh_subcommands_cache[$key]=$(print -r -- "$out" | awk -F'\t' 'NF > 1 { print $1 }')
  fi
  [[ -n ${(M)${(f)_gh_subcommands_cache[$key]}:#$word} ]]
}

# gh: same folder rule. An explicit GH_CONFIG_DIR always wins.
# Unknown subcommands fall through to the real command, so a stray `gh`
# prefix (e.g. `gh ls`) still does what you meant instead of erroring out.
gh() {
  local cfg=$GH_CONFIG_DIR
  if [[ -z $cfg && $(_claude_profile_for) == bithippie ]]; then
    cfg=$GH_BITHIPPIE_CONFIG
  fi

  if [[ -n $1 && $1 != -* && $1 != gh ]] && ! _gh_knows_subcommand "$cfg" "$1"; then
    if (( $+commands[$1] || $+builtins[$1] || $+functions[$1] )); then
      print -P "%F{244}→ gh: no subcommand '$1'; running it directly%f" >&2
      "$@"
      return
    fi
  fi

  if [[ -n $cfg ]]; then
    GH_CONFIG_DIR=$cfg command gh "$@"
  else
    command gh "$@"
  fi
}

claude-whoami() {
  local profile=$(_claude_profile_for)
  if [[ -n $CLAUDE_CONFIG_DIR ]]; then
    print "explicit: CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR"
  elif [[ $profile == bithippie ]]; then
    print "bithippie ($CLAUDE_BITHIPPIE_CONFIG)"
  else
    print "personal (~/.claude)"
  fi
  if [[ -n $GH_CONFIG_DIR ]]; then
    print "gh: explicit GH_CONFIG_DIR=$GH_CONFIG_DIR"
  elif [[ $profile == bithippie ]]; then
    print "gh: bithippie ($GH_BITHIPPIE_CONFIG)"
  else
    print "gh: personal (~/.config/gh)"
  fi
}

# Idempotent: (re)link what bithippie shares with personal. Re-run after
# adding a personal skill you also want in bithippie.
#   shared by symlink: CLAUDE.md, RTK.md, keybindings.json, each personal skill
#   seeded once:       settings.json with only the personal hooks (RTK)
#   never touched:     bithippie's own skills, plugins, memory, login
claude-bithippie-sync() {
  local src=$HOME/.claude dst=$CLAUDE_BITHIPPIE_CONFIG f s
  mkdir -p $dst/skills
  for f in CLAUDE.md RTK.md keybindings.json; do
    [[ -e $src/$f && ! -e $dst/$f ]] && ln -s $src/$f $dst/$f && print "linked $f"
  done
  for s in $src/skills/*(N); do
    [[ -e $dst/skills/${s:t} || -L $dst/skills/${s:t} ]] && continue
    ln -s $s $dst/skills/${s:t} && print "linked skill ${s:t}"
  done
  if [[ ! -e $dst/settings.json ]]; then
    python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); json.dump({"hooks": d.get("hooks", {})}, open(sys.argv[2], "w"), indent=2)' \
      $src/settings.json $dst/settings.json && print "seeded settings.json (hooks only)"
  fi
  # gh: copy preferences (aliases, editor, protocol) once; never the login.
  mkdir -p $GH_BITHIPPIE_CONFIG
  if [[ -e $HOME/.config/gh/config.yml && ! -e $GH_BITHIPPIE_CONFIG/config.yml ]]; then
    cp $HOME/.config/gh/config.yml $GH_BITHIPPIE_CONFIG/config.yml && print "seeded gh config.yml"
  fi
}
