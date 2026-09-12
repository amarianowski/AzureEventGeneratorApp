using AzureEventGeneratorApp.Contracts;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Services.AddApplicationInsightsTelemetry(builder.Configuration);

var app = builder.Build();

if (app.Environment.IsDevelopment()) app.MapOpenApi();

app.UseHttpsRedirection();

app.MapPost("/telemetry", (TelemetryReading reading) =>
{
    app.Logger.LogInformation(
        "Received telemetry reading from station {StationId} at {Timestamp}: Temperature={TemperatureCelsius}, WindSpeed={WindSpeedMps}, BatteryVoltage={BatteryVoltage}",
        reading.StationId,
        reading.Timestamp,
        reading.TemperatureCelsius,
        reading.WindSpeedMps,
        reading.BatteryVoltage
    );
    return Results.Accepted("Received telemetry reading");
})
.WithName("Push arctic telemetry readings");

app.Run();

