import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

/// Collectible item component that can be picked up by the player
/// Provides score value and visual/audio feedback when collected
class Collectible extends SpriteComponent with HasGameRef, CollisionCallbacks {
  /// Score value awarded when this collectible is picked up
  final int scoreValue;
  
  /// Whether this collectible has been collected
  bool _isCollected = false;
  
  /// Animation effects for visual appeal
  late final RotateEffect _rotationEffect;
  late final MoveEffect _floatEffect;
  
  /// Callback function triggered when collectible is picked up
  final void Function(Collectible collectible)? onCollected;
  
  /// Sound effect identifier to play when collected
  final String? soundEffect;
  
  /// Original position for floating animation
  late Vector2 _originalPosition;
  
  /// Animation parameters
  static const double _rotationSpeed = 2.0;
  static const double _floatAmplitude = 5.0;
  static const double _floatDuration = 1.5;

  Collectible({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
    this.scoreValue = 10,
    this.onCollected,
    this.soundEffect,
  }) : super(
          sprite: sprite,
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Store original position for floating animation
    _originalPosition = position.clone();
    
    // Add collision detection
    add(RectangleHitbox());
    
    // Setup rotation animation
    _rotationEffect = RotateEffect.by(
      2 * pi,
      EffectController(
        duration: _rotationSpeed,
        infinite: true,
      ),
    );
    add(_rotationEffect);
    
    // Setup floating animation
    _setupFloatingAnimation();
  }

  /// Sets up the floating up and down animation
  void _setupFloatingAnimation() {
    final floatUp = MoveToEffect(
      _originalPosition + Vector2(0, -_floatAmplitude),
      EffectController(
        duration: _floatDuration / 2,
        curve: Curves.easeInOut,
      ),
    );
    
    final floatDown = MoveToEffect(
      _originalPosition + Vector2(0, _floatAmplitude),
      EffectController(
        duration: _floatDuration / 2,
        curve: Curves.easeInOut,
      ),
    );
    
    final floatSequence = SequenceEffect([
      floatUp,
      floatDown,
    ]);
    
    _floatEffect = MoveEffect.by(
      Vector2.zero(),
      EffectController(
        duration: _floatDuration,
        infinite: true,
        alternate: true,
      ),
    );
    
    // Create continuous floating motion
    final continuousFloat = SequenceEffect([
      floatSequence,
    ], infinite: true);
    
    add(continuousFloat);
  }

  @override
  bool onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    // Check if collision is with player or player-controlled component
    if (!_isCollected && _shouldCollectFrom(other)) {
      _collect();
      return true;
    }
    return false;
  }

  /// Determines if this collectible should be collected by the given component
  bool _shouldCollectFrom(PositionComponent other) {
    // This can be customized based on your game's player component
    // For now, we'll assume any collision should trigger collection
    // In a real game, you might check: other is Player
    return true;
  }

  /// Handles the collection of this item
  void _collect() {
    if (_isCollected) return;
    
    _isCollected = true;
    
    try {
      // Play sound effect if specified
      if (soundEffect != null && gameRef.hasAudio) {
        gameRef.audio.play(soundEffect!);
      }
      
      // Trigger collection callback
      onCollected?.call(this);
      
      // Add collection animation before removing
      _playCollectionAnimation();
      
    } catch (e) {
      // Handle any errors gracefully
      print('Error during collectible collection: $e');
      // Still remove the collectible even if sound/callback fails
      removeFromParent();
    }
  }

  /// Plays a visual effect when the collectible is collected
  void _playCollectionAnimation() {
    // Stop existing animations
    _rotationEffect.removeFromParent();
    
    // Scale up and fade out effect
    final scaleEffect = ScaleEffect.to(
      Vector2.all(1.5),
      EffectController(duration: 0.3, curve: Curves.easeOut),
    );
    
    final fadeEffect = OpacityEffect.to(
      0.0,
      EffectController(duration: 0.3, curve: Curves.easeOut),
      onComplete: () {
        removeFromParent();
      },
    );
    
    add(scaleEffect);
    add(fadeEffect);
  }

  /// Gets the current score value of this collectible
  int get currentScoreValue => _isCollected ? 0 : scoreValue;
  
  /// Checks if this collectible has been collected
  bool get isCollected => _isCollected;
  
  /// Manually trigger collection (useful for testing or special game events)
  void forceCollect() {
    _collect();
  }
  
  /// Reset the collectible to its uncollected state
  void reset() {
    if (!_isCollected) return;
    
    _isCollected = false;
    opacity = 1.0;
    scale = Vector2.all(1.0);
    position = _originalPosition.clone();
    
    // Restart animations
    if (!_rotationEffect.isMounted) {
      add(_rotationEffect);
    }
  }
}