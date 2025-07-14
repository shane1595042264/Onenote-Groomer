try {
    # Create OneNote Application
    $oneNote = New-Object -ComObject OneNote.Application
    Write-Host "OneNote application created successfully"
    
    # Get notebook hierarchy
    $notebookXml = ""
    $oneNote.GetHierarchy("", 1, [ref]$notebookXml)
    Write-Host "Got hierarchy XML"
    
    # Parse XML
    [xml]$xml = $notebookXml
    Write-Host "Parsed XML successfully"
    
    # Show notebooks
    foreach ($notebook in $xml.Notebooks.Notebook) {
        $notebookName = $notebook.name
        $notebookId = $notebook.ID
        Write-Host "Notebook: $notebookName (ID: $notebookId)"
        
        # Show sections
        foreach ($section in $notebook.Section) {
            $sectionName = $section.name
            $sectionId = $section.ID
            Write-Host "  Section: $sectionName (ID: $sectionId)"
            
            # Show pages
            foreach ($page in $section.Page) {
                $pageName = $page.name
                $pageId = $page.ID
                Write-Host "    Page: $pageName (ID: $pageId)"
                
                # Try to get page content
                try {
                    $pageXml = ""
                    $oneNote.GetPageContent($pageId, [ref]$pageXml)
                    Write-Host "      Got page content, length: $($pageXml.Length)"
                    
                    # Try to extract some text
                    if ($pageXml.Length -gt 0) {
                        [xml]$pageContent = $pageXml
                        $textElements = $pageContent.SelectNodes("//*[local-name()='T']")
                        Write-Host "      Found $($textElements.Count) text elements"
                        
                        $first5Texts = @()
                        for ($i = 0; $i -lt [Math]::Min(5, $textElements.Count); $i++) {
                            $text = $textElements[$i].InnerText
                            if ($text -and $text.Trim()) {
                                $first5Texts += $text.Trim()
                            }
                        }
                        
                        if ($first5Texts.Count -gt 0) {
                            Write-Host "      Sample text:"
                            foreach ($text in $first5Texts) {
                                Write-Host "        $text"
                            }
                        }
                    }
                } catch {
                    Write-Host "      Error getting page content: $($_.Exception.Message)"
                }
            }
        }
    }
    
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
