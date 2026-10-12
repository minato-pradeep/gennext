const fs = require('fs');
let c = fs.readFileSync('../lib/screens/explore_page.dart', 'utf8');

// Add missing fields after class declaration
c = c.replace(
  'class _ExplorePageState extends State<ExplorePage> with TickerProviderStateMixin {',
  `class _ExplorePageState extends State<ExplorePage> with TickerProviderStateMixin {
  double _scrollOffset = 0;
  int? _expandedIndex;`
);

// Add scroll listener in initState
c = c.replace(
  '_gridController.forward();',
  `_gridController.forward();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });`
);

fs.writeFileSync('../lib/screens/explore_page.dart', c, 'utf8');
console.log('done');
