import 'package:flutter/material.dart';

import '../../../../core/theme/studyflow_palette.dart';
import '../../../../shared/widgets/studyflow_components.dart';
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
  static const List<String> _availableColors = <String>[
    '#F97316',
    '#2563EB',
    '#0F766E',
    '#A21CAF',
    '#DC2626',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  int? _subjectId;
  late String _selectedColor;

  bool get _isEditing => widget.initialValue != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialValue?.title ?? '');
    _contentController =
        TextEditingController(text: widget.initialValue?.content ?? '');
    _subjectId = widget.initialValue?.subjectId;
    _selectedColor = widget.initialValue?.color ?? '#2563EB';
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
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: <Widget>[
                  StudyFlowCircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _isEditing
                            ? 'S\u1eeda ghi ch\u00fa'
                            : 'T\u1ea1o ghi ch\u00fa',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
                  children: <Widget>[
                    _EditorFieldCard(
                      child: TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Ti\u00eau \u0111\u1ec1 ghi ch\u00fa',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isCollapsed: true,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'H\u00e3y nh\u1eadp ti\u00eau \u0111\u1ec1 ghi ch\u00fa.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    StudyFlowSurfaceCard(
                      radius: 24,
                      color: StudyFlowPalette.surface,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'M\u00f4n h\u1ecdc',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int?>(
                            initialValue: _subjectId,
                            decoration: _fieldDecoration(),
                            items: <DropdownMenuItem<int?>>[
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Ghi ch\u00fa chung'),
                              ),
                              ...widget.subjects.map(
                                (SubjectModel subject) =>
                                    DropdownMenuItem<int?>(
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
                          const SizedBox(height: 18),
                          Text(
                            'M\u00e0u ghi ch\u00fa',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _availableColors.map((String colorHex) {
                              final Color color = Color(
                                int.parse(colorHex.replaceFirst('#', '0xFF')),
                              );
                              final bool selected = _selectedColor == colorHex;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedColor = colorHex;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: selected ? 38 : 34,
                                  height: selected ? 38 : 34,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: selected
                                        ? Border.all(
                                            color: Colors.white, width: 3)
                                        : null,
                                    boxShadow: selected
                                        ? <BoxShadow>[
                                            BoxShadow(
                                              color:
                                                  color.withValues(alpha: 0.28),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: selected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _EditorFieldCard(
                      minHeight: 260,
                      child: TextFormField(
                        controller: _contentController,
                        maxLines: null,
                        minLines: 12,
                        decoration: const InputDecoration(
                          hintText: 'N\u1ed9i dung ghi ch\u00fa...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          alignLabelWithHint: true,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 16,
                          height: 1.6,
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'H\u00e3y nh\u1eadp n\u1ed9i dung ghi ch\u00fa.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          mediaQuery.viewInsets.bottom + 20,
        ),
        child: _isEditing
            ? Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: StudyFlowPalette.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'H\u1ee7y',
                          style: TextStyle(
                            color: StudyFlowPalette.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StudyFlowGradientButton(
                      label: 'L\u01b0u',
                      onTap: _submit,
                      height: 54,
                    ),
                  ),
                ],
              )
            : StudyFlowGradientButton(
                label: 'L\u01b0u ghi ch\u00fa',
                onTap: _submit,
                height: 54,
              ),
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: StudyFlowPalette.surfaceSoft,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: StudyFlowPalette.blue),
      ),
    );
  }
}

class _EditorFieldCard extends StatelessWidget {
  const _EditorFieldCard({
    required this.child,
    this.minHeight,
  });

  final Widget child;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 84),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StudyFlowPalette.border),
        boxShadow: StudyFlowPalette.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      alignment: Alignment.topLeft,
      child: child,
    );
  }
}
