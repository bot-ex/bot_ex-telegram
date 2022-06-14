defmodule BotexTelegram.MixProject do
  use Mix.Project

  def project do
    [
      app: :botex_telegram,
      version: "0.4.1",
      description: "Telegram module for https://github.com/bot-ex/bot_ex",
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
      {:bot_ex, "~> 1.0.1"},
      {:nadia, "~> 0.7"},
      {:timex, "~> 3.7"},
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.21", only: :dev},
      {:jason, "~> 1.3"}
    ]
  end
end
