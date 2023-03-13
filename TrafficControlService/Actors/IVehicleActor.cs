﻿using Dapr.Actors;
using TrafficControlService.Events;

namespace TrafficControlService.Actors;
public interface IVehicleActor : IActor {
    public Task RegisterEntryAsync(VehicleRegistered msg);
    public Task RegisterExitAsync(VehicleRegistered msg);
}
