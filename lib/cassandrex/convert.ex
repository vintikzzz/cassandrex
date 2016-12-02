defmodule Cassandrex.Convert do
  @moduledoc """
  Converts data from Elixir to Cassandra and back.
  """
  def convert(:serial_consistency, :undefined), do: :undefined
  def convert(:serial_consistency, c), do: Keyword.fetch!(Cassandrex.consistencies, c)
  def convert(:consistency, c), do: Keyword.fetch!(Cassandrex.consistencies, c)
  def convert(:batch_mode, c), do: Keyword.fetch!(Cassandrex.batch_modes, c)
  def convert(:spec, res), do: Enum.map(elem(res, 1), fn (s) -> {elem(s, 3), elem(s, 4)} end)
  def convert(:values, values), do: values |> Enum.map(&convert(:value, &1, :default))
  def convert(:value, {k, v}, _), do: {k, convert(:value, v, :default)}
  def convert(:value, nil, _), do: :null
  def convert(:value, {k, v}, type), do: {k, convert(:value, v, type)}
  def convert(:col, {k, v}, spec), do: {k, convert(:result, v, spec[k])}
  def convert(:row, row, spec), do: row |> Enum.map(&convert(:col, &1, spec))
  def convert(:result, :null, _), do: nil
  def convert(:result, {k, v}, {:varchar, vt}), do:
    {String.to_atom(k), convert(:result, v, vt)}
  def convert(:result, {k, v}, {kt, vt}), do:
    {convert(:result, k, kt), convert(:result, v, vt)}
  def convert(any, list, {:tuple, types}), do:
    Enum.zip(list, types) |> Enum.map(&(convert(any, elem(&1, 0), elem(&1, 1))))
    |> List.to_tuple
  def convert(any, list, {:udt, types}), do:
    for {val_key, val} <- list,
        {type_key, type} <- types,
        val_key == String.to_atom(type_key), do:
          {val_key, convert(any, val, type)}
  def convert(any, list, {:map, ktype, vtype}),
    do: Enum.map(list, &convert(any, &1, {ktype, vtype})) |> Enum.into(%{})
  def convert(any, list, {type, stype}) when type in [:set, :list], do:
    Enum.map(list, &convert(any, &1, stype))
  def convert(_, any, _), do: any
end
