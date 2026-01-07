import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Obstacle component that blocks tile swaps and adds challenge to the puzzle
/// Can be static or moving, with various visual styles
class Obstacle extends PositionComponent with HasCollisionDetection, CollisionCallbacks {
  /// Type of obstacle determining behavior and appearance
  final ObstacleType type;
  
  /// Whether this obstacle is currently active
  bool isActive = true;
  
  /// Movement speed for moving obstacles
  final double moveSpeed;
  
  /// Direction vector for movement
  Vector2 _moveDirection = Vector2.zero();
  
  /// Visual component for the obstacle
  late Component _visual;
  
  /// Timer for pulsing animation
  double _pulseTimer = 0.0;
  
  /// Random generator for movement patterns
  static final math.Random _random = math.Random();

  Obstacle({
    required this.type,
    required Vector2 position,
    required Vector2 size,
    this.moveSpeed = 50.0,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add collision detection
    add(RectangleHitbox(
      size: size,
      anchor: Anchor.center,
    ));
    
    // Create visual representation based on type
    await _createVisual();
    
    // Initialize movement direction for moving obstacles
    if (type == ObstacleType.moving) {
      _initializeMovement();
    }
    
    // Add entrance animation
    _addEntranceAnimation();
  }

  /// Creates the visual representation of the obstacle
  Future<void> _createVisual() async {
    switch (type) {
      case ObstacleType.static:
        _visual = _createStaticVisual();
        break;
      case ObstacleType.moving:
        _visual = _createMovingVisual();
        break;
      case ObstacleType.pulsing:
        _visual = _createPulsingVisual();
        break;
      case ObstacleType.rotating:
        _visual = _createRotatingVisual();
        break;
    }
    
    add(_visual);
  }

  /// Creates visual for static obstacles
  Component _createStaticVisual() {
    return RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFF8B4513)
        ..style = PaintingStyle.fill,
      anchor: Anchor.center,
    )..add(
      RectangleComponent(
        size: size * 0.8,
        paint: Paint()
          ..color = const Color(0xFFA0522D)
          ..style = PaintingStyle.fill,
        anchor: Anchor.center,
      ),
    );
  }

  /// Creates visual for moving obstacles
  Component _createMovingVisual() {
    final visual = CircleComponent(
      radius: size.x / 2,
      paint: Paint()
        ..color = const Color(0xFFDC143C)
        ..style = PaintingStyle.fill,
      anchor: Anchor.center,
    );
    
    // Add inner circle for depth
    visual.add(
      CircleComponent(
        radius: size.x / 3,
        paint: Paint()
          ..color = const Color(0xFFFF6347)
          ..style = PaintingStyle.fill,
        anchor: Anchor.center,
      ),
    );
    
    return visual;
  }

  /// Creates visual for pulsing obstacles
  Component _createPulsingVisual() {
    return RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFF9932CC)
        ..style = PaintingStyle.fill,
      anchor: Anchor.center,
    );
  }

  /// Creates visual for rotating obstacles
  Component _createRotatingVisual() {
    final visual = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFF4169E1)
        ..style = PaintingStyle.fill,
      anchor: Anchor.center,
    );
    
    // Add rotating effect
    visual.add(
      RotateEffect.by(
        2 * math.pi,
        EffectController(duration: 3.0, infinite: true),
      ),
    );
    
    return visual;
  }

  /// Initializes movement direction for moving obstacles
  void _initializeMovement() {
    final angle = _random.nextDouble() * 2 * math.pi;
    _moveDirection = Vector2(math.cos(angle), math.sin(angle));
  }

  /// Adds entrance animation when obstacle spawns
  void _addEntranceAnimation() {
    scale = Vector2.zero();
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(
          duration: 0.5,
          curve: Curves.elasticOut,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isActive) return;
    
    switch (type) {
      case ObstacleType.moving:
        _updateMovement(dt);
        break;
      case ObstacleType.pulsing:
        _updatePulsing(dt);
        break;
      case ObstacleType.static:
      case ObstacleType.rotating:
        // No special update needed
        break;
    }
  }

  /// Updates movement for moving obstacles
  void _updateMovement(double dt) {
    final newPosition = position + (_moveDirection * moveSpeed * dt);
    
    // Check bounds and bounce if necessary
    if (parent != null) {
      final parentSize = parent!.size;
      
      if (newPosition.x <= size.x / 2 || newPosition.x >= parentSize.x - size.x / 2) {
        _moveDirection.x *= -1;
      }
      
      if (newPosition.y <= size.y / 2 || newPosition.y >= parentSize.y - size.y / 2) {
        _moveDirection.y *= -1;
      }
    }
    
    position = newPosition;
  }

  /// Updates pulsing animation
  void _updatePulsing(double dt) {
    _pulseTimer += dt;
    final pulseScale = 1.0 + 0.2 * math.sin(_pulseTimer * 4);
    _visual.scale = Vector2.all(pulseScale);
    
    // Update color intensity
    if (_visual is RectangleComponent) {
      final rect = _visual as RectangleComponent;
      final intensity = (math.sin(_pulseTimer * 4) + 1) / 2;
      rect.paint.color = Color.lerp(
        const Color(0xFF9932CC),
        const Color(0xFFDA70D6),
        intensity,
      )!;
    }
  }

  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Handle collision with other game components
    try {
      _handleCollision(other);
      return true;
    } catch (e) {
      // Log error but don't crash the game
      print('Error handling obstacle collision: $e');
      return false;
    }
  }

  /// Handles collision with other components
  void _handleCollision(PositionComponent other) {
    // This would be implemented based on the specific game needs
    // For example, blocking tile swaps or triggering game events
    
    // Add visual feedback for collision
    _addCollisionEffect();
  }

  /// Adds visual effect when collision occurs
  void _addCollisionEffect() {
    add(
      ScaleEffect.by(
        Vector2.all(1.2),
        EffectController(
          duration: 0.2,
          reverseDuration: 0.2,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  /// Removes the obstacle with animation
  void destroy() {
    isActive = false;
    
    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(
          duration: 0.3,
          curve: Curves.easeIn,
        ),
        onComplete: () => removeFromParent(),
      ),
    );
    
    // Add particle effect for destruction
    _addDestructionEffect();
  }

  /// Adds particle effect when obstacle is destroyed
  void _addDestructionEffect() {
    // This would create particle effects based on the game's particle system
    // For now, just add a simple fade effect
    add(
      OpacityEffect.to(
        0.0,
        EffectController(duration: 0.3),
      ),
    );
  }

  /// Temporarily disables the obstacle
  void disable(double duration) {
    isActive = false;
    
    add(
      OpacityEffect.to(
        0.3,
        EffectController(duration: 0.2),
        onComplete: () {
          Future.delayed(Duration(milliseconds: (duration * 1000).round()), () {
            if (isMounted) {
              enable();
            }
          });
        },
      ),
    );
  }

  /// Re-enables the obstacle
  void enable() {
    isActive = true;
    
    add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: 0.2),
      ),
    );
  }

  /// Changes the obstacle type dynamically
  void changeType(ObstacleType newType) {
    if (type == newType) return;
    
    // Remove current visual
    _visual.removeFromParent();
    
    // Create new visual
    _createVisual().then((_) {
      if (newType == ObstacleType.moving) {
        _initializeMovement();
      }
    });
  }
}

/// Enum defining different types of obstacles
enum ObstacleType {
  /// Static obstacle that doesn't move
  static,
  
  /// Moving obstacle that bounces around
  moving,
  
  /// Pulsing obstacle that changes size and color
  pulsing,
  
  /// Rotating obstacle that spins continuously
  rotating,
}