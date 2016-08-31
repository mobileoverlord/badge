defmodule BadgeLib.Firmata do
  use GenServer
  use Firmata.Protocol.Modes
  alias Firmata.Board, as: Board

  @high 1
  @low 0

  @vibration_pin 9
  @vibration_pulse 300
  @vibration_times 7

  @display_clear 0x81
  @display_text  0x82
  @display_time  20_000

  def start_link(opts \\ []) do
    port =  opts[:port] || "ttyS0"
    speed = opts[:speed] || 57600
    serial_opts = [speed: speed]
    GenServer.start_link(__MODULE__, [port, serial_opts], name: __MODULE__)
  end

  def vibrate(state \\ @high) do
    GenServer.call(__MODULE__, {:vibrate, state})
  end

  def vibrate_pulse() do
    GenServer.call(__MODULE__, :vibrate_pulse)
  end

  def text(message) do
    GenServer.call(__MODULE__, {:text, message})
  end

  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  def init([port, serial_opts]) do
    {:ok, board}  = Board.start_link(port, serial_opts)
    {:ok, %{
      board: board
    }}
  end

  def handle_call({:vibrate, state}, _from, s) do
    Board.digital_write(s.board, @vibration_pin, state)
    {:reply, :ok, s}
  end

  def handle_call(:vibrate_pulse, _from, s) do
    send(self, {:vibrate_pulse, 0, 1})
    {:reply, :ok, s}
  end

  def handle_call({:text, message}, _from, s) do
    resp = Board.sysex_write(s.board, @display_text, message)
    Process.send_after(self, :clear_display, @display_time)
    {:reply, {:ok, resp}, s}
  end

  def handle_call(:clear, _from, s) do
    resp = Board.sysex_write(s.board, @display_clear, "")
    {:reply, {:ok, resp}, s}
  end

  def handle_info(:clear_display, s) do
    Board.sysex_write(s.board, @display_clear, "")
    {:noreply, s}
  end

  def handle_info({:vibrate_pulse, @vibration_times, _},s) do
    Board.digital_write(s.board, @vibration_pin, @low)
    {:noreply, s}
  end

  def handle_info({:vibrate_pulse, times, state}, s) do
    Board.digital_write(s.board, @vibration_pin, state)
    state =
      if state == 0, do: 1, else: 0

    Process.send_after(self,
      {:vibrate_pulse, times + 1, state}, @vibration_pulse)
    {:noreply, s}
  end

  def handle_info({:firmata, {:pin_map, _pin_map}}, s) do
    Board.set_pin_mode(s.board, 9, @output)
    {:noreply, s}
  end

  def handle_info(_, s) do
    {:noreply, s}
  end

end
