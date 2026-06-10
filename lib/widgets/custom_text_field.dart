import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool enabled;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.enabled = true,
    this.controller,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  final _controller = TextEditingController();

  TextEditingController get effectiveController =>
      widget.controller ?? _controller;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: widget.enabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.enabled
                  ? Colors.grey.shade300
                  : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: effectiveController,
            enabled: widget.enabled,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            style: TextStyle(
              fontSize: 16,
              color: widget.enabled
                  ? Colors.black87
                  : Colors.grey.shade500,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
              ),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: widget.enabled
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
                size: 20,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                onPressed: widget.enabled
                    ? _togglePasswordVisibility
                    : null,
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: widget.enabled
                      ? Colors.grey.shade500
                      : Colors.grey.shade400,
                  size: 20,
                ),
              )
                  : null,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}