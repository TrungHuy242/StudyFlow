import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../semester/data/semester_repository.dart';
import '../data/subject_model.dart';
import '../data/subject_repository.dart';

class SubjectEditorPage extends StatefulWidget {
  const SubjectEditorPage({
    super.key,
    this.subjectId,
  });

  final int? subjectId;

  @override
  State<SubjectEditorPage> createState() => _SubjectEditorPageState();
}

class _SubjectEditorPageState extends State<SubjectEditorPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController(text: '3');
  final TextEditingController _teacherController = TextEditingController();
  late final SubjectRepository _subjectRepository;
  late final SemesterRepository _semesterRepository;
  bool _initialized = false;
  int? _semesterId;
  String _selectedColor = '#6F62FF';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final DatabaseService databaseService = context.read<DatabaseService>();
    _subjectRepository = SubjectRepository(databaseService);
    _semesterRepository = SemesterRepository(databaseService);
    _bootstrap();
    _initialized = true;
  }

  Future<void> _bootstrap() async {
    final subjectId = widget.subjectId;
    if (subjectId != null) {
      final SubjectModel? subject = await _subjectRepository.getSubjectById(subjectId);
      if (subject != null && mounted) {
        setState(() {
          _nameController.text = subject.name;
          _codeController.text = subject.code;
          _creditsController.text = subject.credits.toString();
          _teacherController.text = subject.teacher;
          _selectedColor = subject.color;
          _semesterId = subject.semesterId;
        });
      }
      return;
    }
    final activeSemester = await _semesterRepository.getActiveSemester();
    if (mounted) {
      setState(() {
        _semesterId = activeSemester?.id;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _creditsController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _subjectRepository.saveSubject(
      SubjectModel(
        id: widget.subjectId,
        semesterId: _semesterId,
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        color: _selectedColor,
        credits: int.parse(_creditsController.text.trim()),
        teacher: _teacherController.text.trim(),
        room: '',
        note: '',
      ),
    );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final Color previewColor = Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')));
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    StudyFlowCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.subjectId == null ? 'Thêm môn học' : 'Sửa môn học',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 26),
                Text('Màu sắc', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppConstants.subjectPalette.map((Color color) {
                    final String hex = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                    final bool selected = hex == _selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: selected ? Border.all(color: Colors.white, width: 2) : null,
                          boxShadow: selected ? const <BoxShadow>[BoxShadow(color: Color(0x22000000), blurRadius: 10)] : null,
                        ),
                        child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                StudyFlowInput(
                  controller: _nameController,
                  label: 'Tên môn học',
                  hintText: 'VD: UX/UI Design',
                  validator: (String? value) => value == null || value.trim().isEmpty ? 'Nhập tên môn học.' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StudyFlowInput(
                        controller: _codeController,
                        label: 'Mã môn',
                        hintText: 'VD: CS401',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StudyFlowInput(
                        controller: _creditsController,
                        label: 'Số tín chỉ',
                        keyboardType: TextInputType.number,
                        validator: (String? value) {
                          final int? credits = int.tryParse(value ?? '');
                          return credits == null || credits <= 0 ? 'Không hợp lệ' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                StudyFlowInput(
                  controller: _teacherController,
                  label: 'Giảng viên',
                  hintText: 'Tên giảng viên',
                ),
                const SizedBox(height: 20),
                Text('Preview', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                StudyFlowSurfaceCard(
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: previewColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(_nameController.text.isEmpty ? 'Tên môn học' : _nameController.text),
                            const SizedBox(height: 4),
                            Text(
                              '${_codeController.text.isEmpty ? 'CODE' : _codeController.text} • ${_creditsController.text.isEmpty ? '3' : _creditsController.text} tín chỉ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (widget.subjectId != null)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StudyFlowOutlineButton(label: 'Hủy', onTap: () => context.pop()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StudyFlowGradientButton(label: 'Lưu', onTap: _save),
                      ),
                    ],
                  )
                else
                  StudyFlowGradientButton(
                    label: 'Thêm môn học',
                    onTap: _save,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

