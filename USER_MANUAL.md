# OneNote Groomer - User Manual

## Welcome to OneNote Groomer! 🎉

This manual will help you get the most out of OneNote Groomer, even if you're new to AI-powered tools.

## Table of Contents
1. [First Launch](#first-launch)
2. [Basic Usage](#basic-usage)
3. [Custom Prompts](#custom-prompts)
4. [Tips & Tricks](#tips--tricks)
5. [Troubleshooting](#troubleshooting)

## First Launch

### What You'll See
When you first open OneNote Groomer, you'll see:
- **Dark theme interface** (easier on the eyes)
- **File drop zone** (drag your OneNote files here)
- **Prompt editor** (customize what data to extract)
- **Process button** (starts the AI magic)

### Before You Start
Make sure you've completed the setup:
1. ✅ Ollama is installed
2. ✅ An AI model is downloaded (phi3.5, llama3.2, or gemma2:2b)
3. ✅ Ollama is running (should start automatically)

## Basic Usage

### Step 1: Load Your OneNote File
**Method A: Drag & Drop**
- Simply drag your `.one` file from File Explorer
- Drop it onto the application window
- You'll see the file path appear

**Method B: File Browser**
- Click "Select OneNote File"
- Navigate to your OneNote file
- Click "Open"

### Step 2: Review the Extraction Prompt
The default prompt extracts common business data:
- Company/Client names
- Dates and times
- Key decisions
- Financial information
- Contact details
- Status updates
- Follow-up items

**You can use this as-is or customize it!**

### Step 3: Process the File
1. Click "Process OneNote File"
2. Watch the progress indicator
3. Wait for the AI to analyze your content (1-5 minutes)
4. See the success dialog when complete

### Step 4: Export Your Results
**Option A: Open Immediately**
- Click "Open Excel" to view results right away
- Your default spreadsheet app will open the file

**Option B: Save to Custom Location**
- Click "Save As" to choose where to save
- Pick a folder and filename
- Perfect for organizing multiple extractions

## Custom Prompts

### Why Customize?
Every OneNote file is different. Custom prompts help you extract exactly what you need.

### Prompt Examples

**📋 Meeting Notes**
```
Extract from these meeting notes:
- Attendee names
- Meeting date and time
- Action items assigned to people
- Decisions made
- Next meeting scheduled date
- Key discussion points
```

**📞 Contact Information**
```
Find and extract:
- Full names
- Email addresses
- Phone numbers
- Company names
- Job titles
- Physical addresses
```

**📊 Project Management**
```
Extract project details:
- Project names
- Start and due dates
- Team member assignments
- Task status (completed, in progress, pending)
- Budget or cost information
- Priority levels
```

**📝 Research Notes**
```
Organize research data:
- Source titles and authors
- Publication dates
- Key findings or quotes
- Research categories or tags
- Page numbers or references
```

**🏥 Medical Records** (for personal use)
```
Extract health information:
- Appointment dates
- Doctor or clinic names
- Symptoms mentioned
- Medications prescribed
- Test results
- Follow-up instructions
```

### Writing Effective Prompts

**DO:**
- ✅ Be specific about what you want
- ✅ Use simple, clear language
- ✅ List items with bullet points
- ✅ Mention the format you prefer

**DON'T:**
- ❌ Make prompts too long or complex
- ❌ Ask for data that might not exist
- ❌ Use technical jargon
- ❌ Include conflicting instructions

## Tips & Tricks

### 🚀 Performance Tips
- **Close other apps** during processing for faster results
- **Use smaller AI models** (phi3.5, gemma2:2b) for speed
- **Break large files** into smaller sections if possible
- **Restart Ollama** if processing seems slow

### 🎯 Better Results
- **Review your OneNote content** before processing
- **Clean up messy formatting** in OneNote first
- **Be specific in prompts** about data format
- **Test with small files** before processing large ones

### 💡 Workflow Ideas
- **Batch process** similar files with the same prompt
- **Save prompts** in a text file for reuse
- **Create templates** in Excel for consistent formatting
- **Use descriptive filenames** for saved extractions

### 🔄 Reprocessing
- **Same file, different prompt**: Extract different data types
- **Updated content**: Process again after OneNote updates
- **Better prompts**: Refine and reprocess for improved results

## Troubleshooting

### Common Issues & Solutions

**❓ "No data extracted" or empty results**
- Check if your OneNote file has readable text
- Simplify your prompt
- Try a different AI model
- Ensure Ollama is running properly

**❓ Application won't start**
- Run as Administrator
- Check Windows antivirus isn't blocking it
- Ensure all files are in the same folder
- Try restarting your computer

**❓ Processing takes too long**
- Large files naturally take longer (5-10 minutes is normal)
- Switch to a smaller AI model
- Close other applications
- Check if your computer is busy with other tasks

**❓ Ollama connection errors**
- Restart Ollama: Open Command Prompt, type `ollama serve`
- Check if Ollama is in Windows startup programs
- Reinstall Ollama if problems persist

**❓ Excel export issues**
- Make sure you have Excel or LibreOffice installed
- Try "Save As" instead of "Open Excel"
- Check file permissions in the save location

**❓ Poor extraction quality**
- Review and improve your prompt
- Try a larger AI model (llama3.2)
- Check if OneNote content is well-formatted
- Break complex files into smaller sections

### Getting Help

**📚 Documentation**
- Read `SETUP_GUIDE.md` for installation help
- Check `README.md` for technical details

**💬 Community Support**
- Report bugs on GitHub Issues
- Ask questions in GitHub Discussions
- Share your prompts and tips with others

**🔧 Advanced Users**
- Modify the source code (it's open source!)
- Try different Ollama models
- Contribute improvements back to the project

## Best Practices

### File Organization
```
📁 OneNote Extractions/
  📁 2024-Meetings/
    📄 Jan-Team-Meeting_extracted.xlsx
    📄 Feb-Board-Meeting_extracted.xlsx
  📁 2024-Contacts/
    📄 Client-Database_extracted.xlsx
    📄 Vendor-Contacts_extracted.xlsx
  📁 Templates/
    📄 meeting-prompt.txt
    📄 contact-prompt.txt
```

### Regular Workflow
1. **Weekly**: Process new OneNote pages
2. **Monthly**: Review and organize extractions
3. **Quarterly**: Update and improve prompts
4. **Annually**: Archive old extractions

### Security & Privacy
- ✅ All processing happens on your computer
- ✅ No data sent to external servers
- ✅ Your OneNote content stays private
- ✅ You control all data and exports

---

## Enjoy Using OneNote Groomer! 🌟

Remember: The more you use it, the better you'll get at writing prompts and organizing your data. Don't hesitate to experiment and find what works best for your needs!

**Happy extracting!** 🚀
