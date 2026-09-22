import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'location_picker_page.dart';

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
  final _descriptionController = TextEditingController();
  final _maxMemberController = TextEditingController();

  String? _selectedCategory;
  LatLng? _selectedLatLng;
  String? _selectedAddress;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxMemberController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<ClubLocationResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(initialLatLng: _selectedLatLng),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedLatLng = result.latLng;
        _selectedAddress = result.address;
      });
    }
  }

  void _submit() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    // TODO: 실제 저장/제출 로직 연결
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${_nameController.text}" 동호회가 생성되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('동호회 만들기')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '동호회 이름',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? '동호회 이름을 입력해주세요.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
              ),
              items: _clubCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
              validator: (value) => value == null ? '카테고리를 선택해주세요.' : null,
            ),
            const SizedBox(height: 16),
            FormField<LatLng>(
              validator: (_) =>
                  _selectedLatLng == null ? '지도에서 위치를 선택해주세요.' : null,
              builder: (field) {
                return InkWell(
                  onTap: () async {
                    await _pickLocation();
                    field.didChange(_selectedLatLng);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '모임 위치',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.map_outlined),
                      errorText: field.errorText,
                    ),
                    child: Text(
                      _selectedAddress ?? '지도에서 위치를 선택하세요',
                      style: _selectedAddress == null
                          ? TextStyle(color: Theme.of(context).hintColor)
                          : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '소개글',
                hintText: '동호회를 소개하는 글을 작성해주세요',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? '소개글을 입력해주세요.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxMemberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '최대 인원',
                suffixText: '명',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('동호회 만들기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
