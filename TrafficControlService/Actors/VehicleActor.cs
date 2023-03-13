using Dapr.Actors.Runtime;
using Dapr.Client;
using TrafficControlService.Events;
using TrafficControlService.Models;
using TrafficControlService.Services;

namespace TrafficControlService.Actors;
public class VehicleActor : Actor, IVehicleActor, IRemindable {
    private readonly ISpeedingViolationCalculator speedingViolationCalculator;
    private readonly string roadId;
    private readonly DaprClient client;

    public VehicleActor(ActorHost host, ISpeedingViolationCalculator speedingViolationCalculator, DaprClient client) : base(host) {
        this.speedingViolationCalculator = speedingViolationCalculator;
        this.roadId = speedingViolationCalculator.GetRoadId();
        this.client = client;
    }

    public async Task RegisterEntryAsync(VehicleRegistered msg) {
        try {
            //log entry
            Logger.LogInformation($"Entry detected in lane {msg.Lane} at " +
                $"{msg.Timestamp.ToString("hh:mm:ss")} of vehicle with licensenumber {msg.LicenseNumber}");

            //Store vehicle state
            var vehicleState = new VehicleState(msg.LicenseNumber, msg.Timestamp);
            await this.StateManager.SetStateAsync<VehicleState>("VehicleState", vehicleState);

            //register a reminder for cars that enter but doesn't exit within 20 seconds
            //They might have broken down and need assistance
            await RegisterReminderAsync("VehicleLost", null, TimeSpan.FromSeconds(20), TimeSpan.FromSeconds(20));
        }
        catch (Exception ex) {
            Logger.LogError(ex, "Error in RegisterEntry");
        }
    }

    public async Task RegisterExitAsync(VehicleRegistered msg) {
        try {
            Logger.LogInformation($"Exit detected in lane {msg.Lane} at " +
                $"{msg.Timestamp.ToString("hh:mm:ss")} " +
                $"of vehicle with licensenumber {msg.LicenseNumber}.");

            // remove lost vehicle timer
            await UnregisterReminderAsync("VehicleLost");

            // get vehicle state
            var vehicleState = await this.StateManager.GetStateAsync<VehicleState>("VehicleState");
            vehicleState = vehicleState with { ExitTimeStamp = msg.Timestamp };
            await this.StateManager.SetStateAsync("VehicleState", vehicleState);

            // handle possible speeding violation
            int violation = speedingViolationCalculator.DetermineSpeedingViolationInKmh(
                vehicleState.EntryTimeStamp, vehicleState.ExitTimeStamp.Value);
            if (violation > 0) {
                Logger.LogInformation($"Speeding violation detected ({violation} KMh) of vehicle " +
                    $"with licensenumber {vehicleState.LicenseNumber}.");

                var speedingViolation = new SpeedingViolation {
                    VehicleId = msg.LicenseNumber,
                    RoadId = roadId,
                    ViolationInKmh = violation,
                    Timestamp = msg.Timestamp
                };

                // publish speedingviolation (Dapr publish / subscribe)
                await client.PublishEventAsync("pubsub", "speedingviolations", speedingViolation);
            }
        }
        catch (Exception ex) {
            Logger.LogError(ex, "Error in RegisterExit");
        }
    }

    async Task IRemindable.ReceiveReminderAsync(string reminderName, byte[] state, TimeSpan dueTime, TimeSpan period) {
        if (reminderName == "VehicleLost") {
            // remove lost vehicle timer
            await UnregisterReminderAsync("VehicleLost");

            var vehicleState = await this.StateManager.GetStateAsync<VehicleState>("VehicleState");

            Logger.LogInformation($"Lost track of vehicle with license-number {vehicleState.LicenseNumber}. " +
                "Sending road-assistence.");

            // send road assistence ...
        }
    }
}