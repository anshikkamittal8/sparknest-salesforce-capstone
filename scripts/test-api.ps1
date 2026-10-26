# Runs the 5 SparkNest API requests (3 custom REST + 2 Composite) and checks the results.
# Usage (from the project folder):  powershell -ExecutionPolicy Bypass -File scripts\test-api.ps1
$org = "sparknest"
$apiVersion = "64.0"

$base  = (sf org display --target-org $org --json | ConvertFrom-Json).result.instanceUrl
$token = (sf org auth show-access-token --target-org $org --json --no-prompt | ConvertFrom-Json).result.accessToken
if (-not $base -or -not $token) { Write-Host "Could not read instance URL or token. Check: sf org list" -ForegroundColor Red; exit 1 }

$headers = @{ Authorization = "Bearer $token" }
$stamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

function Invoke-Api($name, $url, $bodyObject) {
    Write-Host ""
    Write-Host "=== $name ===" -ForegroundColor Cyan
    $json = $bodyObject | ConvertTo-Json -Depth 6
    try {
        $res = Invoke-WebRequest -Method Post -Uri $url -Headers $headers -ContentType "application/json" -Body $json -UseBasicParsing
        Write-Host ("HTTP " + [int]$res.StatusCode) -ForegroundColor Green
        Write-Host $res.Content
    } catch {
        $r = $_.Exception.Response
        if ($r) {
            $reader = New-Object System.IO.StreamReader($r.GetResponseStream())
            Write-Host ("HTTP " + [int]$r.StatusCode) -ForegroundColor Yellow
            Write-Host $reader.ReadToEnd()
        } else {
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
}

$restUrl = "$base/services/apexrest/SparkNestEnquiryAPI"

Invoke-Api "1. REST - New customer (expect 200, contactCreated true)" $restUrl @{
    email = "new.customer.$stamp@example.com"; firstName = "Divya"; lastName = "Menon"; phone = "+91 90000 20001"; city = "Bengaluru"
    subject = "Interested in SparkNest Pulse Smartwatch"; enquiryType = "Product Enquiry"; customerBudget = 15000; source = "Website"; priority = "Medium"
}

Invoke-Api "2. REST - Existing customer (expect 200, contactCreated false)" $restUrl @{
    email = "ananya.reddy@example.com"; subject = "Question about Care Plus plan"
    enquiryType = "Care Plan Enquiry"; planDuration = "1 Year"; customerBudget = 4000
}

Invoke-Api "3. REST - Missing email (expect 400, Email is required)" $restUrl @{
    firstName = "No"; lastName = "Email"; subject = "Enquiry without an email address"
}

$compositeUrl = "$base/services/data/v$apiVersion/composite"

function New-Composite($email, $budget) {
    return @{
        allOrNone = $true
        compositeRequest = @(
            @{ method = "POST"; url = "/services/data/v$apiVersion/sobjects/Contact"; referenceId = "newContact"
               body = @{ FirstName = "Arvind"; LastName = "Rao"; Email = $email; Phone = "+91 90000 30001"; MailingCity = "Hyderabad" } },
            @{ method = "POST"; url = "/services/data/v$apiVersion/sobjects/Enquiry__c"; referenceId = "newEnquiry"
               body = @{ Name = "B2B onboarding enquiry"; Contact__c = '@{newContact.id}'; Enquiry_Type__c = "Product Enquiry"; Customer_Budget__c = $budget } }
        )
    }
}

Invoke-Api "4. Composite - B2B onboarding (expect 200, two 201 results)" $compositeUrl (New-Composite "b2b.$stamp@example.com" 25000)
Invoke-Api "5. Composite - Rollback test, budget 500 (expect Enquiry error and PROCESSING_HALTED on the Contact)" $compositeUrl (New-Composite "rollback.$stamp@example.com" 500)

Write-Host ""
Write-Host "=== Checks ===" -ForegroundColor Cyan
$rb = (sf data query -q "SELECT COUNT() FROM Contact WHERE Email = 'rollback.$stamp@example.com'" --target-org $org --json | ConvertFrom-Json).result.totalSize
Write-Host "Contacts with the rollback email (expect 0): $rb"
$dup = (sf data query -q "SELECT COUNT() FROM Contact WHERE Email = 'ananya.reddy@example.com'" --target-org $org --json | ConvertFrom-Json).result.totalSize
Write-Host "Contacts for ananya.reddy (expect 1): $dup"
$tk = (sf data query -q "SELECT COUNT() FROM Task WHERE Subject LIKE 'Follow up: Interested in SparkNest Pulse%'" --target-org $org --json | ConvertFrom-Json).result.totalSize
Write-Host "Follow-up Tasks created by the trigger (expect 1 or more): $tk"
