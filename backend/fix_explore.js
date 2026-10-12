const fs = require('fs');
let c = fs.readFileSync('../lib/screens/explore_page.dart', 'utf8');
const startIdx = c.indexOf('  @override\n  Widget build(BuildContext context) {');
const endIdx = c.indexOf('\nclass ExploreOption');

const newBuild = `  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final options = _exploreOptions;
    final screenHeight = MediaQuery.of(context).size.height;
    const cardHeight = 200.0;
    const peekHeight = 90.0;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Icon(Icons.arrow_back_ios_new, size: 18, color: isDark ? Colors.white : Colors.black87))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Community', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                  Text('\${options.length} services', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
                ])),
                GestureDetector(
                  onTap: () => _showProfileSheet(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person, color: Colors.white, size: 20))),
              ]),
            ),
            Expanded(
              child: options.isEmpty
                  ? Center(child: Text('No options available', style: AppTheme.titleMedium))
                  : GestureDetector(
                      onTap: () { if (_expandedIndex != null) setState(() => _expandedIndex = null); },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: _expandedIndex != null ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                        child: SizedBox(
                          height: peekHeight * (options.length - 1) + cardHeight + 40,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: List.generate(options.length, (index) {
                              final option = options[index];
                              final isExpanded = _expandedIndex == index;
                              final isCollapsed = _expandedIndex != null && !isExpanded;
                              
                              return AnimatedPositioned(
                                duration: const Duration(milliseconds: 550),
                                curve: Curves.easeInOutCubic,
                                top: isExpanded ? _scrollOffset : isCollapsed ? _scrollOffset + screenHeight : (index * peekHeight) + 10,
                                left: 20, right: 20,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 550),
                                  curve: Curves.easeInOutCubic,
                                  height: isExpanded ? screenHeight * 0.75 : cardHeight,
                                  child: AnimatedScale(
                                    scale: isExpanded ? 1.0 : (isCollapsed ? 0.85 : 1.0 - (index * 0.005)),
                                    duration: const Duration(milliseconds: 550),
                                    child: _WalletCard(
                                      option: option, index: index, isExpanded: isExpanded,
                                      onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
                                      onAction: () => _showOptionDetail(context, option),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final ExploreOption option;
  final int index;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onAction;

  static const List<List<Color>> _palettes = [
    [Color(0xFF6366F1), Color(0xFF4338CA)], // Indigo
    [Color(0xFFEC4899), Color(0xFFBE185D)], // Pink
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Violet
    [Color(0xFF10B981), Color(0xFF047857)], // Emerald
    [Color(0xFFF59E0B), Color(0xFFB45309)], // Amber
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Blue
    [Color(0xFFEF4444), Color(0xFFB91C1C)], // Red
  ];

  const _WalletCard({required this.option, required this.index, required this.isExpanded, required this.onTap, required this.onAction});

  List<Color> get _colors => option.gradientColors.length >= 2 ? option.gradientColors : _palettes[index % _palettes.length];

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspective
        ..rotateX(isExpanded ? 0 : -0.06) // Slight tilt
        ..translate(0.0, isExpanded ? 0 : -index * 3.0, 0.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: _colors[1].withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 12), spreadRadius: -5),
              if (!isExpanded) BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
            ]),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Positioned(right: -30, bottom: -30, child: Icon(option.icon, size: 200, color: Colors.white.withOpacity(0.08))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.2))),
                    child: Image.asset(option.imagePath, width: 26, height: 26, errorBuilder: (_, __, ___) => Icon(option.icon, color: Colors.white, size: 26))),
                  const SizedBox(width: 16),
                  Expanded(child: Text(option.title, style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5))),
                  AnimatedRotation(turns: isExpanded ? 0.25 : 0, duration: const Duration(milliseconds: 400), child: Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.6), size: 16)),
                ]),
                if (isExpanded) ...[
                  const Spacer(),
                  Text(option.description, maxLines: 4, style: TextStyle(fontFamily: 'Segoe UI', fontSize: 15, height: 1.4, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: onAction,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))]),
                      child: Center(child: Text('Explore \${option.title}', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 16, fontWeight: FontWeight.w800, color: _colors[1]))))),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
`;

c = c.slice(0, startIdx) + newBuild + '\n' + c.slice(endIdx);
fs.writeFileSync('../lib/screens/explore_page.dart', c, 'utf8');
console.log('done, startIdx:', startIdx, 'endIdx:', endIdx);
