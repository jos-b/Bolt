defmodule Bolt.USW.Filters.Burst do
  @moduledoc "Filters messages sent in quick succession."
  @behaviour Bolt.USW.Filter

  alias Bolt.{MessageCache, USW}
  alias Nostrum.Struct.{Message, Snowflake}

  @impl true
  @spec apply(Message.t(), non_neg_integer(), non_neg_integer(), Snowflake.t()) ::
          :action | :passthrough
  def apply(msg, limit, interval, interval_seconds_ago_snowflake) do
    total_recents =
      msg.guild_id
      |> MessageCache.recent_in_guild()
      |> Stream.filter(&(&1.id >= interval_seconds_ago_snowflake))
      |> Stream.filter(&(&1.author_id == msg.author.id))
      |> Enum.take(limit)
      |> length()

    if total_recents >= limit do
      USW.punish(
        msg.guild_id,
        msg.author,
        "sending #{total_recents} messages in #{interval}s"
      )

      :action
    else
      :passthrough
    end
  end
end
