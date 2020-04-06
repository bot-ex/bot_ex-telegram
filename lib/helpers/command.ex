defmodule BotexTelegram.Helpers.Command do
  @moduledoc """
  Command helper module
  """

  @doc """
  Create short command with some data

  ## Parameters
  - name: command name
  - data: data for command
  """
  @spec create_short_command(binary(), binary()) :: binary()
  def create_short_command(name, data) do
    "/#{name}\\_#{data}"
  end
end
