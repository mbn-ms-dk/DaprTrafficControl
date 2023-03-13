using MQTTnet;
using MQTTnet.Client;
using System.Text;
using System.Text.Json;
using TrafficSimulationServiceConsole.Events;

namespace TrafficSimulationServiceConsole.Services;
public  class MqttTrafficControlService : ITrafficControlService {
    private IMqttClient client;

    public MqttTrafficControlService(IMqttClient client) {
        this.client = client;
    }

    public static async Task<MqttTrafficControlService> CreateAsync(int cameraNumber) {
        var mqttHost = Environment.GetEnvironmentVariable("MQTT_HOST") ?? "localhost";
        var factory = new MqttFactory();
        var mqttClient = factory.CreateMqttClient();
        var options = new MqttClientOptionsBuilder()
            .WithTcpServer(mqttHost, 1883)
            .WithClientId($"camerasimulation{cameraNumber}")
            .Build();
        await mqttClient.ConnectAsync(options, CancellationToken.None);
        return new MqttTrafficControlService(mqttClient);
    }
    public async Task SendVehicleEntryAsync(VehicleRegistered vehicleRegistered) {
        var evt = JsonSerializer.Serialize(vehicleRegistered);
        var msg = new MqttApplicationMessageBuilder()
            .WithTopic("trafficcontrol/entrycam")
            .WithPayload(Encoding.UTF8.GetBytes(evt))
            .Build();
        await client.PublishAsync(msg, CancellationToken.None);
    }

    public async Task SendVehicleExitAsync(VehicleRegistered vehicleRegistered) {
        var evt = JsonSerializer.Serialize(vehicleRegistered);
        var msg = new MqttApplicationMessageBuilder()
            .WithTopic("trafficcontrol/exitcam")
            .WithPayload(Encoding.UTF8.GetBytes(evt))
            .Build();
        await client.PublishAsync(msg, CancellationToken.None);
    }
}
