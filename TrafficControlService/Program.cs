using Dapr.Actors;
using Dapr.Actors.Client;
using Dapr.Client;
using TrafficControlService.Actors;
using TrafficControlService.Events;
using TrafficControlService.Models;
using TrafficControlService.Repositories;
using TrafficControlService.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddSingleton<ISpeedingViolationCalculator>(
    new DefaultSpeedingViolationCalculator("A12", 10, 100, 5));

builder.Services.AddSingleton<IVehicleStateRepository, DaprVehicleStateRepository>();

builder.Services.AddActors(options => {
    options.Actors.RegisterActor<VehicleActor>();
});

var daprHttpPort = Environment.GetEnvironmentVariable("DAPR_HTTP_PORT") ?? "3600";
var daprGrpcPort = Environment.GetEnvironmentVariable("DAPR_GRPC_PORT") ?? "60002";
builder.Services.AddDaprClient(builder => builder
    .UseHttpEndpoint($"http://localhost:{daprHttpPort}")
    .UseGrpcEndpoint($"http://localhost:{daprGrpcPort}"));
var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseCloudEvents();
app.MapActorsHandlers();


app.MapGet("/", () => "Hi from Api");

var useActors = Environment.GetEnvironmentVariable("USE_ACTORS") ?? "false";
Console.WriteLine($"Actor: {useActors}");
if (useActors.ToLower().Equals("false")) {
    app.MapPost("entrycam", async (VehicleRegistered msg, IVehicleStateRepository repo) => {
        try {
            //log entry
            Console.WriteLine($"ENTRY detected in lane {msg.Lane} at {msg.Timestamp.ToString("hh:mm:ss")} " +
                $"of vehicle with licenseplate {msg.LicenseNumber}");
            //store vehicle state
            var vehicleState = new VehicleState(msg.LicenseNumber, msg.Timestamp, null);
            await repo.SaveVehicleStateAsync(vehicleState);
            return Results.Ok();
        }
        catch (Exception ex) {
            Console.WriteLine($"ENTRY: {ex}");
            return Results.Problem(ex.Message, ex.StackTrace, 500);
        }
    });

    app.MapPost("exitcam", async (VehicleRegistered msg, IVehicleStateRepository repo, ISpeedingViolationCalculator calc, DaprClient client) => {
        try {
            var state = await repo.GetVehicleStateAsync(msg.LicenseNumber);
            if (state == default(VehicleState))
                return Results.NotFound(msg.LicenseNumber);

            //log exit
            Console.WriteLine($"EXIT detected in lane {msg.Lane} at {msg.Timestamp.ToString("hh:mm:ss")} " +
                $"of vehicle with licenseplate {msg.LicenseNumber}");

            //update vehicle state
            var exitState = state.Value with { ExitTimeStamp = msg.Timestamp };
            await repo.SaveVehicleStateAsync(exitState);

            // handle possible speeding violation
            int violation = calc.DetermineSpeedingViolationInKmh(exitState.EntryTimeStamp, exitState.ExitTimeStamp.Value);
            if (violation > 0) {
                Console.WriteLine($"Speeding violation detected ({violation} KMh) of vehicle" +
                    $"with license-number {state.Value.LicenseNumber}.");

                var speedingViolation = new SpeedingViolation {
                    VehicleId = msg.LicenseNumber,
                    RoadId = calc.GetRoadId(),
                    ViolationInKmh = violation,
                    Timestamp = msg.Timestamp
                };

                // publish speedingviolation (Dapr publish / subscribe)
                await client.PublishEventAsync("pubsub", "speedingviolations", speedingViolation);
            }

            return Results.Ok();
        }
        catch (Exception ex) {
            Console.WriteLine($"EXIT: {ex}");
            return Results.Problem(ex.Message, ex.StackTrace, 500);
        }
    });
}
else {
    app.MapPost("entrycam", async (VehicleRegistered msg) => {
        try {
            var actorId = new ActorId(msg.LicenseNumber);
            var proxy = ActorProxy.Create<IVehicleActor>(actorId, nameof(VehicleActor));
            await proxy.RegisterEntryAsync(msg);
            return Results.Ok();
        }
        catch (Exception ex) {
            Console.WriteLine(ex);
            return Results.Problem(ex.Message, ex.StackTrace, 500);
        }
    });

    app.MapPost("exitcam", async (VehicleRegistered msg) => {
        try {
            var actorId = new ActorId(msg.LicenseNumber);
            var proxy = ActorProxy.Create<IVehicleActor>(actorId, nameof(VehicleActor));
            await proxy.RegisterExitAsync(msg);
            return Results.Ok();
        }
        catch (Exception ex) {
            Console.WriteLine(ex);
            return Results.Problem(ex.Message, ex.StackTrace, 500);
        }
    });
}

app.Run();
