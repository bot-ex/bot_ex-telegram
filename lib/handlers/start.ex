defmodule BotexTelegram.Handlers.Start do
  @moduledoc """
  Модуль обработки команды запуска бота `/start`
  """
  use GenServer
  use BotEx.ModuleHandler
  use BotEx.ModuleHandler.Init

  alias BotEx.Models.Message
  alias BotexTelegram.Services.Menu.Api, as: MenuApi

  def get_cmd_name, do: "start"

  @spec handle_message(Message.t(), State.t()) :: {:noreply, State.t()}
  def handle_message(%Message{is_cmd: true, user: user}, state) do
    MenuApi.show_menu("main_menu", user.id)

    {:noreply, state}
  end
end
