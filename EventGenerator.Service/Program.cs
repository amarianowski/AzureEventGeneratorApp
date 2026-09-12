using EventGenerator.Service;

var builder = Host.CreateApplicationBuilder(args);
builder.Services.AddHostedService<Worker>();

builder.Services.AddHttpClient("EventProcessorApi", client =>
    client.BaseAddress = new Uri(builder.Configuration["EventProcessorApi:BaseUrl"]!));

var host = builder.Build();
host.Run();

