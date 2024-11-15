import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State class to handle the dock's reordering and animations.
class _DockState<T extends Object> extends State<Dock<T>> {
  // Internal list of items to manage the order dynamically.
  final List<T> _items = [];

  // Tracks the index of the item being hovered over for placeholder display.
  int? _hoveringIndex;

  // Tracks the data of the currently dragged item.
  T? _draggingItem;

  // Animation duration for the position changes.
  final Duration _animationDuration = const Duration(milliseconds: 300);

  // Dimensions for the items and margins
  final double _itemWidth = 48;
  final double _itemMargin = 8;

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the total number of positions (items + placeholder if present)
    int totalPositions = _items.length +
        (_hoveringIndex != null ? 1 : 0) -
        (_draggingItem != null ? 1 : 0);

    // Calculate the total width of the dock based on the number of items
    double dockWidth = totalPositions * (_itemWidth + 2 * _itemMargin);

    return DragTarget<T>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final receivedItem = details.data;
        setState(() {
          _items.remove(receivedItem);
          int insertIndex = _hoveringIndex ?? _items.length;
          _items.insert(insertIndex, receivedItem);
          _hoveringIndex = null;
          _draggingItem = null;
        });
      },
      onLeave: (data) {
        setState(() {
          _hoveringIndex = null;
        });
      },
      onMove: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);
        int newIndex = (localPosition.dx / (_itemWidth + 2)).floor();
        newIndex = newIndex.clamp(0, _items.length);
        if (newIndex != _hoveringIndex) {
          setState(() {
            _hoveringIndex = newIndex;
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: _animationDuration,
          curve: Curves.easeInOut,
          width: dockWidth,
          height: _itemWidth + 2 * _itemMargin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          child: Stack(
            children: _buildDockItems(),
          ),
        );
      },
    );
  }

  /// Builds the list of items in the dock, including any placeholders.
  List<Widget> _buildDockItems() {
    final dockItems = <Widget>[];
    final itemsToDisplay = List<T>.from(_items);

    // Remove the dragged item from the list
    if (_draggingItem != null) {
      itemsToDisplay.remove(_draggingItem);
    }

    double leftPosition = 0;

    int totalItems = itemsToDisplay.length + (_hoveringIndex != null ? 1 : 0);

    for (var index = 0; index < totalItems; index++) {
      // Add placeholder at the hovering index
      if (_hoveringIndex != null && index == _hoveringIndex) {
        dockItems.add(
          _buildPlaceholder(leftPosition),
        );
        leftPosition += _itemWidth + 2 * _itemMargin;
      } else {
        int itemIndex = index;
        if (_hoveringIndex != null && index > _hoveringIndex!) {
          itemIndex -= 1;
        }
        if (itemIndex < itemsToDisplay.length) {
          final item = itemsToDisplay[itemIndex];
          dockItems.add(
            _buildAnimatedDockItem(item, leftPosition),
          );
          leftPosition += _itemWidth + 2 * _itemMargin;
        }
      }
    }

    return dockItems;
  }

  /// Builds an animated placeholder to create space for dragging effects.
  Widget _buildPlaceholder(double leftPosition) {
    return AnimatedPositioned(
      key: const ValueKey('placeholder'),
      duration: _animationDuration,
      curve: Curves.easeInOut,
      left: leftPosition,
      child: SizedBox(
        width: _itemWidth + 2 * _itemMargin,
        height: _itemWidth + 2 * _itemMargin,
      ),
    );
  }

  /// Builds each draggable item in the dock and handles drag events.
  Widget _buildAnimatedDockItem(T item, double leftPosition) {
    return AnimatedPositioned(
      key: ValueKey(item),
      duration: _animationDuration,
      curve: Curves.easeOut,
      left: leftPosition,
      child: _buildDraggableItem(item),
    );
  }

  /// Builds each draggable item in the dock and handles drag events.
  Widget _buildDraggableItem(T item) {
    return Draggable<T>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: widget.builder(item),
      ),
      childWhenDragging: const SizedBox.shrink(),
      onDragStarted: () {
        setState(() {
          _draggingItem = item;
          _hoveringIndex = null;
        });
      },
      onDragEnd: (_) {
        setState(() {
          _draggingItem = null;
          _hoveringIndex = null;
        });
      },
      child: widget.builder(item),
    );
  }
}
