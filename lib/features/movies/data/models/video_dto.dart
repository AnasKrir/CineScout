import '../../domain/entities/video.dart';

class VideoDto {
  final String id;
  final String key;
  final String name;
  final String site;
  final String type;
  final bool official;

  const VideoDto({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.type,
    required this.official,
  });

  factory VideoDto.fromJson(Map<String, dynamic> json) {
    return VideoDto(
      id: json['id'] as String,
      key: json['key'] as String,
      name: (json['name'] ?? '') as String,
      site: (json['site'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      official: json['official'] as bool? ?? false,
    );
  }

  Video toDomain() => Video(
        id: id,
        key: key,
        name: name,
        site: site,
        type: type,
        official: official,
      );
}