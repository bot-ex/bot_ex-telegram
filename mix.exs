defmodule BotexTelegram.MixProject do
  use Mix.Project

  def project do
    [
      app: :botex_telegram,
      version: "0.3.0",
      description: "Telegram module for https://github.com/bot-ex/bot_ex",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        licenses: ["MIT"],
        homepage_url: "https://github.com/bot-ex",
        links: %{"GitHub" => "https://github.com/bot-ex/bot_ex-telegram"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bot_ex, "~> 0.2.0"},
      {:nadia, "~> 0.6"},
      {:timex, "~> 3.6"},
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.21", only: :dev},
      {:jason, "~> 1.1"}
    ]
  end
end
