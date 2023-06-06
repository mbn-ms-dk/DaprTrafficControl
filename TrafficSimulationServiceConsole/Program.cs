using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using TrafficSimulationServiceConsole;
using TrafficSimulationServiceConsole.Services;


var services = new ServiceCollection();
// Being a regular console app, there is no appsettings.json or configuration providers enabled by default.
services.AddLogging(loggingBuilder => 
    loggingBuilder.AddFilter<Microsoft.Extensions.Logging.ApplicationInsights.ApplicationInsightsLoggerProvider>("Category", LogLevel.Information));


// Build ServiceProvider.
IServiceProvider serviceProvider = services.BuildServiceProvider();

// Obtain logger instance from DI.
ILogger<Program> logger = serviceProvider.GetRequiredService<ILogger<Program>>();


services.AddApplicationInsightsTelemetry();
services.Configure<TelemetryConfiguration>((o) => {
    o.TelemetryInitializers.Add(new AppInsightsTelemetryInitializer());
});

// Enable application insights for Kubernetes (LogLevel.Error is the default; Setting it to LogLevel.Trace to see detailed logs.)
// services.AddApplicationInsightsKubernetesEnricher(diagnosticLogLevel: LogLevel.Error);


logger.LogInformation("Setting number of lanes");
int lanes = 3;
CameraSimulation[] cameras = new CameraSimulation[lanes];
for (var i = 0; i < lanes; i++)
{
    var camNumber = i + 1;
    ITrafficControlService trafficControlService = await MqttTrafficControlService.CreateAsync(camNumber);
    cameras[i] = new CameraSimulation(camNumber, trafficControlService, logger);
}
Parallel.ForEach(cameras, cam => cam.start());

Task.Run(() => Thread.Sleep(Timeout.Infinite)).Wait();

// Explicitly call Flush() followed by sleep is required in console apps.
// This is to ensure that even if application terminates, telemetry is sent to the back-end.
Task.Delay(5000).Wait();