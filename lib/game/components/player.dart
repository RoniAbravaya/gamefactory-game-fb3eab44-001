import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Player component for the puzzle game that manages the player's mascot character
/// Handles animations, reactions to game events, and visual feedback
class Player extends SpriteAnimationComponent with HasKeyboardHandlerComponents, HasCollisionDetection {
  /// Current health of the player
  int _health = 3;
  
  /// Maximum health the player can have
  final int _maxHealth = 3;
  
  /// Whether the player is currently invulnerable
  bool _isInvulnerable = false;
  
  /// Duration of invulnerability frames in seconds
  final double _invulnerabilityDuration = 2.0;
  
  /// Timer for invulnerability frames
  Timer? _invulnerabilityTimer;
  
  /// Current animation state
  PlayerAnimationState _currentState = PlayerAnimationState.idle;
  
  /// Map of animation states to their corresponding sprite animations
  late Map<PlayerAnimationState, SpriteAnimation> _animations;
  
  /// Reference to the game world for collision detection
  late Component gameWorld;
  
  /// Player's movement speed (not used for movement but for animation timing)
  final double animationSpeed = 0.15;
  
  /// Scale factor for the player sprite
  final double playerScale = 1.5;

  /// Getter for current health
  int get health => _health;
  
  /// Getter for maximum health
  int get maxHealth => _maxHealth;
  
  /// Getter for invulnerability status
  bool get isInvulnerable => _isInvulnerable;
  
  /// Getter for current animation state
  PlayerAnimationState get currentState => _currentState;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Set initial size and position
    size = Vector2(64, 64);
    scale = Vector2.all(playerScale);
    
    // Position player at bottom center of screen
    position = Vector2(
      (gameRef.size.x - size.x * scale.x) / 2,
      gameRef.size.y - size.y * scale.y - 100,
    );
    
    // Load animations
    await _loadAnimations();
    
    // Set initial animation
    _changeAnimationState(PlayerAnimationState.idle);
    
    // Add collision detection
    add(RectangleHitbox());
  }

  /// Loads all sprite animations for different player states
  Future<void> _loadAnimations() async {
    _animations = {
      PlayerAnimationState.idle: await gameRef.loadSpriteAnimation(
        'player_idle.png',
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: animationSpeed * 2,
          textureSize: Vector2(64, 64),
        ),
      ),
      PlayerAnimationState.happy: await gameRef.loadSpriteAnimation(
        'player_happy.png',
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: animationSpeed,
          textureSize: Vector2(64, 64),
          loop: false,
        ),
      ),
      PlayerAnimationState.sad: await gameRef.loadSpriteAnimation(
        'player_sad.png',
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: animationSpeed * 1.5,
          textureSize: Vector2(64, 64),
          loop: false,
        ),
      ),
      PlayerAnimationState.thinking: await gameRef.loadSpriteAnimation(
        'player_thinking.png',
        SpriteAnimationData.sequenced(
          amount: 3,
          stepTime: animationSpeed * 3,
          textureSize: Vector2(64, 64),
        ),
      ),
      PlayerAnimationState.celebrating: await gameRef.loadSpriteAnimation(
        'player_celebrating.png',
        SpriteAnimationData.sequenced(
          amount: 8,
          stepTime: animationSpeed * 0.8,
          textureSize: Vector2(64, 64),
          loop: false,
        ),
      ),
      PlayerAnimationState.hurt: await gameRef.loadSpriteAnimation(
        'player_hurt.png',
        SpriteAnimationData.sequenced(
          amount: 3,
          stepTime: animationSpeed,
          textureSize: Vector2(64, 64),
          loop: false,
        ),
      ),
    };
  }

  /// Changes the player's animation state
  void _changeAnimationState(PlayerAnimationState newState) {
    if (_currentState == newState) return;
    
    _currentState = newState;
    animation = _animations[newState];
    
    // Handle state-specific logic
    switch (newState) {
      case PlayerAnimationState.happy:
      case PlayerAnimationState.celebrating:
        // Add bounce effect
        add(ScaleEffect.to(
          Vector2.all(playerScale * 1.2),
          EffectController(duration: 0.2, reverseDuration: 0.2),
        ));
        break;
      case PlayerAnimationState.hurt:
        // Add shake effect
        add(MoveEffect.by(
          Vector2(5, 0),
          EffectController(
            duration: 0.1,
            reverseDuration: 0.1,
            repeatCount: 3,
          ),
        ));
        break;
      case PlayerAnimationState.sad:
        // Slight scale down
        add(ScaleEffect.to(
          Vector2.all(playerScale * 0.9),
          EffectController(duration: 0.3, reverseDuration: 0.3),
        ));
        break;
      default:
        break;
    }
  }

  /// Reacts to successful pattern completion
  void onPatternCompleted() {
    _changeAnimationState(PlayerAnimationState.celebrating);
    
    // Return to idle after celebration
    Timer(2.0, () {
      if (mounted) {
        _changeAnimationState(PlayerAnimationState.idle);
      }
    });
  }

  /// Reacts to level failure
  void onLevelFailed() {
    _changeAnimationState(PlayerAnimationState.sad);
    
    // Return to idle after showing sadness
    Timer(2.0, () {
      if (mounted) {
        _changeAnimationState(PlayerAnimationState.idle);
      }
    });
  }

  /// Reacts to player making a move
  void onPlayerMove() {
    if (_currentState == PlayerAnimationState.idle) {
      _changeAnimationState(PlayerAnimationState.thinking);
      
      // Return to idle after a short time
      Timer(1.0, () {
        if (mounted && _currentState == PlayerAnimationState.thinking) {
          _changeAnimationState(PlayerAnimationState.idle);
        }
      });
    }
  }

  /// Reacts to good move (getting closer to solution)
  void onGoodMove() {
    _changeAnimationState(PlayerAnimationState.happy);
    
    // Return to idle after showing happiness
    Timer(1.0, () {
      if (mounted) {
        _changeAnimationState(PlayerAnimationState.idle);
      }
    });
  }

  /// Takes damage and handles invulnerability frames
  void takeDamage(int damage) {
    if (_isInvulnerable || _health <= 0) return;
    
    _health = (_health - damage).clamp(0, _maxHealth);
    
    // Change to hurt animation
    _changeAnimationState(PlayerAnimationState.hurt);
    
    // Start invulnerability frames
    _startInvulnerability();
    
    // Return to appropriate state after hurt animation
    Timer(0.5, () {
      if (mounted) {
        if (_health <= 0) {
          onLevelFailed();
        } else {
          _changeAnimationState(PlayerAnimationState.idle);
        }
      }
    });
  }

  /// Heals the player
  void heal(int amount) {
    _health = (_health + amount).clamp(0, _maxHealth);
    onGoodMove(); // Show happy animation
  }

  /// Starts invulnerability frames
  void _startInvulnerability() {
    _isInvulnerable = true;
    
    // Add flashing effect during invulnerability
    final flashEffect = OpacityEffect.fadeOut(
      EffectController(
        duration: 0.2,
        reverseDuration: 0.2,
        infinite: true,
      ),
    );
    add(flashEffect);
    
    // End invulnerability after duration
    _invulnerabilityTimer?.cancel();
    _invulnerabilityTimer = Timer(_invulnerabilityDuration, () {
      _isInvulnerable = false;
      flashEffect.removeFromParent();
      opacity = 1.0;
    });
  }

  /// Resets player to initial state
  void reset() {
    _health = _maxHealth;
    _isInvulnerable = false;
    _invulnerabilityTimer?.cancel();
    _changeAnimationState(PlayerAnimationState.idle);
    opacity = 1.0;
    scale = Vector2.all(playerScale);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Handle animation completion for non-looping animations
    if (animation?.done() == true) {
      switch (_currentState) {
        case PlayerAnimationState.happy:
        case PlayerAnimationState.celebrating:
        case PlayerAnimationState.hurt:
        case PlayerAnimationState.sad:
          _changeAnimationState(PlayerAnimationState.idle);
          break;
        default:
          break;
      }
    }
  }

  @override
  bool onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Handle collisions with game objects
    if (other is Collectible && !_isInvulnerable) {
      other.collect();
      onGoodMove();
      return false;
    }
    
    if (other is Obstacle && !_isInvulnerable) {
      takeDamage(1);
      return true;
    }
    
    return false;
  }

  @override
  void onRemove() {
    _invulnerabilityTimer?.cancel();
    super.onRemove();
  }
}

/// Enumeration of player animation states
enum PlayerAnimationState {
  idle,
  happy,
  sad,
  thinking,
  celebrating,
  hurt,
}

/// Base class for collectible items
abstract class Collectible extends PositionComponent {
  void collect();
}

/// Base class for obstacles
abstract class Obstacle extends PositionComponent {
  // Obstacle-specific properties can be added here
}