try {
    # Create OneNote Application
    $oneNote = New-Object -ComObject OneNote.Application
    Write-Host "OneNote application created successfully"
    
    # Get all hierarchy levels to see what's available
    $fullHierarchy = ""
    $oneNote.GetHierarchy("", 4, [ref]$fullHierarchy)  # 4 = hsPages (deepest level)
    
    Write-Host "Full hierarchy XML length: $($fullHierarchy.Length)"
    
    # Save to file for examination
    $fullHierarchy | Out-File -FilePath "onenote_hierarchy.xml" -Encoding UTF8
    Write-Host "Saved hierarchy to onenote_hierarchy.xml"
    
    # Parse and show structure
    [xml]$xml = $fullHierarchy
    
    foreach ($notebook in $xml.Notebooks.Notebook) {
        $notebookName = $notebook.name
        Write-Host "Notebook: $notebookName"
        Write-Host "  Sections: $($notebook.Section.Count)"
        
        foreach ($section in $notebook.Section) {
            $sectionName = $section.name
            Write-Host "    Section: $sectionName"
            Write-Host "      Pages: $($section.Page.Count)"
            
            foreach ($page in $section.Page) {
                $pageName = $page.name
                $pageId = $page.ID
                Write-Host "      Page: $pageName (ID: $pageId)"
                
                # Try to get some content
                try {
                    $pageContentXml = ""
                    $oneNote.GetPageContent($pageId, [ref]$pageContentXml)
                    Write-Host "        Content length: $($pageContentXml.Length)"
                    
                    if ($pageContentXml.Length -gt 100) {
                        # Save first page content for examination
                        $pageContentXml | Out-File -FilePath "sample_page_content.xml" -Encoding UTF8
                        Write-Host "        Saved sample page content to sample_page_content.xml"
                        break
                    }
                } catch {
                    Write-Host "        Error: $($_.Exception.Message)"
                }
            }
        }
    }
    
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
