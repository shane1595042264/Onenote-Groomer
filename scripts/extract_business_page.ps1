# Extract a sample business page from the OneNote file
try {
    $oneNote = New-Object -ComObject OneNote.Application
    
    # Get the hierarchy
    [xml]$hierarchy = ""
    $oneNote.GetHierarchy("", [Microsoft.Office.Interop.OneNote.HierarchyScope]::hsPages, [ref]$hierarchy)
    
    # Find the NewBusiness_Copy notebook
    $notebook = $hierarchy.Notebooks.Notebook | Where-Object { $_.name -eq "NewBusiness_Copy" }
    
    if ($notebook) {
        # Get June 2025 section
        $section = $notebook.Section | Where-Object { $_.name -eq "June 2025" }
        
        if ($section) {
            # Get the first business page (not template or empty)
            $businessPage = $section.Page | Where-Object { $_.name -like "*American Containers*" } | Select-Object -First 1
            
            if ($businessPage) {
                Write-Host "Extracting page: $($businessPage.name)"
                
                # Get the page content
                [xml]$pageContent = ""
                $oneNote.GetPageContent($businessPage.ID, [ref]$pageContent)
                
                # Save the content
                $pageContent.OuterXml | Out-File -FilePath "sample_business_page.xml" -Encoding UTF8
                
                Write-Host "Page content saved to sample_business_page.xml"
                Write-Host "Page ID: $($businessPage.ID)"
                Write-Host "Last modified: $($businessPage.lastModifiedTime)"
            } else {
                Write-Host "No American Containers page found"
                # Get any business page
                $businessPage = $section.Page | Select-Object -First 1
                if ($businessPage) {
                    Write-Host "Extracting first page instead: $($businessPage.name)"
                    
                    [xml]$pageContent = ""
                    $oneNote.GetPageContent($businessPage.ID, [ref]$pageContent)
                    
                    $pageContent.OuterXml | Out-File -FilePath "sample_business_page.xml" -Encoding UTF8
                    Write-Host "Page content saved to sample_business_page.xml"
                }
            }
        } else {
            Write-Host "June 2025 section not found"
        }
    } else {
        Write-Host "NewBusiness_Copy notebook not found"
    }
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
}
finally {
    if ($oneNote) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($oneNote) | Out-Null
    }
}
