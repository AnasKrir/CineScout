class Video {
  final String id;
  final String key;
  final String name;
  final String site;
  final String type;
  final bool official;

  const Video({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.type,
    required this.official,
  });

  bool get isYoutube => site.toLowerCase() == 'youtube';
  bool get isTrailer => type.toLowerCase() == 'trailer';
}
