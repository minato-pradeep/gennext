import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import 'add_poll_page.dart';
import '../theme/app_theme.dart';

class PollsPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final Map<String, String> userProfile;
  final bool isAdmin;

  const PollsPage(
      {super.key,
      required this.userRole,
      required this.userName,
      required this.userProfile,
      this.isAdmin = false});

  @override
  State<PollsPage> createState() => _PollsPageState();
}

class _PollsPageState extends State<PollsPage> {
  static String get _base => '${AppConstants.baseUrl}/api/polls';

  List<Map<String, dynamic>> _polls = [];
  bool _loading = true;
  String _userId = '';
  // Map of pollId -> voted optionId
  final Map<String, int> _votedOptions = {};
  // Map of pollId -> selected optionId (before submitting)
  final Map<String, int> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? widget.userName;
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res =
          await http.get(Uri.parse(_base)).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        final polls = List<Map<String, dynamic>>.from(data['polls']);
        // Check voted status for each poll
        for (final poll in polls) {
          final pollId = poll['id'].toString();
          final vRes = await http
              .get(Uri.parse('$_base/$pollId/voted/$_userId'))
              .timeout(const Duration(seconds: 5));
          final vData = jsonDecode(vRes.body);
          if (vData['voted'] == true && vData['option_id'] != null) {
            _votedOptions[pollId] = vData['option_id'] as int;
          }
        }
        if (mounted) {
          setState(() {
            _polls = polls;
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _vote(String pollId, int optionId) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/$pollId/vote'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'option_id': optionId, 'user_id': _userId}),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          _votedOptions[pollId] = optionId;
          _selectedOptions.remove(pollId);
        });
        await _load();
        _snack('✅ Vote recorded!', Colors.green);
      } else {
        _snack(data['message'] ?? 'Failed', Colors.red);
      }
    } catch (e) {
      _snack('Error: $e', Colors.red);
    }
  }

  Future<void> _deletePoll(String pollId) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Delete Poll?',
                  style: TextStyle(
                      fontFamily: 'Arial Narrow', fontWeight: FontWeight.w700)),
              content: const Text('This cannot be undone.',
                  style: TextStyle(
                    fontFamily: 'Arial Narrow',
                  )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.white))),
              ],
            ));
    if (confirm == true) {
      await http.delete(Uri.parse('$_base/$pollId'));
      _load();
      _snack('Poll deleted', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Arial Narrow', fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Community Polls',
            style: TextStyle(
                fontFamily: 'Arial Narrow',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        backgroundColor: AppTheme.brand(context),
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddPollPage(
                            userRole: widget.userRole,
                            userName: widget.userName,
                            userProfile: widget.userProfile)));
                _load();
              }),
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.brand(context)))
          : _polls.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Icon(Icons.poll_outlined,
                          size: 64,
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No polls yet',
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              color: AppTheme.textColor(context).withOpacity(0.45))),
                      const SizedBox(height: 8),
                      Text('Tap + to create a poll',
                          style: TextStyle(
                              fontFamily: 'Arial Narrow',
                              fontSize: 12,
                              color: AppTheme.textColor(context).withOpacity(0.38))),
                    ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.brand(context),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _polls.length,
                    itemBuilder: (_, i) => _pollCard(_polls[i], isDark),
                  ),
                ),
    );
  }

  Widget _pollCard(Map<String, dynamic> poll, bool isDark) {
    final pollId = poll['id'].toString();
    final options = List<Map<String, dynamic>>.from(poll['options'] ?? []);
    final totalVotes = poll['total_votes'] as int? ?? 0;
    final hasVoted = _votedOptions.containsKey(pollId);
    final votedOptionId = _votedOptions[pollId];
    final selectedOptionId = _selectedOptions[pollId];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                    color: AppTheme.brand(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child:
                    Icon(Icons.poll, color: AppTheme.brand(context), size: 24)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(poll['question'] ?? '',
                      style: TextStyle(
                          fontFamily: 'Arial Narrow',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor(context))),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.person_outline,
                        size: 12,
                        color: AppTheme.textColor(context).withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Text('${poll['created_by'] ?? ''} • $totalVotes votes',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 10,
                            color: AppTheme.textColor(context).withOpacity(0.45))),
                  ]),
                ])),
            // Delete button
            GestureDetector(
              onTap: () => _deletePoll(pollId),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.delete, color: Colors.red, size: 18),
              ),
            ),
          ]),
        ),

        const Divider(height: 1),

        // Options
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              children: options.map((opt) {
            final optId = opt['id'] as int;
            final votes = opt['votes'] as int? ?? 0;
            final pct = totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;
            final isVoted = votedOptionId == optId;
            final isSelected = selectedOptionId == optId;
            final isDisabled = hasVoted && !isVoted;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: hasVoted
                    ? null
                    : () => setState(() => _selectedOptions[pollId] = optId),
                child: Opacity(
                  opacity: isDisabled ? 0.45 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isVoted
                          ? AppTheme.brand(context).withOpacity(0.08)
                          : (isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isVoted
                            ? AppTheme.brand(context)
                            : isSelected
                                ? AppTheme.brand(context)
                                : (isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                        width: (isVoted || isSelected) ? 2 : 1,
                      ),
                    ),
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          // Radio circle
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: (isVoted || isSelected)
                                        ? AppTheme.brand(context)
                                        : Colors.grey,
                                    width: 2)),
                            child: (isVoted || isSelected)
                                ? Icon(Icons.check_circle,
                                    size: 18, color: AppTheme.brand(context))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(opt['option_text'] ?? '',
                                  style: TextStyle(
                                      fontFamily: 'Arial Narrow',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87))),
                          if (hasVoted)
                            Text('$votes (${pct.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                    fontFamily: 'Arial Narrow',
                                    fontSize: 11,
                                    color: AppTheme.brand(context),
                                    fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      // Progress bar after voting
                      if (hasVoted)
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12)),
                          child: LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              color: AppTheme.brand(context),
                              minHeight: 5),
                        ),
                    ]),
                  ),
                ),
              ),
            );
          }).toList()),
        ),

        // Submit / Voted status
        if (!hasVoted)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedOptionId == null
                    ? null
                    : () => _vote(pollId, selectedOptionId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brand(context),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                    selectedOptionId == null
                        ? 'Select an option first'
                        : 'Submit Vote',
                    style: const TextStyle(
                        fontFamily: 'Arial Narrow',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppTheme.brand(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.check_circle, color: AppTheme.brand(context), size: 18),
                SizedBox(width: 8),
                Expanded(
                    child: Text('You have voted. Thank you! 🎉',
                        style: TextStyle(
                            fontFamily: 'Arial Narrow',
                            fontSize: 11,
                            color: AppTheme.brand(context),
                            fontWeight: FontWeight.w500))),
              ]),
            ),
          ),
      ]),
    );
  }
}
