defmodule BotexTelegram.Helpers.Menu do
  require Logger

  alias BotEx.Models.Menu
  alias BotexTelegram.Helpers.Buttons

  @doc """
  Finds and returns the specified menu
  ## Parameters
  - name: menu name
  - menu: full menu
  """
  @spec get_menu(binary(), map()) :: Menu.t()
  def get_menu(name, menus) do
    menu = menus[name]

    unless menu do
      Logger.error("Menu #{name} not found")
    end

    menu
  end

  @spec get_menu_caption(Menu.t()) :: any()
  def get_menu_caption(%Menu{text: text}), do: text

  @doc """
  create telegram menu buttons from `BotEx.Models.Menu`
  """
  @spec create_menu_buttons(Menu.t(), any()) :: [
          [Telegex.Type.InlineKeyboardButton.t(), ...],
          ...
        ]
  def create_menu_buttons(
        %Menu{buttons: buttons_config},
        params
      ) do
    cond do
      is_function(buttons_config) -> buttons_config.(params)
      is_list(buttons_config) -> buttons_config
      true -> raise "unexpected param #{inspect(buttons_config)}\nMust be list or function"
    end
    |> Buttons.create_from_model()
  end
end
