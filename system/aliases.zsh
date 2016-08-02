# grc overides for ls
#   Made possible through contributions from generous benefactors like
#   `brew install coreutils`
if $(gls &>/dev/null)
then
  alias ls="gls -F --color"
  alias l="gls -lAh --color"
  alias ll="gls -lFh --color"
  alias la='gls -A --color'
fi

alias http-server='python -m SimpleHTTPServer'
#alias weather="curl -s ipinfo.io/$1 | curl -s wttr.in/$1 | head -n 38"
alias weather="curl -s wttr.in/72.229.28.185 | head -n 38"
