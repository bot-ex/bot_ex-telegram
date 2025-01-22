defmodule BotexTelegram.Updaters.Telegram do
  @moduledoc """
  The main module that is responsible
  for receiving new messages from the telegram
  """

  use GenServer
  require Logger
  alias BotEx.Routing.MessageHandler

  @default_upate_interval 1000

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

  @spec init(any) :: {:ok, map()}
  def init(_opts) do
    Process.flag(:trap_exit, true)

    interval = Application.get_env(:botex_telegram, :update_interval, @default_upate_interval)

    cycle(nil, interval)
    {:ok, %{"interval" => interval}}
  end

  # as an argument receives the id of the last update
  defp cycle(id, interval) do
    Process.send_after(self(), {:get_updates, id}, interval)
  end

  @doc """
  The function requests data from the telegram
  """
  @spec handle_info({:get_updates, integer()}, map()) :: {:noreply, map()}
  def handle_info({:get_updates, id}, %{"interval" => interval} = state) do
    try do
      case Telegex.get_updates(offset: id) do
        {:ok, updates} ->
          # Logger.debug(inspect(updates))
          handleEvents(updates, interval)

        {:error, reason} ->
          Logger.error("Update error: #{inspect(reason)}")
          cycle(id, interval)
      end
    rescue
      e in Jason.EncodeError -> Logger.error("Update error: #{inspect(e)}")
    end

    {:noreply, state}
  end

  def handle_info({:EXIT, from_pid, reason}, state) do
    Logger.error(inspect(["process die", from_pid, reason]))
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  # processes the list of new messages
  @spec handleEvents([Telegex.Type.Update.t(), ...], integer()) :: reference
  defp handleEvents([], interval), do: cycle(nil, interval)

  defp handleEvents(updates, interval) do
    Enum.map(
      updates,
      fn
        # вообще вариантов может быть больше, но в текущем варианте, нужно обрабатывать только
        # простые сообщения и нажатия кнопок
        %Telegex.Type.Update{
          message: nil,
          callback_query: nil,
          pre_checkout_query: %Telegex.Type.PreCheckoutQuery{} = msg
        } ->
          msg

        %Telegex.Type.Update{message: nil, callback_query: msg} ->
          msg

        %Telegex.Type.Update{message: msg, callback_query: nil} ->
          msg

        msg ->
          Logger.debug("Unexpected message: " <> inspect(msg))
          nil
      end
    )
    |> Enum.filter(fn msg -> msg != nil end)
    |> MessageHandler.handle(:telegram)

    %Telegex.Type.Update{update_id: lastId} = List.last(updates)
    cycle(lastId + 1, interval)
  end
end
