using AzureEventGeneratorApp.Contracts;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddOpenApi();

var app = builder.Build();
if (app.Environment.IsDevelopment()) app.MapOpenApi();
app.UseHttpsRedirection();

app.MapPost("/telemetry", (TelemetryReading reading) =>
{
    return Results.Accepted("Received telemetry reading");
})
.WithName("Push arctic telemetry readings");

app.Run();

