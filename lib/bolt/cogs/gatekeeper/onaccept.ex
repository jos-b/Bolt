defmodule Bolt.Cogs.GateKeeper.OnAccept do
  @moduledoc false
  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.Converters
  alias Bolt.{ErrorFormatters, ModLog, Repo}
  alias Bolt.Schema.AcceptAction
  alias Nostrum.Api
  alias Nostrum.Struct.User
  import Ecto.Query, only: [from: 2]

  @impl true
  def usage, do: ["keeper onaccept <action...>"]

  @impl true
  def description,
    do: """
    Sets actions to be executed when members use `.accept`.

    **Actions**:
    - `ignore`: Deletes all existing actions.
    - `add role <role:role>`: Adds the given role to the member.
    - `remove role <role:role>`: Removes the given role from the member.
    - `delete invocation`: Deletes the `.accept` message.
    """

  @impl true
  def predicates, do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @impl true
  def command(msg, ["ignore"]) do
    {total_deleted, _} =
      Repo.delete_all(from(action in AcceptAction, where: action.guild_id == ^msg.guild_id))

    response =
      if total_deleted == 0 do
        "🚫 no actions to delete"
      else
        ModLog.emit(
          msg.guild_id,
          "CONFIG_UPDATE",
          "#{User.full_name(msg.author)} deleted **#{total_deleted}** accept action(s)"
        )

        "👌 deleted **#{total_deleted}** accept action(s)"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, ["add", "role" | role_str]) do
    response =
      with {:ok, role} <- Converters.to_role(msg.guild_id, Enum.join(role_str, " ")),
           action_map <- %{
             guild_id: msg.guild_id,
             action: "add_role",
             data: %{"role_id" => role.id}
           },
           changeset <- AcceptAction.changeset(%AcceptAction{}, action_map),
           {:ok, _created_action} <- Repo.insert(changeset) do
        ModLog.emit(
          msg.guild_id,
          "CONFIG_UPDATE",
          "#{User.full_name(msg.author)} set gatekeeper to add role `#{role.name}` on `.accept`"
        )

        "👌 will now add role `#{role.name}` on `.accept`"
      else
        error -> ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, ["remove", "role" | role_str]) do
    response =
      with {:ok, role} <- Converters.to_role(msg.guild_id, Enum.join(role_str, " ")),
           action_map <- %{
             guild_id: msg.guild_id,
             action: "remove_role",
             data: %{"role_id" => role.id}
           },
           changeset <- AcceptAction.changeset(%AcceptAction{}, action_map),
           {:ok, _created_action} <- Repo.insert(changeset) do
        ModLog.emit(
          msg.guild_id,
          "CONFIG_UPDATE",
          "#{User.full_name(msg.author)} set gatekeeper to remove role `#{role.name}` on `.accept`"
        )

        "👌 will now remove role `#{role.name}` on `.accept`"
      else
        error -> ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, ["delete", "invocation"]) do
    action_map = %{
      guild_id: msg.guild_id,
      action: "delete_invocation",
      data: %{}
    }

    changeset = AcceptAction.changeset(%AcceptAction{}, action_map)

    response =
      case Repo.insert(changeset) do
        {:ok, _struct} ->
          ModLog.emit(
            msg.guild_id,
            "CONFIG_UPDATE",
            "#{User.full_name(msg.author)} set gatekeeper to remove command invocations of `.accept`"
          )

          "👌 will now delete invocations of `.accept`"

        error ->
          ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
