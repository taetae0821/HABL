import 'package:flutter/material.dart';
import 'theme.dart';

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

  // 테두리·배경 등 기본 모양은 앱 테마(inputDecorationTheme)를 따름
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
      prefixIcon: icon == null ? null : Icon(icon),
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
    return Scaffold(
      appBar: AppBar(title: const Text('동호회 개설하기')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _buildBanner(),
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
                dropdownColor: AppColors.surface,
                items: clubCategories
                    .map((c) => DropdownMenuItem(
                          value: c.name,
                          child: Text('${c.emoji}  ${c.name}'),
                        ))
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
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
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

  // 상단 안내 배너
  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow(AppColors.primary),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '나만의 동호회를 만들어요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '원하는 종목과 테마로\n새로운 취미 커뮤니티를 시작해 보세요',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Text('🎉', style: TextStyle(fontSize: 30)),
          ),
        ],
      ),
    );
  }
}
