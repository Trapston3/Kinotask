import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alarm_challenge.dart';
import '../providers/alarm_coordinator.dart';
import '../services/notification_service.dart';

class AlarmCaptchaScreen extends StatefulWidget {
  const AlarmCaptchaScreen({
    super.key,
    required this.session,
  });

  final AlarmChallengeSession session;

  @override
  State<AlarmCaptchaScreen> createState() => _AlarmCaptchaScreenState();
}

class _AlarmCaptchaScreenState extends State<AlarmCaptchaScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: PopScope(
        canPop: false,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'High Priority Alarm',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.session.payload.title,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.session.challenge.prompt,
                          style: theme.textTheme.bodyLarge,
                        ),
                        if (widget.session.challenge.displayValue.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            ),
                            child: Text(
                              widget.session.challenge.displayValue,
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextField(
                          key: const ValueKey<String>('alarm-answer-field'),
                          controller: _controller,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: widget.session.challenge.type ==
                                    AlarmChallengeType.math
                                ? 'Enter the answer'
                                : 'Type the phrase exactly',
                            errorText: _showError ? 'That answer is not correct.' : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _submit,
                            child: const Text('Dismiss Alarm'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final isValid = widget.session.challenge.isValidAnswer(_controller.text);
    if (!isValid) {
      setState(() {
        _showError = true;
      });
      return;
    }

    await context
        .read<NotificationService>()
        .cancelForTaskId(widget.session.payload.taskId);
    if (mounted) {
      context.read<AlarmCoordinator>().dismiss();
    }
  }
}
