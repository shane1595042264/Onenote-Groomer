param(
    [Parameter(Mandatory=$true)]
    [string]$OneNoteFile
)

try {
    # Create OneNote Application
    $oneNote = New-Object -ComObject OneNote.Application
    Write-Host "OneNote application created successfully"
    
    # Get absolute path
    $absolutePath = (Resolve-Path $OneNoteFile).Path
    Write-Host "Opening OneNote file: $absolutePath"
    
    # Try to open the .one file
    try {
        $oneNote.OpenHierarchy($absolutePath, "", "", 0)
        Write-Host "OneNote file opened successfully"
        Start-Sleep -Seconds 3
    } catch {
        Write-Host "Could not open file directly: $($_.Exception.Message)"
        Write-Host "Continuing with existing notebooks..."
    }
    
    # Get updated hierarchy
    $notebookXml = ""
    $oneNote.GetHierarchy("", 1, [ref]$notebookXml)
    Write-Host "Got updated hierarchy XML"
    
    # Parse XML
    [xml]$xml = $notebookXml
    Write-Host "Parsed XML successfully"
    
    $allResults = @()
    
    # Process all notebooks
    foreach ($notebook in $xml.Notebooks.Notebook) {
        $notebookName = $notebook.name
        $notebookId = $notebook.ID
        Write-Host "Processing Notebook: $notebookName"
        
        # Get sections for this notebook
        $sectionXml = ""
        $oneNote.GetHierarchy($notebookId, 2, [ref]$sectionXml)  # 2 = hsSections
        [xml]$sectionData = $sectionXml
        
        foreach ($section in $sectionData.Notebooks.Notebook.Section) {
            $sectionName = $section.name
            $sectionId = $section.ID
            Write-Host "  Processing Section: $sectionName"
            
            # Get pages for this section
            $pageXml = ""
            $oneNote.GetHierarchy($sectionId, 3, [ref]$pageXml)  # 3 = hsPages
            [xml]$pageData = $pageXml
            
            foreach ($page in $pageData.Notebooks.Notebook.Section.Page) {
                $pageName = $page.name
                $pageId = $page.ID
                Write-Host "    Processing Page: $pageName"
                
                try {
                    # Get page content
                    $pageContentXml = ""
                    $oneNote.GetPageContent($pageId, [ref]$pageContentXml)
                    
                    if ($pageContentXml.Length -gt 0) {
                        Write-Host "      Got page content, length: $($pageContentXml.Length)"
                        
                        # Extract text
                        [xml]$pageContent = $pageContentXml
                        $textElements = $pageContent.SelectNodes("//*[local-name()='T']")
                        
                        $allText = @()
                        foreach ($textElement in $textElements) {
                            if ($textElement.InnerText -and $textElement.InnerText.Trim()) {
                                $allText += $textElement.InnerText.Trim()
                            }
                        }
                        
                        if ($allText.Count -gt 0) {
                            $content = $allText -join "`n"
                            Write-Host "      Extracted $($content.Length) characters of text"
                            
                            $result = @{
                                notebook = $notebookName
                                section = $sectionName
                                page = $pageName
                                content = $content
                            }
                            $allResults += $result
                            
                            # Show a preview
                            $preview = $content.Substring(0, [Math]::Min(100, $content.Length))
                            Write-Host "      Preview: $preview..."
                        }
                    }
                } catch {
                    Write-Host "      Error getting page content: $($_.Exception.Message)"
                }
            }
        }
    }
    
    # Output results
    Write-Host ""
    Write-Host "=== EXTRACTION COMPLETE ==="
    Write-Host "Total pages with content: $($allResults.Count)"
    
    if ($allResults.Count -gt 0) {
        Write-Host ""
        Write-Host "RESULTS_START"
        $allResults | ConvertTo-Json -Depth 10
        Write-Host "RESULTS_END"
    }
    
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}
