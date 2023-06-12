using Common;
using System.Text.Json;

var builder = Host.CreateApplicationBuilder(args);
builder.AddRedisPubSub();

var host = builder.Build();

var _logger = host.Services.GetRequiredService<ILogger<Program>>();

host.MapRedisSubscription(nameof(WeatherForecast), async (channel, message) =>
{
    var weatherForecast = JsonSerializer.Deserialize<WeatherForecast>(message);
    _logger.LogInformation($"Message received from test-channel : {weatherForecast.Summary} " +
        $"({weatherForecast.TemperatureF}) " +
        $"at {weatherForecast.Date.ToString()}");
});

host.Run();
