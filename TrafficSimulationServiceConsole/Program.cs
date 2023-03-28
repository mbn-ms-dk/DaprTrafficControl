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
// if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING")))
//     services.Configure<TelemetryConfiguration>(c => c.ConnectionString = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING"));

//     services.AddLogging(builder =>
//     {
//         builder.AddApplicationInsights();
//     });
// Being a regular console app, there is no appsettings.json or configuration providers enabled by default.
// Hence instrumentation key/ connection string and any changes to default logging level must be specified here.
services.AddLogging(loggingBuilder => loggingBuilder.AddFilter<Microsoft.Extensions.Logging.ApplicationInsights.ApplicationInsightsLoggerProvider>("Category", LogLevel.Information));
services.AddApplicationInsightsTelemetryWorkerService((ApplicationInsightsServiceOptions options) => options.ConnectionString = "InstrumentationKey=9fe13a4d-fc47-4535-b030-55bbcfba805a;IngestionEndpoint=https://northeurope-2.in.applicationinsights.azure.com/;LiveEndpoint=https://northeurope.livediagnostics.monitor.azure.com/");
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


int lanes = 3;
CameraSimulation[] cameras = new CameraSimulation[lanes];
for (var i = 0; i < lanes; i++)
{
    var camNumber = i + 1;
    var trafficControlService = await MqttTrafficControlService.CreateAsync(camNumber);
    cameras[i] = new CameraSimulation(camNumber, trafficControlService, logger);
}
Parallel.ForEach(cameras, cam => cam.start());

Task.Run(() => Thread.Sleep(Timeout.Infinite)).Wait();
