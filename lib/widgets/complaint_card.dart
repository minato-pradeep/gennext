import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../theme/app_theme.dart';

class ComplaintCard extends StatefulWidget {
  final Complaint complaint;
  final int index;
  final bool isNew;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.index,
    this.isNew = false,
  });

  @override
  State<ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<ComplaintCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _roleColor {
    switch (widget.complaint.userRole.toLowerCase()) {
      case 'admin':
        return AppTheme.brand(context);   // Primary blue
      case 'security':
        return const Color(0xFFF04438);   // Semantic red
      case 'owner':
        return const Color(0xFF12B76A);   // Semantic green
      default:
        return const Color(0xFFF79009);   // Semantic amber
    }
  }

  String get _roleLabel {
    switch (widget.complaint.userRole.toLowerCase()) {
      case 'owner':
        return 'House Owner';
      case 'security':
        return 'Security';
      case 'visitor':
        return 'Visitor';
      default:
        return widget.complaint.userRole;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _roleColor.withOpacity(0.12),
                      radius: 20,
                      child: Text(
                        widget.complaint.userName[0].toUpperCase(),
                        style: TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _roleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.complaint.userName,
                                style: const TextStyle(fontFamily: 'Arial Narrow', 
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF172033),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (widget.isNew)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF12B76A),  // Semantic green
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _roleLabel,
                              style: TextStyle(fontFamily: 'Arial Narrow', 
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(Icons.access_time,
                            size: 13, color: Colors.black38),
                        const SizedBox(height: 2),
                        Text(
                          widget.complaint.dateTime.length > 10
                              ? widget.complaint.dateTime.substring(0, 10)
                              : widget.complaint.dateTime,
                          style: const TextStyle(fontFamily: 'Arial Narrow', 
                            fontSize: 10,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.complaint.complaintText,
                    style: const TextStyle(fontFamily: 'Arial Narrow', 
                      fontSize: 13,
                      color: Color(0xFF172033),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
