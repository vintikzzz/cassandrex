defmodule Cassandrex do
  @moduledoc """
  Cassandra driver for Elixir
  """
  alias Cassandrex.Query
  alias Cassandrex.Batch

  alias :cqerl, as: CQErl

  @doc """
  Gets client from underlying cqerl driver by cluster name. If no cluster name
  provided returns client for default cluster.
  """
  def get_client(), do: CQErl.get_client()
  def get_client(cluster) when is_atom(cluster), do: CQErl.get_client(cluster)

  @doc """
  Closes provided client
  """
  defdelegate close_client(client), to: :cqerl, as: :close_client

  @doc """
  Adds nodes to the cluster.

  ## Options
    * `keyspace` - Keyspace to use by default
    * `auth` - Authorization parameters
    * `ssl` - SSL parameters
    * And so on, all options passed to cqerl as is (please see cqerl docs)

  ## Examples

      C.add_nodes(["127.0.0.1:9042"])

      C.add_nodes(:my_cluster, ["127.0.0.1:9042"])

      C.add_nodes(:my_cluster, ["127.0.0.1:9042"], keyspace: :my_keyspace)
  """
  defdelegate add_nodes(a),       to: :cqerl_cluster, as: :add_nodes
  defdelegate add_nodes(a, b),    to: :cqerl_cluster, as: :add_nodes
  defdelegate add_nodes(a, b, c), to: :cqerl_cluster, as: :add_nodes

  @doc """
  Performs query

  ## Options
    * `consistency` - Consistency of query (please see Cassandra docs)
    * `serial_consistency` - Serial consistency (please see Cassandra docs)

  ## Examples

      {:ok, res} = C.query(c, "SELECT name, legs, friendly FROM animals")

      {:ok, _} = C.query(c, "INSERT INTO animals (name, legs, friendly) values (?, ?, ?)", [name: "cat", legs: 4, friendly: false])

      {:ok, res} = C.query(c, "SELECT name, legs, friendly FROM animals", consistency: :quorum)
  """

  def query(client, statement, values \\ [], opts \\ []), do:
    Query.call(client, statement, values, opts)

  @doc """
  Performs batched query

  ## Options
    * `consistency` - Consistency of query (please see Cassandra docs)
    * `mode` - batch mode (please see Cassandra docs)

  ## Examples
      statement = "INSERT INTO animals (name, legs, friendly) values (?, ?, ?)"
      {:ok, _} = C.batch(c, [
        {statement, [name: "cat", legs: 4, friendly: false]},
        {statement, [name: "dog", legs: 4, friendly: true]}
      ])
  """

  def batch(client, queries, opts \\ []), do:
    Batch.call(client, queries, opts)

  @consistencies [
    any:            0,
    one:            1,
    two:            2,
    three:          3,
    quorum:         4,
    all:            5,
    local_quorum:   6,
    each_quorum:    7,
    serial:         8,
    local_serial:   9,
    local_one:      10
  ]

  @batch_modes [
    logged:   0,
    unlogged: 1,
    counter:  2
  ]

  def consistencies do
    @consistencies
  end

  def batch_modes do
    @batch_modes
  end
end
