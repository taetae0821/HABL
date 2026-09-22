import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

/// 지도에서 선택한 위치 결과입니다.
class ClubLocationResult {
  const ClubLocationResult({required this.latLng, required this.address});

  final LatLng latLng;
  final String address;
}

/// 카카오 지도를 탭해 모임 위치를 고르는 화면입니다.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initialLatLng});

  final LatLng? initialLatLng;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  KakaoMapController? _mapController;
  LatLng? _pickedLatLng;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _pickedLatLng = widget.initialLatLng;
  }

  Future<void> _confirm() async {
    final latLng = _pickedLatLng;
    final controller = _mapController;
    if (latLng == null || controller == null) return;

    setState(() => _isLoadingAddress = true);
    try {
      final response = await controller.coord2Address(
        Coord2AddressRequest(x: latLng.longitude, y: latLng.latitude),
      );
      final found = response.list.isNotEmpty ? response.list.first : null;
      final address = found?.roadAddress?.addressName ??
          found?.address?.addressName ??
          '주소를 찾을 수 없습니다';

      if (!mounted) return;
      Navigator.of(context)
          .pop(ClubLocationResult(latLng: latLng, address: address));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주소를 가져오지 못했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickedLatLng = _pickedLatLng;
    final markers = pickedLatLng == null
        ? const <Marker>[]
        : [Marker(markerId: 'picked', latLng: pickedLatLng)];

    return Scaffold(
      appBar: AppBar(title: const Text('모임 위치 선택')),
      body: Stack(
        children: [
          KakaoMap(
            center: widget.initialLatLng ?? LatLng(37.5665, 126.9780),
            onMapCreated: (controller) => _mapController = controller,
            onMapTap: (latLng) => setState(() => _pickedLatLng = latLng),
            markers: markers,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: KakaoMapPointerInterceptor(
              child: FilledButton(
                onPressed:
                    pickedLatLng == null || _isLoadingAddress ? null : _confirm,
                child: _isLoadingAddress
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('이 위치로 선택'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
