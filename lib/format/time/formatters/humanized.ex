defmodule Timex.Format.Time.Formatters.Humanized do
  @moduledoc """
  Handles formatting timestamp values as human readable strings.
  For formatting timestamps as points in time rather than intervals,
  use `Timex.format`
  """
  use Timex.Format.Time.Formatter
  alias Timex.Translator

  @minute 60
  @hour   @minute * 60
  @day    @hour * 24
  @week   @day * 7
  @month  @day * 30
  @year   @day * 365

  @doc """
  Return a human readable string representing the time interval.

  ## Examples

      iex> {1435, 180354, 590264} |> #{__MODULE__}.format
      "45 years, 6 months, 5 days, 21 hours, 12 minutes, 34 seconds, 590.264 milliseconds"
      iex> {0, 65, 0} |> #{__MODULE__}.format
      "1 minute, 5 seconds"

  """
  @spec format(Types.timestamp) :: String.t | {:error, term}
  def format({_,_,_} = timestamp), do: lformat(timestamp, Translator.default_locale)
  def format(_), do: {:error, :invalid_timestamp}

  @doc """
  Return a human readable string representing the time interval, translated to the given locale

  ## Examples
      iex> {1435, 180354, 590264} |> #{__MODULE__}.lformat("ru")
      "45 года  6 месяца  5 днем  21 час  12 минуты  34 секунды  590.264 миллисекунды"
      iex> {0, 65, 0} |> #{__MODULE__}.lformat("ru")
      "1 минута  5 секунды"

  """
  @spec lformat(Types.timestamp, String.t) :: String.t | {:error, term}
  def lformat({_,_,_} = timestamp, locale) do
    timestamp
    |> deconstruct
    |> do_format(locale)
  end
  def lformat(_, _locale), do: {:error, :invalid_timestamp}

  defp do_format(components, locale),
    do: do_format(components, <<>>, locale)
  defp do_format([], str, _locale),
    do: str
  defp do_format([{unit, value}|rest], str, locale) do
    unit = Atom.to_string(unit)
    unit_with_value = Translator.translate_plural(locale, "units", "%{count} #{unit}", "%{count} #{unit}s", value)
    separator = Translator.translate(locale, "symbols", ",")
    case str do
      <<>> -> do_format(rest, "#{unit_with_value}", locale)
      _    -> do_format(rest, str <> "#{separator} #{unit_with_value}", locale)
    end
  end

  defp deconstruct({_, _, micro} = ts), do: deconstruct({ts |> Time.to_seconds |> trunc, micro}, [])
  defp deconstruct({0, 0}, components), do: components |> Enum.reverse
  defp deconstruct({seconds, us}, components) when seconds > 0 do
    cond do
      seconds >= @year   -> deconstruct({rem(seconds, @year), us}, [{:year, div(seconds, @year)} | components])
      seconds >= @month  -> deconstruct({rem(seconds, @month), us}, [{:month, div(seconds, @month)} | components])
      seconds >= @week   -> deconstruct({rem(seconds, @week), us}, [{:week, div(seconds, @week)} | components])
      seconds >= @day    -> deconstruct({rem(seconds, @day), us}, [{:day, div(seconds, @day)} | components])
      seconds >= @hour   -> deconstruct({rem(seconds, @hour), us}, [{:hour, div(seconds, @hour)} | components])
      seconds >= @minute -> deconstruct({rem(seconds, @minute), us}, [{:minute, div(seconds, @minute)} | components])
      true -> deconstruct({0, us}, [{:second, seconds} | components])
    end
  end
  defp deconstruct({seconds, micro}, components) when seconds < 0, do: deconstruct({seconds * -1, micro}, components)
  defp deconstruct({0, micro}, components) do
    msecs = {0, 0, micro} |> Time.abs |> Time.to_milliseconds
    cond do
      msecs >= 1.0 -> deconstruct({0, 0}, [{:millisecond, msecs} | components])
      true         -> deconstruct({0, 0}, [{:microsecond, micro} | components])
    end
  end
end
