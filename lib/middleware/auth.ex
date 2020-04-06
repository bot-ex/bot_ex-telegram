defmodule BotexTelegram.Middleware.Auth do
  @moduledoc """
  Middleware module that get user from telegram message and set it to `BotEx.Models.Message`
  """
  @behaviour BotEx.Behaviours.Middleware

  alias BotexTelegram.Services.Telegram.Api, as: TelegramApi
  alias BotEx.Models.Message

  @spec transform(Message.t()) :: Message.t()
  def transform(%Message{msg: msg} = t_msg) do
    %Nadia.Model.User{id: tlgm_id} = user = TelegramApi.get_user(msg)

    %Message{t_msg | user: user, user_id: tlgm_id, chat_id: TelegramApi.get_chat_id(msg)}
  end
end
