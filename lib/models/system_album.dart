import 'package:flutter/material.dart';

class SystemAlbum {
  final String id;
  final String title;
  final String subtitle;
  final String query;
  final IconData icon;
  final String coverUrl;

  const SystemAlbum({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.query,
    required this.icon,
    required this.coverUrl,
  });
}

const systemAlbums = [
  SystemAlbum(
    id: 'thien-ha',
    title: 'Thien ha nghe gi',
    subtitle: 'Hot V-Pop hom nay',
    query: 'nhac tre viet nam hot nhat hien nay official music',
    icon: Icons.local_fire_department_rounded,
    coverUrl: 'https://i.ytimg.com/vi/kPa7bsKwL-c/hqdefault.jpg',
  ),
  SystemAlbum(
    id: 'top-100',
    title: 'Top 100 Viet',
    subtitle: 'Nhac Viet duoc nghe nhieu',
    query: 'top 100 nhac viet hay nhat vpop official audio',
    icon: Icons.emoji_events_rounded,
    coverUrl: 'https://i.ytimg.com/vi/knW7-x7Y7RE/hqdefault.jpg',
  ),
  SystemAlbum(
    id: 'rap-viet',
    title: 'Rap Viet',
    subtitle: 'B Ray, HIEUTHUHAI, Obito',
    query: 'rap viet bray hieuthuhai obito official mv',
    icon: Icons.mic_external_on_rounded,
    coverUrl: 'https://i.ytimg.com/vi/9hR9YEFYZ3s/hqdefault.jpg',
  ),
  SystemAlbum(
    id: 'son-tung',
    title: 'Son Tung M-TP',
    subtitle: 'Album ca si',
    query: 'Son Tung M-TP official music video',
    icon: Icons.star_rounded,
    coverUrl: 'https://i.ytimg.com/vi/knW7-x7Y7RE/hqdefault.jpg',
  ),
  SystemAlbum(
    id: 'chill-vpop',
    title: 'Chill V-Pop',
    subtitle: 'Nghe nhe buoi toi',
    query: 'chill vpop lofi viet nam official audio',
    icon: Icons.nights_stay_rounded,
    coverUrl: 'https://i.ytimg.com/vi/J7C4Ue7Iry0/hqdefault.jpg',
  ),
  SystemAlbum(
    id: 'ballad',
    title: 'Ballad Viet',
    subtitle: 'Tinh ca, acoustic',
    query: 'ballad viet acoustic official audio',
    icon: Icons.favorite_rounded,
    coverUrl: 'https://i.ytimg.com/vi/1zyzVj89y9I/hqdefault.jpg',
  ),
  SystemAlbum(
    id: 'remix',
    title: 'EDM Remix',
    subtitle: 'Nang luong cao',
    query: 'nhac viet remix edm hot official',
    icon: Icons.bolt_rounded,
    coverUrl: 'https://i.ytimg.com/vi/uelHwf8o7_U/hqdefault.jpg',
  ),
  SystemAlbum(
    id: 'study',
    title: 'Lofi hoc bai',
    subtitle: 'Tap trung, nhe dau',
    query: 'lofi hoc bai viet nam chill beats',
    icon: Icons.school_rounded,
    coverUrl: 'https://i.ytimg.com/vi/jfKfPfyJRdk/hqdefault.jpg',
  ),
];
