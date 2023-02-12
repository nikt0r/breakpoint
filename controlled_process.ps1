$user = "kenny.cole"
$pass = "test"

$passSecure = ConvertTo-SecureString -String $pass -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $passSecure

$JsonBody = @{
    caseDefinitionKey = "A15-pSCase01"
    returnVariables   = $True
} | ConvertTo-Json

$Params = @{
    Method                         = "Post"
    Uri                            = "http://localhost:8080/flowable-work/cmmn-api/cmmn-runtime/case-instances"
    Body                           = $JsonBody
    Headers                        = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    ContentType                    = "application/json"
    Credential                     = $credential
    AllowUnencryptedAuthentication = $True
}

$result = Invoke-RestMethod @Params
$result

# Read-Host "Set breakpoint"

$caseId = $result.id

$JsonBody = @{
    actionId           = "addBreakpointAfter"
    activityId         = "variableActivity1"
    # scopeDefinitionId = "CAS-16f6ed11-2d69-11ec-a9f3-d7a2a35598a0"
    scopeDefinitionKey = "A15-pSCase01"
    scopeType          = "cmmn"
} | ConvertTo-Json

$Params = @{
    Method                         = "Post"
    Uri                            = "http://localhost:8080/flowable-work/inspect-api/current-instance/$caseId/breakpoint-definitions"
    Body                           = $JsonBody
    Headers                        = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    ContentType                    = "application/json"
    Credential                     = $credential
    AllowUnencryptedAuthentication = $True
}

$result = Invoke-RestMethod @Params
$result

Write-Host "-> Case started" -ForegroundColor DarkYellow
Write-Host "-> Breakpoint set" -ForegroundColor DarkYellow
Write-Host "-> Case ID: $caseId" -ForegroundColor DarkYellow
Write-Host "-> Execute the following tasks before continuing:`r`n1. Finish Submitter task`r`n2. Finish Approver task`r`n3. Change some attributes in RM+" -ForegroundColor Yellow

Do {

    Read-Host "Press Enter to continue"

    # Switch user to SPID
    $user = "admin"
    $pass = "test"

    $passSecure = ConvertTo-SecureString -String $pass -AsPlainText -Force
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $passSecure

    $Params = @{
        Method                         = "Get"
        Uri                            = "http://localhost:8080/flowable-work/cmmn-api/cmmn-management/suspended-jobs?caseInstanceId=$caseId"
        Headers                        = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
        ContentType                    = "application/json"
        Credential                     = $credential
        AllowUnencryptedAuthentication = $True
    }

    $result = Invoke-RestMethod @Params
    $jobId = $result.data[0].id

    $isJobReady = ($jobId -is [string]) -and ($jobId -ne "")

    if ($isJobReady -ne $true) {
        Write-Host "-> Looks like you haven't finished the tasks yet. Please finish them and press Continue." -ForegroundColor DarkYellow
    }

} While ($isJobReady -ne $true)

$JsonBody = @{
    continuationType = "continue"
} | ConvertTo-Json

$Params = @{
    Method                         = "Post"
    Uri                            = "http://localhost:8080/flowable-work/inspect-api/current-instance/${caseId}/breakpoint-instances/${jobId}?scopeType=cmmn"
    Body                           = $JsonBody
    Headers                        = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }
    ContentType                    = "application/json"
    Credential                     = $credential
    AllowUnencryptedAuthentication = $True
}

$result = Invoke-RestMethod @Params

Write-Host "DONE!" -ForegroundColor Yellow
