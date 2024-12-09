defmodule BotexTelegram.Helpers.Buttons do
  @moduledoc """
   Buttons creating helper
  """
  alias BotEx.Models.Button

  @empty_btn_text " "
  @max_command_length 64

  @doc """
  Create telegram menu buttons from list `BotEx.Models.Button`

  ## Parameters
  - buttons: list of `[[BotEx.Models.Button]]`
  """
  @spec create_from_model([[Button.t()]]) :: [
          [Telegex.Type.InlineKeyboardButton.t()]
        ]
  def create_from_model(buttons) do
    Enum.map(buttons, fn group ->
      Enum.map(group, fn %Button{
                           action: action,
                           data: data,
                           module: module,
                           text: text
                         } ->
        %Telegex.Type.InlineKeyboardButton{text: text, callback_data: "/#{module}|#{action}|#{data}"}
      end)
    end)
  end

  @doc """
  create pagination button set

  ## Parameters
  - module: command routing module
  - action: command routing action
  - page: scrivener_ecto pagination object
  - data: command additional data
  - next_symbol: next page symbol
  - prev_symbol: prev page symbol
  - last_symbol: last page symbol
  - first_symbol: first page symbol
  """
  @spec get_pagination(
          binary(),
          binary(),
          %{total_pages: integer(), page_size: integer(), page_number: integer()},
          binary(),
          binary(),
          binary(),
          binary(),
          binary()
        ) :: [[%{text: binary(), callback_data: binary()}]]
  def get_pagination(
        module,
        action,
        page,
        data,
        next_symbol = ">",
        prev_symbol = "<",
        last_symbol = ">>",
        first_symbol = "<<"
      ) do
    page_num = page.page_number

    p_page = if page_num == 1, do: 1, else: page_num - 1
    n_page = if page.total_pages === page_num, do: page_num, else: page_num + 1

    show_next = page_num < page.total_pages
    show_prev = page_num > 1

    button_stub = create_empty_button()

    prev_btn =
      if show_prev do
        [create_button("/#{module}|#{action}|#{data}:#{p_page}:#{page.page_size}", prev_symbol)]
      else
        [button_stub]
      end

    next_btn =
      if show_next do
        [create_button("/#{module}|#{action}|#{data}:#{n_page}:#{page.page_size}", next_symbol)]
      else
        [button_stub]
      end

    first_btn =
      if show_prev do
        [create_button("/#{module}|#{action}|#{data}:1:#{page.page_size}", first_symbol)]
      else
        [button_stub]
      end

    last_btn =
      if show_next do
        [
          create_button(
            "/#{module}|#{action}|#{data}:#{page.total_pages}:#{page.page_size}",
            last_symbol
          )
        ]
      else
        [button_stub]
      end

    buttons = [first_btn ++ prev_btn ++ next_btn ++ last_btn]

    cond do
      is_all_empty?(buttons) -> []
      true -> buttons
    end
  end

  @doc """
  a set of buttons, fits entire single row,
  with only a "back" button inside

  ## Parameters
    - action: back action
  """
  @spec get_back_button(binary()) :: [[%{callback_data: binary(), text: binary()}]]
  def get_back_button(back_action) do
    create_single_row_button(back_action, "BACK")
  end

  @doc """
  a set of buttons, fits entire single row,
  with only a "back" button inside

  ## Parameters
    - action: back action
    - caption: button caption
  """
  @spec get_back_button(binary(), binary()) :: [[%{callback_data: binary(), text: binary()}]]
  def get_back_button(back_action, caption) do
    create_single_row_button(back_action, caption)
  end

  @doc "create set of buttons, which already fits one entire row"
  @spec create_single_row_button(binary(), binary()) :: [
          [%{callback_data: binary(), text: binary()}]
        ]
  def create_single_row_button(action, caption) do
    [[create_button(action, caption)]]
  end

  @doc """
  create set of buttons, which already fits one entire row

  ## Parameters
  - module: command routing module
  - action: command routing action
  - data: command routing data
  - caption: button caption
  """
  @spec create_single_row_button(binary(), binary(), binary(), binary()) :: [
          [%{callback_data: binary(), text: binary()}]
        ]
  def create_single_row_button(module, action, data, caption) do
    [[create_button(module, action, data, caption)]]
  end

  @doc """
  create button object

  ## Parameters
  - module: command routing module
  - action: command routing action
  - data: command routing data
  - caption: button caption
  """
  @spec create_button(binary(), binary(), binary(), binary()) :: %{
          callback_data: binary(),
          text: binary()
        }
  def create_button(module, action, data, caption) do
    command =
      "/#{module}|#{action}" <>
        case data do
          "" -> ""
          nil -> ""
          _ -> "|#{data}"
        end

    create_button(command, caption)
  end

  @doc """
  create button object

  ## Parameters
  - action: command routing action
  - caption: button caption
  """
  @spec create_button(binary(), binary()) :: %{callback_data: binary, text: binary()}
  def create_button(action, caption) do
    %{
      callback_data: action |> check_btn_command_size!(),
      text: caption
    }
  end

  @doc """
  Create button with no caption and no action in it
  ## Parameters
  - caption: button caption
  """
  @spec create_empty_button(binary) :: %{callback_data: binary, text: binary}
  def create_empty_button(caption \\ @empty_btn_text) do
    create_button("/stub", caption)
  end

  # is all buttons empty
  @spec is_all_empty?([[%{callback_data: binary(), text: binary}]]) :: boolean
  defp is_all_empty?([buttons]) do
    Enum.all?(buttons, fn %{text: text} -> text == @empty_btn_text end)
  end

  defp check_btn_command_size!(command) when length(command) > @max_command_length,
    do: raise("Button command too long! #{@max_command_length} max")

  defp check_btn_command_size!(command), do: command
end
