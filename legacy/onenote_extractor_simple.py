"""
Simple OneNote extractor using direct PowerShell automation
"""

import subprocess
import json
import re
import pandas as pd
from datetime import datetime
import sys
import os

def extract_onenote_using_powershell(onenote_file):
    """Extract OneNote content using PowerShell COM automation"""
    
    powershell_script = f'''
try {{
    # Create OneNote Application
    $oneNote = New-Object -ComObject OneNote.Application
    
    # Get the absolute path
    $filePath = (Resolve-Path "{onenote_file}").Path
    Write-Host "Processing OneNote file: $filePath"
    
    # Try to open the file first
    try {{
        $oneNote.OpenHierarchy($filePath, "", "", 0)
        Write-Host "OneNote file opened successfully"
        Start-Sleep -Seconds 2
    }} catch {{
        Write-Host "Warning: Could not open file directly: $($_.Exception.Message)"
    }}
    
    # Get notebook hierarchy  
    $notebookXml = ""
    $oneNote.GetHierarchy("", 1, [ref]$notebookXml)
    
    # Parse XML and extract content
    [xml]$xml = $notebookXml
    $results = @()
    
    foreach ($notebook in $xml.Notebooks.Notebook) {{
        $notebookName = $notebook.name
        Write-Host "Found notebook: $notebookName"
        
        foreach ($section in $notebook.Section) {{
            $sectionName = $section.name
            Write-Host "  Section: $sectionName"
            
            foreach ($page in $section.Page) {{
                $pageName = $page.name
                $pageId = $page.ID
                Write-Host "    Page: $pageName"
                
                try {{
                    # Get page content
                    $pageXml = ""
                    $oneNote.GetPageContent($pageId, [ref]$pageXml)
                    
                    # Extract text from XML
                    [xml]$pageContent = $pageXml
                    $textElements = $pageContent.SelectNodes("//*[local-name()='T']")
                    
                    $allText = @()
                    foreach ($textElement in $textElements) {{
                        if ($textElement.InnerText -and $textElement.InnerText.Trim()) {{
                            $allText += $textElement.InnerText.Trim()
                        }}
                    }}
                    
                    $content = $allText -join "`n"
                    
                    if ($content.Trim()) {{
                        $result = @{{
                            notebook = $notebookName
                            section = $sectionName  
                            page = $pageName
                            content = $content
                        }}
                        $results += $result
                        Write-Host "      Extracted $($content.Length) characters"
                    }}
                }} catch {{
                    Write-Host "      Error extracting page: $($_.Exception.Message)"
                }}
            }}
        }}
    }}
    
    # Output results as JSON
    Write-Host "RESULTS_START"
    $results | ConvertTo-Json -Depth 10
    Write-Host "RESULTS_END"
    
}} catch {{
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}}
'''
    
    try:
        result = subprocess.run(
            ["powershell", "-Command", powershell_script],
            capture_output=True,
            text=True,
            timeout=120
        )
        
        if result.returncode != 0:
            print(f"PowerShell error: {result.stderr}")
            return []
        
        output = result.stdout
        print(f"PowerShell output: {output[:500]}...")
        
        # Extract JSON from output
        if "RESULTS_START" in output and "RESULTS_END" in output:
            start_idx = output.find("RESULTS_START") + len("RESULTS_START")
            end_idx = output.find("RESULTS_END")
            json_str = output[start_idx:end_idx].strip()
            
            if json_str:
                try:
                    data = json.loads(json_str)
                    return data if isinstance(data, list) else [data]
                except json.JSONDecodeError as e:
                    print(f"JSON decode error: {e}")
                    print(f"JSON string: {json_str[:200]}...")
                    return []
        
        return []
        
    except subprocess.TimeoutExpired:
        print("PowerShell script timed out")
        return []
    except Exception as e:
        print(f"Error running PowerShell script: {e}")
        return []

def chunk_by_business_entities(content):
    """Chunk content based on business entity markers"""
    chunks = []
    
    lines = content.split('\\n')
    entity_patterns = [
        r'underwriter:?\\s*([A-Za-z\\s&,.\\'-]+)',
        r'(?:company|business|client|account):?\\s*([A-Za-z\\s&,.\\'-]+)', 
        r'^([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)\\s*(?:LLC|INC|CORP|COMPANY|GROUP)',
        r'\\b[A-Z][a-z]+\\s+[A-Z][a-z]+\\s+(?:LLC|INC|CORP|COMPANY)\\b'
    ]
    
    current_chunk = ''
    found_entity = False
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        # Check if this line starts a new business entity
        for pattern in entity_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                # Save current chunk if it has content
                if current_chunk.strip() and found_entity:
                    chunks.append(current_chunk.strip())
                    current_chunk = ''
                found_entity = True
                break
        
        current_chunk += line + '\\n'
        
        # If chunk gets too long without entity, split it
        if len(current_chunk) > 800 and not found_entity:
            chunks.append(current_chunk.strip())
            current_chunk = ''
    
    # Add final chunk
    if current_chunk.strip():
        chunks.append(current_chunk.strip())
    
    return [chunk for chunk in chunks if len(chunk.strip()) > 30]

def is_valid_business_entry(chunk):
    """Check if chunk is a valid business entry"""
    lower_chunk = chunk.lower()
    
    # Must have underwriter (and not N/A)
    has_underwriter = ('underwriter' in lower_chunk or 'underwritten' in lower_chunk) and 'n/a' not in lower_chunk
    
    # Or have broker/company AND date
    has_broker = 'broker' in lower_chunk and 'n/a' not in lower_chunk
    has_company = bool(re.search(r'(?:company|business|client|account)[:\\s]*[a-z]', chunk, re.IGNORECASE))
    has_date = bool(re.search(r'\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}', chunk))
    
    # Also accept entries with company names ending in LLC, INC, etc
    has_business_name = bool(re.search(r'[A-Z][a-z]+\\s+[A-Z][a-z]+\\s+(?:LLC|INC|CORP|COMPANY)', chunk))
    
    return has_underwriter or ((has_broker or has_company or has_business_name) and has_date)

def extract_business_metadata(chunk):
    """Extract business metadata from chunk"""
    metadata = {}
    
    # Extract underwriter
    underwriter_patterns = [
        r'underwriter:?\\s*([A-Za-z\\s&,.\\'-]+)',
        r'underwritten\\s+by\\s*([A-Za-z\\s&,.\\'-]+)'
    ]
    
    for pattern in underwriter_patterns:
        match = re.search(pattern, chunk, re.IGNORECASE)
        if match:
            metadata['underwriter'] = match.group(1).strip()
            break
    
    # Extract company  
    company_match = re.search(r'(?:company|business|client|account):?\\s*([A-Za-z\\s&,.\\'-]+)', chunk, re.IGNORECASE)
    if company_match:
        metadata['company'] = company_match.group(1).strip()
    
    # Extract broker
    broker_match = re.search(r'broker:?\\s*([A-Za-z\\s&,.\\'-]+)', chunk, re.IGNORECASE)
    if broker_match:
        metadata['broker'] = broker_match.group(1).strip()
    
    # Extract business names
    business_name_match = re.search(r'([A-Z][a-z]+\\s+[A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*)\\s*(?:LLC|INC|CORP|COMPANY)', chunk)
    if business_name_match and 'company' not in metadata:
        metadata['company'] = business_name_match.group(1).strip()
    
    # Extract dates
    dates = re.findall(r'\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}', chunk)
    if dates:
        metadata['dates'] = ', '.join(dates)
        metadata['primary_date'] = dates[0]
    
    # Extract money amounts
    amounts = re.findall(r'\\$[\\d,]+(?:\\.\\d{2})?', chunk)
    if amounts:
        metadata['amounts'] = ', '.join(amounts)
    
    return metadata

def main():
    if len(sys.argv) != 2:
        print("Usage: python onenote_extractor_simple.py <onenote_file>")
        sys.exit(1)
    
    onenote_file = sys.argv[1]
    
    if not os.path.exists(onenote_file):
        print(f"Error: OneNote file not found: {onenote_file}")
        sys.exit(1)
    
    print(f"Extracting data from OneNote file: {onenote_file}")
    
    # Extract OneNote content
    content_list = extract_onenote_using_powershell(onenote_file)
    
    if not content_list:
        print("No content extracted from OneNote file")
        sys.exit(1)
    
    print(f"Extracted content from {len(content_list)} pages")
    
    # Parse into business entries
    business_entries = []
    
    for page_data in content_list:
        content = page_data.get('content', '')
        if not content.strip():
            continue
            
        # Split content into potential business entries
        entries = chunk_by_business_entities(content)
        
        for entry in entries:
            if is_valid_business_entry(entry):
                metadata = extract_business_metadata(entry)
                
                business_entry = {
                    'source_notebook': page_data.get('notebook', ''),
                    'source_section': page_data.get('section', ''), 
                    'source_page': page_data.get('page', ''),
                    'raw_content': entry,
                    **metadata
                }
                
                business_entries.append(business_entry)
    
    print(f"Found {len(business_entries)} valid business entries")
    
    if business_entries:
        # Create DataFrame and save to Excel
        df = pd.DataFrame(business_entries)
        
        # Save to Excel with timestamp
        output_file = f"onenote_extracted_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
        df.to_excel(output_file, index=False)
        
        print(f"Results saved to: {output_file}")
        
        # Also save as JSON for debugging
        json_file = output_file.replace('.xlsx', '.json')
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(business_entries, f, indent=2, ensure_ascii=False)
        
        print(f"Debug data saved to: {json_file}")
        
        # Print summary
        print("\\n=== SUMMARY ===")
        underwriter_count = len([e for e in business_entries if e.get('underwriter')])
        company_count = len([e for e in business_entries if e.get('company')])
        broker_count = len([e for e in business_entries if e.get('broker')])
        
        print(f"Entries with underwriters: {underwriter_count}")
        print(f"Entries with companies: {company_count}")
        print(f"Entries with brokers: {broker_count}")
        
    else:
        print("No valid business entries found")
        print("This suggests the OneNote file may not contain the expected business data format")

if __name__ == "__main__":
    main()
