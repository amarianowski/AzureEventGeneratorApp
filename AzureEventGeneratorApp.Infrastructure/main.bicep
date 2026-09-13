targetScope='resourceGroup'

var location string = 'uksouth'

var workbookContent = '''
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 12,
      "name": "main",
      "content": {
        "version": "NotebookGroup/1.0",
        "groupType": "editable",
        "items": [
          {
            "type": 3,
            "name": "Latest readings per station",
            "content": {
              "version": "KqlItem/1.0",
              "query": "let Readings = AppTraces\r\n| where Message contains \"Received telemetry reading\"\r\n| extend\r\n    StationId = tostring(Properties.StationId),\r\n    Temperature = todouble(Properties.TemperatureCelsius),\r\n    WindSpeed = todouble(Properties.WindSpeedMps),\r\n    BatteryVoltage = todouble(Properties.BatteryVoltage);\r\n\r\nReadings\r\n| summarize arg_max(TimeGenerated, *) by StationId\r\n| project StationId, TimeGenerated, Temperature, WindSpeed, BatteryVoltage\r\n",
              "size": 0,
              "timeContext": {
                "durationMs": 86400000
              },
              "queryType": 0,
              "crossComponentResources": [
                "${logAnalyticsWorkspace.id}"
              ],
              "title": "Latest readings per station"
            },
            "styleSettings": {
              "showBorder": true,
              "borderStyle": "light thick",
              "x": 0,
              "y": 0,
              "w": 11,
              "h": 8
            }
          },
          {
            "type": 3,
            "name": "Latest readings per station",
            "content": {
              "version": "KqlItem/1.0",
              "query": "let Readings = AppTraces\r\n| where Message contains \"Received telemetry reading\"\r\n| extend\r\n    StationId = tostring(Properties.StationId),\r\n    Temperature = todouble(Properties.TemperatureCelsius),\r\n    WindSpeed = todouble(Properties.WindSpeedMps),\r\n    BatteryVoltage = todouble(Properties.BatteryVoltage);\r\n\r\nReadings\r\n| summarize MinTemp = min(Temperature), AvgTemp = round(avg(Temperature), 2), MaxTemp = max(Temperature) by StationId\r\n| order by AvgTemp desc\r\n",
              "size": 0,
              "timeContext": {
                "durationMs": 86400000
              },
              "queryType": 0,
              "crossComponentResources": [
                "${logAnalyticsWorkspace.id}"
              ],
              "title": "Temperature per station"
            },
            "styleSettings": {
              "showBorder": true,
              "borderStyle": "light thick",
              "x": 11,
              "y": 0,
              "w": 13,
              "h": 8
            }
          },
          {
            "type": 3,
            "name": "Latest readings per station",
            "content": {
              "version": "KqlItem/1.0",
              "query": "let Readings = AppTraces\r\n| where Message contains \"Received telemetry reading\"\r\n| extend\r\n    StationId = tostring(Properties.StationId),\r\n    Temperature = todouble(Properties.TemperatureCelsius),\r\n    WindSpeed = todouble(Properties.WindSpeedMps),\r\n    BatteryVoltage = todouble(Properties.BatteryVoltage);\r\n\r\nReadings\r\n| where BatteryVoltage < 3.3\r\n| summarize LowReadings = count(), LastSeen = max(TimeGenerated) by StationId\r\n| order by LowReadings desc",
              "size": 0,
              "timeContext": {
                "durationMs": 86400000
              },
              "queryType": 0,
              "crossComponentResources": [
                "${logAnalyticsWorkspace.id}"
              ],
              "title": "Low battery readings"
            },
            "styleSettings": {
              "showBorder": true,
              "borderStyle": "light thick",
              "x": 0,
              "y": 8,
              "w": 11,
              "h": 8
            }
          },
          {
            "type": 3,
            "name": "Latest readings per station",
            "content": {
              "version": "KqlItem/1.0",
              "query": "let Readings = AppTraces\r\n| where Message contains \"Received telemetry reading\"\r\n| extend\r\n    StationId = tostring(Properties.StationId),\r\n    Temperature = todouble(Properties.TemperatureCelsius),\r\n    WindSpeed = todouble(Properties.WindSpeedMps),\r\n    BatteryVoltage = todouble(Properties.BatteryVoltage);\r\n\r\nReadings\r\n| where WindSpeed > 80\r\n| project TimeGenerated, StationId, WindSpeed\r\n| order by TimeGenerated desc\r\n",
              "size": 0,
              "timeContext": {
                "durationMs": 86400000
              },
              "queryType": 0,
              "crossComponentResources": [
                "${logAnalyticsWorkspace.id}"
              ],
              "title": "Extreme wind"
            },
            "styleSettings": {
              "showBorder": true,
              "borderStyle": "light thick",
              "x": 11,
              "y": 8,
              "w": 13,
              "h": 8
            }
          },
          {
            "type": 3,
            "name": "Latest readings per station",
            "content": {
              "version": "KqlItem/1.0",
              "query": "AppTraces\r\n| where Message contains \"Received telemetry reading\"\r\n| summarize Count = count() by StationId = tostring(Properties.StationId)\r\n| order by Count desc\r\n",
              "size": 0,
              "timeContext": {
                "durationMs": 86400000
              },
              "queryType": 0,
              "crossComponentResources": [
                "${logAnalyticsWorkspace.id}"
              ],
              "title": "Readings per station"
            },
            "styleSettings": {
              "showBorder": true,
              "borderStyle": "light thick",
              "x": 0,
              "y": 16,
              "w": 11,
              "h": 9
            }
          },
          {
            "type": 3,
            "name": "Latest readings per station",
            "content": {
              "version": "KqlItem/1.0",
              "query": "let Readings = AppTraces\r\n| where Message contains \"Received telemetry reading\"\r\n| extend\r\n    StationId = tostring(Properties.StationId),\r\n    Temperature = todouble(Properties.TemperatureCelsius),\r\n    WindSpeed = todouble(Properties.WindSpeedMps),\r\n    BatteryVoltage = todouble(Properties.BatteryVoltage);\r\n\r\nReadings\r\n| summarize avg(BatteryVoltage) by bin(TimeGenerated, 1m), StationId\r\n| render timechart\r\n\r\n",
              "size": 0,
              "timeContext": {
                "durationMs": 86400000
              },
              "queryType": 0,
              "crossComponentResources": [
                "${logAnalyticsWorkspace.id}"
              ],
              "title": "Battery drain"
            },
            "styleSettings": {
              "showBorder": true,
              "borderStyle": "light thick",
              "x": 11,
              "y": 16,
              "w": 13,
              "h": 9
            }
          },
          {
            "type": 3,
            "name": "Latest readings per station",
            "content": {
              "version": "KqlItem/1.0",
              "query": "AppRequests\r\n| where Name contains \"telemetry\"\r\n| summarize Total = count(), Failures = countif(Success == false) by bin(TimeGenerated, 5m)\r\n| extend FailureRatePct = round(100.0 * Failures / Total, 2)\r\n| render timechart\r\n",
              "size": 0,
              "timeContext": {
                "durationMs": 86400000
              },
              "queryType": 0,
              "crossComponentResources": [
                "${logAnalyticsWorkspace.id}"
              ],
              "title": "Processor health"
            },
            "styleSettings": {
              "showBorder": true,
              "borderStyle": "light thick",
              "x": 0,
              "y": 25,
              "w": 11,
              "h": 10
            }
          },
          {
            "type": 3,
            "name": "Latest readings per station",
            "content": {
              "version": "KqlItem/1.0",
              "query": "AppTraces\r\n| where Message contains \"Received telemetry reading\"\r\n| extend StationId = tostring(Properties.StationId), Temperature = todouble(Properties.TemperatureCelsius)\r\n| summarize avg(Temperature) by bin(TimeGenerated, 1m), StationId\r\n| render timechart\r\n",
              "size": 0,
              "timeContext": {
                "durationMs": 86400000
              },
              "queryType": 0,
              "crossComponentResources": [
                "${logAnalyticsWorkspace.id}"
              ],
              "title": "Temperature"
            },
            "styleSettings": {
              "showBorder": true,
              "borderStyle": "light thick",
              "x": 11,
              "y": 25,
              "w": 13,
              "h": 10
            }
          }
        ],
        "layout": {
          "type": "grid"
        }
      }
    }
  ],
  "fallbackResourceIds": [
    "azure monitor"
  ],
  "styleSettings": {
    "paddingStyle": "narrow",
    "spacingStyle": "narrow"
  },
  "$schema": "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
}
'''

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'azure-event-generator-law'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource component 'Microsoft.Insights/components@2020-02-02' = {
  name: 'azure-event-generator-ai'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    DisableIpMasking: false
    DisableLocalAuth: false
    ForceCustomerStorageForProfiler: false
    RetentionInDays: 90
    SamplingPercentage: 100
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource fleetDashboardWorkbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: guid(resourceGroup().id, 'azure-event-generator-fleet-dashboard')
  location: location
  kind: 'shared'
  properties: {
    displayName: 'Arctic Telemetry Fleet Dashboard'
    serializedData: workbookContent
    category: 'workbook'
    sourceId: logAnalyticsWorkspace.id
  }
}

output appInsightsConnectionString string = component.properties.ConnectionString
