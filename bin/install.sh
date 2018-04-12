#!/bin/bash
sudo apt-get update -y

if [ -z "`which git`" ]; then
  sudo apt-get install -y git
fi

if [ -z "`which wget`" ]; then
  sudo apt-get install -y wget
fi

if [ -z "`which erl`" ]; then
  if [ -z "`which asdf`" ]; then
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.4.3
    echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
    echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
    . $HOME/.asdf/asdf.sh
    . $HOME/.asdf/completions/asdf.bash
  fi

  sudo apt-get -y install libssl-dev
  sudo apt-get -y install make
  sudo apt-get -y install automake
  sudo apt-get -y install gcc
  sudo apt-get -y install build-essential
  sudo apt-get -y install autoconf
  sudo apt-get -y install m4
  sudo apt-get -y install libncurses5-dev
  sudo apt-get -y install libwxgtk3.0-dev
  sudo apt-get -y install libgl1-mesa-dev
  sudo apt-get -y install libglu1-mesa-dev
  sudo apt-get -y install libssh-dev
  sudo apt-get -y install unixodbc-dev

  asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
  asdf install erlang 20.3
  asdf global erlang 20.3
fi

wget https://github.com/arkoar-group/ark_tbw_delegate_server/blob/master/releases/atbw-1.0.0?raw=true
sudo rm /usr/bin/atbw 2> /dev/null
sudo mv atbw-1.0.0?raw=true /usr/bin/atbw
sudo chmod 0755 /usr/bin/atbw

echo "Type atbw --help to get started"
