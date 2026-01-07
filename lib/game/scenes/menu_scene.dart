import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Main menu scene component for the puzzle game
/// Displays title, play button, level select, settings, and animated background
class MenuScene extends Component with HasGameRef, TapCallbacks {
  late TextComponent titleText;
  late RectangleComponent playButton;
  late TextComponent playButtonText;
  late RectangleComponent levelSelectButton;
  late TextComponent levelSelectText;
  late RectangleComponent settingsButton;
  late TextComponent settingsText;
  late List<CircleComponent> backgroundShapes;
  
  final List<Color> colorPalette = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFF45B7D1),
    const Color(0xFF96CEB4),
    const Color(0xFFFFEAA7),
  ];
  
  double animationTime = 0.0;
  final double buttonWidth = 200.0;
  final double buttonHeight = 50.0;
  final double buttonSpacing = 20.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    final screenSize = gameRef.size;
    final centerX = screenSize.x / 2;
    
    // Create animated background shapes
    _createBackgroundShapes();
    
    // Create title
    titleText = TextComponent(
      text: 'Tile Swap Puzzle',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(centerX, screenSize.y * 0.25),
    );
    add(titleText);
    
    // Create play button
    final playButtonY = screenSize.y * 0.45;
    playButton = RectangleComponent(
      size: Vector2(buttonWidth, buttonHeight),
      paint: Paint()..color = colorPalette[0],
      anchor: Anchor.center,
      position: Vector2(centerX, playButtonY),
    );
    playButton.add(RectangleComponent(
      size: Vector2(buttonWidth - 4, buttonHeight - 4),
      paint: Paint()..color = Colors.white,
      anchor: Anchor.center,
      position: Vector2(buttonWidth / 2, buttonHeight / 2),
    ));
    add(playButton);
    
    playButtonText = TextComponent(
      text: 'PLAY',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(centerX, playButtonY),
    );
    add(playButtonText);
    
    // Create level select button
    final levelSelectY = playButtonY + buttonHeight + buttonSpacing;
    levelSelectButton = RectangleComponent(
      size: Vector2(buttonWidth, buttonHeight),
      paint: Paint()..color = colorPalette[1],
      anchor: Anchor.center,
      position: Vector2(centerX, levelSelectY),
    );
    levelSelectButton.add(RectangleComponent(
      size: Vector2(buttonWidth - 4, buttonHeight - 4),
      paint: Paint()..color = Colors.white,
      anchor: Anchor.center,
      position: Vector2(buttonWidth / 2, buttonHeight / 2),
    ));
    add(levelSelectButton);
    
    levelSelectText = TextComponent(
      text: 'LEVEL SELECT',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(centerX, levelSelectY),
    );
    add(levelSelectText);
    
    // Create settings button
    final settingsY = levelSelectY + buttonHeight + buttonSpacing;
    settingsButton = RectangleComponent(
      size: Vector2(buttonWidth, buttonHeight),
      paint: Paint()..color = colorPalette[2],
      anchor: Anchor.center,
      position: Vector2(centerX, settingsY),
    );
    settingsButton.add(RectangleComponent(
      size: Vector2(buttonWidth - 4, buttonHeight - 4),
      paint: Paint()..color = Colors.white,
      anchor: Anchor.center,
      position: Vector2(buttonWidth / 2, buttonHeight / 2),
    ));
    add(settingsButton);
    
    settingsText = TextComponent(
      text: 'SETTINGS',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(centerX, settingsY),
    );
    add(settingsText);
  }

  /// Creates animated background shapes for visual appeal
  void _createBackgroundShapes() {
    backgroundShapes = [];
    final screenSize = gameRef.size;
    final random = math.Random();
    
    for (int i = 0; i < 8; i++) {
      final shape = CircleComponent(
        radius: random.nextDouble() * 30 + 20,
        paint: Paint()
          ..color = colorPalette[random.nextInt(colorPalette.length)].withOpacity(0.3),
        position: Vector2(
          random.nextDouble() * screenSize.x,
          random.nextDouble() * screenSize.y,
        ),
      );
      backgroundShapes.add(shape);
      add(shape);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    animationTime += dt;
    
    // Animate background shapes
    for (int i = 0; i < backgroundShapes.length; i++) {
      final shape = backgroundShapes[i];
      final offset = math.sin(animationTime + i) * 2;
      shape.position.y += offset * dt;
      
      // Wrap around screen
      if (shape.position.y > gameRef.size.y + shape.radius) {
        shape.position.y = -shape.radius;
      }
      if (shape.position.y < -shape.radius) {
        shape.position.y = gameRef.size.y + shape.radius;
      }
    }
    
    // Animate title with subtle bounce
    final bounce = math.sin(animationTime * 2) * 2;
    titleText.position.y = gameRef.size.y * 0.25 + bounce;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    final tapPosition = event.localPosition;
    
    try {
      // Check play button tap
      if (_isPointInButton(tapPosition, playButton)) {
        _onPlayButtonTapped();
        return true;
      }
      
      // Check level select button tap
      if (_isPointInButton(tapPosition, levelSelectButton)) {
        _onLevelSelectButtonTapped();
        return true;
      }
      
      // Check settings button tap
      if (_isPointInButton(tapPosition, settingsButton)) {
        _onSettingsButtonTapped();
        return true;
      }
    } catch (e) {
      print('Error handling tap: $e');
    }
    
    return false;
  }

  /// Checks if a point is within a button's bounds
  bool _isPointInButton(Vector2 point, RectangleComponent button) {
    final buttonRect = button.toRect();
    return buttonRect.contains(point.toOffset());
  }

  /// Handles play button tap
  void _onPlayButtonTapped() {
    // Add button press animation
    playButton.scale = Vector2.all(0.95);
    playButtonText.scale = Vector2.all(0.95);
    
    // Reset scale after short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      playButton.scale = Vector2.all(1.0);
      playButtonText.scale = Vector2.all(1.0);
    });
    
    // Navigate to game scene
    print('Play button tapped - starting game');
    // TODO: Implement navigation to game scene
  }

  /// Handles level select button tap
  void _onLevelSelectButtonTapped() {
    // Add button press animation
    levelSelectButton.scale = Vector2.all(0.95);
    levelSelectText.scale = Vector2.all(0.95);
    
    // Reset scale after short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      levelSelectButton.scale = Vector2.all(1.0);
      levelSelectText.scale = Vector2.all(1.0);
    });
    
    print('Level select button tapped');
    // TODO: Implement navigation to level select scene
  }

  /// Handles settings button tap
  void _onSettingsButtonTapped() {
    // Add button press animation
    settingsButton.scale = Vector2.all(0.95);
    settingsText.scale = Vector2.all(0.95);
    
    // Reset scale after short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      settingsButton.scale = Vector2.all(1.0);
      settingsText.scale = Vector2.all(1.0);
    });
    
    print('Settings button tapped');
    // TODO: Implement navigation to settings scene
  }

  @override
  void onRemove() {
    backgroundShapes.clear();
    super.onRemove();
  }
}