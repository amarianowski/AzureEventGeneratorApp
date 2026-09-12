namespace AzureEventGeneratorApp.Contracts;

public class TelemetryReading
{
    public required string StationId { get; init; }
    public required DateTimeOffset Timestamp { get; init; }
    public required double TemperatureCelsius { get; init; }
    public required double WindSpeedMps { get; init; }
    public required double BatteryVoltage { get; init; }
}