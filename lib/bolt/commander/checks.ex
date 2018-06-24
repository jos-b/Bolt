defmodule Bolt.Commander.Checks do
  alias Bolt.Helpers
  use Bitwise

  @doc """
  A function that checks whether
  the given message was sent on a
  Gulid. Note that messages retrieved
  via REST do not have the `guild_id`
  attribute set, and thus, will not
  be detected as guild messages properly.
  """
  @spec guild_only(Nostrum.Struct.Message.t()) ::
          {:ok, Nostrum.Struct.Message.t()} | {:error, String.t()}
  def guild_only(msg) do
    case msg.guild_id do
      nil ->
        {:error, "this command can only be used on guilds"}

      _guild_id ->
        {:ok, msg}
    end
  end

  @spec is_admin?(Integer) :: boolean
  defp is_admin?(permissions) do
    (permissions &&& 0x8) == 0x8
  end

  # Checks if the author of `message` has the permissions specified in `to_check`
  # If yes, returns `{:ok, msg}`
  # If no, returns `{:error, embed}`
  # If an error occured, returns `{:error, embed}`
  @spec has_permission?(Nostrum.Struct.Message.t(), Integer, String.t()) ::
          {:ok, Nostrum.Struct.Message.t()} | {:error, String.t()}
  defp has_permission?(msg, to_check, permission_name) do
    case Helpers.top_role_for(msg.guild_id, msg.author.id) do
      {:ok, role} ->
        case is_admin?(role.permissions) or (role.permissions &&& to_check) == to_check do
          true -> {:ok, msg}
          false -> {:error, "🚫 you need the `#{permission_name}` permission to do that"}
        end

      {:error, reason} ->
        {:error, "❌ cannot check permission information: #{reason}"}
    end
  end

  @bitflags_manage_roles 0x10000000
  @doc "Checks that the message author has the `MANAGE_ROLES` permission."
  @spec can_manage_roles?(Nostrum.Struct.Message.t()) ::
          {:ok, Nostrum.Struct.Message.t()} | {:error, String.t()}
  def can_manage_roles?(msg) do
    has_permission?(msg, @bitflags_manage_roles, "MANAGE_ROLES")
  end

  @bitflags_manage_messages 0x00002000
  @doc "Checks that the message author has the `MANAGE_MESSSAGES` permission."
  @spec can_manage_messages?(Nostrum.Struct.Message.t()) ::
          {:ok, Nostrum.Struct.Message.t()} | {:error, String.t()}
  def can_manage_messages?(msg) do
    has_permission?(msg, @bitflags_manage_messages, "MANAGE_MESSAGES")
  end

  @bitflags_kick_members 0x00000002
  @doc "Checks that the message author has the `KICK_MEMBERS` permission."
  @spec can_kick_members?(Nostrum.Struct.Message.t()) ::
          {:ok, Nostrum.Struct.Message.t()} | {:error, String.t()}
  def can_kick_members?(msg) do
    has_permission?(msg, @bitflags_kick_members, "KICK_MEMBERS")
  end

  @bitflags_ban_members 0x00000004
  @doc "Checks that the message author has the `BAN_MEMBERS` permission."
  @spec can_ban_members?(Nostrum.Struct.Message.t()) ::
          {:ok, Nostrum.Struct.Message.t()} | {:error, String.t()}
  def can_ban_members?(msg) do
    has_permission?(msg, @bitflags_ban_members, "BAN_MEMBERS")
  end
end
