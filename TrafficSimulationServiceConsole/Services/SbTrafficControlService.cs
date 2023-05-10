using TrafficSimulationServiceConsole.Events;
using Azure.Messaging.ServiceBus;
using System.Text.Json;

namespace TrafficSimulationServiceConsole.Services;

public class SbTrafficControlService : ITrafficControlService
{
    private ServiceBusClient client;

    public SbTrafficControlService(ServiceBusClient client)
    {
        this.client = client;
    }

    public static SbTrafficControlService Create() {
         var client = new ServiceBusClient(Environment.GetEnvironmentVariable("SB_CONN_STRING"));
        return new SbTrafficControlService(client);
     }
    public async Task SendVehicleEntryAsync(VehicleRegistered vehicleRegistered)
    {
        var evt = JsonSerializer.Serialize(vehicleRegistered);
        var sender = client.CreateSender("trafficcontrol/entrycam");
        await sender.SendMessageAsync(new ServiceBusMessage(evt));
    }

    public async Task SendVehicleExitAsync(VehicleRegistered vehicleRegistered)
    {
        var evt = JsonSerializer.Serialize(vehicleRegistered);
        var sender = client.CreateSender("trafficcontrol/exitcam");
        await sender.SendMessageAsync(new ServiceBusMessage(evt));
    }
}