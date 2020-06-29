defmodule BotexTelegram.Handlers.Start do
  @moduledoc """
  Модуль обработки команды запуска бота `/start`
  """

  use BotEx.Handlers.ModuleHandler
  use BotEx.Handlers.ModuleInit

  alias BotEx.Models.Message
  alias BotexTelegram.Services.Menu.Api, as: MenuApi

  def get_cmd_name, do: "start"

  def handle_message(%Message{is_cmd: true, user: user}) do
    MenuApi.show_menu("main_menu", user.id)

    nil
  end
end
