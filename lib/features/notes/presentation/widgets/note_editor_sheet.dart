import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../subjects/data/subject_model.dart';
import '../../data/note_model.dart';

class NoteEditorSheet extends StatefulWidget {
  const NoteEditorSheet({
    super.key,
    required this.subjects,
    this.initialValue,
  });

  final List<SubjectModel> subjects;
  final NoteModel? initialValue;

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  int? _subjectId;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialValue?.title ?? '');
    _contentController = TextEditingController(text: widget.initialValue?.content ?? '');
    _subjectId = widget.initialValue?.subjectId;
    _selectedColor = widget.initialValue?.color ?? '#F97316';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final DateTime now = DateTime.now();
    Navigator.of(context).pop(
      NoteModel(
        id: widget.initialValue?.id,
        subjectId: _subjectId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        color: _selectedColor,
        createdAt: widget.initialValue?.createdAt ?? now,
        updatedAt: now,
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
                widget.initialValue == null ? 'Add note' : 'Edit note',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: _subjectId,
                decoration: const InputDecoration(labelText: 'Subject'),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('General note'),
                  ),
                  ...widget.subjects.map(
                    (SubjectModel subject) => DropdownMenuItem<int?>(
                      value: subject.id,
                      child: Text(subject.name),
                    ),
                  ),
                ],
                onChanged: (int? value) {
                  setState(() {
                    _subjectId = value;
                  });
                },
              ),
              const SizedBox(height: AppConstants.itemSpacing),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a note title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.itemSpacing),
              TextFormField(
                controller: _contentController,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(labelText: 'Content'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter note content.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.itemSpacing),
              Text('Color', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const <String>[
                  '#F97316',
                  '#2563EB',
                  '#0F766E',
                  '#A21CAF',
                  '#DC2626',
                ].map((String colorHex) {
                  final Color color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                  final bool selected = _selectedColor == colorHex;
                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      setState(() {
                        _selectedColor = colorHex;
                      });
                    },
                    child: CircleAvatar(
                      radius: selected ? 18 : 16,
                      backgroundColor: color,
                      child: selected
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submit,
                child: const Text('Save note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
