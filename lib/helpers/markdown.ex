defmodule BotexTelegram.Helpers.Markdown do
  @moduledoc "markdown actions"

  @doc """
  Applies bold format to text
  ## Parameters
    - text: any text
  """
  @spec bold(binary()) :: binary()
  def bold(text),  do: "*#{text}*"

  @doc """
  Escapes special chars in text
  ## Parameters
  - text: message text
  """
  @spec escape_markdown(binary()) :: binary()
  def escape_markdown(text) do
    # ] there is no point to escape ], because it is active only with unescaped [
    Regex.replace(
      ~r/([\*\[\\_`#<>])/,
      text,
      fn
        _, "<" -> "&lt;"
        _, ">" -> "&gt;"
        _, "&" -> "&amp;"
        _, "*" -> "\uFE61" # there is an only way to fix asterisk in BOLD font - change it to similar asterisk.
        _, "`" -> "``"
        _, x -> "\\#{x}"
      end,
      global: true
    )
  end
end
