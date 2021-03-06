defmodule Bolt.Cogs.USW.Punish do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Converters, Helpers, Parsers, Repo}
  alias Bolt.Schema.USWPunishmentConfig
  alias Nostrum.Api

  @impl true
  def usage, do: ["usw punish <punishment...>"]

  @impl true
  def description,
    do: """
    Sets the punishment to be applied when a filter triggers.

    Existing punishments:
    • `temprole <role:role> <duration:duration>`: Temporarily `role` for `duration`. This can be useful to mute members temporarily.

    Requires the `MANAGE_GUILD` permission.
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @impl true
  def command(msg, ["temprole", role, duration]) do
    response =
      with {:ok, role} <- Converters.to_role(msg.guild_id, role),
           {:ok, total_seconds} <- Parsers.duration_string_to_seconds(duration),
           new_config <- %{
             guild_id: msg.guild_id,
             duration: total_seconds,
             punishment: "TEMPROLE",
             data: %{
               "role_id" => role.id
             }
           },
           changeset <- USWPunishmentConfig.changeset(%USWPunishmentConfig{}, new_config),
           {:ok, _config} <-
             Repo.insert(
               changeset,
               conflict_target: [:guild_id],
               on_conflict: :replace_all
             ) do
        "👌 punishment is now applying temporary role `#{role.name}` for" <>
          " #{total_seconds} seconds"
      else
        {:error, reason} ->
          "🚫 error: #{Helpers.clean_content(reason)}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, [_unknown_type | _args]) do
    response = "🚫 unknown punishment type"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
