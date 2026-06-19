import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DetailVideoPage extends StatefulWidget {
  final Map<String, dynamic> content;

  const DetailVideoPage({super.key, required this.content});

  @override
  State<DetailVideoPage> createState() => DetailVideoPageState();
}

class DetailVideoPageState extends State<DetailVideoPage> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _isPlaying = false;
  String? _errorMessage;

  late final String _title;
  late final String _mentorName;
  late final String _description;
  late final String _videoUrl;
  late final String _thumbnailUrl;
  late final DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _title = _parseString(widget.content, [
      'title',
      'judul',
      'name',
      'className',
      'class_name',
    ], fallback: 'Konten Mentor');
    _mentorName = _parseString(widget.content, [
      'mentorName',
      'mentor_name',
      'mentor',
      'instructorName',
      'instructor',
      'teacherName',
    ], fallback: 'Mentor');
    _description = _parseString(widget.content, [
      'description',
      'desc',
      'detail',
    ], fallback: 'Tidak ada deskripsi.');
    _videoUrl = _parseString(widget.content, [
      'videoUrl',
      'video_url',
      'video',
      'url',
      'contentUrl',
      'content_url',
    ]);
    _thumbnailUrl = _parseString(widget.content, [
      'photoUrl',
      'photo_url',
      'thumbnailUrl',
      'thumbnail_url',
      'thumbnail',
      'imageUrl',
      'image_url',
      'coverUrl',
    ]);
    _createdAt = _parseCreatedAt(widget.content['createdAt']);
    _initializePlayer();
  }

  String _parseString(Map<String, dynamic> source, List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  DateTime? _parseCreatedAt(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatCreatedAt(DateTime? date) {
    if (date == null) return 'Tanggal tidak tersedia';
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final month = monthNames[(date.month - 1).clamp(0, 11)];
    return '${date.day.toString().padLeft(2, '0')} $month ${date.year}';
  }

  String _resolveCloudinaryUrl(String url) {
    if (url.isEmpty || !url.contains('cloudinary.com')) return url;
    if (url.contains('/image/upload/')) {
      url = url.replaceFirst('/image/upload/', '/video/upload/');
    } else if (url.contains('/raw/upload/')) {
      url = url.replaceFirst('/raw/upload/', '/video/upload/');
    } else if (!url.contains('/video/upload/') && url.contains('/upload/')) {
      url = url.replaceFirst('/upload/', '/video/upload/');
    }
    if (url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.webm')) {
      return url;
    }
    const transform = 'vc_h264,ac_aac,f_mp4,q_auto';
    const marker = '/video/upload/';
    final idx = url.indexOf(marker);
    if (idx < 0) return url;
    final before = url.substring(0, idx + marker.length);
    final after = url.substring(idx + marker.length);
    return '$before$transform/$after';
  }

  Future<void> _initializePlayer() async {
    final resolvedUrl = _resolveCloudinaryUrl(_videoUrl);
    if (resolvedUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Video belum tersedia untuk konten ini.';
      });
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(1.0);
      controller.addListener(_updatePlayingState);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat video. Pastikan URL benar dan dapat diakses.';
      });
      debugPrint('DetailVideoPage init error: $error');
    }
  }

  void _updatePlayingState() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final isPlaying = controller.value.isPlaying;
    if (isPlaying != _isPlaying) {
      setState(() => _isPlaying = isPlaying);
    }
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_updatePlayingState);
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildVideoContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_controller != null && _controller!.value.isInitialized)
                VideoPlayer(_controller!)
              else if (_thumbnailUrl.isNotEmpty)
                Image.network(
                  _thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const ColoredBox(color: Colors.black),
                )
              else
                const ColoredBox(color: Colors.black),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              if (_errorMessage != null)
                Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              if (!_isLoading && _errorMessage == null)
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    color: Colors.black26,
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12,
                          child: _controller?.value.isInitialized == true
                              ? _buildProgressIndicator(_controller!)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(VideoPlayerController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          final duration = value.duration;
          final position = value.position;
          final progress = duration.inMilliseconds > 0
              ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
              : 0.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: progress,
                onChanged: (newValue) {
                  final seekTo = Duration(milliseconds: (duration.inMilliseconds * newValue).round());
                  controller.seekTo(seekTo);
                },
                activeColor: Colors.white,
                inactiveColor: Colors.white24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Detail Video'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildVideoContent(),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _mentorName,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatCreatedAt(_createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
