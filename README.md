# ARK True Block Weight Delegate Server
![ARK Community Fund Project](https://arkcommunity.fund/media-kit/funded/banner.png)
Development paid for by the
[ARK Community Fund](https://arkcommunity.fund/proposal/ark-tbw-delegate-server)<br/>
Development by [arkoar.group delegate](https://arkoar.group)

## Purpose
ARK True Block Weight Delegate Server is a community funded project for
managing voter reward disbursements.

Our focus is on making the delegate true block reward payment process as fast, accurate, and easy as possible.

## Features
- Hopper resistant
- Accurate to the arktoshi
- Rewards calculated by the weight of your wallet at the time the block was forged
- Rolling Balances
- Adjustable Payment Threshold
- Adjustable Share Percentage
- Automated payments
- Audit Log
- Disbursement History
- Outstanding Balances

## Installation

Run the following command from your Ubuntu 16.04 Terminal:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/arkoar-group/ark_tbw_delegate_server/11f1a69ff98f32a11544188609adea7a62281b14/bin/install.sh)" && source ~/.bashrc
```

Bleeding Edge:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/arkoar-group/ark_tbw_delegate_server/master/bin/install.sh)" && source ~/.bashrc
```

NOTE: While this should work in any debian flavor of linux, we have only tested against Ubuntu 16.04 LTS.

## Running the app

From your terminal type `atbw`. For more info, run `atbw --help`.

```sh
$ atbw --help

Usage: atbw <command>

Configuration Options:

    -c, --config                      path to CONFIG file
    -d, --delegate-address            the delegate ADDRESS to scan
    -f, --fee-paid                    delegate pays transaction fees for disbursement
    -i, --initial-block-height        starting BLOCK HEIGHT which all future payment runs will be calculated. This should be the block height of the last block you paid out.
    -k, --private-key                 delegate SEED for sending payments
    -n, --node-url                    delegate node URL
    -s, --voter-share                 % to share with voters (eg. 0.9)
    -t, --payout-threshold            the minimum ARK due before disbursement

        --help,                       this help menu
```

## Documentation

https://medium.com/arkoar-group/ark-true-block-weight-delegate-server-1ea5a60233f6

## Developers

### Contributions
If you would like to contribute to ARK TBW Server, fork this repository and
submit a pull request on a new branch.

#### Editor Settings
  - 1 soft tab
  - 80 char line limit
  - strip trailing white space
  - add new line to eof on save

#### Development Requirements
  - Erlang 20.1
  - Elixir 1.6+

#### Development Setup
We recommend using [asdf](https://github.com/asdf-vm/asdf) to manage Erlang & Elixir installations. You can read and watch more about the power of Erlang/Elixir, BeamVM and OTP [here](https://erlangcentral.org/tag/beam/). Elixir/Erlang now power some of the worlds largest messaging systems such as WhatsApp, League of Legends, Discord, and more.  

```
mix deps.get
mix escript.build
./ark_tbw_delegate_server
```

## Development Roadmap
**If you would like to help fund feature development of this application you can do so through the ARK Community Fund.**
- Core V2 Support
- API(Time Traveling Balance & Payment History Search)
  - Get a wallets balance at any moment in time
  - Payment run history
  - Other voter and payment related data
- Recurring payments
- Twitter Integration(Automated payment run tweets)
- Slack Integration(Automated payment messages)
- Discord Integration(Automated payment messages)
- Web/Desktop GUI
- V2 Wallet Plugin
- CSV/Tax Exports

## Contributors
<a href="https://github.com/arkoar-group">
  <img src="https://avatars0.githubusercontent.com/u/37595014?s=200&v=4"
    width="100">
  </img>
</a>
