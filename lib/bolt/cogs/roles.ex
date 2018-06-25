defmodule Bolt.Cogs.Roles do
  @moduledoc false

  alias Bolt.Constants
  alias Bolt.Helpers
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Guild.Role

  @spec get_role_list(Nostrum.Struct.Snowflake.t()) :: {:ok, [Role.t()]} | {:error, String.t()}
  defp get_role_list(guild_id) do
    case GuildCache.get(guild_id) do
      {:ok, guild} ->
        {:ok, guild.roles}

      {:error, _reason} ->
        case Api.get_guild_roles(guild_id) do
          {:ok, roles} ->
            {:ok, roles}

          {:error, _api_error} ->
            {:error, "Couldn't look up guild from either the cache or the API"}
        end
    end
  end

  def command(msg, "") do
    case get_role_list(msg.guild_id) do
      {:ok, roles} ->
        embed = %Embed{
          title: "All roles on this guild",
          description: roles |> Stream.map(&Role.mention/1) |> Enum.join(", "),
          color: Constants.color_blue()
        }

        {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)

      {:error, reason} ->
        response = "❌ could not fetch guild roles: #{Helpers.clean_content(reason)}"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end

  def command(msg, name) do
    case get_role_list(msg.guild_id) do
      {:ok, roles} ->
        embed = %Embed{
          title: "Roles matching `#{name}` on this guild (case-insensitive)",
          description:
            roles
            |> Stream.filter(&String.contains?(String.downcase(&1.name), String.downcase(name)))
            |> Stream.map(&Role.mention/1)
            |> Enum.join(", "),
          color: Constants.color_blue()
        }

        {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)

      {:error, reason} ->
        response = "❌ could not fetch guild roles: #{Helpers.clean_content(reason)}"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end
end
