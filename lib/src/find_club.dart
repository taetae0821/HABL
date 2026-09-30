import 'package:flutter/material.dart';
import 'package:habl/src/club.dart';
import 'package:habl/src/theme.dart';

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
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (final option in [null, ...options])
                    ChoiceChip(
                      label: Text(option ?? '전체'),
                      selected: option == selected,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
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
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(),
            _buildSearchBar(),
            _buildCategoryBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // 상단 인사 + 위치 선택
  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요 👋',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '오늘은 어떤 모임에\n함께할까요?',
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _LocationButton(
            value: _selectedLocation,
            onTap: () => _pickCondition(
              title: '어느 지역에서 찾을까요?',
              options: _locations,
              selected: _selectedLocation,
              onSelected: (value) => _selectedLocation = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow(),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: '동호회 이름, 종목, 지역으로 검색',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }

  // 카테고리 가로 스크롤 칩 ('전체' + 각 카테고리)
  Widget _buildCategoryBar() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _CategoryChip(
            emoji: '🌈',
            label: '전체',
            color: AppColors.textPrimary,
            selected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          for (final category in clubCategories)
            _CategoryChip(
              emoji: category.emoji,
              label: category.name,
              color: category.color,
              selected: _selectedCategory == category.name,
              onTap: () => setState(() => _selectedCategory =
                  _selectedCategory == category.name ? null : category.name),
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
      color: AppColors.primary,
      onRefresh: _loadClubs,
      child: clubs.isEmpty
          ? _buildEmpty(_hasCondition ? '조건에 맞는 동호회가 없어요' : '아직 등록된 동호회가 없어요')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              itemCount: clubs.length + 1,
              separatorBuilder: (context, index) =>
                  SizedBox(height: index == 0 ? 12 : 14),
              itemBuilder: (context, index) {
                if (index == 0) return _buildListHeader(clubs.length);
                final club = clubs[index - 1];
                return _ClubCard(club: club, onTap: () => _openClub(club));
              },
            ),
    );
  }

  Widget _buildListHeader(int count) {
    return Row(
      children: [
        Text(
          _hasCondition ? '찾은 동호회' : '새로 올라온 동호회',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const Spacer(),
        if (_hasCondition)
          TextButton.icon(
            onPressed: () => setState(() {
              _selectedCategory = null;
              _selectedLocation = null;
              _searchController.clear();
              _query = '';
            }),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('초기화'),
          ),
      ],
    );
  }

  Widget _buildEmpty(String message) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Text('🔍', style: TextStyle(fontSize: 38)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
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
    final category = categoryOf(club.category);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow(),
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: category.light,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${category.emoji} ${club.category}',
                          style: TextStyle(
                            color: category.dark,
                            fontSize: 11.5,
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
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        club.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MetaText(
                        icon: Icons.place_rounded,
                        text: club.locationName,
                      ),
                      if (club.regularMeetingInfo != null) ...[
                        const SizedBox(height: 3),
                        _MetaText(
                          icon: Icons.schedule_rounded,
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
      ),
    );
  }

  // DB에 저장된 대표 이미지(image_url) 표시
  // URL이 없거나 불러오기 실패하면 상세 페이지와 같은 기본 이미지 사용
  Widget _buildThumbnail() {
    const double size = 100;
    final placeholder = Image.asset(
      'assets/badminton_img.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
    final url = club.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
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
                return Container(
                  width: size,
                  height: size,
                  color: AppColors.primaryLight,
                );
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

// 상단 오른쪽 위치 선택 버튼
class _LocationButton extends StatelessWidget {
  const _LocationButton({required this.value, required this.onTap});

  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = value != null;
    final foreground = isSelected ? Colors.white : AppColors.secondary;

    return Material(
      color: isSelected ? AppColors.secondary : AppColors.secondaryLight,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_rounded, size: 16, color: foreground),
              const SizedBox(width: 3),
              Text(
                value ?? '전체 지역',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? color : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: selected ? color : AppColors.border),
            ),
            child: Text(
              '$emoji $label',
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
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
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
