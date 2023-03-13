using TrafficSimulationServiceConsole;
using TrafficSimulationServiceConsole.Services;

int lanes = 3;
CameraSimulation[] cameras = new CameraSimulation[lanes];

for (var i=0; i < lanes; i++) {
    var camNumber = i + 1;
    var trafficControlService = await MqttTrafficControlService.CreateAsync(camNumber);
    cameras[i] = new CameraSimulation(camNumber, trafficControlService);
}
Parallel.ForEach(cameras, cam => cam.start());

Task.Run(() => Thread.Sleep(Timeout.Infinite)).Wait();
