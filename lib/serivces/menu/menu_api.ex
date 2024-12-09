defmodule BotexTelegram.Services.Menu.Api do
  use GenServer

  alias BotEx.Helpers.Tools
  alias BotEx.Config
  alias BotEx.Models.Menu
  alias BotexTelegram.Helpers.Menu, as: MenuHelper
  alias BotexTelegram.Services.Telegram.Api, as: TelegramApi

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker
    }
  end

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @spec init(any) :: {:ok, %{menu: map()}}
  def init(_opts) do
    {menu, _} =
      Config.get(:menu_path)
      |> Tools.check_path!()
      |> Code.eval_file()

    {:ok, %{menu: menu}}
  end

  @doc """
  Function return all menu struct
  """
  @spec get_all :: map()
  def get_all() do
    GenServer.call(__MODULE__, :get_all)
  end

  @doc """
  Method for displaying a specific menu

  ## Parameters
  - name: menu name (BotEx.Models.Menu.name) from menu.exs file
  - uId: user telegram id, for displaying a menu
  - params: in case the buttons in the menu is function,
  (`BotEx.Models.Menu.buttons: fn (params) -> [BotEx.Models.Button.t()] end`)
  this params will be applying as argument
  """
  @spec show_menu(term(), any()) :: :ok
  def show_menu(name, user_id, params \\ [])

  def show_menu(name, user_id, params) do
    GenServer.cast(__MODULE__, {:show, name, user_id, params})
  end

  @doc """
  Returns generated menu buttons

  ## Parameters
  - name: menu name
  - params: in case the buttons in the menu
  (`BotEx.Models.Menu.buttons: fn (params) -> [BotEx.Models.Button.t()] end`)
  is function, this params will be applying as argument
  """
  @spec get_menu_buttons(term(), list()) :: list()
  def get_menu_buttons(name, params \\ []) do
    try do
      GenServer.call(__MODULE__, {:get_menu, name, params})
    catch
      :exit, _value ->
        []
    end
  end

  @doc """
  Dynamically add new menu
  ## Parameters:
  - menu: BotEx.Models.Menu for adding
  """
  @spec add_menu(Menu.t()) :: :ok
  def add_menu(menu) do
    GenServer.cast(__MODULE__, {:add_menu, menu})
  end

  @spec handle_call({:get_menu, binary(), list()} | :get_all, {pid(), tag :: term()}, map()) ::
          {:reply, list(), map()}
  def handle_call(
        {:get_menu, name, params},
        _from,
        %{menu: menu_config} = state
      ) do
    buttons =
      MenuHelper.get_menu(name, menu_config)
      |> MenuHelper.create_menu_buttons(params)

    {:reply, buttons, state}
  end

  def handle_call(:get_all, _from, %{menu: menu_config} = state) do
    {:reply, menu_config, state}
  end

  def handle_cast({:show, name, user_id, params}, %{menu: menu_config} = state) do
    menu = MenuHelper.get_menu(name, menu_config)
    caption = MenuHelper.get_menu_caption(menu)
    buttons = MenuHelper.create_menu_buttons(menu, params)

    TelegramApi.send_with_buttons(caption, user_id, buttons)

    {:noreply, state}
  end

  def handle_cast({:add_menu, menu}, %{menu: old_menu} = state) do
    new_menu = Map.merge(old_menu, menu)

    {:noreply, %{state | menu: new_menu}}
  end
end
