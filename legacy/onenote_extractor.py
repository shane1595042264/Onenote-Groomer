"""
OneNote to Excel Converter using COM automation
This script extracts data from OneNote files and converts to Excel
"""

import os
import sys
import json
import re
from pathlib import Path
import win32com.client
import pandas as pd
from datetime import datetime

def extract_onenote_data(onenote_file):
    """Extract data from OneNote file using COM automation"""
    try:
        # Create OneNote application
        one_note = win32com.client.Dispatch("OneNote.Application")
        
        # Get hierarchy of all notebooks
        hierarchy_xml = one_note.GetHierarchy("", 1)  # 1 = hsNotebooks
        
        print(f"OneNote hierarchy retrieved successfully")
        
        # Since .one files are individual notebook files, we need to open the specific file
        # Try to find or open the notebook
        notebook_id = None
        
        # Parse the XML to find notebooks
        import xml.etree.ElementTree as ET
        root = ET.fromstring(hierarchy_xml)
        
        # Look for the notebook by filename
        onenote_filename = Path(onenote_file).stem
        
        # Get all pages content
        all_pages_content = []
        
        # For each notebook
        for notebook in root.findall('.//{http://schemas.microsoft.com/office/onenote/2013/onenote}Notebook'):
            notebook_name = notebook.get('name', '')
            notebook_id = notebook.get('ID', '')
            
            print(f"Found notebook: {notebook_name} (ID: {notebook_id})")
            
            # Get sections
            for section in notebook.findall('.//{http://schemas.microsoft.com/office/onenote/2013/onenote}Section'):
                section_name = section.get('name', '')
                section_id = section.get('ID', '')
                
                print(f"  Section: {section_name}")
                
                # Get pages in this section
                for page in section.findall('.//{http://schemas.microsoft.com/office/onenote/2013/onenote}Page'):
                    page_name = page.get('name', '')
                    page_id = page.get('ID', '')
                    
                    print(f"    Page: {page_name}")
                    
                    try:
                        # Get page content
                        page_xml = one_note.GetPageContent(page_id)
                        content = extract_text_from_page_xml(page_xml)
                        
                        if content.strip():
                            all_pages_content.append({
                                'notebook': notebook_name,
                                'section': section_name,
                                'page': page_name,
                                'content': content,
                                'page_id': page_id
                            })
                            
                    except Exception as e:
                        print(f"      Error extracting page content: {e}")
        
        if not all_pages_content:
            # Try alternative approach - open the .one file directly
            print(f"No content found in open notebooks, trying to open {onenote_file} directly...")
            
            try:
                # Try to open the .one file
                one_note.OpenHierarchy(onenote_file, "", "", 0)
                
                # Get updated hierarchy
                hierarchy_xml = one_note.GetHierarchy("", 1)
                root = ET.fromstring(hierarchy_xml)
                
                # Try again to extract content
                for notebook in root.findall('.//{http://schemas.microsoft.com/office/onenote/2013/onenote}Notebook'):
                    notebook_name = notebook.get('name', '')
                    
                    for section in notebook.findall('.//{http://schemas.microsoft.com/office/onenote/2013/onenote}Section'):
                        section_name = section.get('name', '')
                        
                        for page in section.findall('.//{http://schemas.microsoft.com/office/onenote/2013/onenote}Page'):
                            page_name = page.get('name', '')
                            page_id = page.get('ID', '')
                            
                            try:
                                page_xml = one_note.GetPageContent(page_id)
                                content = extract_text_from_page_xml(page_xml)
                                
                                if content.strip():
                                    all_pages_content.append({
                                        'notebook': notebook_name,
                                        'section': section_name,
                                        'page': page_name,
                                        'content': content,
                                        'page_id': page_id
                                    })
                                    
                            except Exception as e:
                                print(f"Error extracting page content: {e}")
                                
            except Exception as e:
                print(f"Error opening OneNote file: {e}")
        
        return all_pages_content
        
    except Exception as e:
        print(f"Error in OneNote extraction: {e}")
        return []

def extract_text_from_page_xml(page_xml):
    """Extract plain text from OneNote page XML"""
    try:
        import xml.etree.ElementTree as ET
        root = ET.fromstring(page_xml)
        
        # Find all text elements
        text_elements = []
        
        # Look for T elements (text) in the OneNote namespace
        for text_elem in root.findall('.//{http://schemas.microsoft.com/office/onenote/2013/onenote}T'):
            if text_elem.text:
                text_elements.append(text_elem.text.strip())
        
        # Also look for other text containers
        for outline in root.findall('.//{http://schemas.microsoft.com/office/onenote/2013/onenote}Outline'):
            for oe in outline.findall('.//{http://schemas.microsoft.com/office/onenote/2013/onenote}OE'):
                for t in oe.findall('.//{http://schemas.microsoft.com/office/onenote/2013/onenote}T'):
                    if t.text:
                        text_elements.append(t.text.strip())
        
        return '\n'.join(text_elements)
        
    except Exception as e:
        print(f"Error parsing page XML: {e}")
        return ""

def parse_business_entries(content_list):
    """Parse extracted content into business entries"""
    business_entries = []
    
    for page_data in content_list:
        content = page_data['content']
        if not content.strip():
            continue
            
        # Split content into potential business entries
        entries = chunk_by_business_entities(content)
        
        for entry in entries:
            if is_valid_business_entry(entry):
                metadata = extract_business_metadata(entry)
                
                business_entry = {
                    'source_notebook': page_data['notebook'],
                    'source_section': page_data['section'], 
                    'source_page': page_data['page'],
                    'raw_content': entry,
                    **metadata
                }
                
                business_entries.append(business_entry)
    
    return business_entries

def chunk_by_business_entities(content):
    """Chunk content based on business entity markers"""
    chunks = []
    
    lines = content.split('\n')
    entity_markers = [
        r'(?:underwriter|broker|agent):\s*([A-Za-z\s&,.\'-]+)',
        r'(?:company|business|client|account):\s*([A-Za-z\s&,.\'-]+)', 
        r'^([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s*(?:LLC|INC|CORP|COMPANY|GROUP)',
    ]
    
    current_chunk = ''
    found_entity = False
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        # Check if this line starts a new business entity
        for pattern in entity_markers:
            if re.search(pattern, line, re.IGNORECASE):
                # Save current chunk if it has content
                if current_chunk.strip() and found_entity:
                    chunks.append(current_chunk.strip())
                    current_chunk = ''
                found_entity = True
                break
        
        current_chunk += line + '\n'
        
        # If chunk gets too long without entity, split it
        if len(current_chunk) > 1000 and not found_entity:
            chunks.append(current_chunk.strip())
            current_chunk = ''
    
    # Add final chunk
    if current_chunk.strip():
        chunks.append(current_chunk.strip())
    
    return [chunk for chunk in chunks if len(chunk.strip()) > 50]

def is_valid_business_entry(chunk):
    """Check if chunk is a valid business entry"""
    lower_chunk = chunk.lower()
    
    # Must have underwriter (and not N/A)
    has_underwriter = 'underwriter' in lower_chunk and 'n/a' not in lower_chunk
    
    # Or have broker/company AND date
    has_broker = 'broker' in lower_chunk and 'n/a' not in lower_chunk
    has_company = bool(re.search(r'(?:company|business|client|account):\s*[a-z]', chunk, re.IGNORECASE))
    has_date = bool(re.search(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}', chunk))
    
    return has_underwriter or ((has_broker or has_company) and has_date)

def extract_business_metadata(chunk):
    """Extract business metadata from chunk"""
    metadata = {}
    
    # Extract underwriter
    underwriter_match = re.search(r'underwriter:\s*([A-Za-z\s&,.\'-]+)', chunk, re.IGNORECASE)
    if underwriter_match:
        metadata['underwriter'] = underwriter_match.group(1).strip()
    
    # Extract company  
    company_match = re.search(r'(?:company|business|client|account):\s*([A-Za-z\s&,.\'-]+)', chunk, re.IGNORECASE)
    if company_match:
        metadata['company'] = company_match.group(1).strip()
    
    # Extract broker
    broker_match = re.search(r'broker:\s*([A-Za-z\s&,.\'-]+)', chunk, re.IGNORECASE)
    if broker_match:
        metadata['broker'] = broker_match.group(1).strip()
    
    # Extract dates
    dates = re.findall(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}', chunk)
    if dates:
        metadata['dates'] = ', '.join(dates)
        metadata['primary_date'] = dates[0]
    
    # Extract money amounts
    amounts = re.findall(r'\$[\d,]+(?:\.\d{2})?', chunk)
    if amounts:
        metadata['amounts'] = ', '.join(amounts)
    
    return metadata

def main():
    if len(sys.argv) != 2:
        print("Usage: python onenote_extractor.py <onenote_file>")
        sys.exit(1)
    
    onenote_file = sys.argv[1]
    
    if not os.path.exists(onenote_file):
        print(f"Error: OneNote file not found: {onenote_file}")
        sys.exit(1)
    
    print(f"Extracting data from OneNote file: {onenote_file}")
    
    # Extract OneNote content
    content_list = extract_onenote_data(onenote_file)
    
    if not content_list:
        print("No content extracted from OneNote file")
        sys.exit(1)
    
    print(f"Extracted content from {len(content_list)} pages")
    
    # Parse into business entries
    business_entries = parse_business_entries(content_list)
    
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
    else:
        print("No valid business entries found")

if __name__ == "__main__":
    main()
