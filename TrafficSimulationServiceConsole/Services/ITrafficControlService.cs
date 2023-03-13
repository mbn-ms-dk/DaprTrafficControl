using TrafficSimulationServiceConsole.Events;

namespace TrafficSimulationServiceConsole.Services;
public interface ITrafficControlService {
    public Task SendVehicleEntryAsync(VehicleRegistered vehicleRegistered);
    public Task SendVehicleExitAsync(VehicleRegistered vehicleRegistered);
}
