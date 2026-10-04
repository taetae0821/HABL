import 'package:flutter/material.dart';
import 'auth.dart';
import 'club_manage.dart';

class Header extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const Header({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 새 공지가 오면 알람 탭에 안 읽은 개수 뱃지 표시
    return ListenableBuilder(
      listenable: Listenable.merge([clubNotices, currentUser]),
      builder: (context, _) {
        final unread = unreadNoticeCount(currentUser.value);

        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.search), label: '탐색'),
            const BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
            const BottomNavigationBarItem(icon: Icon(Icons.create), label: '개설'),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.alarm),
              ),
              label: '알람',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
          ],
        );
      },
    );
  }
}
