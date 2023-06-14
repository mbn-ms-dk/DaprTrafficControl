using Dapr.Client;
using FineCollectionService.Models;
using FineCollectionService.Proxies;
using FineCollectionService.Services;
using FineCollectionService.Utils;
using Microsoft.ApplicationInsights.Extensibility;
using FineCollectionService;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddSingleton<IFineCalculator, HardCodedFineCalculator>();

builder.Services.AddDaprClient(builder => builder.Build());

builder.Services.AddSingleton<VehicleRegistrationService>(_ =>
    new VehicleRegistrationService(DaprClient.CreateInvokeHttpClient(
        "vehicleregistrationservice"))); 

builder.Services.AddApplicationInsightsTelemetry();
builder.Services.Configure<TelemetryConfiguration>((o) => {
    o.TelemetryInitializers.Add(new AppInsightsTelemetryInitializer());
});

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseCloudEvents();



// `.WithTopic(...)` tells Dapr to subscribe to the given topic, and call this
// when a value is published.  This still works when posting directly to the
// endpoint!
app.MapPost("collectfine", async (SpeedingViolation speedingViolation, IFineCalculator calc, VehicleRegistrationService registration, DaprClient client) => {
    Console.WriteLine($"REC {speedingViolation.VehicleId}");
    decimal fine = calc.CalculateFine(speedingViolation.ViolationInKmh);
    //get owner information (Dapr service invocation)
    var vehicleInfo = await registration.GetVehicleInfoAsync(speedingViolation.VehicleId);
    //log fine
    var fineString = fine == 0 ? "tbd by the prosecutor" : $"{fine} Euro";
    Console.WriteLine($"Sent speeding ticket to {vehicleInfo.OwnerName}. " +
            $"Road: {speedingViolation.RoadId}, Licensenumber: {speedingViolation.VehicleId}, " +
            $"Vehicle: {vehicleInfo.Brand} {vehicleInfo.Model}, " +
            $"Violation: {speedingViolation.ViolationInKmh} Km/h, Fine: {fineString}, " +
            $"On: {speedingViolation.Timestamp.ToString("dd-MM-yyyy")} " +
            $"at {speedingViolation.Timestamp.ToString("hh:mm:ss")}.");

    // send fine by email (Dapr output binding)
    var body = EmailUtils.CreateEmailBody(speedingViolation, vehicleInfo, fineString);
    var metadata = new Dictionary<string, string> {
        ["emailFrom"] = "noreply@bigbrother.gov",
        ["emailTo"] = vehicleInfo.OwnerEmail,
        ["subject"] = $"Speeding violation on the {speedingViolation.RoadId}"
    };
    await client.InvokeBindingAsync("sendmail", "create", body, metadata);

    return Results.Ok();
}).WithTopic("pubsub", "speedingviolations");


app.Run(); //"http://localhost:6001");

