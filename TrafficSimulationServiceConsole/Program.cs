using Microsoft.ApplicationInsights.Extensibility;
using Azure.Monitor.OpenTelemetry.Exporter;
using OpenTelemetry;
using OpenTelemetry.Trace;
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
services.AddSingleton<ITelemetryInitializer, DtcTelemetryInitializer>();
// Enable application insights for Kubernetes (LogLevel.Error is the default; Setting it to LogLevel.Trace to see detailed logs.)
services.AddApplicationInsightsKubernetesEnricher(diagnosticLogLevel: LogLevel.Error);

using var tracer = Sdk.CreateTracerProviderBuilder()
    .AddSource("simulation")
    .AddAzureMonitorTraceExporter(cfg => 
    {
        cfg.ConnectionString = "InstrumentationKey=9fe13a4d-fc47-4535-b030-55bbcfba805a;IngestionEndpoint=https://northeurope-2.in.applicationinsights.azure.com/;LiveEndpoint=https://northeurope.livediagnostics.monitor.azure.com/"; //Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING");
    })
    .Build();

var provider = services.BuildServiceProvider();
ILogger<Program> logger = provider.GetRequiredService<ILogger<Program>>();

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
