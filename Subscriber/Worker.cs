using Common;
using StackExchange.Redis;
using System.Text.Json;

namespace Subscriber
{
    public class Worker : IHostedService
    {
        private readonly ILogger<Worker> _logger;
        //private const string RedisConnectionString = "redis:6379";
        //private static ConnectionMultiplexer connection = ConnectionMultiplexer.Connect(RedisConnectionString);
        //private const string Channel = "test-channel";
        //private ISubscriber _subscriber;
        
        public Worker(ILogger<Worker> logger)
        {
            _logger = logger;

            //_logger.LogInformation("Listening test-channel");
            //_subscriber = connection.GetSubscriber();
        }

        public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("Worker starting");

            //_subscriber.Subscribe(Channel, (channel, message) =>
            //{
            //    var weatherForecast = JsonSerializer.Deserialize<WeatherForecast>(message);

            //    _logger.LogInformation($"""
            //        Message received from test-channel : 
            //        {weatherForecast.Summary} ({weatherForecast.TemperatureF}) at
            //        {weatherForecast.Date.ToString()}
            //        """);
            //});                

            return Task.CompletedTask;
        }
    }
}