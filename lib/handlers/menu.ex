defmodule BotexTelegram.Handlers.Menu do
  @moduledoc """
  Telgram menu module
  """

  require Logger

  alias BotexTelegram.Helpers.Menu, as: MenuHelper
  alias BotexTelegram.Services.Telegram.Api, as: TelegramApi
  alias BotexTelegram.Services.Menu.Api, as: MenuApi

  alias BotEx.Models.{Message}

  use BotEx.Handlers.ModuleHandler
  use BotEx.Handlers.ModuleInit

  def get_cmd_name, do: "menu"

  # show menu from list
  def handle_message(%Message{action: "show", data: menu_name, user: user, chat_id: chat_id}) do
    menu_config = MenuApi.get_all()
    menu = MenuHelper.get_menu(menu_name, menu_config)
    caption = MenuHelper.get_menu_caption(menu)
    buttons = MenuHelper.create_menu_buttons(menu, user: user.id)

    TelegramApi.send_with_buttons(caption, chat_id, buttons)

    nil
  end

  def handle_message(_msg) do
    Logger.warning("Menu not found")

    nil
  end
end
