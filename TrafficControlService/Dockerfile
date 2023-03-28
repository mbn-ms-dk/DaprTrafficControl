#See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
COPY ["TrafficControlService/TrafficControlService.csproj", "TrafficControlService/"]
RUN dotnet restore "TrafficControlService/TrafficControlService.csproj"
COPY . .
WORKDIR "/src/TrafficControlService"
RUN dotnet build "TrafficControlService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "TrafficControlService.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Expose ports
EXPOSE 6000/tcp
ENV ASPNETCORE_URLS http://*:6000
ENTRYPOINT ["dotnet", "TrafficControlService.dll"]