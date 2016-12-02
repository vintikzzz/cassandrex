defmodule Cassandrex.Error do
  @moduledoc false
  defexception [:type, :code, :msg, :misc, :message, :stacktrace]
  defp exception({code, message, misc}) do
    %__MODULE__{
      type: :cassandra,
      code: code,
      msg: message,
      misc: misc,
      message: "Cassandra error: [#{code}] #{message}"
    }
  end
  defp exception({:error, {message, stacktrace}}) do
    %__MODULE__{
      type: :cqerl,
      stacktrace: stacktrace,
      msg: message,
      message: "CQErl error: #{message}\n#{stacktrace}"
    }
  end

  def error(error), do: {:error, exception(error)}
end
