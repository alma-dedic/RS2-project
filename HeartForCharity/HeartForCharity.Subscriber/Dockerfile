FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["HeartForCharity.Subscriber/HeartForCharity.Subscriber.csproj", "HeartForCharity.Subscriber/"]
COPY ["HeartForCharity.Services/HeartForCharity.Services.csproj", "HeartForCharity.Services/"]
COPY ["HeartForCharity.Model/HeartForCharity.Model.csproj", "HeartForCharity.Model/"]
RUN dotnet restore "./HeartForCharity.Subscriber/HeartForCharity.Subscriber.csproj"
COPY . .
WORKDIR "/src/HeartForCharity.Subscriber"
RUN dotnet build "./HeartForCharity.Subscriber.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./HeartForCharity.Subscriber.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "HeartForCharity.Subscriber.dll"]
