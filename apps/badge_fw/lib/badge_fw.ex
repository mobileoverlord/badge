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
    wlan_config = Application.get_env(:badge_fw, :wlan0)
    WiFi.setup "wlan0", wlan_config
  end

end
