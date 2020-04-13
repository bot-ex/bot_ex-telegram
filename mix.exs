defmodule BotexTelegram.MixProject do
  use Mix.Project

  def project do
    [
      app: :botex_telegram,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:botex, path: "../botex"},
      {:nadia, "~> 0.6"},
      {:timex, "~> 3.6"},
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.21", only: :dev},
      {:jason, "~> 1.1"}
    ]
  end
end
