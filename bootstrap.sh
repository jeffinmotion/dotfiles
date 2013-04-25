#!/bin/bash
cd "$(dirname "${BASH_SOURCE}")"
git pull origin master

# From https://github.com/bede/theftCam/blob/master/getDropboxFolder.sh
function base64_decode {
  local BASE64VALUE="$1"
  local RECODE=$( which recode )
  local UUDECODE=$( which uudecode )
  local PERL=$( which perl )
  local PYTHON=$( which python )
  if [ "$RECODE" ]
  then
    echo $( echo "$BASE64VALUE" | "$RECODE" /b64.. )
  elif [ "$UUDECODE" ]
  then
    local UUDECODE_STRING=$( printf 'begin-base64 0 -\n%s\n====\n' "$BASE64VALUE" )
    case $OSTYPE in
      linux*)  echo $( echo "$UUDECODE_STRING" | "$UUDECODE" ) ;;
      darwin*) echo $( echo "$UUDECODE_STRING" | "$UUDECODE" -p ) ;;
      *)       fatal "Unsupported platform $OSTYPE" ;;
    esac
  elif [ "$PERL" ]
  then
    echo $( "$PERL" -MMIME::Base64 -e "print decode_base64('$BASE64VALUE')" )
  elif [ "$PYTHON" ]
  then
    echo $( "$PYTHON" -c "import base64; print base64.b64decode('$BASE64VALUE')" )
  else
    fatal "Please install one of either recode, uudecode, perl or python"
  fi
}

# From https://github.com/bede/theftCam/blob/master/getDropboxFolder.sh
function getDropboxFolder() {
    if [ -f "$HOME/.dropbox/host.db" ]; then
      local DBFILE="$HOME/.dropbox/host.db"
      local DBVALUE=$( tail -1 "$DBFILE" )
      echo $( base64_decode "$DBVALUE" )
    fi
}

function linkExtra() {
	if ! [ -e $HOME/.extra ]; then

		local DBFOLDER=$( getDropboxFolder )

		if [ -e "$DBFOLDER/dotfiles_extras/.extra" ]; then
			ln -s "$DBFOLDER/dotfiles_extras/.extra" "$HOME/.extra"
		fi
	fi	
}

function doIt() {
	rsync --exclude ".git/" --exclude ".DS_Store" --exclude "bootstrap.sh" --exclude "README.md" -av . ~
	linkExtra
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt
	fi
fi
unset doIt
source ~/.bash_profile
