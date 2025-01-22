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
  @spec get_user(
          Telegex.Type.CallbackQuery.t()
          | Telegex.Type.Message.t()
          | Telegex.Type.PreCheckoutQuery.t()
        ) ::
          Telegex.Type.User.t() | %{}
  # def get_user(%Telegex.Type.Message{from: nil, forward_from_chat: %{} = tUser}), do: tUser
  def get_user(%Telegex.Type.Message{from: tUser}), do: tUser
  def get_user(%Telegex.Type.CallbackQuery{from: tUser}), do: tUser
  def get_user(%Telegex.Type.PreCheckoutQuery{from: tUser}), do: tUser
  def get_user(_msg), do: {:error, "Failed to retrieve user"}

  @doc "gather data from message or callback"
  @spec get_date_time(
          Telegex.Type.CallbackQuery.t()
          | Telegex.Type.Message.t()
          | Telegex.Type.PreCheckoutQuery.t()
          | nil
        ) ::
          DateTime.t() | nil
  def get_date_time(%Telegex.Type.Message{date: timestamp}) do
    timestamp |> DateTime.from_unix!(:second)
  end

  def get_date_time(%Telegex.Type.CallbackQuery{message: message}), do: get_date_time(message)
  def get_date_time(%Telegex.Type.PreCheckoutQuery{}), do: nil
  def get_date_time(%Message{msg: msg}), do: get_date_time(msg)
  def get_date_time(nil), do: nil

  @doc """
  Retrieves chat id from telegram message

  ## Parameters
  - msg: telegram message
  """
  @spec get_chat_id(
          Telegex.Type.CallbackQuery.t()
          | Telegex.Type.Message.t()
          | Telegex.Type.PreCheckoutQuery.t()
        ) :: integer()
  def get_chat_id(%Telegex.Type.Message{
        chat: %Telegex.Type.Chat{
          id: chat_id
        }
      }),
      do: chat_id

  def get_chat_id(%Telegex.Type.CallbackQuery{
        message: %{
          chat: %{
            id: chat_id
          }
        }
      }),
      do: chat_id

  def get_chat_id(%Telegex.Type.PreCheckoutQuery{
        from: %Telegex.Type.User{
          id: chat_id
        }
      }),
      do: chat_id

  def get_chat_id(%Message{msg: msg}), do: get_chat_id(msg)

  @doc """
  Retrieves message id from telegram message
  """
  @spec get_message_id(
          Telegex.Type.CallbackQuery.t()
          | Telegex.Type.Message.t()
          | Telegex.Type.PreCheckoutQuery.t()
        ) :: integer()
  def get_message_id(%Telegex.Type.Message{message_id: id}), do: id
  def get_message_id(%Telegex.Type.CallbackQuery{message: msg}), do: get_message_id(msg)
  def get_message_id(%Telegex.Type.PreCheckoutQuery{id: id}), do: id

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
  - parse_mode: message processing mode for telegram `"Markdown"`, `"MarkdownV2"` or `"HTML"`
  - markup: additional marking of the message, buttons, etc.
  """
  @spec send_message(
          binary(),
          integer(),
          String.t(),
          map()
          | Telegex.Type.ReplyKeyboardMarkup.t()
          | Telegex.Type.ForceReply.t()
        ) ::
          {:error, Telegex.Error.t()} | {:ok, Telegex.Type.Message.t()}
  def send_message(msg, chat_id, parse_mode \\ "MarkdownV2", markup \\ %{})

  def send_message(msg, chat_id, parse_mode, markup) do
    result = Telegex.send_message(chat_id, msg, parse_mode: parse_mode, reply_markup: markup)

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
          {:error, Telegex.Error.t()} | {:ok, Telegex.Type.Message.t()}
  def send_with_buttons(msg, chat_id, buttons) do
    send_message(
      msg,
      chat_id,
      "MarkdownV2",
      buttons
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
          Telegex.Type.CallbackQuery.t() | Telegex.Type.Message.t(),
          binary(),
          list()
        ) :: {:error, Telegex.Error.t()} | {:ok, Telegex.Type.Message.t()}
  def edit_message(%Telegex.Type.CallbackQuery{message: msg}, text, buttons) do
    edit_message(msg, text, buttons)
  end

  def edit_message(%Telegex.Type.Message{} = msg, text, buttons) do
    message_id = get_message_id(msg)

    Telegex.edit_message_text(text,
      chat_id: get_chat_id(msg),
      message_id: message_id,
      reply_markup: %{inline_keyboard: buttons},
      parse_mode: "MarkdownV2"
    )
    |> log_on_error()
  end

  @doc """
  Send new or existing image to user or chat
  ## Parameters
  - file: file path for new photo or id telegram file
  - chat_id: user or chat id
  """
  @spec send_photo(nil | binary, integer()) ::
          {:error, Telegex.Error.t()} | {:ok, binary() | Telegex.Type.Message.t()}
  def send_photo(nil, _chat_id), do: {:error, "set file path or id"}
  def send_photo(file, chat_id), do: Telegex.send_photo(chat_id, file)

  # show error in output
  defp log_on_error({:error, reason}) do
    Logger.warning("Telegram message rejected:\n" <> inspect(reason))
  end

  defp log_on_error(_), do: nil
end
