import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D30),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isHovering ? [
            BoxShadow(
              color: const Color(0xFF9B59B6).withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_note, color: Color(0xFF9B59B6)),
                SizedBox(width: 8),
                Text('AI Extraction Prompt',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter your custom prompt...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onChanged: widget.onPromptChanged,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
