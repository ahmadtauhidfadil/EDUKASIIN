// import 'dart:async';
// import 'package:edukasin/pages/detail_video_page.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:video_player/video_player.dart';

// class VideoPlayerPage extends StatefulWidget {
//   final String videoUrl;
//   final String title;
//   final String mentorName;
//   final String thumbnailUrl;

//   const VideoPlayerPage({
//     super.key,
//     required this.videoUrl,
//     required this.title,
//     required this.mentorName,
//     required this.thumbnailUrl,
//   });

//   @override
//   State<VideoPlayerPage> createState() => _VideoPlayerPageState();
// }

// class _VideoPlayerPageState extends State<VideoPlayerPage> {
//   VideoPlayerController? _controller;
//   bool _isInitializing = true;
//   bool _isPlaying = false;
//   bool _isInitialized = false;
//   bool _isFullscreen = false;
//   bool _showControls = true;
//   String? _errorMessage;
//   Timer? _timeoutTimer;
//   Timer? _hideControlsTimer;

//   // FIX: Simpan URL yang benar-benar dipakai untuk ditampilkan saat debug
//   String _activeUrl = '';

//   @override
//   void initState() {
//     super.initState();
//     _initializeVideo();
//   }

//   // ---------------------------------------------------------
//   // CLOUDINARY URL RESOLVER (diperbaiki total)
//   // ---------------------------------------------------------
//   // Penyebab "layar hitam": URL Cloudinary sering tersimpan sebagai
//   // /image/upload/ atau /raw/upload/ alih-alih /video/upload/.
//   // Memasang transformasi video (vc_h264) pada path non-video, atau
//   // membiarkan codec yang tak didukung (HEVC), menghasilkan controller
//   // yang "initialized" tapi tanpa frame -> layar hitam.
//   String _resolveCloudinaryUrl(String url) {
//     if (!url.contains('cloudinary.com')) {
//       return url; // bukan cloudinary, kembalikan apa adanya
//     }

//     // 1. Paksa delivery type menjadi /video/upload/
//     if (url.contains('/image/upload/')) {
//       url = url.replaceFirst('/image/upload/', '/video/upload/');
//     } else if (url.contains('/raw/upload/')) {
//       url = url.replaceFirst('/raw/upload/', '/video/upload/');
//     } else if (!url.contains('/video/upload/') && url.contains('/upload/')) {
//       url = url.replaceFirst('/upload/', '/video/upload/');
//     }

//     const marker = '/video/upload/';
//     final idx = url.indexOf(marker);
//     if (idx == -1) return url;

//     final before = url.substring(0, idx + marker.length);
//     final after = url.substring(idx + marker.length);

//     // 2. Jika sudah ada transformasi codec, jangan ditimpa
//     if (after.startsWith('vc_') ||
//         after.contains('/vc_') ||
//         after.startsWith('f_')) {
//       return url;
//     }

//     // FIX: Jika URL sudah berakhiran .mp4 dan sudah /video/upload/,
//     // JANGAN tambah transformasi. URL sudah siap putar. Menambah
//     // transcode justru memicu proses transcoding lama di Cloudinary
//     // (timeout) atau hasil yang kadang gagal di sebagian device.
//     final lower = url.toLowerCase();
//     if (lower.endsWith('.mp4') ||
//         lower.endsWith('.mov') ||
//         lower.endsWith('.webm')) {
//       return url; // pakai apa adanya
//     }

//     // 3. Untuk URL tanpa ekstensi, sisipkan transformasi + paksa .mp4
//     const transform = 'vc_h264,ac_aac,f_mp4,q_auto';
//     return '$before$transform/$after';
//   }

//   // FIX: Daftar kandidat URL untuk dicoba berurutan.
//   List<String> get _candidateUrls {
//     final original = widget.videoUrl.trim();
//     final resolved = _resolveCloudinaryUrl(original);
//     final list = <String>[];
//     if (resolved.isNotEmpty) list.add(resolved);
//     if (original.isNotEmpty && original != resolved) list.add(original);
//     return list.isEmpty ? [original] : list;
//   }

//   Future<void> _initializeVideo() async {
//     if (!mounted) return;
//     setState(() {
//       _isInitializing = true;
//       _isInitialized = false;
//       _errorMessage = null;
//     });

//     final candidates = _candidateUrls;
//     debugPrint('Candidate URLs: $candidates');

//     Object? lastError;

//     for (final url in candidates) {
//       if (!mounted) return;
//       debugPrint('Trying: $url');
//       _activeUrl = url;

//       VideoPlayerController controller;
//       try {
//         // FIX: networkUrl menggantikan network() yang deprecated
//         controller = VideoPlayerController.networkUrl(
//           Uri.parse(url),
//           videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
//         );
//       } catch (e) {
//         lastError = e;
//         debugPrint('Uri.parse/construct failed for $url: $e');
//         continue;
//       }

//       _timeoutTimer?.cancel();
//       final completer = Completer<bool>();
//       _timeoutTimer = Timer(const Duration(seconds: 20), () {
//         if (!completer.isCompleted) {
//           debugPrint('Timeout for $url');
//           completer.complete(false);
//         }
//       });

//       try {
//         await controller.initialize();
//         _timeoutTimer?.cancel();
//         if (!completer.isCompleted) completer.complete(true);
//       } catch (e) {
//         _timeoutTimer?.cancel();
//         lastError = e;
//         debugPrint('initialize() failed for $url: $e');
//         await controller.dispose();
//         continue;
//       }

//       final ok = await completer.future;
//       if (!ok) {
//         lastError = 'Timeout saat memuat $url';
//         await controller.dispose();
//         continue;
//       }

//       if (!mounted) {
//         await controller.dispose();
//         return;
//       }

//       // FIX: JANGAN buang controller hanya karena size 0x0.
//       // Beberapa video valid baru mengisi dimensi beberapa saat setelah
//       // initialize(). Pengecekan ketat sebelumnya membuat video yang
//       // sebenarnya OK ikut dibuang -> halaman tetap di state "loading"
//       // lalu fallback ke background putih. Cukup catat untuk log.
//       final size = controller.value.size;
//       debugPrint('Init OK - url: $url size: $size '
//           'dur: ${controller.value.duration} '
//           'aspect: ${controller.value.aspectRatio}');

//       // Sukses
//       await controller.setLooping(false);
//       await controller.setVolume(1.0);
//       controller.addListener(_onControllerUpdate);

//       setState(() {
//         _controller = controller;
//         _isInitializing = false;
//         _isInitialized = true;
//         _showControls = true;
//       });

//       return;
//     }

//     if (!mounted) return;
//     setState(() {
//       _isInitializing = false;
//       _errorMessage =
//           'Gagal memuat video.\n\nSemua sumber dicoba tetapi gagal.\n\nDetail: $lastError';
//     });
//   }

//   void _onControllerUpdate() {
//     if (!mounted) return;
//     final ctrl = _controller;
//     if (ctrl == null) return;

//     final playing = ctrl.value.isPlaying;

//     final isFinished = ctrl.value.duration > Duration.zero &&
//         ctrl.value.position >= ctrl.value.duration &&
//         !ctrl.value.isPlaying;

//     if (isFinished && _isPlaying) {
//       _hideControlsTimer?.cancel();
//       setState(() {
//         _isPlaying = false;
//         _showControls = true;
//       });
//       return;
//     }

//     // FIX: Hanya setState saat status play/pause BERUBAH.
//     // Sebelumnya setState(() {}) dipanggil tiap frame (~60x/detik) untuk
//     // update scrubber -> menyebabkan rebuild seluruh widget di tengah
//     // layout sehingga render box belum ter-layout saat di-hit-test.
//     // Update posisi scrubber kini ditangani ValueListenableBuilder.
//     if (playing != _isPlaying) {
//       setState(() => _isPlaying = playing);
//     }
//   }

//   Future<void> _retryInitialize() async {
//     _timeoutTimer?.cancel();
//     _hideControlsTimer?.cancel();
//     final old = _controller;
//     if (old != null) {
//       old.removeListener(_onControllerUpdate);
//       await old.dispose();
//       _controller = null;
//     }
//     await _initializeVideo();
//   }

//   void _togglePlay() {
//     final ctrl = _controller;
//     if (ctrl == null || !ctrl.value.isInitialized || ctrl.value.hasError) {
//       debugPrint('TogglePlay ignored');
//       return;
//     }

//     final isFinished = ctrl.value.duration > Duration.zero &&
//         ctrl.value.position >= ctrl.value.duration;
//     if (isFinished && !ctrl.value.isPlaying) {
//       ctrl.seekTo(Duration.zero);
//     }

//     if (ctrl.value.isPlaying) {
//       ctrl.pause().then((_) {
//         if (!mounted) return;
//         _hideControlsTimer?.cancel();
//         setState(() {
//           _isPlaying = false;
//           _showControls = true;
//         });
//       }).catchError((e) => debugPrint('Pause failed: $e'));
//     } else {
//       ctrl.play().then((_) {
//         if (!mounted) return;
//         setState(() => _isPlaying = ctrl.value.isPlaying);
//         if (ctrl.value.isPlaying) _scheduleHideControls();
//       }).catchError((e) {
//         debugPrint('Play failed: $e');
//         if (mounted) {
//           setState(() => _errorMessage = 'Gagal memulai pemutaran.\n$e');
//         }
//       });
//     }
//   }

//   void _onVideoTap() {
//     if (!_isInitialized) return;
//     setState(() => _showControls = !_showControls);
//     if (_showControls && _isPlaying) {
//       _scheduleHideControls();
//     } else {
//       _hideControlsTimer?.cancel();
//     }
//   }

//   void _scheduleHideControls() {
//     _hideControlsTimer?.cancel();
//     _hideControlsTimer = Timer(const Duration(seconds: 3), () {
//       if (mounted && _isPlaying) {
//         setState(() => _showControls = false);
//       }
//     });
//   }

//   void _toggleFullscreen() {
//     setState(() => _isFullscreen = !_isFullscreen);
//     if (_isFullscreen) {
//       SystemChrome.setPreferredOrientations([
//         DeviceOrientation.landscapeLeft,
//         DeviceOrientation.landscapeRight,
//       ]);
//       SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//     } else {
//       SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//       SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     }
//   }

//   String _formatDuration(Duration d) {
//     final h = d.inHours;
//     final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return h > 0 ? '$h:$m:$s' : '$m:$s';
//   }

//   @override
//   void dispose() {
//     _timeoutTimer?.cancel();
//     _hideControlsTimer?.cancel();
//     _controller?.removeListener(_onControllerUpdate);
//     _controller?.dispose();
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     super.dispose();
//   }

//   // ---------------------------------------------------------
//   // DEBUG BANNER — tampilkan status videoUrl
//   // Hapus pemanggilan _buildDebugBanner() di build() setelah video jalan.
//   // ---------------------------------------------------------
//   Widget _buildDebugBanner() {
//     //final raw = widget.videoUrl;
//     final raw = 'https://www.youtube.com/watch?v=owijYeRAlEw';
//     final hasUrl = raw.trim().isNotEmpty;
//     final resolved = hasUrl ? _resolveCloudinaryUrl(raw.trim()) : '(kosong)';

//     final ctrl = _controller;
//     final sizeStr = (ctrl != null && ctrl.value.isInitialized)
//         ? '${ctrl.value.size.width.toInt()}x${ctrl.value.size.height.toInt()}'
//         : '-';

//     String status;
//     Color statusColor;
//     if (!hasUrl) {
//       status = 'videoUrl KOSONG ❌';
//       statusColor = Colors.red.shade700;
//     } else if (_errorMessage != null) {
//       status = 'ERROR saat memuat';
//       statusColor = Colors.red.shade700;
//     } else if (_isInitializing) {
//       status = 'Sedang memuat...';
//       statusColor = Colors.orange.shade800;
//     } else if (_isInitialized) {
//       status = 'Terinisialisasi (size: $sizeStr)';
//       statusColor = Colors.green.shade700;
//     } else {
//       status = 'Status tidak diketahui';
//       statusColor = Colors.grey.shade700;
//     }

//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 4),
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFF8E1),
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         border: Border.all(color: Colors.amber.shade300),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.bug_report_outlined,
//                   size: 16, color: Colors.brown),
//               const SizedBox(width: 6),
//               Text(
//                 'DEBUG: $status',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: statusColor,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           // FIX: SelectableText punya viewport scroll internal yang bisa
//           // diberi constraint unbounded oleh Column dalam SingleChildScroll
//           // View -> "RenderBox was not laid out". Pakai Text biasa + softWrap.
//           Text(
//             'RAW URL:\n${hasUrl ? raw : "(string kosong / null)"}',
//             softWrap: true,
//             style: const TextStyle(fontSize: 11, color: Colors.black87),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'RESOLVED URL:\n$resolved',
//             softWrap: true,
//             style: const TextStyle(fontSize: 11, color: Colors.black54),
//           ),
//           if (_activeUrl.isNotEmpty) ...[
//             const SizedBox(height: 4),
//             Text(
//               'ACTIVE (yang dicoba terakhir):\n$_activeUrl',
//               softWrap: true,
//               style:
//                   const TextStyle(fontSize: 11, color: Color(0xFF4A90D9)),
//             ),
//           ],
//           const SizedBox(height: 4),
//           Text(
//             'title: "${widget.title}"  |  mentor: "${widget.mentorName}"',
//             style: const TextStyle(fontSize: 10, color: Colors.black45),
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------------------------------------------------
//   Widget _buildVideoArea() {
//     // FIX: Saat fullscreen, isi seluruh layar (bukan AspectRatio).
//     // AspectRatio yang dipakai langsung sebagai body Scaffold tidak
//     // mendapat constraint lebar terbatas -> "Cannot hit test a render
//     // box that has never been laid out".
//     if (_isFullscreen) {
//       return SizedBox.expand(
//         child: ColoredBox(
//           color: Colors.black,
//           child: _buildVideoContent(),
//         ),
//       );
//     }

//     return AspectRatio(
//       aspectRatio: 16 / 9,
//       child: ClipRRect(
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         child: Container(
//           color: Colors.black,
//           child: _buildVideoContent(),
//         ),
//       ),
//     );
//   }

//   Widget _buildVideoContent() {
//     // ERROR
//     if (_errorMessage != null) {
//       return Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.error_outline_rounded,
//                   size: 52, color: Colors.red.shade300),
//               const SizedBox(height: 12),
//               Text(
//                 _errorMessage!,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                     color: Colors.white70, fontSize: 13, height: 1.5),
//               ),
//               if (_activeUrl.isNotEmpty) ...[
//                 const SizedBox(height: 8),
//                 Text(
//                   'URL: $_activeUrl',
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(color: Colors.white38, fontSize: 10),
//                   maxLines: 3,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//               const SizedBox(height: 16),
//               ElevatedButton.icon(
//                 onPressed: _retryInitialize,
//                 icon: const Icon(Icons.refresh_rounded, size: 18),
//                 label: const Text('Coba Lagi'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF4A90D9),
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10)),
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     // LOADING
//     if (_isInitializing) {
//       return Stack(
//         fit: StackFit.expand,
//         children: [
//           if (widget.thumbnailUrl.isNotEmpty)
//             Image.network(
//               widget.thumbnailUrl,
//               fit: BoxFit.cover,
//               errorBuilder: (_, __, ___) =>
//                   const ColoredBox(color: Colors.black),
//             ),
//           Container(color: Colors.black54),
//           const Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(
//                     color: Colors.white, strokeWidth: 2.5),
//                 SizedBox(height: 10),
//                 Text('Memuat video...',
//                     style: TextStyle(color: Colors.white60, fontSize: 13)),
//               ],
//             ),
//           ),
//         ],
//       );
//     }

//     // VIDEO READY
//     if (_isInitialized && _controller != null) {
//       final ctrl = _controller!;
//       final aspectRatio =
//           ctrl.value.aspectRatio > 0 ? ctrl.value.aspectRatio : 16 / 9;

//       return GestureDetector(
//         onTap: _onVideoTap,
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             if (!_isPlaying && widget.thumbnailUrl.isNotEmpty)
//               Image.network(
//                 widget.thumbnailUrl,
//                 fit: BoxFit.cover,
//                 errorBuilder: (_, __, ___) =>
//                     const ColoredBox(color: Colors.black),
//               )
//             else
//               const ColoredBox(color: Colors.black),
//             Center(
//               child: AspectRatio(
//                 aspectRatio: aspectRatio,
//                 child: VideoPlayer(ctrl),
//               ),
//             ),
//             // FIX (per docs.flutter.dev/testing/common-errors -
//             // "RenderBox was not laid out"): overlay sebelumnya berada
//             // langsung sebagai child Stack tanpa ukuran terdefinisi.
//             // Container gradient tidak punya ukuran intrinsik, sehingga
//             // inner Stack menerima constraint unbounded -> Positioned &
//             // Center di dalamnya gagal di-layout -> error hit test.
//             // Positioned.fill memberi constraint terbatas dari Stack luar
//             // (yang ber-StackFit.expand), dan SizedBox.expand memastikan
//             // inner Stack mengisi penuh area itu.
//             Positioned.fill(
//               child: AnimatedOpacity(
//                 opacity: _showControls ? 1.0 : 0.0,
//                 duration: const Duration(milliseconds: 250),
//                 child: IgnorePointer(
//                   ignoring: !_showControls,
//                   child: Container(
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           Colors.black54,
//                           Colors.transparent,
//                           Colors.transparent,
//                           Colors.black54,
//                         ],
//                         stops: [0, 0.3, 0.7, 1],
//                       ),
//                     ),
//                     child: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         Center(
//                           child: GestureDetector(
//                             onTap: _togglePlay,
//                             child: Container(
//                               width: 64,
//                               height: 64,
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF4A90D9),
//                                 shape: BoxShape.circle,
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black.withOpacity(0.3),
//                                     blurRadius: 8,
//                                     offset: const Offset(0, 2),
//                                   ),
//                                 ],
//                               ),
//                               child: Icon(
//                                 _isPlaying
//                                     ? Icons.pause_rounded
//                                     : Icons.play_arrow_rounded,
//                                 color: Colors.white,
//                                 size: 36,
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           left: 0,
//                           right: 0,
//                           bottom: 0,
//                           child: _buildBottomControls(ctrl),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     // FALLBACK
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: const [
//           Icon(Icons.videocam_off_rounded, size: 48, color: Colors.white38),
//           SizedBox(height: 8),
//           Text('Video tidak tersedia',
//               style: TextStyle(color: Colors.white54, fontSize: 13)),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomControls(VideoPlayerController ctrl) {
//     final duration = ctrl.value.duration;

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // FIX: ValueListenableBuilder hanya merebuild scrubber + teks
//           // waktu setiap frame, BUKAN seluruh halaman. Ini menghilangkan
//           // error "Cannot hit test a render box that has never been laid
//           // out" yang muncul karena rebuild penuh per-frame.
//           ValueListenableBuilder<VideoPlayerValue>(
//             valueListenable: ctrl,
//             builder: (context, value, _) {
//               final position = value.position;
//               final dur = value.duration.inMilliseconds > 0
//                   ? value.duration
//                   : duration;
//               final progress = dur.inMilliseconds > 0
//                   ? (position.inMilliseconds / dur.inMilliseconds)
//                       .clamp(0.0, 1.0)
//                   : 0.0;

//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   SliderTheme(
//                     data: SliderTheme.of(context).copyWith(
//                       trackHeight: 3,
//                       thumbShape: const RoundSliderThumbShape(
//                           enabledThumbRadius: 6),
//                       overlayShape: const RoundSliderOverlayShape(
//                           overlayRadius: 12),
//                       activeTrackColor: const Color(0xFF4A90D9),
//                       inactiveTrackColor: Colors.white30,
//                       thumbColor: const Color(0xFF4A90D9),
//                       overlayColor: const Color(0x334A90D9),
//                     ),
//                     child: Slider(
//                       value: progress,
//                       onChangeStart: (_) => _hideControlsTimer?.cancel(),
//                       onChanged: (v) {
//                         ctrl.seekTo(Duration(
//                           milliseconds:
//                               (v * dur.inMilliseconds).round(),
//                         ));
//                       },
//                       onChangeEnd: (_) {
//                         if (_isPlaying) _scheduleHideControls();
//                       },
//                     ),
//                   ),
//                   Row(
//                     children: [
//                       Text(
//                         '${_formatDuration(position)} / ${_formatDuration(dur)}',
//                         style: const TextStyle(
//                             color: Colors.white, fontSize: 11),
//                       ),
//                       const Spacer(),
//                       GestureDetector(
//                         onTap: _toggleFullscreen,
//                         child: Icon(
//                           _isFullscreen
//                               ? Icons.fullscreen_exit_rounded
//                               : Icons.fullscreen_rounded,
//                           color: Colors.white,
//                           size: 22,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
//     final ctrl = _controller;
//     final position =
//         (ctrl != null && _isInitialized) ? ctrl.value.position : Duration.zero;
//     final duration =
//         (ctrl != null && _isInitialized) ? ctrl.value.duration : Duration.zero;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF2F4F7),
//       appBar: _isFullscreen
//           ? null
//           : AppBar(
//               backgroundColor: Colors.white,
//               elevation: 0,
//               centerTitle: false,
//               iconTheme: const IconThemeData(color: Colors.black87),
//               leading: IconButton(
//                 icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
//                 onPressed: () => Navigator.of(context).pop(),
//               ),
//               title: Text(
//                 widget.title+"tes",
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   color: Colors.black87,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//       body: Container(
//         color: Colors.black,
//         child: VideoApp(),
//       ),
//       // _isFullscreen
//           // ? Container(
//           //     color: Colors.black,
//           //     alignment: Alignment.center,
//           //     width: double.infinity,
//           //     height: double.infinity,
//           //     child: _buildVideoArea(),
//           //   )
//           // : SingleChildScrollView(
//           //     padding: const EdgeInsets.all(16),
//           //     child: Column(
//           //       crossAxisAlignment: CrossAxisAlignment.start,
//           //       children: [
//           //         Container(
//           //           decoration: BoxDecoration(
//           //             color: Colors.white,
//           //             borderRadius: BorderRadius.circular(20),
//           //             boxShadow: [
//           //               BoxShadow(
//           //                 color: Colors.black.withOpacity(0.09),
//           //                 blurRadius: 16,
//           //                 offset: const Offset(0, 4),
//           //               ),
//           //             ],
//           //           ),
//           //           child: Column(
//           //             crossAxisAlignment: CrossAxisAlignment.start,
//           //             children: [
//           //               // ── DEBUG BANNER (hapus nanti setelah video jalan) ──
//           //               _buildDebugBanner(),
//           //               _buildVideoArea(),
//           //               Padding(
//           //                 padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//           //                 child: Column(
//           //                   crossAxisAlignment: CrossAxisAlignment.start,
//           //                   children: [
//           //                     Text(
//           //                       widget.title,
//           //                       style: const TextStyle(
//           //                         fontSize: 16,
//           //                         fontWeight: FontWeight.bold,
//           //                         color: Color(0xFF1A1A2E),
//           //                       ),
//           //                     ),
//           //                     const SizedBox(height: 4),
//           //                     Row(
//           //                       children: [
//           //                         const Icon(Icons.person_outline_rounded,
//           //                             size: 14, color: Color(0xFF888888)),
//           //                         const SizedBox(width: 4),
//           //                         Text(
//           //                           widget.mentorName,
//           //                           style: const TextStyle(
//           //                             fontSize: 13,
//           //                             color: Color(0xFF888888),
//           //                           ),
//           //                         ),
//           //                       ],
//           //                     ),
//           //                   ],
//           //                 ),
//           //               ),
//           //               const Padding(
//           //                 padding: EdgeInsets.symmetric(
//           //                     horizontal: 16, vertical: 12),
//           //                 child: Divider(height: 1, color: Color(0xFFEEEEEE)),
//           //               ),
//           //               Padding(
//           //                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//           //                 child: Column(
//           //                   crossAxisAlignment: CrossAxisAlignment.start,
//           //                   children: [
//           //                     const Text(
//           //                       'Deskripsi Konten',
//           //                       style: TextStyle(
//           //                         fontSize: 14,
//           //                         fontWeight: FontWeight.w700,
//           //                         color: Color(0xFF1A1A2E),
//           //                       ),
//           //                     ),
//           //                     const SizedBox(height: 8),
//           //                     const Text(
//           //                       'Video edukasi lansia dari mentor untuk membantu kegiatan sehari-hari dan meningkatkan kualitas hidup.',
//           //                       style: TextStyle(
//           //                         fontSize: 13,
//           //                         color: Color(0xFF666666),
//           //                         height: 1.6,
//           //                       ),
//           //                     ),
//           //                     const SizedBox(height: 20),
//           //                     Row(
//           //                       children: [
//           //                         ElevatedButton.icon(
//           //                           onPressed: (_isInitialized &&
//           //                                   _errorMessage == null)
//           //                               ? _togglePlay
//           //                               : null,
//           //                           icon: Icon(
//           //                             _isPlaying
//           //                                 ? Icons.pause_rounded
//           //                                 : Icons.play_arrow_rounded,
//           //                             size: 20,
//           //                           ),
//           //                           label: Text(_isPlaying ? 'Pause' : 'Play'),
//           //                           style: ElevatedButton.styleFrom(
//           //                             backgroundColor: const Color(0xFF4A90D9),
//           //                             foregroundColor: Colors.white,
//           //                             disabledBackgroundColor:
//           //                                 Colors.grey.shade300,
//           //                             shape: RoundedRectangleBorder(
//           //                               borderRadius: BorderRadius.circular(10),
//           //                             ),
//           //                             padding: const EdgeInsets.symmetric(
//           //                                 horizontal: 18, vertical: 10),
//           //                           ),
//           //                         ),
//           //                         const SizedBox(width: 14),
//           //                         // FIX: ValueListenableBuilder agar teks
//           //                         // waktu tetap update tanpa setState per-frame
//           //                         (ctrl != null && _isInitialized)
//           //                             ? ValueListenableBuilder<
//           //                                 VideoPlayerValue>(
//           //                                 valueListenable: ctrl,
//           //                                 builder: (context, value, _) {
//           //                                   return Text(
//           //                                     '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
//           //                                     style: const TextStyle(
//           //                                       color: Color(0xFF888888),
//           //                                       fontSize: 13,
//           //                                     ),
//           //                                   );
//           //                                 },
//           //                               )
//           //                             : Text(
//           //                                 '${_formatDuration(position)} / ${_formatDuration(duration)}',
//           //                                 style: const TextStyle(
//           //                                   color: Color(0xFF888888),
//           //                                   fontSize: 13,
//           //                                 ),
//           //                               ),
//           //                       ],
//           //                     ),
//           //                   ],
//           //                 ),
//           //               ),
//           //             ],
//           //           ),
//           //         ),
//           //         const SizedBox(height: 24),
//           //       ],
//           //     ),
//           //   ),
//     );
//   }
// }
