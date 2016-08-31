defmodule BadgeFw do
  use Application
  alias Nerves.InterimWiFi, as: WiFi

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    :os.cmd('modprobe mt7603e')

    # Define workers and child supervisors to be supervised
    children = [
      worker(Task, [fn -> network end], restart: :transient),
      worker(BadgeLib.Firmata, []),
      worker(BadgeFw.Worker, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BadgeFw.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def network do
    wlan_config =
      case settings do
        {:ok, settings} ->
          [psk: settings.password, ssid: settings.ssid]
        _ ->
          Application.get_env(:badge_fw, :wlan0)
      end
    WiFi.setup "wlan0", wlan_config
  end

  def settings do
    settings_file =
      Application.get_env(:badge_settings, :nerves_settings).settings_file
    case File.read(settings_file) do
      {:error, :enoent} = error -> error
      {:ok, ""} -> {:error, :empty}
      {:ok, contents} ->
        unencoded = :erlang.binary_to_term(contents)
        {:ok, unencoded}
    end
  end

end
