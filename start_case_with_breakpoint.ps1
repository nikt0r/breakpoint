$user = "admin"
$pass = "test"

$passSecure = ConvertTo-SecureString -String $pass -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $passSecure

# Get definition ID based on case definition key

$caseDefinitionKey = "a05BreakpointsCase"
$processDefinitionKey = "a05Process02"
$taskKey = "scriptTask1"
$breakpointType = "addBreakpointBefore" # "addBreakpointAfter"

$Params = @{
    Method                         = "Get"
    Uri                            = "http://localhost:8080/flowable-work/cmmn-api/cmmn-repository/case-definitions?latest=true&key=$caseDefinitionKey"
    Headers                        = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    ContentType                    = "application/json"
    Credential                     = $credential
    AllowUnencryptedAuthentication = $True
}

$result = Invoke-RestMethod @Params
$caseDefinitionId = $result.data.id

Write-Host "Case definition key: $caseDefinitionKey" -ForegroundColor Yellow
Write-Host "Case definition ID : $caseDefinitionId" -ForegroundColor Yellow

# Start case using case definition ID

$JsonBody = @{
    caseDefinitionId = $caseDefinitionId
} | ConvertTo-Json

$Params = @{
    Method                         = "Post"
    Uri                            = "http://localhost:8080/flowable-work/platform-api/case-instances?createTestDefinition=true"
    Body                           = $JsonBody
    Headers                        = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    ContentType                    = "application/json"
    Credential                     = $credential
    AllowUnencryptedAuthentication = $True
}

$result = Invoke-RestMethod @Params
$caseId = $result.id

Write-Host "Case ID: $caseId" -ForegroundColor Yellow

# Get latest inflight test model

$Params = @{
    Method                         = "Get"
    Uri                            = "http://localhost:8080/flowable-work/inspect-api/latest-inflight-test-model?scopeType=cmmn&scopeId=$caseId"
    Headers                        = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    ContentType                    = "application/json"
    Credential                     = $credential
    AllowUnencryptedAuthentication = $True
}

$result = Invoke-RestMethod @Params
$inflightModelId = $result.id

Write-Host "Inflight ID: $inflightModelId" -ForegroundColor Yellow

# Get process definition ID

$Params = @{
    Method                         = "Get"
    Uri                            = "http://localhost:8080/flowable-work/process-api/repository/process-definitions?latest=true&key=$processDefinitionKey"
    Headers                        = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    ContentType                    = "application/json"
    Credential                     = $credential
    AllowUnencryptedAuthentication = $True
}

$result = Invoke-RestMethod @Params
$processDefinitionId = $result.data.id

Write-Host "Process definition key: $processDefinitionKey" -ForegroundColor Yellow
Write-Host "Process definition ID : $processDefinitionId" -ForegroundColor Yellow

# Create breakpoint

$JsonBody = @{
    actionId           = $breakpointType
    activityId         = $taskKey
    scopeDefinitionId  = $processDefinitionId
    scopeDefinitionKey = $processDefinitionKey
    scopeType          = "bpmn"
} | ConvertTo-Json

$Params = @{
    Method                         = "Post"
    Uri                            = "http://localhost:8080/flowable-work/inspect-api/inflight-test-models/$inflightModelId/breakpoint-definitions"
    Body                           = $JsonBody
    Headers                        = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    ContentType                    = "application/json"
    Credential                     = $credential
    AllowUnencryptedAuthentication = $True
}

$result = Invoke-RestMethod @Params

Write-Host "Breakpoint for: $($result.activityId)" -ForegroundColor Yellow

# Find job to continue

$Params = @{
    Method                         = "Get"
    Uri                            = "http://localhost:8080/flowable-work/inspect-api/inflight-test-models/$inflightModelId/breakpoint-instances"
    Headers                        = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    ContentType                    = "application/json"
    Credential                     = $credential
    AllowUnencryptedAuthentication = $True
}

$result = Invoke-RestMethod @Params
$jobId = $result.id

# Continue

$JsonBody = @{
    continuationType = "continue"
} | ConvertTo-Json

$Params = @{
    Method                         = "Post"
    Uri                            = "http://localhost:8080/flowable-work/inspect-api/inflight-test-models/$inflightModelId/breakpoint-instances/$jobId"
    Body                           = $JsonBody
    Headers                        = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    ContentType                    = "application/json"
    Credential                     = $credential
    AllowUnencryptedAuthentication = $True
}

$result = Invoke-RestMethod @Params
$result