# Cassandrex

[![Build Status](https://secure.travis-ci.org/vintikzzz/cassandrex.svg?branch=master "Build Status")](http://travis-ci.org/vintikzzz/cassandrex) [![Coverage Status](https://coveralls.io/repos/vintikzzz/cassandrex/badge.svg?branch=master)](https://coveralls.io/r/vintikzzz/cassandrex?branch=master) [![hex.pm version](https://img.shields.io/hexpm/v/cassandrex.svg)](https://hex.pm/packages/cassandrex) [![hex.pm downloads](https://img.shields.io/hexpm/dt/cassandrex.svg)](https://hex.pm/packages/cassandrex) [![Deps Status](https://beta.hexfaktor.org/badge/all/github/vintikzzz/cassandrex.svg)](https://beta.hexfaktor.org/github/vintikzzz/cassandrex)
[![Inline docs](http://inch-ci.org/github/vintikzzz/cassandrex.svg?branch=master&style=flat)](http://inch-ci.org/github/vintikzzz/cassandrex)
[![Ebert](https://ebertapp.io/github/vintikzzz/cassandrex.svg)](https://ebertapp.io/github/vintikzzz/cassandrex)

Cassandra driver for Elixir on top of [cqerl][1]

Documentation: http://hexdocs.pm/cassandrex/

## Features

  * Encoding and decoding Cassandra data types to Elixir (with UDT support)
  * Batches
  * Paging (streaming)

## Data type conversion rules

    Cassandra       Elixir
    ---------       ------
    ascii           string
    bigint          integer
    blob            binary
    boolean         boolean
    counter         integer
    decimal         (not supported by cqerl)
    double          float
    float           float
    inet            (not supported by cqerl)
    int             integer
    list            list
    map             map
    set             list
    text            string
    timestamp       integer
    uuid            binary
    timeuuid        binary
    varchar         string
    varint          integer
    UDT             keyword list

## Example

```iex
iex> alias Cassandrex, as: C
Cassandrex
iex> C.add_nodes(["127.0.0.1:9042"])
:ok
iex> {:ok, c} = C.get_client()
{:ok, {#PID<0.1031.0>, #Reference<0.0.1.2590>}}
iex> C.query(c, "CREATE KEYSPACE my_keyspace WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 }")
{:ok,
 %Cassandrex.Result{columns: [], command: :create, connection_id: nil,
  cqerl: {:cql_schema_changed, :created, :keyspace, "my_keyspace", :undefined,
   :undefined}, last_insert_id: nil, num_rows: 0, rows: [], spec: nil}}
iex> C.query(c, "USE my_keyspace")
{:ok,
 %Cassandrex.Result{columns: [], command: :use, connection_id: nil,
  cqerl: {:set_keyspace, "my_keyspace"}, last_insert_id: nil, num_rows: 0,
  rows: [], spec: nil}}
iex> C.query(c, "CREATE TABLE IF NOT EXISTS animals (name text PRIMARY KEY, legs tinyint, friendly boolean)")
{:ok,
 %Cassandrex.Result{columns: [], command: :create, connection_id: nil,
  cqerl: {:cql_schema_changed, :created, :table, "my_keyspace", "animals",
   :undefined}, last_insert_id: nil, num_rows: 0, rows: [], spec: nil}}
iex> statement = "INSERT INTO animals (name, legs, friendly) values (?, ?, ?)"
"INSERT INTO animals (name, legs, friendly) values (?, ?, ?)"
iex> C.query(c, statement, [name: "cat", legs: 4, friendly: false])
{:ok,
 %Cassandrex.Result{columns: [], command: :insert, connection_id: nil,
  cqerl: :void, last_insert_id: nil, num_rows: 0, rows: [], spec: nil}}
iex> C.query(c, statement, [name: "dog", legs: 4, friendly: true])
{:ok,
 %Cassandrex.Result{columns: [], command: :insert, connection_id: nil,
  cqerl: :void, last_insert_id: nil, num_rows: 0, rows: [], spec: nil}}
iex> C.query(c, "SELECT name, legs, friendly FROM #{table}")
{:ok,
 %Cassandrex.Result{columns: [:name, :legs, :friendly], command: :select,
  connection_id: nil,
  cqerl: {:cql_result,
   [{:cqerl_result_column_spec, "my_keyspace", "animals", :name, :varchar},
    {:cqerl_result_column_spec, "my_keyspace", "animals", :legs, :tinyint},
    {:cqerl_result_column_spec, "my_keyspace", "animals", :friendly, :boolean}],
   [[<<0, 0, 0, 3, 99, 97, 116>>, <<0, 0, 0, 1, 4>>, <<0, 0, 0, 1, 0>>],
    [<<0, 0, 0, 3, 100, 111, 103>>, <<0, 0, 0, 1, 4>>, <<0, 0, 0, 1, 1>>]],
   {:cql_query, "SELECT name, legs, friendly FROM animals", [], :undefined,
    false, 100, :undefined, 1, :undefined, :undefined},
   {#PID<0.1031.0>, #Reference<0.0.1.2597>}}, last_insert_id: nil, num_rows: 2,
  rows: [["cat", 4, false], ["dog", 4, true]],
  spec: [name: :varchar, legs: :tinyint, friendly: :boolean]}}
```

## Installation

  1. Add `cassandrex` and `cqerl` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:cqerl, github: "matehat/cqerl", tag: "v1.0.2", only: :test},
      {:cassandrex, "~> 0.1.0"}]
    end
    ```

  2. Ensure `cassandrex` is started before your application:

    ```elixir
    def application do
      [applications: [:cassandrex]]
    end
    ```

## Contributing

To contribute you need to compile Cassandrex from source and test it:

```
$ git clone https://github.com/vintikzzz/cassandrex.git
$ cd cassandrex
$ mix deps.get
$ mix espec
```

## License

Copyright 2016 Pavel Tatarskiy

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

[1]: https://github.com/matehat/cqerl/
