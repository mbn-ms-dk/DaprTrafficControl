using Dapr.Client;
using TrafficControlService.Models;

namespace TrafficControlService.Repositories {
    public class DaprVehicleStateRepository : IVehicleStateRepository {
        private const string DAPR_STORE_NAME = "statestore";
        private readonly DaprClient client;

        public DaprVehicleStateRepository(DaprClient daprClient) {
            this.client = daprClient;
        }
        public async Task<VehicleState?> GetVehicleStateAsync(string licensePlate) {
            var stateEntry = await client.GetStateEntryAsync<VehicleState>(
                DAPR_STORE_NAME, licensePlate);
            return stateEntry == null ? null : stateEntry.Value;
        }

        public async Task SaveVehicleStateAsync(VehicleState vehicleState) {
            await client.SaveStateAsync<VehicleState>(
                DAPR_STORE_NAME, vehicleState.LicensePlate, vehicleState);
        }
    }
}
