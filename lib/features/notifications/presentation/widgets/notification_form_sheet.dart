import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../data/notification_item_model.dart';

class NotificationFormSheet extends StatefulWidget {
  const NotificationFormSheet({
    super.key,
  });

  @override
  State<NotificationFormSheet> createState() => _NotificationFormSheetState();
}

class _NotificationFormSheetState extends State<NotificationFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _type = 'general';
  DateTime? _scheduledAt;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime initialDate = _scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) {
      return;
    }

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) {
      return;
    }

    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      NotificationItemModel(
        type: _type,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        scheduledAt: _scheduledAt,
        isRead: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppConstants.screenPadding,
        right: AppConstants.screenPadding,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'New reminder',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'general', child: Text('General')),
                  DropdownMenuItem<String>(value: 'deadline', child: Text('Deadline')),
                  DropdownMenuItem<String>(value: 'study', child: Text('Study block')),
                ],
                onChanged: (String? value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _type = value;
                  });
                },
              ),
              const SizedBox(height: AppConstants.itemSpacing),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a reminder title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.itemSpacing),
              TextFormField(
                controller: _messageController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: AppConstants.itemSpacing),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Schedule'),
                subtitle: Text(
                  _scheduledAt == null
                      ? 'Send immediately after saving'
                      : DateTimeUtils.formatDateTime(_scheduledAt!),
                ),
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    if (_scheduledAt != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _scheduledAt = null;
                          });
                        },
                        icon: const Icon(Icons.clear_rounded),
                      ),
                    const Icon(Icons.schedule_rounded),
                  ],
                ),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submit,
                child: const Text('Save reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
