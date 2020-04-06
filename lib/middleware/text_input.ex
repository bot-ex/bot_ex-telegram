defmodule BotexTelegram.Middleware.TextInput do
  @moduledoc """
    Refresh last calls table
  """

  @behaviour BotEx.Behaviours.Middleware

  alias BotEx.Models.Message
  alias BotEx.Helpers.UserActions

  @spec transform(Message.t()) :: Message.t()
  def transform(%Message{chat_id: user_id, text: text, is_cmd: false}) do
    %Message{ UserActions.get_last_call(user_id) | text: text, is_cmd: false}
  end

  def transform(%Message{} = t_msg) do
    t_msg
  end
end
