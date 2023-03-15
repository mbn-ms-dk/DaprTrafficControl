using VehicleRegistrationService.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddScoped<IVehicleInfoRepository, InMemoryVehicleInfoRepository>();

// var daprHttpPort = Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3602";
// var daprGrpcPort = Environment.GetEnvironmentVariable("DAPR_GRPC_PORT") ?? "60002";
// builder.Services.AddDaprClient(builder => builder
//     .UseHttpEndpoint($"http://localhost:{daprHttpPort}")
//     .UseGrpcEndpoint($"http://localhost:{daprGrpcPort}"));

builder.Services.AddDaprClient(builder => builder.Build());

builder.Services.AddApplicationInsightsTelemetry(options => {
     options.ConnectionString = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING");
});
// Enable application insights for Kubernetes (LogLevel.Error is the default; Setting it to LogLevel.Trace to see detailed logs.)
builder.Services.AddApplicationInsightsKubernetesEnricher(diagnosticLogLevel: LogLevel.Error);

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseCloudEvents();

app.MapGet("vehicleinfo", (string licenseNumber, IVehicleInfoRepository repo) => {
    Console.WriteLine($"Retrieving vehicle-info for licensenumber {licenseNumber}");
    var info = repo.GetVehicleInfo(licenseNumber);
    return Results.Ok(info);
});

app.Run("http://localhost:6002");


