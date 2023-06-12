using StackExchange.Redis;

namespace Microsoft.Extensions.Hosting;

public static class RedisSubscriptionHostExtensions
{
    public static IHost MapRedisSubscription(this IHost host, 
        string channel, 
        Action<RedisChannel, RedisValue> action)
    {
        host.Services.GetRequiredService<ISubscriber>()
            .Subscribe(channel, action);

        return host;
    }
}
