import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_refresh_notifier.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../subjects/data/subject_model.dart';
import '../data/note_model.dart';
import '../data/note_repository.dart';
import 'widgets/note_editor_sheet.dart';

class NoteDetailPage extends StatefulWidget {
  const NoteDetailPage({
    super.key,
    required this.note,
    required this.repository,
    required this.subjects,
  });

  final NoteModel note;
  final NoteRepository repository;
  final List<SubjectModel> subjects;

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late NoteModel _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  Future<void> _editNote() async {
    final AppRefreshNotifier refreshNotifier =
        context.read<AppRefreshNotifier>();
    final NoteModel? updated = await Navigator.of(context).push<NoteModel>(
      MaterialPageRoute<NoteModel>(
        builder: (BuildContext context) => NoteEditorSheet(
          initialValue: _note,
          subjects: widget.subjects,
        ),
      ),
    );
    if (updated == null) {
      return;
    }
    await widget.repository.saveNote(updated);
    if (!mounted) {
      return;
    }
    refreshNotifier.markDirty();
    final int? noteId = updated.id;
    if (noteId == null) {
      return;
    }
    final NoteModel? refreshed = await widget.repository.getNoteById(noteId);
    if (!mounted || refreshed == null) {
      return;
    }
    setState(() {
      _note = refreshed;
    });
  }

  Future<void> _deleteNote() async {
    final int? id = _note.id;
    if (id == null) {
      return;
    }
    final AppRefreshNotifier refreshNotifier =
        context.read<AppRefreshNotifier>();
    final bool confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'X\u00f3a ghi ch\u00fa?',
      message:
          '"${_note.title}" s\u1ebd b\u1ecb x\u00f3a kh\u1ecfi danh s\u00e1ch ghi ch\u00fa.',
      confirmLabel: 'X\u00f3a',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    await widget.repository.deleteNote(id);
    if (!mounted) {
      return;
    }
    refreshNotifier.markDirty();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
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
                  const Spacer(),
                  StudyFlowCircleIconButton(
                    icon: Icons.edit_outlined,
                    size: 42,
                    onTap: _editNote,
                  ),
                  const SizedBox(width: 10),
                  StudyFlowCircleIconButton(
                    icon: Icons.delete_outline_rounded,
                    size: 42,
                    backgroundColor: const Color(0xFFFFF1EE),
                    foregroundColor: StudyFlowPalette.red,
                    onTap: _deleteNote,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
                children: <Widget>[
                  Text(
                    _note.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _NoteMetaChip(
                        icon: Icons.book_outlined,
                        label: _note.subjectName ?? 'Ghi ch\u00fa chung',
                      ),
                      _NoteMetaChip(
                        icon: Icons.calendar_today_outlined,
                        label: DateTimeUtils.toDbDate(_note.updatedAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  StudyFlowSurfaceCard(
                    radius: 28,
                    padding: const EdgeInsets.all(20),
                    child: SelectableText(
                      _note.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF334155),
                            height: 1.65,
                            fontSize: 16,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteMetaChip extends StatelessWidget {
  const _NoteMetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: StudyFlowPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
