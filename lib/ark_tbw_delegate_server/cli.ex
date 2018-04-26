defmodule ArkTbwDelegateServer.CLI do
  @moduledoc """
  Main command line interface.

  ## Configuration

  The initial run of **ARK True Block Weight Delegate Server** will require you
  to setup your delegate information and a point in time to start payments from.
  Going forward, ArkTbws will manage your payment windows for you by paying out
  all unpaid forged blocks since your last payment run.

  Pay run data is recorded on the ARK blockchain in the `vendorId` field encoded
  in `JSON` format. The data is recorded when paying to your
  `delegate_payout_address`.

  Any front end data you would like to show your delegates can be built from
  this data. Learn more about how to do that here `We need to write something
  about this and put it here`

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

  `--delegate_address(d)`
  `--delegate_payout_address(p)`
  `--voter_share(s)`
  `--initial_block_height(i)`
  `--private_key(k)`
  `--node_url(n)`
  """

  @config_write_failed_message "Unable to open the config file for writing. " <>
    "WARNING: Your configuration was not saved."

  @delegate_address_prompt "Please enter the address of the delegate you " <>
    "would like to scan"

  @devnet_nethash "578e820911f24e039733b45e4882b73e301f813a0d2c31330dafda8" <>
    "4534ffa23"

  @fee_paid_prompt "Do you cover transaction fees for disbursement " <>
    "payments? (Y/N)"

  @initial_block_height_prompt "Please enter the starting block height. " <>
    "This is either the height of the last block you paid out or '0'"

  @invalid_voter_share_message "Please enter a value between 0 and 1..."

  @mainnet_nethash "6e84d08bd299ed97c212c886c98a57e36545c8f5d645ca7eeae63a8b" <>
    "d62d8988"

  @node_url_prompt "Please enter the address of the node you'd like to " <>
    "scan. Please be friendly to the ecosystem and use your own"

  @payout_threshold_prompt "Please enter the minimum balance required for " <>
    "a reward disbursement (example: 0.3)"

  @private_key_prompt "Please enter the private key of your delegate " <>
    "account for reward disbursements"

  @switches [
    command: :string,
    config: :string,
    delegate_address: :string,
    delegate_payout_address: :string,
    help: nil,
    fee_paid: :string,
    force: nil,
    initial_block_height: :string,
    node_url: :string,
    payout_threshold: :string,
    private_key: :string,
    voter_share: :string
  ]

  @switch_aliases [
    c: :config,
    d: :delegate_address,
    e: :command,
    f: :fee_paid,
    i: :initial_block_height,
    k: :private_key,
    n: :node_url,
    p: :delegate_payout_address,
    s: :voter_share,
    t: :payout_threshold
  ]

  @voter_share_prompt "Please enter the percentage share that voters " <>
    "receive expressed as a decimal (example: 0.95)"

  import ArkTbwDelegateServer.Utils

  alias ArkTbwDelegateServer.{Audit, Logger, MainMenu}

  @doc """
  Entry point for command line application.
  """
  @spec main(List.t) :: any
  def main(args \\ []) do
    if Enum.member?(args, "--help") do
      help()
    else
      opts = extract_options(args)
      config = load_config(opts)

      %{}
      |> Map.merge(config) # Merge the config file options
      |> Map.merge(opts) # Merge the command line options
      |> prompt_for_missing_options # Ask for missing options
      |> validate_share
      |> save_config(opts) # Save the config
      |> add_command(opts)
      |> add_force(args)
      |> create_audit_logger
      |> fetch_network_address
      |> fetch_network_hash
      |> load_api_client
      |> load_delegate_public_key
      |> MainMenu.run
    end
  end

  # private

  defp add_command(config, %{command: command}) do
    Map.put(config, :command, command)
  end

  defp add_command(config, _opts) do
    config
  end

  defp add_force(config, args) do
    if Enum.member?(args, "--force") do
      Map.put(config, :force, true)
    else
      Map.put(config, :force, false)
    end
  end

  defp config_file_path(opts) do
    if Map.has_key?(opts, :config) do
      Map.get(opts, :config)
    else
      home = System.user_home()
      path = "#{home}/.atbw"
      File.mkdir_p!(path)
      "#{path}/config.json"
    end
  end

  defp create_audit_logger(opts) do
    audit = Audit.new
    Audit.write(audit, "Running ArkTbwDelegateServer")
    Map.put(opts, :audit, audit)
  end

  defp extract_options(args) do
    args
    |> OptionParser.parse(aliases: @switch_aliases, switches: @switches)
    |> elem(0)
    |> Enum.into(%{})
  end

  defp fetch_network_address(%{delegate_address: "D" <> _remainer} = opts) do
    Map.put(opts, :network_address, ArkElixir.Client.devnet_network_address())
  end

  defp fetch_network_address(%{delegate_address: "A" <> _remainer} = opts) do
    Map.put(opts, :network_address, ArkElixir.Client.mainnet_network_address())
  end

  defp fetch_network_address(_) do
    raise "Invalid delegate address! Please remove config.json and restart."
  end

  defp fetch_network_hash(%{delegate_address: "D" <> _remainder} = opts) do
    Map.put(opts, :nethash, @devnet_nethash)
  end

  defp fetch_network_hash(%{delegate_address: "A" <> _remainder} = opts) do
    Map.put(opts, :nethash, @mainnet_nethash)
  end

  defp fetch_network_hash(_) do
    raise "Invalid delegate address! Please remove config.json and restart."
  end

  defp fetch_or_prompt(opts, key, prompt) do
    case Map.get(opts, key) do
      nil -> receive_input(prompt, "")
      value -> to_string(value)
    end
  end

  defp handle_fee_paid_prompt(:back) do
    shutdown()
  end

  defp handle_fee_paid_prompt(:quit) do
    shutdown()
  end

  defp handle_fee_paid_prompt(value) do
    str = "#{value}"
    cond do
      Regex.match?(~r/true/i, str) -> true
      Regex.match?(~r/yes/i, str) -> true
      str == "y" -> true
      str == "Y" -> true
      true -> false
    end
  end

  defp handle_prompt(:back) do
    shutdown()
  end

  defp handle_prompt(:quit) do
    shutdown()
  end

  defp handle_prompt(value) do
    value
  end

  defp help do
   Bunt.puts([:white, "
Usage: atbw <command>

Configuration Options:

    -c, --config                      path to CONFIG file
    -d, --delegate-address            the delegate ADDRESS to scan
    -e, --command                     the number of the menu option you would like to auto-run
    -f, --fee-paid                    delegate pays transaction fees for disbursement
    -i, --initial-block-height        starting BLOCK HEIGHT from which all future payment runs will be calculated. This should be the block height of the last block you paid out or '0'.
    -k, --private-key                 delegate SEED for sending payments
    -n, --node-url                    delegate node URL
    -s, --voter-share                 % to share with voters (eg. 0.9)
    -t, --payout-threshold            the minimum ARK due before disbursement

        --force,                      skips the prompts and accepts all the things (for use with cron)
        --help,                       this help menu
    "])
  end

  defp load_api_client(opts) do
    client = ArkElixir.Client.new(%{
      nethash: opts.nethash,
      network_address: opts.network_address,
      url: opts.node_url,
      version: "1.1.1"
    })

    Map.put(opts, :client, client)
  end

  defp load_config(opts) do
    case File.read(config_file_path(opts)) do
      {:ok, json} -> Poison.Parser.parse!(json, keys: :atoms!)
      _error -> %{}
    end
  end

  defp load_delegate_public_key(
    %{client: client, delegate_address: delegate_address} = opts
  ) do
    {:ok, public_key} = ArkElixir.Account.publickey(client, delegate_address)
    Map.put(opts, :delegate_public_key, public_key)
  end

  defp prompt_for_missing_options(opts) do
    delegate_address =
      opts
      |> fetch_or_prompt(:delegate_address, @delegate_address_prompt)
      |> handle_prompt

    initial_block_height =
      opts
      |> fetch_or_prompt(:initial_block_height, @initial_block_height_prompt)
      |> handle_prompt
      |> String.to_integer

    node_url =
      opts
      |> fetch_or_prompt(:node_url, @node_url_prompt)
      |> handle_prompt

    private_key =
      opts
      |> fetch_or_prompt(:private_key, @private_key_prompt)
      |> handle_prompt

    voter_share =
      opts
      |> fetch_or_prompt(:voter_share, @voter_share_prompt)
      |> handle_prompt

    fee_paid =
      opts
      |> fetch_or_prompt(:fee_paid, @fee_paid_prompt)
      |> handle_fee_paid_prompt

    payout_threshold =
      opts
      |> fetch_or_prompt(:payout_threshold, @payout_threshold_prompt)
      |> handle_prompt

    %{
      delegate_address: delegate_address,
      fee_paid: fee_paid,
      initial_block_height: initial_block_height,
      node_url: node_url,
      payout_threshold: payout_threshold,
      private_key: private_key,
      voter_share: voter_share
    }
  end

  defp save_config(config, opts) do
    file_path = config_file_path(opts)
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
