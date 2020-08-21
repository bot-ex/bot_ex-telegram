# Botex telegram

Telegram module for [:bot_ex](https://github.com/bot-ex/bot_ex)

# How to start:
  
```elixir
  #mix.exs
  def deps do
    [
      {:botex_telegram, "~> 0.0.1"}
    ]
  end

 config :bot_ex,
   ....
    bots: [:telegram],
    middlware: [
      telegram: [
        BotexTelegram.Middleware.NadiaMessageTransformer,
        BotexTelegram.Middleware.Auth,
        BotexTelegram.Middleware.TextInput,
        BotEx.Middleware.MessageLogger,
        BotexTelegram.Middleware.MessageLogger
      ]
    ],
    handlers: [
      telegram: [
        #tupples with {module, buffering time}
        {BotexTelegram.Handlers.Start, 500},
        {BotexTelegram.Handlers.Menu, 500}
      ]
    ]

  #the interval for getting updates from telegram api
  config :bot_ex, update_interval: 1000
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
