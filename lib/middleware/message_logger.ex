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
    Config.get(:show_msg_log)
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
      "\nType: #{message_type(msg)}" <>
      "\nUser info" <>
      "\n - user_id: #{user_id}\n - telegram name: #{name}\n - first_name: #{first_name}\n - last name: #{
        last_name
      }" <>
      "\noriginal text: #{message_text(msg)}"
  end

  defp message_type(%Telegex.Type.Message{}), do: "Telegram Message"
  defp message_type(%Telegex.Type.CallbackQuery{}), do: "Telegram Callback"

  defp message_text(%Telegex.Type.Message{text: text}), do: text
  defp message_text(%Telegex.Type.CallbackQuery{data: data}), do: data
end
