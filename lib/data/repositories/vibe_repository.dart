import 'package:flutter/material.dart';

import '../models/ambient_sound.dart';
import '../models/music_track.dart';
import '../models/vibe_preset.dart';

class VibeRepository {
  MusicTrack get defaultTrack {
    return const MusicTrack(
      id: 'local-demo',
      title: 'No music selected',
      artist: 'Make Your Vibe',
      assetPath: '',
    );
  }

  List<AmbientSound> getAmbientSounds() {
    return const [
      AmbientSound(
        id: 'rain_1',
        groupId: 'rain',
        nameVi: 'Mưa',
        nameEn: 'Rain',
        variantVi: 'nhẹ',
        variantEn: 'Soft',
        assetPath: 'assets/audio/ambient/rain_1.mp3',
        icon: Icons.water_drop_rounded,
      ),
      AmbientSound(
        id: 'rain_2',
        groupId: 'rain',
        nameVi: 'Mưa',
        nameEn: 'Rain',
        variantVi: 'nặng',
        variantEn: 'Heavy',
        assetPath: 'assets/audio/ambient/rain_2.mp3',
        icon: Icons.water_drop_rounded,
      ),
      AmbientSound(
        id: 'ocean_1',
        groupId: 'ocean',
        nameVi: 'Sóng biển',
        nameEn: 'Ocean',
        variantVi: 'êm',
        variantEn: 'Calm',
        assetPath: 'assets/audio/ambient/ocean_1.mp3',
        icon: Icons.waves_rounded,
      ),
      AmbientSound(
        id: 'ocean_2',
        groupId: 'ocean',
        nameVi: 'Sóng biển',
        nameEn: 'Ocean',
        variantVi: 'mạnh',
        variantEn: 'Strong',
        assetPath: 'assets/audio/ambient/ocean_2.mp3',
        icon: Icons.waves_rounded,
      ),
      AmbientSound(
        id: 'fire_crackling_1',
        groupId: 'fire_crackling',
        nameVi: 'Lửa',
        nameEn: 'Fire',
        variantVi: 'nhẹ',
        variantEn: 'Soft',
        assetPath: 'assets/audio/ambient/fire_crackling_1.mp3',
        icon: Icons.local_fire_department_rounded,
      ),
      AmbientSound(
        id: 'fire_crackling_2',
        groupId: 'fire_crackling',
        nameVi: 'Lửa',
        nameEn: 'Fire',
        variantVi: 'trại lửa',
        variantEn: 'Campfire',
        assetPath: 'assets/audio/ambient/fire_crackling_2.mp3',
        icon: Icons.local_fire_department_rounded,
      ),
      AmbientSound(
        id: 'wind_1',
        groupId: 'wind',
        nameVi: 'Gió',
        nameEn: 'Wind',
        variantVi: 'nhẹ',
        variantEn: 'Soft',
        assetPath: 'assets/audio/ambient/wind_1.mp3',
        icon: Icons.air_rounded,
      ),
      AmbientSound(
        id: 'wind_2',
        groupId: 'wind',
        nameVi: 'Gió',
        nameEn: 'Wind',
        variantVi: 'mạnh',
        variantEn: 'Strong',
        assetPath: 'assets/audio/ambient/wind_2.mp3',
        icon: Icons.air_rounded,
      ),
      AmbientSound(
        id: 'cricket_1',
        groupId: 'cricket',
        nameVi: 'Tiếng dế',
        nameEn: 'Cricket',
        variantVi: 'đêm',
        variantEn: 'Night',
        assetPath: 'assets/audio/ambient/cricket_1.mp3',
        icon: Icons.nightlight_round,
      ),
      AmbientSound(
        id: 'cricket_2',
        groupId: 'cricket',
        nameVi: 'Tiếng dế',
        nameEn: 'Cricket',
        variantVi: 'rừng',
        variantEn: 'Forest',
        assetPath: 'assets/audio/ambient/cricket_2.mp3',
        icon: Icons.nightlight_round,
      ),
      AmbientSound(
        id: 'brown_noise_1',
        groupId: 'brown_noise',
        nameVi: 'Brown noise',
        nameEn: 'Brown noise',
        variantVi: 'xe ô tô',
        variantEn: 'Car',
        assetPath: 'assets/audio/ambient/brown_noise_1.mp3',
        icon: Icons.directions_car_rounded,
      ),
      AmbientSound(
        id: 'brown_noise_2',
        groupId: 'brown_noise',
        nameVi: 'Brown noise',
        nameEn: 'Brown noise',
        variantVi: 'trầm',
        variantEn: 'Deep',
        assetPath: 'assets/audio/ambient/brown_noise_2.mp3',
        icon: Icons.graphic_eq_rounded,
      ),
    ];
  }

  List<VibePreset> getPresets() {
    return const [
      VibePreset(
        id: 'focus-rain',
        nameVi: 'Mưa tập trung',
        nameEn: 'Focus Rain',
        subtitleVi: 'Mưa nhẹ + không gian học tập',
        subtitleEn: 'Soft rain + focus mood',
        descriptionVi: 'Không gian tập trung với tiếng mưa nhẹ, phù hợp để học hoặc làm việc.',
        descriptionEn: 'A focused atmosphere with soft rain, made for studying or working.',
        defaultAmbientIds: ['rain_1'],
        icon: Icons.water_drop_rounded,
        musicVolume: 0.72,
        ambientVolume: 0.38,
        gradientColors: [
          Color(0xFF182848),
          Color(0xFF4B6CB7),
          Color(0xFF101820),
        ],
      ),
      VibePreset(
        id: 'sleep-ocean',
        nameVi: 'Biển thư giãn',
        nameEn: 'Ocean Sleep',
        subtitleVi: 'Sóng biển + brown noise',
        subtitleEn: 'Ocean waves + brown noise',
        descriptionVi: 'Không gian dịu nhẹ cho lúc nghỉ ngơi, thư giãn hoặc chuẩn bị ngủ.',
        descriptionEn: 'A calm space for resting, relaxing, or winding down.',
        defaultAmbientIds: ['ocean_1', 'brown_noise_2'],
        icon: Icons.waves_rounded,
        musicVolume: 0.48,
        ambientVolume: 0.56,
        gradientColors: [
          Color(0xFF0F2027),
          Color(0xFF203A43),
          Color(0xFF2C5364),
        ],
      ),
      VibePreset(
        id: 'night-coding',
        nameVi: 'Đêm học bài',
        nameEn: 'Night Coding',
        subtitleVi: 'Dế đêm + gió nhẹ',
        subtitleEn: 'Cricket + soft wind',
        descriptionVi: 'Không gian đêm nhẹ nhàng dành cho lúc học, code hoặc làm việc sâu.',
        descriptionEn: 'A quiet night atmosphere for studying, coding, or deep work.',
        defaultAmbientIds: ['cricket_1', 'wind_1'],
        icon: Icons.nightlight_round,
        musicVolume: 0.62,
        ambientVolume: 0.42,
        gradientColors: [
          Color(0xFF42275A),
          Color(0xFF734B6D),
          Color(0xFF1F1C2C),
        ],
      ),
    ];
  }
}