import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:serveease_app/l10n/app_localizations.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(String)? onSubmitted;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _labelAnimation;
  late Color borderColorStart;
  late Color borderColorEnd;

  bool get _hasText {
    return widget.controller?.text.isNotEmpty == true ||
        widget.initialValue?.isNotEmpty == true;
  }

  bool get _isFocused => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _labelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // DON'T access Theme.of(context) here
    // Store these as regular properties instead

    _focusNode.addListener(_onFocusChange);
    widget.controller?.addListener(_onTextChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // SAFE: Access Theme here
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    borderColorStart = colorScheme.outline;
    borderColorEnd = colorScheme.primary;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_isFocused || _hasText) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() {});
  }

  void _onTextChange() {
    if (_hasText && !_isFocused) {
      _animationController.forward();
    } else if (!_hasText && !_isFocused) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Create the border color animation here in build()
    final borderColorAnimation = ColorTween(
      begin: borderColorStart,
      end: borderColorEnd,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          AnimatedBuilder(
            animation: _labelAnimation,
            builder: (context, child) {
              return Text(
                widget.label!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _isFocused
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final currentBorderColor = borderColorAnimation.value ?? borderColorStart;
            
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: TextFormField(
                controller: widget.controller,
                initialValue: widget.initialValue,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                obscureText: widget.obscureText,
                enabled: widget.enabled,
                readOnly: widget.readOnly,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                validator: widget.validator,
                onChanged: widget.onChanged,
                onTap: widget.onTap,
                onFieldSubmitted: widget.onSubmitted,
                inputFormatters: widget.inputFormatters,
                textCapitalization: widget.textCapitalization,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: _isFocused
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        )
                      : null,
                  suffixIcon: widget.suffixIcon,
                  filled: true,
                  fillColor: _isFocused
                      ? colorScheme.primaryContainer.withOpacity(0.1)
                      : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: currentBorderColor,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.error,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.error,
                      width: 2,
                    ),
                  ),
                  contentPadding: widget.contentPadding ??
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  counterText: '',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}// Specialized text field variants
class EmailTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const EmailTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return CustomTextField(
      label: label ?? localizations.emailLabel,
      hint: hint ?? localizations.emailHint,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.email_outlined,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return localizations.validationEmailRequired;
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return localizations.validationEmailInvalid;
            }
            return null;
          },
      onChanged: onChanged,
    );
  }
}

class PasswordTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const PasswordTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return CustomTextField(
      label: widget.label ?? localizations.passwordLabel,
      hint: widget.hint ?? 'Enter your password',
      controller: widget.controller,
      obscureText: _obscureText,
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
      validator: widget.validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return localizations.validationPasswordRequired;
            }
            if (value.length < 6) {
              return localizations.validationPasswordLength;
            }
            return null;
          },
      onChanged: widget.onChanged,
    );
  }
}

class NameTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const NameTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return CustomTextField(
      label: label ?? localizations.nameLabel,
      hint: hint ?? 'Enter your full name',
      controller: controller,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      prefixIcon: Icons.person_outline,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return localizations.nameValidation;
            }
            if (value.length < 2) {
              return localizations.validationNameLength;
            }
            return null;
          },
      onChanged: onChanged,
    );
  }
}

class ConfirmPasswordTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const ConfirmPasswordTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  State<ConfirmPasswordTextField> createState() => _ConfirmPasswordTextFieldState();
}

class _ConfirmPasswordTextFieldState extends State<ConfirmPasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return CustomTextField(
      label: widget.label ?? localizations.confirmPasswordLabel,
      hint: widget.hint ?? 'Confirm your password',
      controller: widget.controller,
      obscureText: _obscureText,
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
      validator: widget.validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return localizations.validationConfirmPassword;
            }
            return null;
          },
      onChanged: widget.onChanged,
    );
  }
}