import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';

/// Player component for the puzzle game that represents the game mascot
/// Provides visual feedback and reactions to player actions
class Player extends SpriteAnimationComponent with HasKeyboardHandlerComponents, HasCollisionDetection {
  /// Current animation state of the player
  PlayerState _currentState = PlayerState.idle;
  
  /// Player's current score
  int _score = 0;
  
  /// Player's current star count
  int _stars = 0;
  
  /// Player's current lives (for potential future use)
  int _lives = 3;
  
  /// Animation components for different states
  late SpriteAnimation _idleAnimation;
  late SpriteAnimation _celebrateAnimation;
  late SpriteAnimation _disappointedAnimation;
  late SpriteAnimation _thinkingAnimation;
  
  /// Animation duration constants
  static const double _animationStepTime = 0.2;
  
  /// Callback functions for game events
  void Function(int newScore)? onScoreChanged;
  void Function(int newStars)? onStarsChanged;
  void Function(int newLives)? onLivesChanged;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize collision detection
    add(RectangleHitbox());
    
    // Load sprite animations
    await _loadAnimations();
    
    // Set initial state
    _setState(PlayerState.idle);
    
    // Set initial position and size
    size = Vector2(80, 80);
    anchor = Anchor.center;
  }

  /// Loads all sprite animations for different player states
  Future<void> _loadAnimations() async {
    try {
      // Load idle animation
      _idleAnimation = await gameRef.loadSpriteAnimation(
        'player_idle.png',
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: _animationStepTime * 2,
          textureSize: Vector2(64, 64),
        ),
      );
      
      // Load celebrate animation
      _celebrateAnimation = await gameRef.loadSpriteAnimation(
        'player_celebrate.png',
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: _animationStepTime,
          textureSize: Vector2(64, 64),
          loop: false,
        ),
      );
      
      // Load disappointed animation
      _disappointedAnimation = await gameRef.loadSpriteAnimation(
        'player_disappointed.png',
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: _animationStepTime,
          textureSize: Vector2(64, 64),
          loop: false,
        ),
      );
      
      // Load thinking animation
      _thinkingAnimation = await gameRef.loadSpriteAnimation(
        'player_thinking.png',
        SpriteAnimationData.sequenced(
          amount: 3,
          stepTime: _animationStepTime * 1.5,
          textureSize: Vector2(64, 64),
        ),
      );
    } catch (e) {
      // Fallback to single sprite if animations fail to load
      final fallbackSprite = await gameRef.loadSprite('player_idle.png');
      _idleAnimation = SpriteAnimation.spriteList([fallbackSprite], stepTime: 1.0);
      _celebrateAnimation = _idleAnimation;
      _disappointedAnimation = _idleAnimation;
      _thinkingAnimation = _idleAnimation;
    }
  }

  /// Sets the player's animation state
  void _setState(PlayerState newState) {
    if (_currentState == newState) return;
    
    _currentState = newState;
    
    switch (newState) {
      case PlayerState.idle:
        animation = _idleAnimation;
        break;
      case PlayerState.celebrating:
        animation = _celebrateAnimation;
        // Return to idle after celebration
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (_currentState == PlayerState.celebrating) {
            _setState(PlayerState.idle);
          }
        });
        break;
      case PlayerState.disappointed:
        animation = _disappointedAnimation;
        // Return to idle after disappointment
        Future.delayed(const Duration(milliseconds: 800), () {
          if (_currentState == PlayerState.disappointed) {
            _setState(PlayerState.idle);
          }
        });
        break;
      case PlayerState.thinking:
        animation = _thinkingAnimation;
        break;
    }
  }

  /// Triggers celebration animation when player succeeds
  void celebrate() {
    _setState(PlayerState.celebrating);
    
    // Add bounce effect
    final originalScale = scale.clone();
    scale = Vector2.all(1.2);
    
    Future.delayed(const Duration(milliseconds: 200), () {
      scale = originalScale;
    });
  }

  /// Triggers disappointed animation when player fails
  void showDisappointment() {
    _setState(PlayerState.disappointed);
    
    // Add shake effect
    final originalPosition = position.clone();
    
    for (int i = 0; i < 6; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (i % 2 == 0) {
          position = originalPosition + Vector2(2, 0);
        } else {
          position = originalPosition + Vector2(-2, 0);
        }
      });
    }
    
    Future.delayed(const Duration(milliseconds: 300), () {
      position = originalPosition;
    });
  }

  /// Shows thinking animation when player is considering moves
  void showThinking() {
    _setState(PlayerState.thinking);
  }

  /// Returns to idle state
  void returnToIdle() {
    _setState(PlayerState.idle);
  }

  /// Adds points to the player's score
  void addScore(int points) {
    _score += points;
    onScoreChanged?.call(_score);
  }

  /// Adds stars to the player's collection
  void addStars(int stars) {
    _stars += stars;
    onStarsChanged?.call(_stars);
  }

  /// Removes a life from the player
  void loseLife() {
    if (_lives > 0) {
      _lives--;
      onLivesChanged?.call(_lives);
      showDisappointment();
    }
  }

  /// Resets player stats for a new game
  void resetStats() {
    _score = 0;
    _stars = 0;
    _lives = 3;
    onScoreChanged?.call(_score);
    onStarsChanged?.call(_stars);
    onLivesChanged?.call(_lives);
    returnToIdle();
  }

  /// Getters for player stats
  int get score => _score;
  int get stars => _stars;
  int get lives => _lives;
  PlayerState get currentState => _currentState;

  @override
  void update(double dt) {
    super.update(dt);
    
    // Update animation based on current state
    if (animation != null) {
      animation!.update(dt);
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Handle keyboard input for debugging or accessibility
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.space:
          celebrate();
          return true;
        case LogicalKeyboardKey.keyH:
          showThinking();
          return true;
        case LogicalKeyboardKey.keyR:
          returnToIdle();
          return true;
      }
    }
    return false;
  }
}

/// Enumeration of possible player animation states
enum PlayerState {
  idle,
  celebrating,
  disappointed,
  thinking,
}