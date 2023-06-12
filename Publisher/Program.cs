using Common;
using StackExchange.Redis;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.AddRedisPubSub();

var app = builder.Build();

app.MapGet("/", () => "Publisher is up");

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapPost("/weatherforecast", async (WeatherForecast forecast, 
    ILogger<Program> logger, 
    ISubscriber pubsub) =>
{
    await pubsub.PublishAsync(nameof(WeatherForecast),
        JsonSerializer.Serialize(forecast), 
        CommandFlags.FireAndForget);
    return Results.Ok();
})
.WithOpenApi()
.WithName("ReceiveWeatherForecast");

app.Run();
