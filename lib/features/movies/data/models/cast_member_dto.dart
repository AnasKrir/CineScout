import '../../domain/entities/cast_member.dart';

class CastMemberDto {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  const CastMemberDto({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });

  factory CastMemberDto.fromJson(Map<String, dynamic> json) {
    return CastMemberDto(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      character: json['character'] as String?,
      profilePath: json['profile_path'] as String?,
    );
  }

  CastMember toDomain() => CastMember(
        id: id,
        name: name,
        character: character,
        profilePath: profilePath,
      );
}
