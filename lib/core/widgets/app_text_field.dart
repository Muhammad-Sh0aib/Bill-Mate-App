import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// BillMate standard text input field widget.
///
/// Wraps [TextFormField] with consistent design system tokens,
/// optional required-field indicator, helper and error texts,
/// prefix/suffix icons, accessible labels, and theme responsiveness.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.initialValue,
    this.textCapitalization = TextCapitalization.none,
    this.semanticLabel,
    this.isRequired = false,
    this.errorText,
    this.helperText,
    this.obscureText = false,
  });

  /// The text label displayed above the field.
  final String label;

  /// Placeholder hint inside the input.
  final String? hint;

  /// Controller for reading and modifying text.
  final TextEditingController? controller;

  /// Invoked when text changes.
  final ValueChanged<String>? onChanged;

  /// Invoked when field is submitted (e.g. keyboard Done/Next).
  final ValueChanged<String>? onSubmitted;

  /// Invoked when the field is tapped, including read-only fields.
  final GestureTapCallback? onTap;

  /// Keyboard type (number, phone, text, etc.).
  final TextInputType? keyboardType;

  /// Action key on the software keyboard.
  final TextInputAction? textInputAction;

  /// Input formatters (e.g. FilteringTextInputFormatter.digitsOnly).
  final List<TextInputFormatter>? inputFormatters;

  /// Form field validation callback.
  final FormFieldValidator<String>? validator;

  /// Optional widget displayed at the start of the field.
  final Widget? prefixIcon;

  /// Optional widget displayed at the end of the field.
  final Widget? suffixIcon;

  /// Maximum line count. Default 1.
  final int maxLines;

  /// Minimum line count.
  final int? minLines;

  /// If true, the field cannot be edited by the user.
  final bool readOnly;

  /// If false, the field is disabled.
  final bool enabled;

  /// If true, automatically gains focus when displayed.
  final bool autofocus;

  /// External focus node.
  final FocusNode? focusNode;

  /// Initial value when controller is null.
  final String? initialValue;

  /// Text capitalization behavior.
  final TextCapitalization textCapitalization;

  /// Accessible label override.
  final String? semanticLabel;

  /// Whether to display a required red asterisk indicator.
  final bool isRequired;

  /// Manual error text to display under the field.
  final String? errorText;

  /// Supporting helper text under the field.
  final String? helperText;

  /// Whether to obscure text for passwords or PINs.
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.formLabel.copyWith(
                    color: isDark
                        ? const Color(0xFFB0C4DE)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          TextFormField(
            controller: controller,
            initialValue: controller == null ? initialValue : null,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            onTap: onTap,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            validator: validator,
            maxLines: maxLines,
            minLines: minLines,
            readOnly: readOnly,
            enabled: enabled,
            autofocus: autofocus,
            focusNode: focusNode,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            style: AppTextStyles.inputText.copyWith(
              color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              helperText: helperText,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }
}
