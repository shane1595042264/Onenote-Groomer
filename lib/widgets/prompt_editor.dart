import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class PromptPreset {
  final String name;
  final String prompt;
  final IconData icon;
  final String description;

  const PromptPreset({
    required this.name,
    required this.prompt,
    required this.icon,
    required this.description,
  });
}

class PromptEditor extends StatefulWidget {
  final String initialPrompt;
  final Function(String) onPromptChanged;

  const PromptEditor({
    super.key,
    required this.initialPrompt,
    required this.onPromptChanged,
  });

  @override
  _PromptEditorState createState() => _PromptEditorState();
}

class _PromptEditorState extends State<PromptEditor> {
  late TextEditingController _controller;
  bool _isHovering = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  Timer? _autoSaveTimer;
  String _lastSavedPrompt = '';
  
  // Predefined prompt presets
  static const List<PromptPreset> _presets = [
    PromptPreset(
      name: 'Meeting',
      icon: Icons.people,
      description: 'Extract meeting information',
      prompt: '''- Key decisions or actions
- Financial information  
- Contact details
- Status or outcomes
- Any follow-up items

Map the existing columns to these requested fields.''',
    ),
    PromptPreset(
      name: 'Sales',
      icon: Icons.trending_up,
      description: 'Extract sales data',
      prompt: '''- Client or company name
- Deal value or pricing
- Sales stage or status  
- Contact information
- Next steps or actions
- Closing date

Focus on extracting specific sales metrics and customer details.''',
    ),
    PromptPreset(
      name: 'Recruiting',
      icon: Icons.person_search,
      description: 'Extract recruiting info',
      prompt: '''- Candidate name
- Position or role
- Skills and experience
- Contact information
- Interview status
- Salary expectations
- Start date

Extract relevant recruiting and hiring information.''',
    ),
    PromptPreset(
      name: 'Project',
      icon: Icons.assignment,
      description: 'Extract project details',
      prompt: '''- Project name
- Status or phase
- Deadline or milestones
- Team members
- Budget or costs
- Risks or issues
- Next actions

Focus on project management details and timelines.''',
    ),
    PromptPreset(
      name: 'Customer Support',
      icon: Icons.support_agent,
      description: 'Extract support tickets',
      prompt: '''- Customer name
- Issue description
- Priority level
- Status
- Assigned agent
- Resolution notes
- Follow-up required

Extract customer support and ticket information.''',
    ),
    PromptPreset(
      name: 'Financial',
      icon: Icons.attach_money,
      description: 'Extract financial data',
      prompt: '''- Amount or value
- Transaction type
- Date
- Account or category
- Vendor or client
- Approval status
- Budget impact

Focus on financial transactions and budget information.''',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt);
    _lastSavedPrompt = widget.initialPrompt;
    
    // Listen for changes to detect unsaved content
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final currentText = _controller.text;
    final hasChanges = currentText != _lastSavedPrompt;
    
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }

    // Cancel previous timer and start new one for autosave
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _hasUnsavedChanges) {
        _savePrompt(showSnackbar: false); // Autosave without notification
      }
    });

    // Notify parent of changes immediately
    widget.onPromptChanged(currentText);
  }

  Future<void> _savePrompt({bool showSnackbar = true}) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_ai_prompt', _controller.text);
      
      setState(() {
        _lastSavedPrompt = _controller.text;
        _hasUnsavedChanges = false;
        _isSaving = false;
      });

      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Prompt saved successfully'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving prompt: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _loadPreset(PromptPreset preset) {
    _controller.text = preset.prompt;
    widget.onPromptChanged(preset.prompt);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(preset.icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Loaded ${preset.name} preset'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovering ? theme.colorScheme.primary.withOpacity(0.3) : theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: _isHovering ? [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            // Header with title and save button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note, 
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Extraction Prompt',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Auto-save indicator
                  if (_isSaving)
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Saving...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  else if (_hasUnsavedChanges)
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Unsaved',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Saved',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(width: 16),
                  // Manual save button
                  Tooltip(
                    message: 'Save prompt now',
                    child: FilledButton.icon(
                      onPressed: _hasUnsavedChanges && !_isSaving 
                        ? () => _savePrompt(showSnackbar: true)
                        : null,
                      icon: _isSaving 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 16),
                      label: const Text('Save'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Preset buttons section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Presets',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presets.map((preset) {
                      return Tooltip(
                        message: preset.description,
                        child: OutlinedButton.icon(
                          onPressed: () => _loadPreset(preset),
                          icon: Icon(preset.icon, size: 16),
                          label: Text(preset.name),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 32),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // Text editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter your custom prompt or select a preset above...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
