# AzureEventGeneratorApp — Context

Purpose of this file: continuity doc so work can resume cleanly if a session gets disconnected. Reflects state and decisions as of 2026-09-12 (updated same day — hosting model changed from Container Apps to App Service, and generator/API/contracts are no longer just boilerplate).

## Goal of the project

Not a general distributed event system. The point is to **demonstrate wiring Application Insights + Log Analytics + dashboards into a real Azure deployment**, end to end:

1. `EventGenerator.Service` generates fake telemetry-shaped data and fires it at `EventProcessorApi.Service`.
2. `EventProcessorApi.Service` exposes several endpoints that simulate real APIs (varied latency, occasional errors, maybe a fake internal dependency hop) and reports telemetry to Application Insights.
3. Azure infra (Bicep) provisions App Insights, a Log Analytics workspace, and dashboards/workbooks to visualize the resulting metrics.

Success criterion is "deployed on Azure with real metrics rendering on a dashboard," not the sophistication of the event model itself.

## Repo layout

```
AzureEventGeneratorApp.slnx                                          — solution file (new XML .slnx format), references all 3 .csproj
EventGenerator.Service/                                               — Worker Service (Sdk="Microsoft.NET.Sdk.Worker")
EventProcessorApi.Service/                                            — minimal API (Sdk="Microsoft.NET.Sdk.Web")
AzureEventGeneratorApp.Contracts/                                     — class library (Sdk="Microsoft.NET.Sdk")
AzureEventGeneratorApp.Infrastructure/main.bicep                      — Log Analytics workspace + workspace-based App Insights
AzureEventGeneratorApp.Infrastructure/Start-InfrastructureDeployment.ps1 — creates RG + deploys main.bicep
.gitignore                                                            — created, covers .NET + VS/VSCode/Rider + node_modules/.likec4
README.md                                                             — empty
```

Both `EventGenerator.Service` and `EventProcessorApi.Service` already have a `ProjectReference` to `AzureEventGeneratorApp.Contracts`. All three projects are in `AzureEventGeneratorApp.slnx`.

## Current state

- `AzureEventGeneratorApp.Contracts/TelemetryReading.cs` — real DTO (replaced the `Class1` stub): `StationId`, `Timestamp`, `TemperatureCelsius`, `WindSpeedMps`, `BatteryVoltage`, all `required` with `{ get; init; }` (immutable after construction).
- `EventGenerator.Service/Worker.cs` — generates a random `TelemetryReading` (Antarctic research station theme: MCM/ASP/VOK/ESP/ROT/CON) every 3 seconds and logs it via `ILogger` (structured logging, not `Console.WriteLine`, so it'll flow into App Insights once instrumented). **Not yet sending it anywhere** — `IHttpClientFactory` is injected and a named `"EventProcessorApi"` client is registered in `Program.cs` (`BaseUrl` from `appsettings.json`, currently `http://localhost:9090`), but the actual `PostAsJsonAsync` call to `EventProcessorApi.Service` hasn't been wired in yet.
- `EventProcessorApi.Service/Program.cs` — has a real `POST /telemetry` minimal API endpoint accepting `TelemetryReading` from the JSON body (`app.MapPost("/telemetry", (TelemetryReading reading) => ...)`), currently just returns `Results.Accepted(...)` — no actual processing/telemetry-emission logic yet. The "varied simulated endpoints with latency/error injection" from the build-order plan haven't been built yet — only this one endpoint exists so far.
- `AzureEventGeneratorApp.Infrastructure/main.bicep` — no longer empty: has a `Microsoft.OperationalInsights/workspaces` (Log Analytics, name `azure-event-generator-law`) and a `Microsoft.Insights/components` (App Insights, name `azure-event-generator-ai`) resource, correctly linked via `WorkspaceResourceId` (workspace-based App Insights, not classic), `SamplingPercentage: 100`. No App Service Plan/Web App resources yet (see updated hosting decision below).
- `AzureEventGeneratorApp.Infrastructure/Start-InfrastructureDeployment.ps1` — creates the resource group (`event-generator-app-rg`, `uksouth`) and deploys `main.bicep` directly (Az PowerShell transpiles Bicep to ARM itself — no separate ARM JSON/parameters file needed).
- Neither service has App Insights/OpenTelemetry wired into `Program.cs` yet (decision #1/#2 below, not yet implemented).
- Git repo initialized; no remote confirmed.

## Decisions made (agreed, not yet implemented)

1. **Telemetry SDK: Azure Monitor OpenTelemetry Distro** (`Azure.Monitor.OpenTelemetry.AspNetCore`), not the legacy `Microsoft.ApplicationInsights.AspNetCore` SDK (that one's in maintenance mode).
2. **Instrument both services**, not just the processor — gives distributed trace correlation (Application Map shows two connected nodes) for minimal extra cost, since OTel/App Insights propagates W3C trace-context over `HttpClient` automatically.
3. **`EventProcessorApi.Service` needs several varied simulated endpoints** (e.g. `/orders`, `/payments`, `/inventory`), each with randomized latency/jitter and a deliberate error rate, so the resulting telemetry isn't flat/boring on dashboards. Consider a simulated internal "dependency" hop for a richer Application Map.
4. **Emit custom telemetry, not just auto-collected requests** — e.g. `TrackEvent`/OTel custom metrics derived from the generated payload (event type, simulated segment, etc.), since default request telemetry alone makes for thin dashboards.
5. **Dashboards: use Azure Monitor Workbooks** (`microsoft.insights/workbooks`), not classic Azure Dashboards — Workbooks are KQL-driven and template cleanly in Bicep; classic dashboards are JSON blobs with hardcoded resource IDs and template poorly.
6. **Disable/adjust sampling** (set close to 100%) for this demo, since adaptive sampling can make a low-volume synthetic dataset look sparse.
7. ~~Hosting target: Azure Container Apps~~ — **SUPERSEDED, see decision #8.**
8. **Hosting target (current): Azure App Service, no containers.** `EventProcessorApi.Service` → a normal App Service Web App (`Microsoft.Web/sites` on an `Microsoft.Web/serverfarms` plan). `EventGenerator.Service` → deployed as a **continuous WebJob** (a WebJob is not its own Azure resource type — it's a deployment artifact that runs inside an App Service). Still to decide: bundle the WebJob into the same App Service as the API (under `App_Data/jobs/continuous/<name>/`) vs. give it its own dedicated App Service on the same Plan — leaning toward the dedicated-App-Service option since the two have always been treated as independent services, but not finalized. No Dockerfiles, no container registry, no Container Apps environment needed as a result.
9. **CI/CD**: a pipeline compiles the projects (`dotnet publish`) and zip-deploys the output — no container build step. For GitHub Actions this is `dotnet publish` + `azure/webapps-deploy@v3`; equivalent Azure DevOps task is `AzureWebApp@1`/`AzureRmWebAppDeployment@4`.
10. **App Insights config value: use the connection string, not the instrumentation key** — Microsoft retired instrumentation-key-only ingestion (Feb 2025), and the OTel distro (`Azure.Monitor.OpenTelemetry.AspNetCore`) only accepts a connection string anyway. `main.bicep` should output it: `output appInsightsConnectionString string = component.properties.ConnectionString`. The OTel distro auto-reads it from the `APPLICATIONINSIGHTS_CONNECTION_STRING` env var if `UseAzureMonitor()` is called with no explicit options.
11. **Never put the App Insights connection string in `appsettings.json`/`appsettings.Development.json`** — those files are tracked by git by default (no `.gitignore` rule excludes them), so a value written there would get committed like any other tracked file; "it's just config, not code" does not exempt it from `git add`. For local dev, use **.NET User Secrets** instead (`dotnet user-secrets set "APPLICATIONINSIGHTS_CONNECTION_STRING" "<value>" --project <proj>`), which lives outside the repo entirely (`%APPDATA%\Microsoft\UserSecrets\<UserSecretsId>\secrets.json`) and so cannot end up in a commit. Only `EventGenerator.Service` has a `UserSecretsId` today — `EventProcessorApi.Service` needs `dotnet user-secrets init` before it can use this. In deployed environments (App Service), the equivalent is an App Service Application Setting (or Key Vault reference), not a committed config file.

## Agreed build order (updated — infra for App Insights/Log Analytics is done; App Service pieces still pending)

1. ~~Write `main.bicep`: App Insights + Log Analytics workspace~~ — **DONE.** Workbook dashboard(s) still pending (needs real data flowing first to know what's worth querying).
2. Wire Azure Monitor OpenTelemetry Distro into `EventProcessorApi.Service`, pointed at the deployed App Insights connection string (via User Secrets locally per decision #11). **Not started.**
3. Finish `Worker.cs`: add the actual `httpClientFactory.CreateClient("EventProcessorApi")` + `PostAsJsonAsync("/telemetry", ...)` call — currently only generates+logs, doesn't send. **Not started.**
4. Flesh out the varied simulated endpoints on `EventProcessorApi.Service` (latency jitter, deliberate error rate, maybe a fake dependency hop) — currently only the one plain `/telemetry` endpoint exists. **Not started.**
5. Instrument `EventGenerator.Service` with OTel too, for distributed trace correlation (decision #2). **Not started.**
6. Get real data flowing end-to-end locally, then build the Workbook dashboard(s) in `main.bicep` once it's clear what's worth visualizing.
7. Add `Microsoft.Web/serverfarms` + `Microsoft.Web/sites` to `main.bicep` for the API and the WebJob host (decide bundled-vs-dedicated App Service per decision #8).
8. Set up the CI/CD pipeline (`dotnet publish` + zip-deploy, decision #9).

## Not yet decided / open questions for whoever picks this up

- Exact shape of the "fake telemetry data" payload / what `AzureEventGeneratorApp.Contracts` DTOs should look like.
- Exact set of simulated endpoint names/behaviors on the processor.
- Whether Log Analytics is used only via App Insights' own workspace, or whether other resources (e.g. Container Apps logs) should also feed into the same workspace for a unified dashboard.
- CI/CD approach for deployment (not discussed yet).

## Working style notes for whoever (human or agent) continues this

- **The agent does not make changes to this project unless explicitly requested.** Default mode is explanation + commands/code for the user to run themselves. Only edit files, run scaffolding commands, install packages, etc. when the user directly asks for it (e.g. "create X", "go ahead", "do it") — not as a proactive follow-up to a discussion or review.
- LikeC4 was also discussed for architecture diagrams (separate from this app's runtime code) — see earlier conversation if diagrams are wanted; not set up yet, but `.gitignore` already accounts for `.likec4/` and `node_modules/`.
