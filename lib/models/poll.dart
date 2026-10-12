class Poll {
  final String id;
  final String question;
  final List<PollOption> options;
  final String createdBy;
  final String createdByApartment;
  final String createdAt;
  final bool isActive;
  int totalVotes;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.createdBy,
    required this.createdByApartment,
    required this.createdAt,
    required this.isActive,
    required this.totalVotes,
  });
}

class PollOption {
  final String id;
  final String text;
  int votes;

  PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
  });
}