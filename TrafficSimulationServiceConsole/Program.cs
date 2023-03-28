using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using TrafficSimulationServiceConsole;
using TrafficSimulationServiceConsole.Services;


var services = new ServiceCollection();
if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING")))
    services.Configure<TelemetryConfiguration>(c => c.ConnectionString = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING"));

    services.AddLogging(builder =>
    {
        builder.AddApplicationInsights();
    });

// Enable application insights for Kubernetes (LogLevel.Error is the default; Setting it to LogLevel.Trace to see detailed logs.)
services.AddApplicationInsightsKubernetesEnricher(diagnosticLogLevel: LogLevel.Error);
var provider = services.BuildServiceProvider();
ILogger<Program> logger = provider.GetRequiredService<ILogger<Program>>();

int lanes = 3;
CameraSimulation[] cameras = new CameraSimulation[lanes];
Console.WriteLine(string.IsNullOrEmpty(Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING"))? "No Conn string": Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING"));
logger.LogInformation(string.IsNullOrEmpty(Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING"))? "No Conn string": Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING"));
for (var i = 0; i < lanes; i++)
{
    var camNumber = i + 1;
    var trafficControlService = await MqttTrafficControlService.CreateAsync(camNumber);
    cameras[i] = new CameraSimulation(camNumber, trafficControlService, logger);
}
Parallel.ForEach(cameras, cam => cam.start());

Task.Run(() => Thread.Sleep(Timeout.Infinite)).Wait();
