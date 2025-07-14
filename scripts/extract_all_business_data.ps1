# PowerShell script to extract ALL business data from OneNote
Write-Host "Extracting all business data from OneNote..." -ForegroundColor Green

try {
    # Connect to OneNote
    $oneNote = New-Object -ComObject OneNote.Application
    [xml]$hierarchy = ""
    $oneNote.GetHierarchy("", [Microsoft.Office.Interop.OneNote.HierarchyScope]::hsPages, [ref]$hierarchy)
    
    Write-Host "OneNote connected successfully" -ForegroundColor Green
    
    # Find the business notebook
    $businessNotebook = $hierarchy.Notebooks.Notebook | Where-Object { $_.name -like "*NewBusiness*" -or $_.name -like "*Business*" }
    
    if (-not $businessNotebook) {
        Write-Host "No business notebook found. Available notebooks:" -ForegroundColor Yellow
        $hierarchy.Notebooks.Notebook | ForEach-Object { Write-Host "  - $($_.name)" }
        exit 1
    }
    
    Write-Host "Found business notebook: $($businessNotebook.name)" -ForegroundColor Green
    
    # Extract all business data
    $allBusinessData = @()
    $pageCounter = 0
    
    # Process each section in the notebook
    foreach ($section in $businessNotebook.Section) {
        Write-Host "Processing section: $($section.name)" -ForegroundColor Cyan
        
        # Process each page in the section
        foreach ($page in $section.Page) {
            $pageCounter++
            Write-Host "  Page $pageCounter`: $($page.name)" -ForegroundColor White
            
            try {
                # Get page content
                [xml]$pageXml = ""
                $oneNote.GetPageContent($page.ID, [ref]$pageXml)
                
                # Extract text content from the XML
                $textContent = ""
                $pageXml.Page.Outline.OEChildren.OE | ForEach-Object {
                    if ($_.T) {
                        $text = $_.T.InnerText
                        if ($text -and $text.Trim() -ne "") {
                            $textContent += $text + "`n"
                        }
                    }
                    
                    # Process nested content
                    if ($_.OEChildren) {
                        $_.OEChildren.OE | ForEach-Object {
                            if ($_.T) {
                                $text = $_.T.InnerText
                                if ($text -and $text.Trim() -ne "") {
                                    $textContent += "  " + $text + "`n"
                                }
                            }
                        }
                    }
                }
                
                # Look for business data patterns
                $businessDataFound = $false
                
                # Check for key business indicators
                $businessPatterns = @(
                    "underwriter",
                    "broker",
                    "company",
                    "account",
                    "premium",
                    "limit",
                    "deductible",
                    "policy",
                    "effective",
                    "expiration",
                    "coverage",
                    "GL",
                    "Property",
                    "liability",
                    "insurance"
                )
                
                foreach ($pattern in $businessPatterns) {
                    if ($textContent -match "(?i)$pattern") {
                        $businessDataFound = $true
                        break
                    }
                }
                
                # If this looks like business data, extract structured information
                if ($businessDataFound -and $textContent.Trim() -ne "") {
                    
                    # Try to extract key fields
                    $underwriter = ""
                    $broker = ""
                    $company = ""
                    $effectiveDate = ""
                    $accountName = ""
                    
                    # Extract underwriter
                    if ($textContent -match "(?i)underwriter[:\s]*([^\r\n]+)") {
                        $underwriter = $matches[1].Trim()
                    }
                    
                    # Extract broker
                    if ($textContent -match "(?i)broker[:\s]*([^\r\n]+)") {
                        $broker = $matches[1].Trim()
                    }
                    
                    # Extract company/account
                    if ($textContent -match "(?i)(company|account)[:\s]*([^\r\n]+)") {
                        $company = $matches[2].Trim()
                    }
                    
                    # Extract effective date
                    if ($textContent -match "(?i)effective[:\s]*([^\r\n]+)") {
                        $effectiveDate = $matches[1].Trim()
                    }
                    
                    # Create business data entry
                    $businessEntry = [PSCustomObject]@{
                        PageName = $page.name
                        SectionName = $section.name
                        Underwriter = $underwriter
                        Broker = $broker
                        Company = $company
                        EffectiveDate = $effectiveDate
                        AccountName = $accountName
                        Content = $textContent.Trim()
                        PageID = $page.ID
                        LastModified = $page.lastModifiedTime
                    }
                    
                    $allBusinessData += $businessEntry
                    Write-Host "    ✓ Business data extracted" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "    ✗ Error processing page: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "`nExtraction complete. Found $($allBusinessData.Count) business entries." -ForegroundColor Green
    
    # Export to JSON for the Dart application
    $jsonOutput = $allBusinessData | ConvertTo-Json -Depth 10
    $jsonOutput | Out-File -FilePath "extracted_business_data.json" -Encoding UTF8
    
    # Also export to CSV for review
    $allBusinessData | Export-Csv -Path "extracted_business_data.csv" -NoTypeInformation
    
    Write-Host "Data exported to:" -ForegroundColor Yellow
    Write-Host "  - extracted_business_data.json" -ForegroundColor White
    Write-Host "  - extracted_business_data.csv" -ForegroundColor White
    
    # Display summary
    Write-Host "`nSummary of extracted data:" -ForegroundColor Yellow
    $allBusinessData | ForEach-Object {
        Write-Host "  Page: $($_.PageName)" -ForegroundColor White
        if ($_.Underwriter) { Write-Host "    Underwriter: $($_.Underwriter)" -ForegroundColor Cyan }
        if ($_.Broker) { Write-Host "    Broker: $($_.Broker)" -ForegroundColor Cyan }
        if ($_.Company) { Write-Host "    Company: $($_.Company)" -ForegroundColor Cyan }
        Write-Host ""
    }
    
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.Exception.StackTrace)" -ForegroundColor Red
}
finally {
    # Clean up COM object
    if ($oneNote) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($oneNote) | Out-Null
    }
}
