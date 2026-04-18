import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../state/subject_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/subject_bottom_nav.dart';
import '../widgets/subject_card.dart';
import 'subject_detail_screen.dart';
import 'subject_form_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({required this.controller, super.key});

  final SubjectController controller;

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final subjects = widget.controller.subjects;
        final visibleSubjects = _filterSubjects(subjects);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 48, 22, 0),
                  child: _Header(onAdd: _openAddSubject),
                ),
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: _SearchField(controller: _searchController),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: _buildBody(
                    allSubjects: subjects,
                    visibleSubjects: visibleSubjects,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const SubjectBottomNav(),
        );
      },
    );
  }

  Widget _buildBody({
    required List<Subject> allSubjects,
    required List<Subject> visibleSubjects,
  }) {
    if (allSubjects.isEmpty && _query.isEmpty) {
      return _EmptySubjects(onAdd: _openAddSubject);
    }

    if (visibleSubjects.isEmpty) {
      return _NoSearchResults(query: _query);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
      itemCount: visibleSubjects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final subject = visibleSubjects[index];
        return SubjectCard(
          subject: subject,
          onTap: () => _openDetail(subject),
          onEdit: () => _openEditSubject(subject),
          onDelete: () => _confirmDelete(subject),
        );
      },
    );
  }

  List<Subject> _filterSubjects(List<Subject> subjects) {
    final query = _query.toLowerCase();
    if (query.isEmpty) {
      return subjects;
    }
    return subjects.where((subject) {
      final searchable =
          '${subject.name} ${subject.code} ${subject.teacher} ${subject.room}'
              .toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  void _handleSearchChanged() {
    setState(() => _query = _searchController.text.trim());
  }

  void _openAddSubject() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubjectFormScreen(controller: widget.controller),
      ),
    );
  }

  void _openEditSubject(Subject subject) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SubjectFormScreen(controller: widget.controller, subject: subject),
      ),
    );
  }

  void _openDetail(Subject subject) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubjectDetailScreen(
          controller: widget.controller,
          subjectId: subject.id,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Subject subject) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa môn học?'),
        content: Text('Bạn có chắc muốn xóa ${subject.name} khỏi danh sách?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    widget.controller.deleteSubject(subject.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã xóa ${subject.name}')));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Môn học',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Tooltip(
          message: 'Thêm môn học',
          child: FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm môn học...',
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.subtleText,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.subtleText,
        ),
        filled: true,
        fillColor: AppColors.backgroundSoft,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _EmptySubjects extends StatelessWidget {
  const _EmptySubjects({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Chưa có môn học',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bắt đầu bằng cách thêm các môn học của bạn để quản lý lịch học và deadline.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm môn học đầu tiên'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Text(
          'Không tìm thấy môn học phù hợp với "$query".',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.mutedText,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
