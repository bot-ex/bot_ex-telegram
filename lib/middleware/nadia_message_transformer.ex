defmodule BotexTelegram.Middleware.NadiaMessageTransformer do
  @moduledoc """
  Convert telegram message to `BotEx.Models.Message`
  """
  @behaviour BotEx.Behaviours.MiddlewareParser

  alias BotEx.Models.Message

  @spec transform(Nadia.Model.Message.t() | Nadia.Model.CallbackQuery.t()) ::
          Message.t()
  def transform(msg) do
    data =
      case msg do
        %Nadia.Model.Message{text: text} -> text
        %Nadia.Model.CallbackQuery{data: cmd} -> cmd
      end

    t_msg = %Message{
      msg: msg,
      text: data,
      date_time: Timex.local(),
      from: :telegram
    }

    handle_message(data, t_msg)
  end

  # Handle incoming message
  # ## Parameters:
  # - text: text from message
  # - t_msg: `BotEx.Models.Message`
  @spec handle_message(nil | binary(), Message.t()) :: Message.t()
  defp handle_message(nil, t_msg), do: t_msg

  defp handle_message(text, t_msg) do
    if is_command?(text) do
      analyze_command(text)
      |> finalize(t_msg)
    else
      %Message{t_msg | text: text, is_cmd: false}
    end
  end

  # Checks if an incoming message is a command
  # ## Parameters:
  # - text: analyzed text
  @spec is_command?(binary()) :: boolean
  defp is_command?(text), do: Regex.match?(~r/^\/.+/, text)

  # Additional helper for parsing a command by separator type
  # ## Parameters:
  # - text: analyzed text
  @spec analyze_command(:split, list()) ::
          {binary(), nil | binary(), nil | binary()}
  defp analyze_command(:split, [cmd]), do: {cmd, nil, nil}

  defp analyze_command(:split, [cmd, action]), do: {cmd, action, nil}

  defp analyze_command(:split, [cmd, action, data]), do: {cmd, action, data}

  defp analyze_command(:split, text) do
    {_, data} = Enum.split(text, 2)
    {Enum.at(text, 0), Enum.at(text, 1), Enum.join(data, " ")}
  end

  # Splits the command into components
  # ## Parameters:
  # - text: analyzed text
  @spec analyze_command(binary() | list()) ::
          {binary(), nil | binary(), nil | binary()}
  defp analyze_command(text) do
    case analyze_command(:split, String.split(text, "|")) do
      {_cmd, nil, nil} ->
        analyze_command(:split, String.split(text, " "))

      result ->
        result
    end
  end

  # Lays out the command in the fields of the model
  # ## Parameters:
  # - {"cmd, action, data}: tuple with data
  #   `cmd`: command
  #   `action`: action
  #   `data`: additional data
  # - t_msg: `BotEx.Models.Message`
  @spec finalize({binary(), nil | binary(), nil | binary()}, Message.t()) :: Message.t()
  defp finalize({"/" <> cmd, action, data}, t_msg) do
    %Message{t_msg | is_cmd: true, module: cmd, action: action, data: data, text: ""}
  end
end
