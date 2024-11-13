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
  late final List<T> _items = widget.items.toList();

  // Tracks the index of the item being hovered over for placeholder display.
  int? _hoveringIndex;
  // Tracks the data of the currently dragged item.
  T? _draggingItem;

  @override
  Widget build(BuildContext context) {
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
        int newIndex = (localPosition.dx / (48 + 16)).floor();
        newIndex = newIndex.clamp(0, _items.length);
        if (newIndex != _hoveringIndex) {
          setState(() {
            _hoveringIndex = newIndex;
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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

    for (var index = 0; index <= itemsToDisplay.length; index++) {
      // Add placeholder at the hovering index
      if (_hoveringIndex == index) {
        dockItems.add(_buildPlaceholder());
      }
      if (index < itemsToDisplay.length) {
        final item = itemsToDisplay[index];
        dockItems.add(_buildDraggableItem(item));
      }
    }

    return dockItems;
  }

  /// Builds an animated placeholder to create space for dragging effects.
  Widget _buildPlaceholder() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 48,
      height: 48,
      margin: const EdgeInsets.all(8),
      curve: Curves.easeOut,
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
          _hoveringIndex = _items.indexOf(item);
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
