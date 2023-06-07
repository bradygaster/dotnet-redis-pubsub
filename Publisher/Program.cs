using Common;
using StackExchange.Redis;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

string RedisConnectionString = "redis:6379";
ConnectionMultiplexer connection = ConnectionMultiplexer.Connect(RedisConnectionString);
string Channel = "test-channel";

app.MapGet("/weatherforecast", () =>
{
    var forecast = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateTime.UtcNow,
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast")
.WithOpenApi();


app.MapPost("/weatherforecast", (WeatherForecast forecast, ILogger<Program> logger) =>
{
    logger.LogInformation("Sending message to test-channel");
    var pubsub = connection.GetSubscriber();
    pubsub.PublishAsync(Channel, JsonSerializer.Serialize(forecast), CommandFlags.FireAndForget);
    logger.LogInformation("Message Successfully sent to test-channel");

    return Results.Created();
})
.WithName("ReceiveWeatherForecast")
.WithOpenApi();

app.Run();
