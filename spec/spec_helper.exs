ESpec.configure fn(config) ->
  config.before fn(tags) ->
    {:shared, hello: :world, tags: tags}
  end

  config.finally fn(_shared) ->
    :ok
  end
end

defmodule BeStoredAsAssertion do
  use ESpec
  use ESpec.Assertions.Interface
  alias Cassandrex, as: C

  defp match(subject, val) do
    C.add_nodes(["127.0.0.1:9042"])
    {:ok, c} = C.get_client()
    table = Regex.replace(~r/[<>\,\s]/, val, "") <> "test"
    {:ok, _} = C.query(c, "CREATE TABLE IF NOT EXISTS #{table} (col1 int PRIMARY KEY, col2 #{val})")
    {:ok, _} = C.query(c, "INSERT INTO #{table} (col1, col2) values (?, ?)", [col1: 1, col2: subject])
    {:ok, %Cassandrex.Result{rows: [[_, result] | _]}} = C.query(c, "SELECT col1, col2 FROM #{table}")
    {:ok, _} = C.query(c, "DROP TABLE #{table}")
    cond do
      is_list(result) && is_list(subject) -> {Enum.sort(result) == Enum.sort(subject), subject}
      true -> {result == subject, result}
    end
  end

  defp success_message(subject, val, _result, positive) do
    to = if positive, do: "is", else: "is not"
    "`#{inspect subject}` #{to} is stored as #{val}."
  end

  defp error_message(subject, val, result, positive) do
    to = if positive, do: "to", else: "not to"
    "Expected `#{inspect subject}` #{to} be stored as `#{val}` correctly, but it is stored as '#{inspect result}'."
  end
end

defmodule MyCustomAssertions do
  def be_stored_as(val), do: {BeStoredAsAssertion, val}
end
