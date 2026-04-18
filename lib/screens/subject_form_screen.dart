import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/subject.dart';
import '../state/subject_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/subject_card.dart';

class SubjectFormScreen extends StatefulWidget {
  const SubjectFormScreen({required this.controller, this.subject, super.key});

  final SubjectController controller;
  final Subject? subject;

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  static const List<Color> _palette = [
    Color(0xFF6366F1),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFEF4444),
    Color(0xFF64748B),
  ];

  static const List<String> _days = [
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'Chủ nhật',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _creditsController;
  late final TextEditingController _teacherController;
  late final TextEditingController _timeController;
  late final TextEditingController _roomController;
  late final TextEditingController _descriptionController;
  late Color _selectedColor;
  late String _selectedDay;
  late double _progress;

  bool get _isEditing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    final subject = widget.subject;
    _nameController = TextEditingController(text: subject?.name ?? '');
    _codeController = TextEditingController(text: subject?.code ?? '');
    _creditsController = TextEditingController(
      text: (subject?.credits ?? 3).toString(),
    );
    _teacherController = TextEditingController(text: subject?.teacher ?? '');
    _timeController = TextEditingController(
      text: subject?.time ?? '7:00 - 9:30',
    );
    _roomController = TextEditingController(text: subject?.room ?? '');
    _descriptionController = TextEditingController(
      text: subject?.description ?? '',
    );
    _selectedColor = subject?.color ?? _palette.first;
    _selectedDay = subject?.day ?? _days.first;
    _progress = subject?.progress ?? 0.5;

    for (final controller in [
      _nameController,
      _codeController,
      _creditsController,
      _teacherController,
      _timeController,
      _roomController,
    ]) {
      controller.addListener(_refreshPreview);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _codeController,
      _creditsController,
      _teacherController,
      _timeController,
      _roomController,
      _descriptionController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 34, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      minimumSize: const Size(42, 42),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Sửa môn học' : 'Thêm môn học',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
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
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
                  children: [
                    _SectionLabel(label: 'Màu sắc'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final color in _palette)
                          _ColorDot(
                            color: color,
                            isSelected: color == _selectedColor,
                            onTap: () => setState(() => _selectedColor = color),
                          ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    _SubjectTextField(
                      controller: _nameController,
                      label: 'Tên môn học',
                      hintText: 'VD: UX/UI Design',
                      textInputAction: TextInputAction.next,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _SubjectTextField(
                            controller: _codeController,
                            label: 'Mã môn',
                            hintText: 'VD: CS401',
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            validator: _requiredValidator,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SubjectTextField(
                            controller: _creditsController,
                            label: 'Số tín chỉ',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.next,
                            validator: _creditsValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SubjectTextField(
                      controller: _teacherController,
                      label: 'Giảng viên',
                      hintText: 'Tên giảng viên',
                      textInputAction: TextInputAction.next,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedDay,
                            decoration: _fieldDecoration(context, 'Ngày học'),
                            borderRadius: BorderRadius.circular(16),
                            items: [
                              for (final day in _days)
                                DropdownMenuItem<String>(
                                  value: day,
                                  child: Text(day),
                                ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() => _selectedDay = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SubjectTextField(
                            controller: _roomController,
                            label: 'Phòng học',
                            hintText: 'A301',
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            validator: _requiredValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SubjectTextField(
                      controller: _timeController,
                      label: 'Giờ học',
                      hintText: '7:00 - 9:30',
                      textInputAction: TextInputAction.next,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const _SectionLabel(label: 'Tiến độ học tập'),
                        const Spacer(),
                        Text(
                          '${(_progress * 100).round()} %',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _progress,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      activeColor: _selectedColor,
                      inactiveColor: AppColors.divider,
                      onChanged: (value) => setState(() => _progress = value),
                    ),
                    const SizedBox(height: 8),
                    _SubjectTextField(
                      controller: _descriptionController,
                      label: 'Mô tả',
                      hintText: 'Mô tả nội dung môn học',
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel(label: 'Preview'),
                    const SizedBox(height: 12),
                    IgnorePointer(
                      child: SubjectCard(
                        subject: _previewSubject,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: _isEditing ? _buildEditActions() : _buildAddAction(),
        ),
      ),
    );
  }

  Widget _buildAddAction() {
    return FilledButton.icon(
      onPressed: _save,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Thêm môn học'),
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(onPressed: _save, child: const Text('Lưu')),
        ),
      ],
    );
  }

  Subject get _previewSubject {
    return Subject(
      id: widget.subject?.id ?? 'preview',
      name: _nameController.text.trim().isEmpty
          ? 'Tên môn học'
          : _nameController.text.trim(),
      code: _codeController.text.trim().isEmpty
          ? 'CODE'
          : _codeController.text.trim().toUpperCase(),
      credits: int.tryParse(_creditsController.text.trim()) ?? 3,
      teacher: _teacherController.text.trim().isEmpty
          ? 'Tên giảng viên'
          : _teacherController.text.trim(),
      day: _selectedDay,
      time: _timeController.text.trim().isEmpty
          ? '7:00 - 9:30'
          : _timeController.text.trim(),
      room: _roomController.text.trim().isEmpty
          ? 'A301'
          : _roomController.text.trim().toUpperCase(),
      progress: _progress,
      color: _selectedColor,
      description: _normalizedDescription,
    );
  }

  String get _normalizedDescription {
    final description = _descriptionController.text.trim();
    if (description.isNotEmpty) {
      return description;
    }
    return 'Môn học này giúp bạn theo dõi lịch học, tiến độ và các thông tin quan trọng trong học kỳ.';
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final subject = _previewSubject.copyWith(id: widget.subject?.id ?? 'new');
    if (_isEditing) {
      widget.controller.updateSubject(subject);
    } else {
      widget.controller.addSubject(subject);
    }
    Navigator.of(context).pop();
  }

  void _refreshPreview() {
    setState(() {});
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.mutedText,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _selectedColor, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Không được để trống';
    }
    return null;
  }

  String? _creditsValidator(String? value) {
    final credits = int.tryParse(value ?? '');
    if (credits == null || credits <= 0) {
      return 'Nhập số tín chỉ';
    }
    if (credits > 10) {
      return 'Tối đa 10';
    }
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SubjectTextField extends StatelessWidget {
  const _SubjectTextField({
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.subtleText,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Chọn màu',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 44,
          padding: EdgeInsets.all(isSelected ? 4 : 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
