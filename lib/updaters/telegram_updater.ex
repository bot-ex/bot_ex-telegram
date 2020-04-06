defmodule BotexTelegram.Updaters.Telegram do
  @moduledoc """
  The main module that is responsible
  for receiving new messages from the telegram
  """

  use GenServer
  require Logger
  alias BotEx.Middleware.Handler

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

  @spec init(any) :: {:ok, :no_state}
  def init(_opts) do
    Process.flag(:trap_exit, true)
    cycle()
    {:ok, :no_state}
  end

  # main data acquisition cycle
  defp cycle(), do: cycle(nil)

  # as an argument receives the id of the last update
  defp cycle(id) do
    Process.send_after(self(), {:get_updates, id}, 1000)
  end

  @doc """
  The function requests data from the telegram
  """
  @spec handle_info({:get_updates, integer()}, map()) :: {:noreply, map()}
  def handle_info({:get_updates, id}, state) do
    try do
      case Nadia.get_updates(offset: id) do
        {:ok, updates} -> handleEvents(updates)
        {:error, reason} ->
          Logger.error("Update error: #{inspect(reason)}")
          cycle(id)
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
  @spec handleEvents([Nadia.Model.Update.t(), ...]) :: reference
  defp handleEvents([]), do: cycle()

  defp handleEvents(updates) do
    Enum.map(
      updates,
      fn
        # вообще вариантов может быть больше, но в текущем варианте, нужно обрабатывать только
        # простые сообщения и нажатия кнопок
        %Nadia.Model.Update{message: nil, callback_query: msg} -> msg
        %Nadia.Model.Update{message: msg, callback_query: nil} -> msg
        _msg -> nil
      end
    )
    |> Enum.filter(fn msg -> msg != nil end)
    |> Handler.handle(:telegram)

    %Nadia.Model.Update{update_id: lastId} = List.last(updates)
    cycle(lastId + 1)
  end
end
