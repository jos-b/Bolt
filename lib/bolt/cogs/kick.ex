defmodule Bolt.Cogs.Kick do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Converters, ErrorFormatters, Helpers, ModLog, Repo}
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.User
  require Logger

  @impl true
  def usage, do: ["kick <user:member> [reason:str...]"]

  @impl true
  def description,
    do: """
    Kick the given member with an optional reason.
    An infraction is stored in the infraction database, and can be retrieved later.
    Requires the `KICK_MEMBERS` permission.

    **Examples**:
    ```rs
    // kick Dude without an explicit reason
    kick @Dude#0001

    // kick Dude with an explicit reason
    kick @Dude#0001 spamming cats when asked to post ducks
    ```
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_kick_members?/1]

  @impl true
  def command(msg, [user | reason_list]) do
    response =
      with reason <- Enum.join(reason_list, " "),
           {:ok, member} <- Converters.to_member(msg.guild_id, user),
           {:ok, true} <- Helpers.is_above(msg.guild_id, msg.author.id, member.user.id),
           {:ok} <- Api.remove_guild_member(msg.guild_id, member.user.id),
           infraction <- %{
             type: "kick",
             guild_id: msg.guild_id,
             user_id: member.user.id,
             actor_id: msg.author.id,
             reason: if(reason != "", do: reason, else: nil)
           },
           changeset <- Infraction.changeset(%Infraction{}, infraction),
           {:ok, _created_infraction} <- Repo.insert(changeset) do
        ModLog.emit(
          msg.guild_id,
          "INFRACTION_CREATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) kicked" <>
            " #{User.full_name(member.user)} (`#{member.user.id}`)" <>
            if(reason != "", do: " with reason `#{reason}`", else: "")
        )

        response = "👌 kicked #{User.full_name(member.user)} (`#{member.user.id}`)"

        if reason != "" do
          response <> " with reason `#{Helpers.clean_content(reason)}`"
        else
          response
        end
      else
        {:ok, false} ->
          "🚫 you need to be above the target user in the role hierarchy"

        error ->
          ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `kick <user:member> [reason:str...]`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
