import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/models/media_item.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../widgets/song_selector_sheet.dart';

class EditAlarmScreen extends StatefulWidget {
  final Alarm? alarm;

  const EditAlarmScreen({super.key, this.alarm});

  @override
  State<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  late TimeOfDay _time;
  MediaItem? _selectedMedia;
  String? _mediaUrl; // Store URL separately in case we restore from alarm model

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      _time = widget.alarm!.time;
      if (widget.alarm!.mediaId != null) {
        // Construct a temporary media item for display
        _selectedMedia = MediaItem(
          id: widget.alarm!.mediaId!,
          title: widget.alarm!.mediaTitle ?? 'Unknown',
          artist: widget.alarm!.artistName != null 
              ? ArtistInfo(id: 0, name: widget.alarm!.artistName!) 
              : null,
          mediaType: MediaType.audio,
          status: MediaStatus.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _mediaUrl = widget.alarm!.mediaUrl;
      }
    } else {
      _time = TimeOfDay.now();
    }
  }

  void _pickSong() async {
    final result = await showModalBottomSheet<MediaItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SongSelectorSheet(),
    );

    if (result != null) {
      setState(() {
        _selectedMedia = result;
        _mediaUrl = result.hlsUrl; // Assuming HLS URL is what we want to play
      });
    }
  }

  void _save() async {
    if (_selectedMedia == null && _mediaUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a song for the alarm')),
      );
      return;
    }

    // Check for exact alarm permission on Android 12+
    if (Platform.isAndroid) {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'To cancel alarms at exact times, this app needs the "Alarms & Reminders" permission.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await openAppSettings();
                  },
                  child: const Text('Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    final alarmService = context.read<AlarmService>();
    final id = widget.alarm?.id ?? const Uuid().v4();

    final newAlarm = Alarm(
      id: id,
      time: _time,
      isEnabled: true,
      mediaId: _selectedMedia?.id ?? widget.alarm?.mediaId,
      mediaTitle: _selectedMedia?.title ?? widget.alarm?.mediaTitle,
      artistName: _selectedMedia?.artistName ?? widget.alarm?.artistName,
      mediaUrl: _mediaUrl,
    );

    await alarmService.saveAlarm(newAlarm);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarm == null ? 'Add Alarm' : 'Edit Alarm'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                children: [
                  // Time Picker
                  SizedBox(
                    height: 200,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: DateTime(2020, 1, 1, _time.hour, _time.minute),
                      onDateTimeChanged: (dateTime) {
                        setState(() {
                          _time = TimeOfDay.fromDateTime(dateTime);
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Song Selection
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: _pickSong,
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedMedia?.thumbnailUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(_selectedMedia!.thumbnailUrl!, fit: BoxFit.cover),
                            )
                          : Icon(Icons.music_note_rounded, color: AppColors.primary),
                      ),
                      title: Text(
                        _selectedMedia?.title ?? 'Select Song',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _selectedMedia?.artistName ?? 'Choose from library',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
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
