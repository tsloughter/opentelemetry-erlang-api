defmodule OpenTelemetry.Tracer do
  @moduledoc """
  Defines tracer module.

  ## Example

      defmodule Tracer do
        use #{inspect __MODULE__}
      end
  """

  # TODO:
  # - what options are possible there?
  # - should we use `:otp_app` attribute to allow configuring tracer within
  #   given application?
  defmacro __using__(tracer) do
    quote bind_quoted: [module: __MODULE__, tracer: tracer] do
      @behaviour module

      # TODO: Maybe we should make it public?
      defp __tracer__, do: :opentelemetry.get_tracer(unquote(tracer))

      @impl module
      def start_span(name, opts \\ []), do: :ot_tracer.start_span(__tracer__(), name, opts)

      @impl module
      def end_span(name, span_ctx \\ current_span()),
        do: :ot_tracer.end_span(__tracer__(), span_ctx)

      @impl module
      def current_span(), do: :ot_tracer.current_span(__tracer__())

      @impl module
      def with_span(name, opts \\ [], func) do
        tracer = __tracer__()
        span_ctx = :ot_tracer.start_span(tracer, name, opts)

        try do
          func.()
          # TODO: Set status on errors
          # catch
          #   kind, value ->
          #     # Mock, the real handling will probavly look a little bit different
          #     set_status(Exception.normalize(kind, value, __STACKTRACE__)
          #     :erlang.raise(kind, value, __STACKTRACE__)
        after
          :ot_tracer.end_span(tracer, span_ctx)
        end
      end
    end
  end

  @doc """
  Starts new span.
  """
  @callback start_span(name :: :opentelemetry.span_name(), opts :: :ot_span.start_opts()) ::
              :opentelemetry.span_ctx()

  @doc """
  Ends span.

  By default it ends current span.
  """
  @callback end_span(span_ctx :: :opentelemetry.span_ctx()) :: :ok

  @doc """
  Return currently active span.
  """
  @callback current_span_ctx() :: :opentelemetry.span_ctx() | :undefined

  @doc """
  Runs given function within new span and closes it afterwards.

  ## Example

      parent_span = Tracer.current_span_ctx()

      Tracer.with_span("foo", fn ->
        parent_span != Tracer.current_span_ctx()
      end)

      parent_span == Tracer.current_span_ctx()
  """
  @callback with_span(
              name :: :opentelemetry.span_name(),
              opts :: :ot_span.start_opts(),
              func :: (() -> return)
            ) ::
              return
            when return: any()
end
