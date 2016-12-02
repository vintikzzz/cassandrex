defmodule Cassandrex.Query do
  @moduledoc false
  import Cassandrex.CQErl
  import Cassandrex.Error
  alias Cassandrex.Result
  alias Cassandrex.Error
  alias Cassandrex.Convert, as: C
  alias Keyword, as: K
  alias :cqerl, as: CQErl

  def call(client, statement, values, opts) do
    query = prepare_query(statement, values, opts)
    case CQErl.run_query(client, query) do
      {:ok, res} -> {:ok, Result.convert(res, query)}
      {:error, error} -> error(error)
    end
  end

  def prepare_query(statement, values, opts) do
    cql_query(
      statement: statement,
      values: C.convert(:values, values),
      reusable: K.get(opts, :reusable, :undefined),
      named: K.get(opts, :named, false),
      page_size: K.get(opts, :page_size, 100),
      page_state: K.get(opts, :page_state, :undefined),
      consistency: C.convert(:consistency, K.get(opts, :consistency, :one)),
      serial_consistency: C.convert(:serial_consistency, K.get(opts, :serial_consistency, :undefined)),
      value_encode_handler: K.get(opts, :value_encode_handler, :undefined)
    )
  end
end
