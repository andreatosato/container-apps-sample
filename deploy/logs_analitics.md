ContainerAppConsoleLogs_CL 
| where isnotempty( Message)
| order by TimeGenerated desc 