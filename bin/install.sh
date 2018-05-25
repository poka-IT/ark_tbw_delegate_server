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

  sudo apt-get -y install build-essential
  wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
  sudo dpkg -i erlang-solutions_1.0_all.deb
  sudo rm erlang-solutions_1.0_all.deb
  sudo apt-get update -y
  sudo apt-get install -y erlang=1:20.3-1

fi

wget https://github.com/arkoar-group/ark_tbw_delegate_server/blob/master/releases/atbw-1.1.0?raw=true
sudo rm /usr/bin/atbw 2> /dev/null
sudo mv atbw-1.1.0?raw=true /usr/bin/atbw
sudo chmod 0755 /usr/bin/atbw

echo "Type atbw --help to get started"
