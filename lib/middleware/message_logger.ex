defmodule BotexTelegram.Middleware.MessageLogger do
  @moduledoc """
  Logger middleware that show additional info about routing message
  """
  @behaviour BotEx.Behaviours.Middleware

  alias BotEx.Models.Message
  alias BotEx.Config

  require Logger

  @spec transform(Message.t()) :: Message.t()
  def transform(%Message{} = t_msg) do
    Config.get_show_msg_log()
    |> Kernel.if do
      Logger.info(t_msg |> info_to_string)
      Logger.info("==================================================================")
    end

    t_msg
  end

  @doc """
  Convert `BotEx.Models.Message` in debug string
  """
  @spec info_to_string(Message.t()) :: binary()
  def info_to_string(%Message{
        msg:
          %{
            from: %{
              id: user_id,
              first_name: first_name,
              last_name: last_name,
              username: name
            }
          } = msg
      }) do
    "Tlgm Message" <>
      "\nType: " <>
      nadia_type(msg) <>
      "\nUser info" <>
      "\n - user_id: #{user_id}\n - telegram name: #{name}\n - first_name: #{first_name}\n - last name: #{
        last_name
      }" <>
      "\noriginal text: " <> nadia_text(msg)
  end

  defp nadia_type(%Nadia.Model.Message{}), do: "Nadia Message"
  defp nadia_type(%Nadia.Model.CallbackQuery{}), do: "Nadia Callback"

  defp nadia_text(%Nadia.Model.Message{text: text}), do: text
  defp nadia_text(%Nadia.Model.CallbackQuery{data: data}), do: data
end
