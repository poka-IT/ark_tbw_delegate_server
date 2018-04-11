# ARK True Block Weight Delegate Server
![ARK Community Fund Project](https://arkcommunity.fund/media-kit/funded/banner.png)
Development paid for by the
[ARK Community Fund](https://arkcommunity.fund/proposal/ark-tbw-delegate-server)<br/>
Development by [arkoar.group delegate](https://arkoar.group)

## Purpose
ARK True Block Weight Delegate Server is a community funded project for
managing voter reward disbursements.

Our focus is on making the delegate reward payment process as fast and easy as possible.

## Delegate Usage
### Installation

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
- API(Time Traveling Balance & Payment History Search)
  - Get a wallets balance at any moment in time
  - Payment run history
  - Other voter and payment related data
- Twitter Integration(Automated payment run tweets)
- Slack Integration(Automated payment messages)
- Discord Integration(Automated payment messages)
- Web/Desktop GUI
- V2 Wallet Plugin

## Contributors
<a href="https://github.com/arkoar-group">
  <img src="https://avatars0.githubusercontent.com/u/37595014?s=200&v=4"
    width="100">
  </img>
</a>
