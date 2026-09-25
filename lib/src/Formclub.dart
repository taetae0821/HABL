import 'package:flutter/material.dart';

const List<String> _clubCategories = [
  '운동',
  '스터디',
  '음악',
  '미술/공예',
  '여행',
  '게임',
  '봉사활동',
  '기타',
];

class Formclub extends StatefulWidget {
  const Formclub({super.key});

  @override
  State<Formclub> createState() => _FormclubState();
}

class _FormclubState extends State<Formclub> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxMemberController = TextEditingController();

  String? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _maxMemberController.dispose();
    super.dispose();
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    IconData? icon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      prefixIcon: icon == null ? null : Icon(icon, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.4),
      ),
    );
  }

  void _submit() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${_nameController.text}" 동호회가 생성되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      appBar: AppBar(
        title: const Text('동호회 개설하기'),
        backgroundColor: const Color(0xFFF7F6FB),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.groups_2_rounded, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                '원하는 종목과 테마로 새로운 취미 커뮤니티를 만듭니다',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _nameController,
                decoration: _decoration(
                  label: '동호회 이름',
                  hint: '개성 넘치는 이름을 써주세요!',
                  icon: Icons.badge_outlined,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? '동호회 이름을 입력해주세요.'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _decoration(label: '카테고리', icon: Icons.category_outlined),
                borderRadius: BorderRadius.circular(14),
                items: _clubCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? '카테고리를 선택해주세요.' : null,
              ),
              const SizedBox(height: 16),
              // TODO: 임시 위치 입력칸 - 추후 카카오맵 위치 선택으로 교체
              TextFormField(
                controller: _locationController,
                decoration: _decoration(
                  label: '위치',
                  hint: '주요 모임 장소를 써주세요!',
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _decoration(
                  label: '소개글',
                  hint: '동호회를 소개하는 글을 작성해주세요',
                ).copyWith(alignLabelWithHint: true),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? '소개글을 입력해주세요.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxMemberController,
                keyboardType: TextInputType.number,
                decoration: _decoration(
                  label: '최대 인원',
                  icon: Icons.people_alt_outlined,
                  suffixText: '명',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '최대 인원을 입력해주세요.';
                  }
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) return '올바른 숫자를 입력해주세요.';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    onPressed: _submit,
                    child: const Text('동호회 만들기'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
