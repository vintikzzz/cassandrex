defmodule Cassandrex.CQErl do
  @moduledoc """
  Defines records for communication with cqerl
  """

  require Record

  Record.defrecord :cql_query, [
    statement: <<>>,
    values: [],
    reusable: :undefined,
    named: false,
    page_size: 100,
    page_state: :undefined,
    consistency: 1,
    serial_consistency: :undefined,
    value_encode_handler: :undefined
  ]

  Record.defrecord :cql_query_batch, [
    consistency: 1,
    mode: 0,
    queries: []
  ]
end
