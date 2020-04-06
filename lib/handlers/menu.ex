defmodule BotexTelegram.Handlers.Menu do
  @moduledoc """
  Telgram menu module
  """

  require Logger

  alias BotexTelegram.Helpers.Menu, as: MenuHelper
  alias BotexTelegram.Services.Telegram.Api, as: TelegramApi
  alias BotexTelegram.Services.Menu.Api, as: MenuApi

  alias BotEx.Models.{Message}

  use BotEx.ModuleHandler
  use BotEx.ModuleHandler.Init

  def get_cmd_name, do: "menu"

  # show menu from list
  @spec handle_message(Message.t(), State.t()) :: {:noreply, State.t()}
  def handle_message(
        %Message{action: "show", data: menu_name, user: user, chat_id: chat_id},
        state
      ) do

    menu_config = MenuApi.get_all()
    menu = MenuHelper.get_menu(menu_name, menu_config)
    caption = MenuHelper.get_menu_caption(menu)
    buttons = MenuHelper.create_menu_buttons(menu, user: user.id)

    TelegramApi.send_with_buttons(caption, chat_id, buttons)

    {:noreply, state}
  end

  def handle_message(_msg, state) do
    Logger.warn("Menu not found")

    {:noreply, state}
  end
end
