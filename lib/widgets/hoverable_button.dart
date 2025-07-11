import 'package:flutter/material.dart';

class HoverableButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? hoverColor;
  final Color? foregroundColor;
  final Color? hoverForegroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? elevation;
  final double? hoverElevation;
  final bool isIcon;
  final IconData? icon;
  final String? label;

  const HoverableButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.hoverColor,
    this.foregroundColor,
    this.hoverForegroundColor,
    this.padding,
    this.borderRadius,
    this.elevation,
    this.hoverElevation,
    this.isIcon = false,
    this.icon,
    this.label,
  });

  @override
  _HoverableButtonState createState() => _HoverableButtonState();
}

class _HoverableButtonState extends State<HoverableButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: widget.isIcon && widget.icon != null && widget.label != null
            ? ElevatedButton.icon(
                onPressed: widget.onPressed,
                icon: Icon(widget.icon),
                label: Text(widget.label!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isHovering 
                      ? (widget.hoverColor ?? theme.primaryColor.withOpacity(0.1))
                      : (widget.backgroundColor ?? theme.primaryColor),
                  foregroundColor: _isHovering
                      ? (widget.hoverForegroundColor ?? Colors.white)
                      : (widget.foregroundColor ?? Colors.white),
                  elevation: _isHovering 
                      ? (widget.hoverElevation ?? 8) 
                      : (widget.elevation ?? 4),
                  padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isHovering 
                      ? (widget.hoverColor ?? theme.primaryColor.withOpacity(0.1))
                      : (widget.backgroundColor ?? theme.primaryColor),
                  foregroundColor: _isHovering
                      ? (widget.hoverForegroundColor ?? Colors.white)
                      : (widget.foregroundColor ?? Colors.white),
                  elevation: _isHovering 
                      ? (widget.hoverElevation ?? 8) 
                      : (widget.elevation ?? 4),
                  padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                  ),
                ),
                child: widget.child,
              ),
      ),
    );
  }
}

class HoverableTextButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? foregroundColor;
  final Color? hoverColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isIcon;
  final IconData? icon;
  final String? label;

  const HoverableTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.foregroundColor,
    this.hoverColor,
    this.padding,
    this.borderRadius,
    this.isIcon = false,
    this.icon,
    this.label,
  });

  @override
  _HoverableTextButtonState createState() => _HoverableTextButtonState();
}

class _HoverableTextButtonState extends State<HoverableTextButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: _isHovering ? BoxDecoration(
          color: widget.hoverColor ?? theme.primaryColor.withOpacity(0.1),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ) : null,
        child: widget.isIcon && widget.icon != null && widget.label != null
            ? TextButton.icon(
                onPressed: widget.onPressed,
                icon: Icon(
                  widget.icon,
                  color: _isHovering 
                      ? (widget.hoverColor ?? theme.primaryColor)
                      : (widget.foregroundColor ?? theme.primaryColor),
                ),
                label: Text(
                  widget.label!,
                  style: TextStyle(
                    color: _isHovering 
                        ? (widget.hoverColor ?? theme.primaryColor)
                        : (widget.foregroundColor ?? theme.primaryColor),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              )
            : TextButton(
                onPressed: widget.onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: _isHovering 
                      ? (widget.hoverColor ?? theme.primaryColor)
                      : (widget.foregroundColor ?? theme.primaryColor),
                  padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: widget.child,
              ),
      ),
    );
  }
}
