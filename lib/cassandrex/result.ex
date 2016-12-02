defmodule Cassandrex.Result do
  @moduledoc """
  Struct stores result of Cassandra query. Has paging support.
  """
  require Record
  alias :cqerl, as: CQErl
  alias Cassandrex.Convert, as: C
  alias __MODULE__, as: R

  defstruct [:command, :columns, :rows, :last_insert_id,
             :num_rows, :connection_id, :cqerl, :spec]

  def convert(res) when Record.is_record(res, :cql_result), do: convert(res, elem(res, 3))
  def convert(res, query) when Record.is_record(res, :cql_result) do
    spec = C.convert(:spec, res)
    cqerl_rows = CQErl.all_rows(res)

    rows = cqerl_rows
    |> Enum.map(&C.convert(:row, &1, spec))
    |> Enum.map(&Keyword.values/1)

    %R{defaults(res, query) |
      columns: Keyword.keys(spec),
      rows: rows,
      num_rows: Enum.count(rows),
      spec: spec
    }
  end
  def convert(res, query) when Record.is_record(res, :cql_schema_changed), do: defaults(res, query)
  def convert({_, _} = res, query), do: defaults(res, query)
  def convert(:void = res, query), do: defaults(res, query)

  defp get_command(query) do
    query |> elem(1) |> :binary.split([" ", "\n"])
    |> hd |> String.downcase |> String.to_atom
  end

  defp defaults(res, query) when Record.is_record(query, :cql_query)  do
    defaults(res, get_command(query))
  end
  defp defaults(res, query) when Record.is_record(query, :cql_query_batch)  do
    defaults(res, :batch)
  end
  defp defaults(res, command) when is_atom(command) do
    %R{
      command: command,
      columns: [],
      rows: [],
      num_rows: 0,
      cqerl: res,
      connection_id: nil
    }
  end

  def fetch_more(r) do
    case CQErl.fetch_more(r.cqerl) do
      {:ok, res} -> {:ok, R.convert(res)}
      :no_more_result -> :no_more_result
      any -> any
    end
  end

  def has_more_pages?(res), do: CQErl.has_more_pages(res.cqerl)

  defimpl Enumerable do
    alias __MODULE__, as: E

    def count(res) do
      case R.has_more_pages?(res) do
        true -> {:error, E}
        false -> {:ok, res.num_rows}
      end
    end

    def member?(_res, _row) do
      {:error, E}
    end

    def reduce(%R{num_rows: 0} = res, {:cont, acc}, fun) do
      case R.fetch_more(res) do
        {:ok, res} -> reduce(res, {:cont, acc}, fun)
        :no_more_result -> {:done, acc}
      end
    end
    def reduce(res, {:cont, acc}, fun) do
      [h | t] = res.rows
      t = %R{res | rows: t, num_rows: res.num_rows - 1}
      reduce(t, fun.(h, acc), fun)
    end
    def reduce(res, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(res, &1, fun)}
    end
    def reduce(_res, {:halt, acc}, _fun), do: {:halted, acc}
  end
end
