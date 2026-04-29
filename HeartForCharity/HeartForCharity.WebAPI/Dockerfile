FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5145

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["HeartForCharity.WebAPI/HeartForCharity.WebAPI.csproj", "HeartForCharity.WebAPI/"]
COPY ["HeartForCharity.Services/HeartForCharity.Services.csproj", "HeartForCharity.Services/"]
COPY ["HeartForCharity.Model/HeartForCharity.Model.csproj", "HeartForCharity.Model/"]
RUN dotnet restore "./HeartForCharity.WebAPI/HeartForCharity.WebAPI.csproj"
COPY . .
WORKDIR "/src/HeartForCharity.WebAPI"
RUN dotnet build "./HeartForCharity.WebAPI.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./HeartForCharity.WebAPI.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
RUN mkdir -p /app/wwwroot/uploads
ENTRYPOINT ["dotnet", "HeartForCharity.WebAPI.dll"]
