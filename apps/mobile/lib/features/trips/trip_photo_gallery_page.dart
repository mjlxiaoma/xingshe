import 'dart:typed_data';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/local_database.dart';
import '../../core/location/track_synchronizer.dart';
import '../../core/media/trip_photo_controller.dart';

class TripPhotoGalleryPage extends ConsumerStatefulWidget {
  const TripPhotoGalleryPage({super.key, required this.tripID});

  final String tripID;

  @override
  ConsumerState<TripPhotoGalleryPage> createState() =>
      _TripPhotoGalleryPageState();
}

class _TripPhotoGalleryPageState extends ConsumerState<TripPhotoGalleryPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(localTripDatabaseProvider);
    final photos =
        (database.select(database.localTripPhotos)
              ..where((row) => row.tripId.equals(widget.tripID))
              ..orderBy([(row) => OrderingTerm.desc(row.takenAt)]))
            .watch();
    return Scaffold(
      key: const Key('trip-photo-gallery-page'),
      appBar: AppBar(title: const Text('行程照片')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: _PrivacyNote(),
          ),
          Expanded(
            child: StreamBuilder<List<LocalTripPhoto>>(
              stream: photos,
              initialData: const [],
              builder: (context, snapshot) {
                final values = snapshot.data ?? const [];
                if (values.isEmpty) return const _EmptyGallery();
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: values.length,
                  itemBuilder: (context, index) => _PhotoTile(
                    photo: values[index],
                    enabled: !_busy,
                    onPreview: () => _preview(values[index]),
                    onDelete: () => _confirmDelete(values[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _preview(LocalTripPhoto photo) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          key: const Key('trip-photo-preview'),
          backgroundColor: const Color(0xFF101512),
          appBar: AppBar(
            backgroundColor: const Color(0xFF101512),
            foregroundColor: Colors.white,
            title: Text(photo.photoSource == 'camera' ? '行摄拍摄' : '相册导入'),
            actions: [
              IconButton(
                key: const Key('preview-delete-photo'),
                onPressed: () => Navigator.pop(context, 'delete'),
                icon: const Icon(Icons.delete_outline),
                tooltip: '删除',
              ),
            ],
          ),
          body: Center(
            child: _ContentUriImage(
              uri: photo.filePath,
              maxSize: 1600,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
    if (action == 'delete' && mounted) await _confirmDelete(photo);
  }

  Future<void> _confirmDelete(LocalTripPhoto photo) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除这张照片？'),
        content: Text(
          photo.photoSource == 'camera'
              ? '默认仅移除应用内关联，系统相册原图会保留。'
              : '这张照片来自系统相册。只能移除应用内关联，系统相册原图不会删除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            key: const Key('remove-photo-association'),
            onPressed: () => Navigator.pop(context, 'association'),
            child: const Text('仅移除关联'),
          ),
          if (photo.photoSource == 'camera')
            FilledButton(
              key: const Key('delete-camera-original'),
              onPressed: () => Navigator.pop(context, 'original'),
              child: const Text('同时删除原图'),
            ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'original' && !await _confirmOriginalDeletion()) return;
    setState(() => _busy = true);
    try {
      final controller = ref.read(tripPhotoControllerProvider);
      if (action == 'original') {
        await controller.deleteCameraOriginal(photo.id);
      } else {
        await controller.removeAssociation(photo.id);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('照片删除失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmOriginalDeletion() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除系统相册原图？'),
          content: const Text('此操作不可撤销。原图会从系统相册中删除，不只是移除行程关联。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('保留原图'),
            ),
            FilledButton(
              key: const Key('confirm-delete-camera-original'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认删除原图'),
            ),
          ],
        ),
      ) ??
      false;
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F1E9),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Row(
      children: [
        Icon(Icons.lock, color: Color(0xFF2D6B3F), size: 17),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '照片保存在设备本地，不会自动上传',
            style: TextStyle(
              color: Color(0xFF2D6B3F),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PhotoTile extends ConsumerWidget {
  const _PhotoTile({
    required this.photo,
    required this.enabled,
    required this.onPreview,
    required this.onDelete,
  });

  final LocalTripPhoto photo;
  final bool enabled;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
    color: const Color(0xFFEAF0E8),
    borderRadius: BorderRadius.circular(5),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: Key('trip-photo-${photo.id}'),
      onTap: enabled ? onPreview : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ContentUriImage(uri: photo.filePath),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              color: const Color(0xCC1E3322),
              child: Text(
                photo.photoSource == 'camera' ? '行摄拍摄' : '相册导入',
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton.filled(
              key: Key('delete-photo-${photo.id}'),
              onPressed: enabled ? onDelete : null,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xCCFFFFFF),
                foregroundColor: const Color(0xFFBA1A1A),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: '删除照片',
            ),
          ),
        ],
      ),
    ),
  );
}

class _ContentUriImage extends ConsumerStatefulWidget {
  const _ContentUriImage({
    required this.uri,
    this.maxSize = 512,
    this.fit = BoxFit.cover,
  });

  final String uri;
  final int maxSize;
  final BoxFit fit;

  @override
  ConsumerState<_ContentUriImage> createState() => _ContentUriImageState();
}

class _ContentUriImageState extends ConsumerState<_ContentUriImage> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _ContentUriImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri || oldWidget.maxSize != widget.maxSize) {
      _load();
    }
  }

  void _load() {
    _bytes = ref
        .read(mediaBridgeProvider)
        .loadPhoto(widget.uri, maxSize: widget.maxSize);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _bytes,
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      if (bytes == null) return const _PhotoPlaceholder();
      return Image.memory(
        bytes,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
      );
    },
  );
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFEAF0E8),
    child: Center(
      child: Icon(Icons.landscape, color: Color(0xFF2D6B3F), size: 30),
    ),
  );
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) => const Center(
    key: Key('trip-photo-gallery-empty'),
    child: Text('这次行程还没有关联照片'),
  );
}
