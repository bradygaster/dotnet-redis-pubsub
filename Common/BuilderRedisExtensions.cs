using StackExchange.Redis;

namespace Microsoft.AspNetCore.Builder;

public static class BuilderRedisExtensions
{
    public static WebApplicationBuilder AddRedisPubSub(this WebApplicationBuilder builder)
    {
        builder.Services.AddRedisPubSub(builder.Configuration);
        return builder;
    }
    
    public static HostApplicationBuilder AddRedisPubSub(this HostApplicationBuilder builder)
    {
        builder.Services.AddRedisPubSub(builder.Configuration);
        return builder;
    }

    public static IServiceCollection AddRedisPubSub(this IServiceCollection services, IConfiguration configuration)
    {
        if (GetRedisConnectionString(configuration) is string redisConnectionString)
        {
            var connection = ConnectionMultiplexer.Connect(redisConnectionString);
            var pubsub = connection.GetSubscriber();
            services.AddSingleton(pubsub);
        }
        else throw new ArgumentException("The app hasn't been configured for Redis yet.");

        return services;
    }

    private static string? GetRedisConnectionString(IConfiguration configuration)
    {
        var azureContainerAppsScenario = new AzureContainerAppsServiceConnectorScenario();
        var localhostScenario = new LocalhostAppSettingsScenario();
        azureContainerAppsScenario.SetNext(localhostScenario);
        return azureContainerAppsScenario.BuildRedisConnectionString(configuration);
    }
}
