import 'package:flutter/material.dart';
import 'package:habl/src/club.dart';

const Color _primary = Color(0xFF4A4EED);
const Color _primaryLight = Color(0xFFEEEEFF);
const Color _background = Color(0xFFF7F7FB);

// 동호회 개설 폼(Formclub)의 카테고리와 동일
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

class ClubSummary {
  const ClubSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.locationName,
    this.regularMeetingInfo,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String category;
  final String description;
  final String locationName;
  final String? regularMeetingInfo;
  final String? imageUrl;

  factory ClubSummary.fromJson(Map<String, dynamic> json) {
    return ClubSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category_name'] as String,
      description: json['description'] as String,
      locationName: json['location_name'] as String,
      regularMeetingInfo: json['regular_meeting_info'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class FindClub extends StatefulWidget {
  const FindClub({super.key});

  @override
  State<FindClub> createState() => _FindClubState();
}

class _FindClubState extends State<FindClub> {
  List<ClubSummary> _clubs = [];
  bool _isLoading = true;

  final _searchController = TextEditingController();
  String _query = '';

  // 조건 조회 (null이면 전체)
  String? _selectedCategory;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 위치 선택지: 등록된 동호회들의 위치에서 중복 없이 뽑음
  List<String> get _locations {
    return _clubs.map((club) => club.locationName).toSet().toList()..sort();
  }

  bool get _hasCondition =>
      _query.trim().isNotEmpty ||
      _selectedCategory != null ||
      _selectedLocation != null;

  // 검색어 + 카테고리 + 위치 조건을 모두 만족하는 동호회만 표시
  List<ClubSummary> get _filteredClubs {
    final query = _query.trim().toLowerCase();

    return _clubs.where((club) {
      if (_selectedCategory != null && club.category != _selectedCategory) {
        return false;
      }
      if (_selectedLocation != null && club.locationName != _selectedLocation) {
        return false;
      }
      if (query.isEmpty) return true;
      return [
        club.name,
        club.category,
        club.description,
        club.locationName,
      ].any((field) => field.toLowerCase().contains(query));
    }).toList();
  }

  // TODO: DB 연결 후 서버에서 동호회 목록을 받아오도록 교체
  // (예: GET /clubs 응답을 ClubSummary.fromJson으로 변환, 최신순 정렬)
  // imageUrl은 DB clubs.image_url 값
  // (아래는 임시 샘플 이미지: assets/sample 사진은 Wikimedia Commons의 CC0 사진)
  Future<void> _loadClubs() async {
    setState(() {
      _clubs = const [
        ClubSummary(
          id: 1,
          name: '스매시 파크 성동',
          category: '운동',
          description: '초보부터 실력자까지 함께 즐기는 배드민턴 모임입니다.',
          locationName: '서울 성동구',
          regularMeetingInfo: '매주 토요일 오후 2시',
          imageUrl: 'assets/badminton_img.png',
        ),
        ClubSummary(
          id: 2,
          name: '주말 북클럽',
          category: '스터디',
          description: '한 달에 한 권, 같이 읽고 이야기 나눠요.',
          locationName: '서울 마포구',
          regularMeetingInfo: '격주 일요일 오전 11시',
          imageUrl: 'assets/sample/book_club.jpg',
        ),
        ClubSummary(
          id: 3,
          name: '한강 러닝크루',
          category: '운동',
          description: '퇴근 후 한강에서 같이 5km 달려요.',
          locationName: '서울 마포구',
          regularMeetingInfo: '매주 수요일 오후 8시',
          imageUrl: 'assets/sample/running_club.jpg',
        ),
        ClubSummary(
          id: 4,
          name: '성수 통기타 모임',
          category: '음악',
          description: '기타 초보도 환영! 좋아하는 노래를 함께 연주해요.',
          locationName: '서울 성동구',
          regularMeetingInfo: '매주 금요일 오후 7시',
          imageUrl: 'assets/sample/guitar_club.jpg',
        ),
      ];
      _isLoading = false;
    });
  }

  void _openClub(ClubSummary club) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Club(
          clubName: club.name,
          clubId: club.id,
          imageUrl: club.imageUrl,
          location: club.locationName,
          meetingTime: club.regularMeetingInfo,
        ),
      ),
    );
  }

  // 조건 선택 바텀시트 (선택하면 값, '전체'면 null 반환)
  Future<void> _pickCondition({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) async {
    final result = await showModalBottomSheet<_Pick>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in [null, ...options])
                    ChoiceChip(
                      label: Text(option ?? '전체'),
                      selected: option == selected,
                      showCheckmark: false,
                      selectedColor: _primary,
                      backgroundColor: _background,
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: option == selected
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => Navigator.pop(context, _Pick(option)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // 바깥을 눌러 닫은 경우(result == null)는 변경하지 않음
    if (result != null) setState(() => onSelected(result.value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        title: const Text(
          '동호회 찾기',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildConditionBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '동호회 이름, 종목, 지역으로 검색',
          hintStyle: const TextStyle(color: Colors.black38),
          prefixIcon: const Icon(Icons.search, color: Colors.black38),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: Colors.black38),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: _primary, width: 1.4),
          ),
        ),
      ),
    );
  }

  // 카테고리 / 위치 조건 선택 버튼
  Widget _buildConditionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          _ConditionButton(
            label: '카테고리',
            value: _selectedCategory,
            onTap: () => _pickCondition(
              title: '카테고리 선택',
              options: _clubCategories,
              selected: _selectedCategory,
              onSelected: (value) => _selectedCategory = value,
            ),
          ),
          const SizedBox(width: 8),
          _ConditionButton(
            label: '위치',
            value: _selectedLocation,
            onTap: () => _pickCondition(
              title: '위치 선택',
              options: _locations,
              selected: _selectedLocation,
              onSelected: (value) => _selectedLocation = value,
            ),
          ),
          const Spacer(),
          if (_selectedCategory != null || _selectedLocation != null)
            TextButton.icon(
              onPressed: () => setState(() {
                _selectedCategory = null;
                _selectedLocation = null;
              }),
              style: TextButton.styleFrom(foregroundColor: Colors.black45),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('초기화'),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final clubs = _filteredClubs;

    // 아래로 당기면 새로 만들어진 동호회까지 다시 불러옴
    return RefreshIndicator(
      onRefresh: _loadClubs,
      child: clubs.isEmpty
          ? _buildEmpty(_hasCondition ? '조건에 맞는 동호회가 없어요' : '아직 등록된 동호회가 없어요')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: clubs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) => _ClubCard(
                club: clubs[index],
                onTap: () => _openClub(clubs[index]),
              ),
            ),
    );
  }

  Widget _buildEmpty(String message) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.groups_outlined, size: 56, color: Colors.black26),
        const SizedBox(height: 12),
        Center(
          child: Text(
            message,
            style: const TextStyle(fontSize: 15, color: Colors.black45),
          ),
        ),
      ],
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club, required this.onTap});

  final ClubSummary club;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        club.category,
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      club.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      club.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MetaText(
                      icon: Icons.location_on_outlined,
                      text: club.locationName,
                    ),
                    if (club.regularMeetingInfo != null) ...[
                      const SizedBox(height: 2),
                      _MetaText(
                        icon: Icons.schedule,
                        text: club.regularMeetingInfo!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // DB에 저장된 대표 이미지(image_url) 표시
  // URL이 없거나 불러오기 실패하면 상세 페이지와 같은 기본 이미지 사용
  Widget _buildThumbnail() {
    const double size = 96;
    final placeholder = Image.asset(
      'assets/badminton_img.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
    final url = club.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: (url == null || url.isEmpty)
          ? placeholder
          : url.startsWith('assets/')
          ? Image.asset(url, width: size, height: size, fit: BoxFit.cover)
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(width: size, height: size, color: _background);
              },
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
    );
  }
}

// 바텀시트 결과 ('전체' 선택 시 value == null)
class _Pick {
  const _Pick(this.value);

  final String? value;
}

class _ConditionButton extends StatelessWidget {
  const _ConditionButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = value != null;

    return Material(
      color: isSelected ? _primary : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value ?? label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: isSelected ? Colors.white : Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black38),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ),
      ],
    );
  }
}
