using AzureEventGeneratorApp.Contracts;

namespace EventGenerator.Service;

public class Worker(ILogger<Worker> logger, IHttpClientFactory httpClientFactory) : BackgroundService
{
    private static readonly string[] StationIds = ["MCM", "ASP", "VOK", "ESP", "ROT", "CON"];

    private static string GenerateStationId() => StationIds[Random.Shared.Next(StationIds.Length)];

    private static double GenerateTemperatureCelsius()
    {
        var minTemperature = -90.0;
        var maxTemperature = 15.0;
        var random = new Random();
        return Math.Round(random.NextDouble() * (maxTemperature - minTemperature) + minTemperature, 2);
    }

    private static double GenerateWindSpeedMps()
    {
        var minWindSpeed = 0.0;
        var maxWindSpeed = 100.0;
        var random = new Random();
        return Math.Round(random.NextDouble() * (maxWindSpeed - minWindSpeed) + minWindSpeed, 2);
    }

    private static double GenerateBatteryVoltage()
    {
        var minVoltage = 3.0;
        var maxVoltage = 4.2;
        var random = new Random();
        return Math.Round(random.NextDouble() * (maxVoltage - minVoltage) + minVoltage, 2);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var telemetryEvent = new TelemetryReading{
                StationId = GenerateStationId(),
                Timestamp = DateTimeOffset.UtcNow,
                TemperatureCelsius = GenerateTemperatureCelsius(),
                WindSpeedMps = GenerateWindSpeedMps(),
                BatteryVoltage = GenerateBatteryVoltage()   
            };  

            logger.LogInformation($"Generated telemetry event: {telemetryEvent.StationId}, {telemetryEvent.Timestamp}, {telemetryEvent.TemperatureCelsius}°C, {telemetryEvent.WindSpeedMps} m/s, {telemetryEvent.BatteryVoltage} V");
            await Task.Delay(TimeSpan.FromSeconds(3), stoppingToken);
        }
    }
}
