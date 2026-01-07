import 'dart:async';
import 'dart:math';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Game states for the puzzle game
enum GameState {
  playing,
  paused,
  gameOver,
  levelComplete,
  loading
}

/// Main game class for the tile-swapping puzzle game
class Batch20260107105243Puzzle01Game extends FlameGame
    with HasTappables, HasCollisionDetection {
  
  /// Current game state
  GameState gameState = GameState.loading;
  
  /// Current level (1-10)
  int currentLevel = 1;
  
  /// Player's current score
  int score = 0;
  
  /// Stars earned in current level
  int starsEarned = 0;
  
  /// Total stars collected
  int totalStars = 0;
  
  /// Time remaining in seconds
  double timeRemaining = 60.0;
  
  /// Grid size for current level
  int gridSize = 3;
  
  /// Number of colors in current level
  int colorCount = 3;
  
  /// Game grid containing tiles
  late List<List<GameTile>> gameGrid;
  
  /// Target pattern to match
  late List<List<int>> targetPattern;
  
  /// Currently selected tile for swapping
  GameTile? selectedTile;
  
  /// Timer component for countdown
  late Timer gameTimer;
  
  /// Grid container component
  late GridContainer gridContainer;
  
  /// Pattern display component
  late PatternDisplay patternDisplay;
  
  /// Game controller reference
  GameController? gameController;
  
  /// Analytics service reference
  AnalyticsService? analyticsService;
  
  /// Available colors for tiles
  static const List<Color> tileColors = [
    Color(0xFFFF6B6B), // Red
    Color(0xFF4ECDC4), // Teal
    Color(0xFF45B7D1), // Blue
    Color(0xFF96CEB4), // Green
    Color(0xFFFFEAA7), // Yellow
    Color(0xFFDDA0DD), // Plum
  ];
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Setup camera
    camera.viewfinder.visibleGameSize = size;
    
    // Initialize timer
    gameTimer = Timer(
      1.0,
      repeat: true,
      onTick: _onTimerTick,
    );
    
    // Load level configuration
    await _loadLevel(currentLevel);
    
    // Setup UI overlays
    _setupOverlays();
    
    // Log game start
    analyticsService?.logEvent('game_start', {
      'level': currentLevel,
    });
  }
  
  /// Loads level configuration and initializes game components
  Future<void> _loadLevel(int level) async {
    gameState = GameState.loading;
    
    // Configure level parameters based on difficulty curve
    _configureLevelParameters(level);
    
    // Generate target pattern
    targetPattern = _generateTargetPattern();
    
    // Initialize game grid
    gameGrid = _initializeGrid();
    
    // Create grid container
    gridContainer = GridContainer(
      gridSize: gridSize,
      tileSize: _calculateTileSize(),
      onTileSelected: _onTileSelected,
    );
    add(gridContainer);
    
    // Create pattern display
    patternDisplay = PatternDisplay(
      pattern: targetPattern,
      colors: tileColors.take(colorCount).toList(),
      size: Vector2(150, 150),
    );
    patternDisplay.position = Vector2(size.x / 2 - 75, 50);
    add(patternDisplay);
    
    // Populate grid with tiles
    _populateGrid();
    
    // Reset timer
    timeRemaining = _getTimeLimit(level);
    gameTimer.start();
    
    gameState = GameState.playing;
    
    // Log level start
    analyticsService?.logEvent('level_start', {
      'level': level,
      'grid_size': gridSize,
      'color_count': colorCount,
      'time_limit': timeRemaining,
    });
  }
  
  /// Configures level parameters based on current level
  void _configureLevelParameters(int level) {
    if (level <= 3) {
      gridSize = 3;
      colorCount = 3;
    } else if (level <= 6) {
      gridSize = 4;
      colorCount = 4;
    } else {
      gridSize = 5;
      colorCount = min(6, 3 + (level - 1) ~/ 2);
    }
  }
  
  /// Generates a random target pattern for the current level
  List<List<int>> _generateTargetPattern() {
    final random = Random();
    final pattern = <List<int>>[];
    
    for (int row = 0; row < gridSize; row++) {
      final rowPattern = <int>[];
      for (int col = 0; col < gridSize; col++) {
        rowPattern.add(random.nextInt(colorCount));
      }
      pattern.add(rowPattern);
    }
    
    return pattern;
  }
  
  /// Initializes empty game grid
  List<List<GameTile>> _initializeGrid() {
    final grid = <List<GameTile>>[];
    for (int row = 0; row < gridSize; row++) {
      final rowTiles = <GameTile>[];
      for (int col = 0; col < gridSize; col++) {
        rowTiles.add(GameTile(
          row: row,
          col: col,
          colorIndex: 0,
          color: tileColors[0],
        ));
      }
      grid.add(rowTiles);
    }
    return grid;
  }
  
  /// Populates grid with random colored tiles
  void _populateGrid() {
    final random = Random();
    final tileSize = _calculateTileSize();
    final startX = (size.x - (gridSize * tileSize)) / 2;
    final startY = size.y / 2 - (gridSize * tileSize) / 2;
    
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final colorIndex = random.nextInt(colorCount);
        final tile = gameGrid[row][col];
        
        tile.colorIndex = colorIndex;
        tile.color = tileColors[colorIndex];
        tile.size = Vector2.all(tileSize);
        tile.position = Vector2(
          startX + col * tileSize,
          startY + row * tileSize,
        );
        
        gridContainer.add(tile);
      }
    }
  }
  
  /// Calculates appropriate tile size based on screen size and grid size
  double _calculateTileSize() {
    final availableWidth = size.x * 0.8;
    final availableHeight = size.y * 0.4;
    final maxSize = min(availableWidth, availableHeight);
    return maxSize / gridSize;
  }
  
  /// Gets time limit for specified level
  double _getTimeLimit(int level) {
    if (level <= 3) return 60.0;
    if (level <= 6) return 45.0;
    return 30.0;
  }
  
  /// Handles tile selection for swapping
  void _onTileSelected(GameTile tile) {
    if (gameState != GameState.playing) return;
    
    if (selectedTile == null) {
      // First tile selection
      selectedTile = tile;
      tile.setSelected(true);
    } else if (selectedTile == tile) {
      // Deselect same tile
      tile.setSelected(false);
      selectedTile = null;
    } else if (_areAdjacent(selectedTile!, tile)) {
      // Swap adjacent tiles
      _swapTiles(selectedTile!, tile);
      selectedTile!.setSelected(false);
      selectedTile = null;
      
      // Check for pattern match
      _checkPatternMatch();
    } else {
      // Select new tile
      selectedTile!.setSelected(false);
      selectedTile = tile;
      tile.setSelected(true);
    }
  }
  
  /// Checks if two tiles are adjacent
  bool _areAdjacent(GameTile tile1, GameTile tile2) {
    final rowDiff = (tile1.row - tile2.row).abs();
    final colDiff = (tile1.col - tile2.col).abs();
    return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1);
  }
  
  /// Swaps two tiles' colors and positions
  void _swapTiles(GameTile tile1, GameTile tile2) {
    final tempColorIndex = tile1.colorIndex;
    final tempColor = tile1.color;
    
    tile1.colorIndex = tile2.colorIndex;
    tile1.color = tile2.color;
    tile2.colorIndex = tempColorIndex;
    tile2.color = tempColor;
    
    tile1.updateVisuals();
    tile2.updateVisuals();
    
    // Play swap sound effect
    _playSwapSound();
  }
  
  /// Checks if current grid matches target pattern
  void _checkPatternMatch() {
    bool matches = true;
    
    for (int row = 0; row < gridSize && matches; row++) {
      for (int col = 0; col < gridSize && matches; col++) {
        if (gameGrid[row][col].colorIndex != targetPattern[row][col]) {
          matches = false;
        }
      }
    }
    
    if (matches) {
      _onLevelComplete();
    }
  }
  
  /// Handles level completion
  void _onLevelComplete() {
    gameState = GameState.levelComplete;
    gameTimer.stop();
    
    // Calculate stars based on time remaining
    starsEarned = _calculateStars();
    totalStars += starsEarned;
    
    // Calculate score bonus
    final timeBonus = (timeRemaining * 10).round();
    score += 100 + timeBonus + (starsEarned * 50);
    
    // Show level complete overlay
    overlays.add('LevelComplete');
    
    // Play success sound
    _playSuccessSound();
    
    // Log level completion
    analyticsService?.logEvent('level_complete', {
      'level': currentLevel,
      'time_remaining': timeRemaining,
      'stars_earned': starsEarned,
      'score': score,
    });
  }
  
  /// Calculates stars earned based on performance
  int _calculateStars() {
    final timeLimit = _getTimeLimit(currentLevel);
    final timeRatio = timeRemaining / timeLimit;
    
    if (timeRatio >= 0.7) return 3;
    if (timeRatio >= 0.4) return 2;
    return 1;
  }
  
  /// Handles timer tick
  void _onTimerTick() {
    if (gameState == GameState.playing) {
      timeRemaining -= 1.0;
      
      if (timeRemaining <= 0) {
        _onTimeExpired();
      }
    }
  }
  
  /// Handles time expiration
  void _onTimeExpired() {
    gameState = GameState.gameOver;
    gameTimer.stop();
    
    // Show game over overlay
    overlays.add('GameOver');
    
    // Play failure sound
    _playFailureSound();
    
    // Log level failure
    analyticsService?.logEvent('level_fail', {
      'level': currentLevel,
      'reason': 'timer_expires',
      'score': score,
    });
  }
  
  /// Advances to next level
  void nextLevel() {
    if (currentLevel < 10) {
      currentLevel++;
      _loadLevel(currentLevel);
      overlays.remove('LevelComplete');
    } else {
      // Game completed
      overlays.remove('LevelComplete');
      overlays.add('GameComplete');
    }
  }
  
  /// Restarts current level
  void restartLevel() {
    score = max(0, score - 50); // Small penalty for restart
    _loadLevel(currentLevel);
    overlays.remove('GameOver');
  }
  
  /// Pauses the game
  void pauseGame() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
      gameTimer.stop();
      overlays.add('PauseMenu');
    }
  }
  
  /// Resumes the game
  void resumeGame() {
    if (gameState == GameState.paused) {
      gameState = GameState.playing;
      gameTimer.start();
      overlays.remove('PauseMenu');
    }
  }
  
  /// Uses hint power-up
  void useHint() {
    if (totalStars >= 1 && gameState == GameState.playing) {
      totalStars--;
      _showHint();
      
      analyticsService?.logEvent('hint_used', {
        'level': currentLevel,
        'stars_remaining': totalStars,
      });
    }
  }
  
  /// Shows hint by highlighting correct tiles
  void _showHint() {
    // Find first incorrect tile
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (gameGrid[row][col].colorIndex != targetPattern[row][col]) {
          gameGrid[row][col].showHint();
          return;
        }
      }
    }
  }
  
  /// Adds extra time power-up
  void addExtraTime() {
    if (totalStars >= 2 && gameState == GameState.playing) {
      totalStars -= 2;
      timeRemaining += 15.0;
      
      analyticsService?.logEvent('extra_time_used', {
        'level': currentLevel,
        'stars_remaining': totalStars,
      });
    }
  }
  
  /// Sets up UI overlays
  void _setupOverlays() {
    overlays.addEntry('HUD', (context, game) => GameHUD(game: this));
  }
  
  /// Plays tile swap sound effect
  void _playSwapSound() {
    // TODO: Implement sound effect
  }
  
  /// Plays success sound effect
  void _playSuccessSound() {
    // TODO: Implement sound effect
  }
  
  /// Plays failure sound effect
  void _playFailureSound() {
    // TODO: Implement sound effect
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    gameTimer.update(dt);
  }
  
  @override
  void onRemove() {
    gameTimer.stop();
    super.onRemove();
  }
}

/// Individual game tile component
class GameTile extends RectangleComponent with Tappable {
  final int row;
  final int col;
  int colorIndex;
  Color color;
  bool isSelected = false;
  bool showingHint = false;
  
  final Function(GameTile) onTap;
  
  GameTile({
    required this.row,
    required this.col,
    required this.colorIndex,
    required this.color,
    required this.onTap,
  }) : super(
    paint: Paint()..color = color,
  );
  
  @override
  bool onTapDown(TapDownInfo info) {
    onTap(this);
    return true;
  }