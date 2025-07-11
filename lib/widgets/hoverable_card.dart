import 'package:flutter/material.dart';

class HoverableCard extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color hoverColor;
  final Color borderColor;
  final Color hoverBorderColor;
  final Color? shadowColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const HoverableCard({
    super.key,
    required this.child,
    required this.baseColor,
    required this.hoverColor,
    required this.borderColor,
    required this.hoverBorderColor,
    this.shadowColor,
    this.padding,
    this.borderRadius,
    this.onTap,
  });

  @override
  _HoverableCardState createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovering ? widget.hoverColor : widget.baseColor,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            border: Border.all(
              color: _isHovering ? widget.hoverBorderColor : widget.borderColor,
            ),
            boxShadow: _isHovering ? [
              BoxShadow(
                color: widget.shadowColor ?? Colors.white.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class HoverableInfoCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final List<Widget>? additionalContent;

  const HoverableInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    this.additionalContent,
  });

  @override
  _HoverableInfoCardState createState() => _HoverableInfoCardState();
}

class _HoverableInfoCardState extends State<HoverableInfoCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.primaryColor.withOpacity(_isHovering ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.primaryColor.withOpacity(_isHovering ? 0.5 : 0.3),
          ),
          boxShadow: _isHovering ? [
            BoxShadow(
              color: widget.primaryColor.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.primaryColor.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.primaryColor.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.additionalContent != null) ...[
              const SizedBox(height: 4),
              ...widget.additionalContent!,
            ],
          ],
        ),
      ),
    );
  }
}
