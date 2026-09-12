# AzureEventGeneratorApp — Context

Purpose of this file: continuity doc so work can resume cleanly if a session gets disconnected. Reflects state and decisions as of 2026-09-12.

## Goal of the project

Not a general distributed event system. The point is to **demonstrate wiring Application Insights + Log Analytics + dashboards into a real Azure deployment**, end to end:

1. `EventGenerator.Service` generates fake telemetry-shaped data and fires it at `EventProcessorApi.Service`.
2. `EventProcessorApi.Service` exposes several endpoints that simulate real APIs (varied latency, occasional errors, maybe a fake internal dependency hop) and reports telemetry to Application Insights.
3. Azure infra (Bicep) provisions App Insights, a Log Analytics workspace, and dashboards/workbooks to visualize the resulting metrics.

Success criterion is "deployed on Azure with real metrics rendering on a dashboard," not the sophistication of the event model itself.

## Repo layout

```
AzureEventGeneratorApp.slnx                          — solution file (new XML .slnx format), references all 3 .csproj
EventGenerator.Service/                               — Worker Service (Sdk="Microsoft.NET.Sdk.Worker")
EventProcessorApi.Service/                            — minimal API (Sdk="Microsoft.NET.Sdk.Web")
AzureEventGeneratorApp.Contracts/                     — class library (Sdk="Microsoft.NET.Sdk")
AzureEventGeneratorApp.Infrastructure/main.bicep      — empty, not started
.gitignore                                            — created, covers .NET + VS/VSCode/Rider + node_modules/.likec4
README.md                                             — empty
```

Both `EventGenerator.Service` and `EventProcessorApi.Service` already have a `ProjectReference` to `AzureEventGeneratorApp.Contracts`. All three projects are in `AzureEventGeneratorApp.slnx`.

## Current state (all boilerplate, nothing wired to the actual idea yet)

- `EventGenerator.Service/Worker.cs` — still the default template: just logs a heartbeat once/sec, does not generate or send anything yet.
- `EventProcessorApi.Service/Program.cs` — still has the default `/weatherforecast` sample endpoint, no App Insights, no real routes.
- `AzureEventGeneratorApp.Contracts/Class1.cs` — still the default empty stub class, no real DTOs defined yet.
- `AzureEventGeneratorApp.Infrastructure/main.bicep` — empty file, no resources defined.
- Git repo initialized; no remote confirmed.

## Decisions made (agreed, not yet implemented)

1. **Telemetry SDK: Azure Monitor OpenTelemetry Distro** (`Azure.Monitor.OpenTelemetry.AspNetCore`), not the legacy `Microsoft.ApplicationInsights.AspNetCore` SDK (that one's in maintenance mode).
2. **Instrument both services**, not just the processor — gives distributed trace correlation (Application Map shows two connected nodes) for minimal extra cost, since OTel/App Insights propagates W3C trace-context over `HttpClient` automatically.
3. **`EventProcessorApi.Service` needs several varied simulated endpoints** (e.g. `/orders`, `/payments`, `/inventory`), each with randomized latency/jitter and a deliberate error rate, so the resulting telemetry isn't flat/boring on dashboards. Consider a simulated internal "dependency" hop for a richer Application Map.
4. **Emit custom telemetry, not just auto-collected requests** — e.g. `TrackEvent`/OTel custom metrics derived from the generated payload (event type, simulated segment, etc.), since default request telemetry alone makes for thin dashboards.
5. **Dashboards: use Azure Monitor Workbooks** (`microsoft.insights/workbooks`), not classic Azure Dashboards — Workbooks are KQL-driven and template cleanly in Bicep; classic dashboards are JSON blobs with hardcoded resource IDs and template poorly.
6. **Disable/adjust sampling** (set close to 100%) for this demo, since adaptive sampling can make a low-volume synthetic dataset look sparse.
7. **Hosting target**: `EventGenerator.Service` (no inbound HTTP, continuous background loop) → **Azure Container Apps with no ingress**. `EventProcessorApi.Service` (needs inbound HTTP) → **Azure Container Apps with ingress enabled**. Both need Dockerfiles whose build context is the **repo root** (not the project subfolder), since both have a `ProjectReference` to `AzureEventGeneratorApp.Contracts` and need that source copied in during `docker build`.

## Agreed build order (not started yet)

1. Wire up Azure Monitor OpenTelemetry Distro in `EventProcessorApi.Service` first, pointed at an App Insights resource (can point at a temporary/manual one before Bicep exists).
2. Flesh out the varied simulated endpoints (latency jitter, error injection) in `EventProcessorApi.Service`.
3. Wire `EventGenerator.Service`'s `Worker` to actually generate fake telemetry payloads and POST them to those endpoints; instrument it with OTel too.
4. Get real data flowing end-to-end locally before touching Bicep.
5. Write `main.bicep`: App Insights + Log Analytics workspace + Workbook dashboard(s), once it's clear what queries/metrics are worth putting on them.
6. Containerize both services (Dockerfiles at repo root context) and deploy to Container Apps (generator: no ingress; processor: ingress enabled).

## Not yet decided / open questions for whoever picks this up

- Exact shape of the "fake telemetry data" payload / what `AzureEventGeneratorApp.Contracts` DTOs should look like.
- Exact set of simulated endpoint names/behaviors on the processor.
- Whether Log Analytics is used only via App Insights' own workspace, or whether other resources (e.g. Container Apps logs) should also feed into the same workspace for a unified dashboard.
- CI/CD approach for deployment (not discussed yet).

## Working style notes for whoever (human or agent) continues this

- **The agent does not make changes to this project unless explicitly requested.** Default mode is explanation + commands/code for the user to run themselves. Only edit files, run scaffolding commands, install packages, etc. when the user directly asks for it (e.g. "create X", "go ahead", "do it") — not as a proactive follow-up to a discussion or review.
- LikeC4 was also discussed for architecture diagrams (separate from this app's runtime code) — see earlier conversation if diagrams are wanted; not set up yet, but `.gitignore` already accounts for `.likec4/` and `node_modules/`.
