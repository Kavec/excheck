defmodule ExCheck do
  use Application

  @moduledoc """
  Provides QuickCheck style testing feature.
  add 'use ExCheck' in the ExUnit test files.
  """

  defmacro __using__(_opts \\ []) do
    quote do
      import ExCheck.Predicate
      import ExCheck.Statement
      use ExCheck.Generator
      use ExUnit.Callbacks

      setup(context) do
        # Redirect all output first to IOServer process before test starts
        ExCheck.IOServer.redirect(self)
        {:ok, context}
      end
    end
  end

  @doc "Starts the ExCheck application."
  def start, do: Application.ensure_all_started(:excheck)

  @doc "Starts the ExCheck application."
  def start(_app, _type) do
    import Supervisor.Spec, warn: false
    children = [
      worker(ExCheck.IOServer, [])
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc """
  Check the property defined in the specified target (module or method).
  If the module name is specified, check all the methods prefixed with 'prop_'.
  """
  def check(target) do
    case :triq.check(target) do
      true ->
        true
      false ->
        false
      {:EXIT, %{__struct__: ExUnit.AssertionError} = error} ->
        raise error
      {:EXIT, %{__struct__: type, message: msg}} ->
        raise %ExCheck.Error{message: "error raised: (#{type}) #{msg}"}
      error ->
        raise %ExCheck.Error{message: "check failed: #{inspect error}"}
    end
  end
end
