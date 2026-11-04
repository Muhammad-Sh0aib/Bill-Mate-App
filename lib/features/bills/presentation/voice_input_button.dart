import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';

class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    super.key,
    required this.fieldLabel,
    required this.onResult,
    this.enabled = true,
    this.tooltip,
  });

  final String fieldLabel;
  final ValueChanged<String> onResult;
  final bool enabled;
  final String? tooltip;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isInitializing = false;
  String _statusMessage = '';

  @override
  void dispose() {
    if (_speech.isListening) {
      _speech.cancel();
    }
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (!widget.enabled || _isInitializing) return;

    if (_isListening) {
      setState(() {
        _isListening = false;
        _statusMessage = 'Stopped';
      });
      await _speech.stop();
      return;
    }

    setState(() => _isInitializing = true);

    try {
      final initialized = await _speech.initialize(
        onError: (error) {
          if (!mounted) return;
          final message = _errorMessageFor(error);
          setState(() {
            _isListening = false;
            _statusMessage = message;
            _isInitializing = false;
          });
          _showMessage(message);
        },
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            _isListening = status == SpeechToText.listeningStatus;
            _statusMessage = _isListening ? 'Listening...' : '';
          });
        },
      );

      if (!mounted) return;
      if (!initialized) {
        setState(() {
          _isInitializing = false;
          _isListening = false;
          _statusMessage = 'Voice input is unavailable on this device.';
        });
        _showMessage('Voice input is unavailable on this device.');
        return;
      }

      final hasPermission = await _speech.hasPermission;
      if (!hasPermission) {
        setState(() {
          _isInitializing = false;
          _isListening = false;
          _statusMessage = 'Microphone permission is required for voice input.';
        });
        _showMessage(
          'Microphone permission is required for voice input. You can enable it in app settings.',
          openSettings: true,
        );
        return;
      }

      setState(() {
        _isListening = true;
        _statusMessage = 'Listening...';
        _isInitializing = false;
      });

      await _speech.listen(
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 22),
        pauseFor: const Duration(seconds: 3),
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords.trim();
          if (words.isEmpty) return;

          if (result.finalResult) {
            setState(() {
              _isListening = false;
              _statusMessage = 'Captured';
            });
            widget.onResult(words);
            _speech.stop();
          } else {
            setState(() => _statusMessage = words);
          }
        },
      );
    } catch (error) {
      if (!mounted) return;
      final message = 'Voice input could not start. Please try again.';
      setState(() {
        _isListening = false;
        _statusMessage = message;
        _isInitializing = false;
      });
      _showMessage(message);
    }
  }

  String _errorMessageFor(SpeechRecognitionError error) {
    switch (error.errorMsg) {
      case 'error_permission':
        return 'Microphone permission is required for voice input.';
      case 'error_network':
        return 'Voice input is unavailable right now. Please check your connection.';
      case 'error_speech_timeout':
        return 'No speech was detected. Please try again.';
      default:
        return 'Voice input could not process the recording. Please try again.';
    }
  }

  void _showMessage(String message, {bool openSettings = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: openSettings
            ? SnackBarAction(
                label: 'Settings',
                onPressed: () => AppSettings.openAppSettings(),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.accentLight : AppColors.accent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isListening || _statusMessage.isNotEmpty) ...[
          Text(
            _isListening ? 'Listening...' : _statusMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _isListening
                ? accentColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: IconButton(
            tooltip:
                widget.tooltip ??
                (_isListening
                    ? 'Stop listening for ${widget.fieldLabel}'
                    : 'Use voice input for ${widget.fieldLabel}'),
            onPressed: widget.enabled && !_isInitializing ? _handlePress : null,
            icon: _isInitializing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  )
                : Icon(
                    _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: _isListening ? accentColor : AppColors.primary,
                    size: 18,
                  ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: AppSpacing.touchTarget,
              height: AppSpacing.touchTarget,
            ),
            splashRadius: 18,
          ),
        ),
      ],
    );
  }
}
