# sup yarn
# https://yarnpkg.com

# `yarn` is a node wrapper, and node is provided by fnm, which is initialised
# much later in .zshrc. Skip silently if node isn't resolvable yet, otherwise
# every shell start prints `env: node: No such file or directory`.
if (( $+commands[yarn] && $+commands[node] ))
then
  yarn_global_bin="$(yarn global bin 2>/dev/null)"
  if [[ -n $yarn_global_bin && ":$PATH:" != *":$yarn_global_bin:"* ]]
  then
    export PATH="$PATH:$yarn_global_bin"
  fi
  unset yarn_global_bin
fi
