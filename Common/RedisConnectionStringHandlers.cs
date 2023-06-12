namespace Microsoft.AspNetCore.Builder;

public interface IRedisScenarioHandler
{
    IRedisScenarioHandler SetNext(IRedisScenarioHandler nextHandler);
    string? BuildRedisConnectionString(IConfiguration configuration);
}

public abstract class RedisScenarioHandler : IRedisScenarioHandler
{
    private IRedisScenarioHandler? _nextHandler;

    public virtual IRedisScenarioHandler SetNext(IRedisScenarioHandler nextHandler)
    {
        _nextHandler = nextHandler;
        return nextHandler;
    }

    public virtual string? BuildRedisConnectionString(IConfiguration configuration)
        => _nextHandler?.BuildRedisConnectionString(configuration);
}

public class AzureContainerAppsServiceConnectorScenario : RedisScenarioHandler
{
    public override string? BuildRedisConnectionString(IConfiguration configuration)
    {
        // this presumes we're using Azure Container Apps new Redis dev service
        if (configuration["REDIS_HOST"] is string redisHost)
        {
            string
                name = string.Empty,
                key = string.Empty,
                ssl = string.Empty;

            name = $"{redisHost}:{configuration["REDIS_PORT"]}";
            key = configuration["REDIS_PASSWORD"];
            ssl = "false";
            return $"{name},abortConnect=false,ssl={ssl},allowAdmin=true,password={key}";
        }

        return base.BuildRedisConnectionString(configuration);
    }
}

public class LocalhostAppSettingsScenario : RedisScenarioHandler
{
    public override string? BuildRedisConnectionString(IConfiguration configuration)
    {
        if (configuration["REDIS_CONNECTION_STRING"] is string redisConnectionString && !string.IsNullOrWhiteSpace(redisConnectionString))
            return redisConnectionString;

        return base.BuildRedisConnectionString(configuration);
    }
}