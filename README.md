# Botex telegram

Telegram module for [:botex](https://github.com/bot-ex/botex)

# How to start:
  
```elixir
  #mix.exs
  def deps do
    [
      {:botex_telegram, "~> 0.0.1"}
    ]
  end

 config :botex,
   ....
    bots: [:telegram],
    middlware: [
      telegram: [
        BotexTelegram.Middleware.NadiaMessageTransformer,
        BotexTelegram.Middleware.Auth,
        BotEx.Middleware.ShortCmd,
        BotexTelegram.Middleware.TextInput,
        BotEx.Middleware.MessageLogger,
        BotexTelegram.Middleware.MessageLogger
      ]
    ],
    handlers: [
      telegram: [
        #tupples with {module, count workers}
        {BotexTelegram.Handlers.Start, 5},
        {BotexTelegram.Handlers.Menu, 10}
      ]
    ]
```

```elixir
#application.ex
def start(_type, _args) do
  children = [
    BotexTelegram.Updaters.Telegram,
    BotexTelegram.Services.Menu.Api
  ]

  opts = [strategy: :one_for_one, name: BotTest.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Example `menu.exs`
```elixir
%{
   "main_menu" => %BotEx.Models.Menu{
     #can be defined as functions
     # buttons: fn() -> [] end
     buttons: [
       [
         %BotEx.Models.Button{
           action: "some",
           data: "data",
           module: BotexTelegram.Handlers.Start.get_cmd_name(),
           text: "This is button"
         }
       ]
     ]
   }
 }
```
# Routing
Rouring create from defined handlers. Each handler have function `get_cmd_name/0` that return command name for this handler. When user call `/start` command, router find module for handle by answer `get_cmd_name/0` value.

Optionaly you can create file `routes.exs` and redefine or add aliases for your commands

### Example `routes.exs`
```elixir
%{
  telegram:
    %{"s" => BotexTelegram.Handlers.Start}
}
```
Also you can create file `short_map.exs` that contains text aliases for command

### Example `short_map.exs`
```elixir
%{
  telegram:
  %{
    "i" => {BotexTelegram.Handlers.Start.get_cmd_name(), "some action"}
  }
}
```
