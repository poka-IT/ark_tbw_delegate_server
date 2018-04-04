defmodule ArkTbwDelegateServer.CLI do
  @moduledoc """
  Main command line interface.

  ## Configuration

  The initial run of **ARK True Block Weight Delegate Server** will require you
  to setup your delegate information and a point in time to start payments from.
  Going forward, ArkTbws will manage your payment windows for you by paying out
  all unpaid forged blocks since your last payment run.

  Pay run data is recorded on the ARK blockchain in the `vendorId` field encoded
  in `JSON` format. The data is recorded when paying to your `delegate_payout_address`.

  Any front end data you would like to show your delegates can be built from this data.
  Learn more about how to do that here `We need to write something about this and put it here`

  > NOTE: Configuration is saved and defaults to the last values entered. If no
  value is passed in command line or via past config, the user is prompted.
  You can update your config using the menu or cli options at any time.

  ## Required Configuration Options
  * config
  * delegate address
  * delegate payout address
  * voter share
  * starting block height
  * private seed for sending automated payments
  * node url(can be ip or dns address)

  ### Command Line Aliases and Configurations options
  `./ark_tbw_delegate_server --help`

  `--delegate_address(da)`
  `--delegate_payout_address(dpa)`
  `--voter_share(s)`
  `--initial_block_height(h)`
  `--private_key(pk)`
  `--node_url(n)`
  """

  @config_write_failed_message "Unable to open the config file for writing. " <>
    "WARNING: Your configuration was not saved."

  @delegate_address_prompt "Please enter the address of the delegate you " <>
    "would like to scan"

  @delegate_payout_address_prompt "Please enter the address you would like " <>
    "receive the delegate share at"

  @initial_block_height_prompt "Please enter the starting block height. " <>
    "If you're not sure, enter the number of the first block forged by the " <>
    "delegate you are scanning"

  @invalid_voter_share_message "Please enter a value between 0 and 1..."

  @node_url_prompt "Please enter the address of the node you'd like to " <>
    "scan. Please be friendly to the ecosystem and use your own"

  @private_key_prompt "Please enter the private key of the account from " <>
    "which the ARK rewards will be sent"

  @switches [
    config: :string,
    delegate_address: :string,
    delegate_payout_address: :string,
    help: nil,
    initial_block_height: :string,
    node_url: :string,
    private_key: :string,
    voter_share: :string
  ]

  @switch_aliases [
    c: :config,
    da: :delegate_address,
    dpa: :delegate_payout_address,
    h: :initial_block_height,
    n: :node_url,
    pk: :private_key,
    s: :voter_share
  ]

  @switch_defaults [
    config: "./config.json",
    node_url: :default,
    voter_share: "0.9"
  ]

  @voter_share_prompt "Please enter the percentage share that voters " <>
    "receive expressed as a decimal. (ex. 0.9)"

  import ArkTbwDelegateServer.Utils

  alias ArkTbwDelegateServer.{Logger, MainMenu}

  @doc """
  Entry point for command line application.
  """
  @spec main(List.t) :: any
  def main(args \\ []) do
    if Enum.member?(args, "--help") do
      help()
    else
      clear()
      motd()

      opts = extract_options(args)
      config = load_config(opts)

      @switch_defaults
      |> Enum.into(%{})
      |> Map.merge(config) # Merge the config file options
      |> Map.merge(opts) # Merge the command line options
      |> prompt_for_missing_options # Ask for missing options
      |> validate_share
      |> save_config(opts) # Save the config
      |> MainMenu.run
    end
  end

  # private

  defp config_file_path(opts) do
    Map.get(opts, :config, @switch_defaults[:config])
  end

  defp extract_options(args) do
    args
    |> OptionParser.parse(aliases: @switch_aliases, switches: @switches)
    |> elem(0)
    |> Enum.into(%{})
  end

  defp fetch_or_prompt(opts, key, prompt) do
    case Map.get(opts, key) do
      nil -> receive_input(prompt)
      value -> value
    end
  end

  defp help do
    [:color23, "
    ---------------------------------
    | ArkTbws Help dots8            |
    |                               |
    |                               |
    --------------------------------
    "]
    |> Bunt.puts
  end

  defp load_config(opts) do
    case File.read(config_file_path(opts)) do
      {:ok, json} -> Poison.Parser.parse!(json, keys: :atoms!)
      _error -> %{}
    end
  end

  defp motd do
    [:color202,
"""
ARK True Block Weight Delegate Server 1.0
"""
    ]
    |> Bunt.puts
  end

  # delegate_address: :string,
  # delegate_payout_address: :string,
  # initial_block_height: :string,
  # node_url: :string,
  # private_key: :string
  defp prompt_for_missing_options(opts) do
    delegate_address =
      case fetch_or_prompt(opts, :delegate_address, @delegate_address_prompt) do
        :back -> Process.exit(self(), :normal)
        :quit -> Process.exit(self(), :normal)
        value -> value
      end

    delegate_payout_address =
      case fetch_or_prompt(
        opts,
        :delegate_payout_address,
        @delegate_payout_address_prompt
      ) do
        :back -> Process.exit(self(), :normal)
        :quit -> Process.exit(self(), :normal)
        value -> value
      end

    initial_block_height =
      case fetch_or_prompt(
        opts,
        :initial_block_height,
        @initial_block_height_prompt
      ) do
        :back -> Process.exit(self(), :normal)
        :quit -> Process.exit(self(), :normal)
        value -> value
      end

    node_url =
      case fetch_or_prompt(opts, :node_url, @node_url_prompt) do
        :back -> Process.exit(self(), :normal)
        :quit -> Process.exit(self(), :normal)
        value -> value
      end

    private_key =
      case fetch_or_prompt(opts, :private_key, @private_key_prompt) do
        :back -> Process.exit(self(), :normal)
        :quit -> Process.exit(self(), :normal)
        value -> value
      end

    voter_share =
      case fetch_or_prompt(opts, :voter_share, @voter_share_prompt) do
        :back -> Process.exit(self(), :normal)
        :quit -> Process.exit(self(), :normal)
        value -> value
      end

    %{
      delegate_address: delegate_address,
      delegate_payout_address: delegate_payout_address,
      initial_block_height: initial_block_height,
      node_url: node_url,
      private_key: private_key,
      voter_share: voter_share
    }
  end

  defp save_config(config, opts) do
    file_path = Map.get(opts, :config, @switch_defaults[:config])
    json = Poison.encode!(config)

    case File.open(file_path, [:write]) do
      {:ok, pid} ->
        case IO.binwrite(pid, json) do
          :ok ->
            case File.close(pid) do
              :ok -> :ok
              _ -> Logger.warn(@config_write_failed_message)
            end
          _ ->
            Logger.warn(@config_write_failed_message)
        end
      _ ->
        Logger.warn(@config_write_failed_message)
    end

    config
  end

  defp validate_share(%{voter_share: voter_share} = opts)
  when is_bitstring(voter_share) do
    try do
      num = voter_share |> Decimal.new |> Decimal.to_float

      opts
      |> Map.put(:voter_share, num)
      |> validate_share
    rescue
      Decimal.Error -> opts |> Map.delete(:voter_share) |> validate_share
    end
  end

  defp validate_share(%{voter_share: voter_share} = opts)
  when is_float(voter_share) do
    cond do
      voter_share <= 1 && voter_share >= 0 ->
        opts
      true ->
        IO.puts(@invalid_voter_share_message)
        opts
        |> Map.delete(:voter_share)
        |> validate_share
    end
  end

  defp validate_share(opts) do
    opts
    |> Map.delete(:voter_share)
    |> prompt_for_missing_options
    |> validate_share
  end
end
