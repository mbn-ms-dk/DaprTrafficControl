using VehicleRegistrationService.Repositories;
using Microsoft.ApplicationInsights.Extensibility;
using VehicleRegistrationService;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddScoped<IVehicleInfoRepository, InMemoryVehicleInfoRepository>();

builder.Services.AddDaprClient(builder => builder.Build());

builder.Services.AddApplicationInsightsTelemetry();
builder.Services.Configure<TelemetryConfiguration>((o) => {
    o.TelemetryInitializers.Add(new AppInsightsTelemetryInitializer());
});

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseCloudEvents();

app.MapGet("vehicleinfo", (string licenseNumber, IVehicleInfoRepository repo) => {
    Console.WriteLine($"Retrieving vehicle-info for licensenumber {licenseNumber}");
    var info = repo.GetVehicleInfo(licenseNumber);
    return Results.Ok(info);
});

app.Run(); 


