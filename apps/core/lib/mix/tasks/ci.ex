defmodule Mix.Tasks.Ci do
  @shortdoc "Runs all CI checks"

  @moduledoc """
  Runs all CI checks locally.

  ## Usage

      mix ci           # Run all checks
      mix ci --quick   # Skip dialyzer (faster)

  ## Checks executed

  1. mix deps.unlock --check-unused
  2. mix format --check-formatted
  3. mix credo --strict
  4. mix hex.audit
  5. mix deps.audit
  6. mix dialyzer (unless --quick is used)
  7. mix test
  """

  use Mix.Task

  @checks [
    {"Checking unused deps", "mix deps.unlock --check-unused"},
    {"Checking formatting", "mix format --check-formatted"},
    {"Running Credo", "mix credo --strict"},
    {"Hex audit", "mix hex.audit"},
    {"Dependencies audit", "mix deps.audit"}
  ]

  @impl Mix.Task
  def run(args) do
    checks = build_checks("--quick" in args)

    failed =
      checks
      |> Enum.map(&run_check/1)
      |> Enum.reject(fn {_name, code, _output} -> code == 0 end)

    print_summary(failed)
  end

  defp build_checks(true), do: @checks ++ [{"Running tests", "mix test"}]

  defp build_checks(false),
    do: @checks ++ [{"Running Dialyzer", "mix dialyzer"}, {"Running tests", "mix test"}]

  defp run_check({name, command}) do
    Mix.shell().info("\n#{IO.ANSI.cyan()}=== #{name} ===#{IO.ANSI.reset()}")
    {output, exit_code} = System.shell(command, stderr_to_stdout: true)
    IO.write(output)
    {name, exit_code, output}
  end

  defp print_summary([]) do
    Mix.shell().info("\n#{IO.ANSI.cyan()}=== Summary ===#{IO.ANSI.reset()}")
    Mix.shell().info("#{IO.ANSI.green()}✓ All checks passed!#{IO.ANSI.reset()}")
  end

  defp print_summary(failed) do
    Mix.shell().info("\n#{IO.ANSI.cyan()}=== Summary ===#{IO.ANSI.reset()}")
    Mix.shell().info("#{IO.ANSI.red()}✗ Failed checks:#{IO.ANSI.reset()}")

    Enum.each(failed, fn {name, _code, output} ->
      Mix.shell().info("\n#{IO.ANSI.red()}--- #{name} ---#{IO.ANSI.reset()}")

      output_lines = String.split(output, "\n")
      lines_to_show = Enum.take(output_lines, -50)

      if length(output_lines) > 50 do
        Mix.shell().info("#{IO.ANSI.yellow()}[Showing last 50 lines of output]#{IO.ANSI.reset()}")
      end

      IO.puts(Enum.join(lines_to_show, "\n"))
    end)

    Mix.raise("CI failed")
  end
end
