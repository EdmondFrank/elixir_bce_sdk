defmodule ElixirBceSdk.Bcm.Client do
  alias ElixirBceSdk.Client
  alias ElixirBceSdk.Client.Response
  import ElixirBceSdk.Config, only: [bcm_user_id: 0, bcm_endpoint: 0]
  @moduledoc """
  Baidu Cloud Monitor related operations
  """

  @prefix "json-api"
  @version "v1"

  @doc """
  Return metric data of product instances owned by the authenticated user.

  This site may help you: https://cloud.baidu.com/doc/BCM/s/9jwvym3kb

  :param scope:
    Cloud product namespace, eg: BCE_BCC.
  :type scope: string

  :param metric_name:
    The metric name of baidu cloud monitor, eg: CpuIdlePercent.
  :type metric_name: string

  :param dimensions:
    Consists of dimensionName: dimensionValue.
    Use semicolons when items have multiple dimensions,
    such as dimensionName: dimensionValue; dimensionName: dimensionValue.
    Only one dimension value can be specified for the same dimension.
    eg: InstanceId:fakeid-2222
  :type dimensions: string

  :param statistics:
    According to the format of statistics1,statistics2,statistics3,
    the optional values are `average`, `maximum`, `minimum`, `sum`, `sampleCount`
  :type statistics: string

  :param start_time:
    Query start time.
    Please refer to the date and time, UTC date indication
  :type start_time: string

  :param end_time:
    Query end time.
    Please refer to the date and time, UTC date indication

  :type end_time: string

  :param period_in_second:
    Statistical period.
    Multiples of 60 in seconds (s).
  :type period_in_second: int
  """
  @spec get_metric_data(String.t(), String.t(), String.t(), String.t(), String.t(), String.t(), integer()) :: {:error, Response.t()} | {:ok, Response.t()}
  def get_metric_data(scope, metric_name, dimensions, statistics \\ "average", start_time \\ nil, end_time \\ nil, period_in_second \\ nil) do
    timenow = :os.system_time(:second) |> DateTime.from_unix!
    request(
      "GET",
      "/#{@prefix}/#{@version}/metricdata/#{bcm_user_id()}/#{scope}/#{metric_name}",
      "",
      params: %{
        "dimensions" => dimensions,
        "statistics[]" => statistics,
        "startTime" => start_time || timenow |> DateTime.add(-15 * 60, :second) |> DateTime.to_iso8601,
        "endTime" => end_time || DateTime.to_iso8601(timenow),
        "periodInSecond" => period_in_second || 60
      }
    )
  end

  defp request(verb, path, body, opts) do
    Client.request(
      %{
        http_method: verb,
        host: bcm_endpoint(),
        body: body,
        path: path,
        resource: nil,
        params: Keyword.get(opts, :params, %{}),
        headers: Keyword.get(opts, :headers, %{}),
        save_path: Keyword.get(opts, :save_path, nil),
        return_body: Keyword.get(opts, :return_body, false),
      }
    )
  end
end
