#!/bin/bash
sudo apt-get update -y

if [ "`which wget`" == "" ]; then
  sudo apt-get install -y wget
fi

if [ "`which erl`" == "" ]; then
  sudo apt-get install -y erlang
fi

wget https://github.com/arkoar-group/ark_tbw_delegate_server/blob/master/releases/atbw-1.0.0?raw=true
sudo rm /usr/bin/atbw 2> /dev/null
sudo mv atbw-1.0.1?raw=true /usr/bin/atbw
sudo chmod 0755 /usr/bin/atbw

echo "Type atbw --help to get started"
