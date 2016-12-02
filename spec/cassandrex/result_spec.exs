defmodule Cassandrex.ResultSpec do
  use ESpec, async: true
  alias Cassandrex, as: C
  alias Cassandrex.Result, as: R

  let_ok :c do
    C.add_nodes(["127.0.0.1:9042"])
    C.get_client()
  end

  let :keyspace, do: "cassandrex_result_test"
  let :page_size, do: 10
  let :row_num, do: 15

  before do
    C.query(c, "CREATE KEYSPACE #{keyspace} WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };")
    {:ok, _} = C.query(c, "USE #{keyspace}")
    {:ok, _} = C.query(c, "CREATE TABLE IF NOT EXISTS #{table} (col1 int PRIMARY KEY)")
    for n <- 1..row_num do
      {:ok, _} = C.query(c, "INSERT INTO #{table} (col1) values (?)", [col1: n])
    end
    :ok
  end
  finally do
    {:ok, _} = C.query(c, "DROP TABLE #{table}")
    # {:ok, _} = C.query(c, "DROP KEYSPACE #{keyspace}")
    :ok
  end
  context "when fetch_more/1" do
    let :table, do: "test"
    it "returns next page" do
      {:ok, res} = C.query(c, "SELECT col1 FROM #{table}", [], page_size: page_size)
      expect(res.num_rows) |> to(eq page_size)
      a = Enum.at(res.rows, 0)
      {:ok, res} = R.fetch_more(res)
      b = Enum.at(res.rows, 0)
      :no_more_result = R.fetch_more(res)
      expect(a) |> not_to(eq b)
    end
  end
  context "when Enum.count/1" do
    context "when all result fits one page" do
      let :table, do: "test2"
      let :row_num, do: 5
      it "returns count" do
        {:ok, res} = C.query(c, "SELECT col1 FROM #{table}", [], page_size: page_size)
        expect(Enum.count(res)) |> to(eq row_num)
      end
    end
    context "when result spread across multiple pages" do
      let :table, do: "test3"
      it "also returns count" do
        {:ok, res} = C.query(c, "SELECT col1 FROM #{table}", [], page_size: page_size)
        expect(Enum.count(res)) |> to(eq row_num)
      end
    end
  end
  context "when Enum.reduce/1" do
    context "when all result fits one page" do
      let :table, do: "test4"
      let :row_num, do: 5
      it "reduces" do
        {:ok, res} = C.query(c, "SELECT col1 FROM #{table}", [], page_size: page_size)
        sum = res.rows
        |> Enum.map(&List.first/1)
        |> Enum.sum
        expect(sum) |> to(eq 15)
      end
    end
    context "when result spread across multiple pages" do
      let :table, do: "test5"
      it "also reduces" do
        {:ok, res} = C.query(c, "SELECT col1 FROM #{table}", [], page_size: page_size)
        sum = res
        |> Enum.map(&List.first/1)
        |> Enum.sum
        expect(sum) |> to(eq 120)
      end
    end
  end
end
