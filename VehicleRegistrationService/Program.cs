using VehicleRegistrationService.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddScoped<IVehicleInfoRepository, InMemoryVehicleInfoRepository>();

var daprHttpPort = Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3602";
var daprGrpcPort = Environment.GetEnvironmentVariable("DAPR_GRPC_PORT") ?? "60002";
builder.Services.AddDaprClient(builder => builder
    .UseHttpEndpoint($"http://localhost:{daprHttpPort}")
    .UseGrpcEndpoint($"http://localhost:{daprGrpcPort}"));
var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseCloudEvents();

app.MapGet("licenseNumber", (string licenseNumber, IVehicleInfoRepository repo) => {
    Console.WriteLine($"Retrieving vehicle-info for licensenumber {licenseNumber}");
    var info = repo.GetVehicleInfo(licenseNumber);
    return Results.Ok(info);
});

app.Run();


