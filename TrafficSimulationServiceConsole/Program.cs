using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.ApplicationInsights.WorkerService;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Net.Http;
using System.Threading.Tasks;
using TrafficSimulationServiceConsole;
using TrafficSimulationServiceConsole.Services;


var services = new ServiceCollection();
// Being a regular console app, there is no appsettings.json or configuration providers enabled by default.
// Hence instrumentation key/ connection string and any changes to default logging level must be specified here.
services.AddLogging(loggingBuilder => 
    loggingBuilder.AddFilter<Microsoft.Extensions.Logging.ApplicationInsights.ApplicationInsightsLoggerProvider>("Category", LogLevel.Information));
services.AddApplicationInsightsTelemetryWorkerService((ApplicationInsightsServiceOptions options) => 
    options.ConnectionString = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING"));

// Build ServiceProvider.
IServiceProvider serviceProvider = services.BuildServiceProvider();

// Obtain logger instance from DI.
ILogger<Program> logger = serviceProvider.GetRequiredService<ILogger<Program>>();

// Add custom TelemetryInitializer
services.AddSingleton<ITelemetryInitializer, DtcTelemetryInitializer>();

// Obtain TelemetryClient instance from DI, for additional manual tracking or to flush.
var telemetryClient = serviceProvider.GetRequiredService<TelemetryClient>();
// Enable application insights for Kubernetes (LogLevel.Error is the default; Setting it to LogLevel.Trace to see detailed logs.)
services.AddApplicationInsightsKubernetesEnricher(diagnosticLogLevel: LogLevel.Error);
telemetryClient.TrackTrace("Starting simulation");
logger.LogWarning("Setting number of lanes");
int lanes = 3;
CameraSimulation[] cameras = new CameraSimulation[lanes];
for (var i = 0; i < lanes; i++)
{
    var camNumber = i + 1;
    ITrafficControlService trafficControlService = Environment.GetEnvironmentVariable("SB_CONN_STRING") == "none"  ?
        await MqttTrafficControlService.CreateAsync(camNumber) :
        SbTrafficControlService.Create();
    cameras[i] = new CameraSimulation(camNumber, trafficControlService, logger);
}
Parallel.ForEach(cameras, cam => cam.start());

Task.Run(() => Thread.Sleep(Timeout.Infinite)).Wait();

// Explicitly call Flush() followed by sleep is required in console apps.
// This is to ensure that even if application terminates, telemetry is sent to the back-end.
telemetryClient.Flush();
Task.Delay(5000).Wait();