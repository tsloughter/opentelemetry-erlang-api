defmodule OpenTelemetry.Tracer do
  @moduledoc false

  defmacro __using__(tracer) do
    case tracer do
      [] ->
        quote do
          defp __get_tracer__() do
            :opentelemetry.get_tracer()
          end
        end
      _ ->
        quote do
          defp __get_tracer__() do
            :opentelemetry.get_tracer(unquote(tracer))
          end
        end
    end
  end

  defmacro start_span(name, opts \\ quote(do: %{}), do: block) do
    quote do
      tracer = __get_tracer__()
      :ot_tracer.start_span(tracer, unquote(name), unquote(opts))
      try do
        unquote(block)
      after
        :ot_tracer.end_span(tracer)
      end
    end
  end

  defmacro with_span(span_ctx) do
    quote do
      :ot_tracer.with_span(__get_tracer__(), unquote(span_ctx))
    end
  end

  defdelegate with_span(tracer, span_ctx), to: :ot_tracer

  defmacro current_span_ctx() do
    quote do
      :ot_tracer.current_span_ctx(__get_tracer__())
    end
  end

  defdelegate current_span_ctx(tracer), to: :ot_tracer
end
