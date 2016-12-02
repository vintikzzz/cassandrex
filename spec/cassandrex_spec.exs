defmodule CassandrexSpec do
  use ESpec, async: false
  import MyCustomAssertions
  alias Cassandrex, as: C
  alias :uuid, as: U

  let_ok :c do
    C.add_nodes(["127.0.0.1:9042"])
    C.get_client()
  end

  let :keyspace, do: "cassandrex_test"

  before do
    C.query(c, "CREATE KEYSPACE #{keyspace} WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };")
    {:ok, _} = C.query(c, "USE #{keyspace}")
    :ok
  end
  finally do
    # {:ok, _} = C.query(c, "DROP KEYSPACE #{keyspace}")
    :ok
  end

  context "when batch/4" do
    it "executes simple queries in batches" do
      table = "animals2"
      statement = "INSERT INTO #{table} (name, legs, friendly) values (?, ?, ?)"
      {:ok, _} = C.query(c, "CREATE TABLE IF NOT EXISTS #{table} (name text PRIMARY KEY, legs tinyint, friendly boolean)")
      {:ok, _} = C.batch(c, [
        {statement, [name: "cat", legs: 4, friendly: false]},
        {statement, [name: "dog", legs: 4, friendly: true]}
      ])
      {:ok, res} = C.query(c, "SELECT name, legs, friendly FROM #{table}")

      res.rows
      |> expect
      |> to(eq [["cat", 4, false],
                ["dog", 4, true]])

      {:ok, _} = C.query(c, "DROP TABLE #{table}")
    end
  end

  context "when query/4" do
    it "executes simple queries" do
      table = "animals"
      statement = "INSERT INTO #{table} (name, legs, friendly) values (?, ?, ?)"
      {:ok, _} = C.query(c, "CREATE TABLE IF NOT EXISTS #{table} (name text PRIMARY KEY, legs tinyint, friendly boolean)")
      {:ok, _} = C.query(c, statement, [name: "cat", legs: 4, friendly: false])
      {:ok, _} = C.query(c, statement, [name: "dog", legs: 4, friendly: true])
      {:ok, res} = C.query(c, "SELECT name, legs, friendly FROM #{table}")

      res.columns
      |> expect
      |> to(eq [:name, :legs, :friendly])

      res.rows
      |> expect
      |> to(eq [["cat", 4, false],
                ["dog", 4, true]])

      {:ok, _} = C.query(c, "DROP TABLE #{table}")
    end
    it "deals with errors" do
      {:error, %Cassandrex.Error{code: 8192}} = C.query(c, "HOW ARE YOU?")
    end
    context "with different data types" do
      it "correctly represents ascii" do
        expect(nil) |> to(be_stored_as "ascii")
        expect("abracadabra") |> to(be_stored_as "ascii")
        expect("") |> to(be_stored_as "ascii")
      end
      it "correctly represents bigint" do
        expect(nil) |> to(be_stored_as "bigint")
        expect(-9_223_372_036_854_775_808) |> to(be_stored_as "bigint")
        expect(9_223_372_036_854_775_807) |> to(be_stored_as "bigint")
        expect(0) |> to(be_stored_as "bigint")
      end
      it "represents blob as binary" do
        expect(<<0,1,2,3>>) |> to(be_stored_as "blob")
        expect(<<>>) |> to(be_stored_as "blob")
        expect(nil) |> to(be_stored_as "blob")
      end
      it "correctly represents boolean" do
        expect(true) |> to(be_stored_as "boolean")
        expect(false) |> to(be_stored_as "boolean")
        expect(nil) |> to(be_stored_as "boolean")
      end
      pending "correctly represents decimal (not supported by cqerl)"
      # do
        # expect(10.5) |> to(be_stored_as "decimal")
        # expect(-10.5) |> to(be_stored_as "decimal")
        # expect(nil) |> to(be_stored_as "decimal")
      # end
      it "correctly represents double" do
        expect(10) |> to(be_stored_as "double")
        expect(-10) |> to(be_stored_as "double")
        expect(-4.9e-324) |> to(be_stored_as "double")
        expect(1.7e+308) |> to(be_stored_as "double")
        expect(0) |> to(be_stored_as "double")
        expect(nil) |> to(be_stored_as "double")
      end
      it "correctly represents float" do
        expect(10) |> to(be_stored_as "float")
        expect(-10) |> to(be_stored_as "float")
        expect(10.5) |> to(be_stored_as "float")
        expect(-10.5) |> to(be_stored_as "float")
        # expect(-1.4e-45) |> to(be_stored_as "float") don't work :(
        # expect(3.4e38) |> to(be_stored_as "float") don't work :(
        expect(0) |> to(be_stored_as "float")
        expect(nil) |> to(be_stored_as "float")
      end
      pending "correctly represents inet (not supported by cqerl)"
      # do
      #   expect("127.0.0.1") |> to(be_stored_as "inet")
      #   expect(nil) |> to(be_stored_as "inet")
      # end
      it "correctly represents int" do
        expect(2_147_483_647) |> to(be_stored_as "int")
        expect(-2_147_483_648) |> to(be_stored_as "int")
        expect(0) |> to(be_stored_as "int")
        expect(nil) |> to(be_stored_as "int")
      end
      it "correctly represents list" do
        expect([1, 2]) |> to(be_stored_as "list<int>")
        expect(nil) |> to(be_stored_as "list<int>")
        expect(["a", "b"]) |> to(be_stored_as "list<text>")
        expect([U.get_v4, U.get_v4])
        |> to(be_stored_as "list<uuid>")
      end
      it "correctly represents map" do
        expect(%{a: "b", c: "d"}) |> to(be_stored_as "map<text, text>")
        expect(nil) |> to(be_stored_as "map<text, text>")
        expect(%{a: 0, c: 1}) |> to(be_stored_as "map<text, int>")
        expect(%{a: U.get_v4, b: U.get_v4})
        |> to(be_stored_as "map<text, uuid>")
      end
      it "correctly represents tuple" do
        expect({1, "abra", U.get_v4, true, 1.5})
        |> to(be_stored_as "tuple<int, text, uuid, boolean, float>")
      end
      it "correctly represents map of tuples" do
        expect(%{
          a: {0, 0},
          b: {1, 1},
          c: {2, 0}
        }) |> to(be_stored_as "map<text, frozen<tuple<int, int>>>")
      end
      it "represents set as a list" do
        expect([1, 2]) |> to(be_stored_as "set<int>")
        expect(nil) |> to(be_stored_as "set<int>")
        expect(["a", "b"]) |> to(be_stored_as "set<text>")
        expect([U.get_v4, U.get_v4])
        |> to(be_stored_as "set<uuid>")
      end
      it "correctly represents text" do
        text = """
          На берегу пустынных волн
          Стоял он, дум великих полн,
          И вдаль глядел. Пред ним широко
          Река неслася; бедный чёлн
          По ней стремился одиноко.
          По мшистым, топким берегам
          Чернели избы здесь и там,
          Приют убогого чухонца;
          И лес, неведомый лучам
          В тумане спрятанного солнца,
          Кругом шумел.
        """
        expect(nil) |> to(be_stored_as "text")
        expect("abracadabra") |> to(be_stored_as "text")
        expect(text) |> to(be_stored_as "text")
        expect("") |> to(be_stored_as "text")
      end
      it "correctly represents timestamp" do
        expect(nil) |> to(be_stored_as "timestamp")
        expect(:os.system_time(:seconds)) |> to(be_stored_as "timestamp")
        expect(:os.system_time(:micro_seconds)) |> to(be_stored_as "timestamp")
      end
      it "correctly represents uuid" do
        expect(U.get_v4) |> to(be_stored_as "uuid")
      end
      it "correctly represents timeuuid" do
        s = U.new(self)
        {u, _} = U.get_v1(s)
        expect(u) |> to(be_stored_as "timeuuid")
      end
      it "correctly represents varchar" do
        expect(nil) |> to(be_stored_as "varchar")
        expect("abracadabra") |> to(be_stored_as "varchar")
        expect("") |> to(be_stored_as "varchar")
      end
      it "correctly represents varint" do
        expect(10) |> to(be_stored_as "varint")
        expect(-10) |> to(be_stored_as "varint")
        expect(nil) |> to(be_stored_as "varint")
      end
      it "represents user-defined types as a list of cols" do
        {:ok, _} = C.query(c, "CREATE TYPE IF NOT EXISTS my_custom_type" <>
          "(col1 int, col2 uuid, col3 map<text, uuid>, " <>
          "col4 tuple<int, text, uuid, boolean, float>, " <>
          "col5 map<text, frozen<tuple<int, int>>>)")
        expect([col1: 1, col2: U.get_v4, col3: %{a: U.get_v4, b: U.get_v4},
          col4: {2, "abra", U.get_v4, false, 3.5},
          col5: %{a: {0, 0}, b: {1, 1}, c: {2, 0}}])
        |> to(be_stored_as "frozen<my_custom_type>")
      end
    end
  end
end
