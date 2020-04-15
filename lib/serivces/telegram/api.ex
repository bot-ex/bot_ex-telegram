defmodule BotexTelegram.Services.Telegram.Api do
  @moduledoc """
  The main api for working with a telegram.
  """

  alias BotEx.Models.Message

  require Logger

  @doc """
  Function retrieves user from telegram message

  ## Parameters
  - msg: telegram message
  """
  @spec get_user(Nadia.Model.CallbackQuery.t() | Nadia.Model.Message.t()) ::
          Nadia.Model.User.t() | %{}
  def get_user(%Nadia.Model.Message{from: nil, forward_from_chat: %{} = tUser}), do: tUser
  def get_user(%Nadia.Model.Message{from: tUser}), do: tUser
  def get_user(%Nadia.Model.CallbackQuery{from: tUser}), do: tUser
  def get_user(_msg), do: {:error, "Failed to retrieve user"}

  @doc "gather data from message or callback"
  @spec get_date_time(Nadia.Model.CallbackQuery.t() | Nadia.Model.Message.t() | nil) ::
          DateTime.t() | nil
  def get_date_time(%Nadia.Model.Message{date: timestamp}) do
    timestamp |> DateTime.from_unix!(:second)
  end

  def get_date_time(%Nadia.Model.CallbackQuery{message: message}), do: get_date_time(message)
  def get_date_time(%Message{msg: nadia_msg}), do: get_date_time(nadia_msg)
  def get_date_time(nil), do: nil

  @doc """
  Retrieves chat id from telegram message

  ## Parameters
  - msg: telegram message
  """
  @spec get_chat_id(Nadia.Model.CallbackQuery.t() | Nadia.Model.Message.t()) :: integer()
  def get_chat_id(%Nadia.Model.Message{
        chat: %Nadia.Model.Chat{
          id: chat_id
        }
      }),
      do: chat_id

  def get_chat_id(%Nadia.Model.CallbackQuery{
        message: %Nadia.Model.Message{
          chat: %Nadia.Model.Chat{
            id: chat_id
          }
        }
      }),
      do: chat_id


  def get_chat_id(%Message{msg: msg}), do: get_chat_id(msg)

  @doc """
  Retrieves message id from telegram message
  """
  @spec get_message_id(Nadia.Model.CallbackQuery.t() | Nadia.Model.Message.t()) :: integer()
  def get_message_id(%Nadia.Model.Message{message_id: id}), do: id
  def get_message_id(%Nadia.Model.CallbackQuery{message: msg}), do: get_message_id(msg)

  @doc """
  Breaks the text into parts according
  to the specified separator and sends messages to the user

  ## Parameters
  - msg: message text
  - chat_id: chat or user id
  - delimiter: delimiter for message split, default - \n
  - remove_delimiters: remove delimiters from original message
  - limit: max length one message (telegram allow max 4096 symbols)
  """
  @spec split_and_send(binary(), integer()) :: :ok
  @spec split_and_send(binary(), integer(), binary(), boolean(), non_neg_integer) :: :ok
  def split_and_send(str, chat_id, delimiter \\ "\n", remove_delimiters? \\ false, limit \\ 4000) do
    # Добавляем в конце разделитель - чтобы не терять последний элемент
    str_with_delimiter = str <> delimiter

    matches =
      Regex.scan(~r/(.{0,#{limit}})#{delimiter}/us, str_with_delimiter, captured: :all)
      |> Enum.map(fn [_s, match] -> match end)

    cond do
      remove_delimiters? -> Enum.map(matches, &String.replace(&1, delimiter, ""))
      true -> matches
    end
    |> Enum.each(&send_message(&1, chat_id))
  end

  @doc """
  Sends a message
  ## Parameters
  - msg: message text
  - chat_id: chat or user id
  - parse_mode: message processing mode for telegram `:Markdown` or `:HTML`
  - markup: additional marking of the message, buttons, etc.
  """
  @spec send_message(
          binary(),
          integer(),
          :Markdown | :HTML,
          map()
          | Nadia.Model.ReplyKeyboardMarkup.t()
          | Nadia.Model.ReplyKeyboardHide.t()
          | Nadia.Model.ForceReply.t()
        ) ::
          {:error, Nadia.Model.Error.t()} | {:ok, Nadia.Model.Message.t()}
  def send_message(msg, chat_id, parse_mode \\ :Markdown, markup \\ %{})

  def send_message(msg, chat_id, parse_mode, markup) do
    result = Nadia.send_message(chat_id, msg, parse_mode: parse_mode, reply_markup: markup)

    log_on_error(result)

    result
  end

  @doc """
  Sends a message with buttons markup
  """
  @spec send_with_buttons(binary(), integer(), [
          [%{callback_data: binary(), text: binary()}, ...],
          ...
        ]) ::
          {:error, Nadia.Model.Error.t()} | {:ok, Nadia.Model.Message.t()}
  def send_with_buttons(msg, chat_id, buttons) do
    send_message(
      msg,
      chat_id,
      :Markdown,
      %{inline_keyboard: buttons}
    )
  end

  @doc """
  Edit existing telegram message

  ## Parameters
  - telegram message
  - text: new text
  - buttons: new buttons
  """
  @spec edit_message(
          Nadia.Model.CallbackQuery.t() | Nadia.Model.Message.t(),
          binary,
          list
        ) :: {:error, Nadia.Model.Error.t()} | {:ok, Nadia.Model.Message.t()}
  def edit_message(%Nadia.Model.CallbackQuery{message: msg}, text, buttons) do
    edit_message(msg, text, buttons)
  end

  def edit_message(%Nadia.Model.Message{} = msg, text, buttons) do
    message_id = get_message_id(msg)

    edit_options = [
      reply_markup: %{inline_keyboard: buttons},
      parse_mode: :Markdown
    ]

    Nadia.edit_message_text(get_chat_id(msg), message_id, nil, text, edit_options)
    |> log_on_error()
  end

  @doc """
  Send new or existing image to user or chat
  ## Parameters
  - file: file path for new photo or id telegram file
  - chat_id: user or chat id
  """
  @spec send_photo(nil | binary, integer()) ::
          {:error, Nadia.Model.Error.t()} | {:ok, binary() | Nadia.Model.Message.t()}
  def send_photo(nil, _chat_id), do: {:error, "set file path or id"}
  def send_photo(file, chat_id), do: Nadia.send_photo(chat_id, file)

  # show error in output
  defp log_on_error({:error, reason}) do
    Logger.warn("Telegram message rejected:\n" <> inspect(reason))
  end

  defp log_on_error(_), do: nil
end
