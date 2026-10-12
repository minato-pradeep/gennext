import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final int index;
  final bool showDelete;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    required this.index,
    this.showDelete = false,
    this.onDelete,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
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
                color: AppTheme.brand(context).withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.brand(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.title,
                              style: const TextStyle(fontFamily: 'Arial Narrow', 
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF172033),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Posted by ${widget.event.postedBy}',
                              style: TextStyle(fontFamily: 'Arial Narrow', 
                                fontSize: 11,
                                color: AppTheme.brand(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.showDelete && widget.onDelete != null)
                        _DeleteButton(onDelete: widget.onDelete!),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.event.description,
                    style: const TextStyle(fontFamily: 'Arial Narrow', 
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 13, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text(
                        widget.event.dateTime,
                        style: const TextStyle(fontFamily: 'Arial Narrow', 
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatefulWidget {
  final VoidCallback onDelete;
  const _DeleteButton({required this.onDelete});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _sc;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _sc = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.88).animate(_sc);
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _sc.forward(),
      onTapUp: (_) async {
        await _sc.reverse();
        widget.onDelete();
      },
      onTapCancel: () => _sc.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.delete_outline,
              color: Color(0xFFE53935), size: 20),
        ),
      ),
    );
  }
}
