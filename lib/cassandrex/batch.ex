defmodule Cassandrex.Batch do
  @moduledoc false
  alias Cassandrex.Query
  alias Cassandrex.Result
  alias Cassandrex.Convert, as: C
  alias Keyword, as: K
  import Cassandrex.CQErl
  import Cassandrex.Error
  alias :cqerl, as: CQErl

  def call(client, queries, opts) do
    batch = prepare_batch(queries, opts)
    case CQErl.run_query(client, batch) do
      {:ok, res} -> {:ok, Result.convert(res, batch)}
      {:error, error} -> error(error)
    end
  end

  defp prepare_batch(queries, opts) do
    queries = queries
    |> Enum.map fn({statement, values}) ->
      Query.prepare_query(statement, values, opts)
    end
    cql_query_batch(
      queries: queries,
      consistency: C.convert(:consistency, K.get(opts, :consistency, :one)),
      mode: C.convert(:batch_mode, K.get(opts, :mode, :logged))
    )
  end
end
