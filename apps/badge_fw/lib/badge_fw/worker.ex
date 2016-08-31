defmodule BadgeFw.Worker do
  use GenServer

  @hashtag "#NervesBadge"
  @handle "@ElixirConf"
  @interval 25_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    BadgeLib.Firmata.clear()
    Process.send_after(self, :update, @interval)
    {:ok, %{last: {nil, nil}}}
  end

  def handle_info(:update, %{last: {lhash, luser}} = s) do
    {hash, user} = {@handle, @hashtag}

    new_hash = get_tweet(hash)
    new_user = get_tweet(user)
    last =
      cond do
        new_hash != lhash ->
          display_tweet(new_hash)
          {new_hash, luser}
        new_user != luser ->
          display_tweet(new_user)
          {lhash, new_user}
        true -> {lhash, luser}
      end
    Process.send_after(self, :update, @interval)
    {:noreply, %{s | last: last}}
  end

  def get_tweet(search) do
    case ExTwitter.search(search, [count: 1]) do
      [tweet] -> tweet
      _ -> nil
    end
  end

  def display_tweet(tweet) do
    IO.puts "display tweet"
    BadgeLib.Utf8ToASCII.convert(tweet.text)
    |> BadgeLib.Firmata.text
    BadgeLib.Firmata.vibrate_pulse
  end
end
