import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Main game scene component that manages the puzzle game state and logic
class GameScene extends Component with HasGameRef, TapCallbacks {
  /// Current level being played
  int currentLevel = 1;
  
  /// Game grid size based on level
  int gridSize = 3;
  
  /// Number of colors available in current level
  int colorCount = 3;
  
  /// Time limit for current level in seconds
  int timeLimit = 60;
  
  /// Current remaining time
  double remainingTime = 60.0;
  
  /// Player's current score
  int score = 0;
  
  /// Player's current stars
  int stars = 0;
  
  /// Game state flags
  bool isGameActive = false;
  bool isGamePaused = false;
  bool isLevelComplete = false;
  bool isGameOver = false;
  
  /// Game grid representing current tile state
  late List<List<int>> gameGrid;
  
  /// Target pattern to match
  late List<List<int>> targetPattern;
  
  /// Selected tile position for swapping
  Vector2? selectedTile;
  
  /// Timer for countdown
  Timer? gameTimer;
  
  /// UI Components
  late TextComponent scoreText;
  late TextComponent timerText;
  late TextComponent levelText;
  late RectangleComponent gridBackground;
  late List<List<RectangleComponent>> tileComponents;
  
  /// Color palette for tiles
  final List<Color> tileColors = [
    const Color(0xFFFF6B6B), // Red
    const Color(0xFF4ECDC4), // Teal
    const Color(0xFF45B7D1), // Blue
    const Color(0xFF96CEB4), // Green
    const Color(0xFFFFEAA7), // Yellow
    const Color(0xFFDDA0DD), // Plum
  ];
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _initializeLevel();
    await _createUI();
    await _createGrid();
    _startLevel();
  }
  
  /// Initialize level parameters based on current level
  Future<void> _initializeLevel() async {
    try {
      // Calculate level parameters
      if (currentLevel <= 3) {
        gridSize = 3;
        colorCount = 3;
        timeLimit = 60;
      } else if (currentLevel <= 6) {
        gridSize = 4;
        colorCount = 4;
        timeLimit = 45;
      } else {
        gridSize = 5;
        colorCount = min(6, 3 + (currentLevel - 1) ~/ 2);
        timeLimit = max(30, 60 - (currentLevel - 1) * 3);
      }
      
      remainingTime = timeLimit.toDouble();
      
      // Initialize grids
      gameGrid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
      targetPattern = List.generate(gridSize, (_) => List.filled(gridSize, 0));
      
      _generateRandomGrid();
      _generateTargetPattern();
      
    } catch (e) {
      print('Error initializing level: $e');
      // Fallback to level 1 settings
      gridSize = 3;
      colorCount = 3;
      timeLimit = 60;
      remainingTime = 60.0;
    }
  }
  
  /// Create UI components
  Future<void> _createUI() async {
    // Score display
    scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(20, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);
    
    // Timer display
    timerText = TextComponent(
      text: 'Time: ${remainingTime.toInt()}',
      position: Vector2(game.size.x - 150, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(timerText);
    
    // Level display
    levelText = TextComponent(
      text: 'Level $currentLevel',
      position: Vector2(game.size.x / 2 - 50, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(levelText);
  }
  
  /// Create game grid visual components
  Future<void> _createGrid() async {
    final double tileSize = min(
      (game.size.x - 40) / gridSize,
      (game.size.y - 200) / (gridSize * 2 + 1),
    );
    
    final Vector2 gridStart = Vector2(
      (game.size.x - tileSize * gridSize) / 2,
      150,
    );
    
    // Create grid background
    gridBackground = RectangleComponent(
      position: gridStart - Vector2(10, 10),
      size: Vector2(tileSize * gridSize + 20, tileSize * gridSize + 20),
      paint: Paint()..color = Colors.black26,
    );
    add(gridBackground);
    
    // Create tile components
    tileComponents = List.generate(gridSize, (row) {
      return List.generate(gridSize, (col) {
        final tile = RectangleComponent(
          position: gridStart + Vector2(col * tileSize, row * tileSize),
          size: Vector2(tileSize - 2, tileSize - 2),
          paint: Paint()..color = tileColors[gameGrid[row][col]],
        );
        add(tile);
        return tile;
      });
    });
    
    // Create target pattern display
    final Vector2 targetStart = Vector2(
      (game.size.x - tileSize * gridSize * 0.6) / 2,
      gridStart.y + tileSize * gridSize + 50,
    );
    
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final targetTile = RectangleComponent(
          position: targetStart + Vector2(col * tileSize * 0.6, row * tileSize * 0.6),
          size: Vector2(tileSize * 0.6 - 1, tileSize * 0.6 - 1),
          paint: Paint()..color = tileColors[targetPattern[row][col]],
        );
        add(targetTile);
      }
    }
  }
  
  /// Generate random initial grid
  void _generateRandomGrid() {
    final random = Random();
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        gameGrid[row][col] = random.nextInt(colorCount);
      }
    }
  }
  
  /// Generate target pattern to match
  void _generateTargetPattern() {
    final random = Random();
    
    // Create solvable patterns based on level complexity
    if (currentLevel <= 3) {
      // Simple 2x2 patterns
      _generateSimplePattern(random);
    } else if (currentLevel <= 6) {
      // Diagonal or cross patterns
      _generateDiagonalPattern(random);
    } else {
      // Complex symmetric patterns
      _generateSymmetricPattern(random);
    }
  }
  
  /// Generate simple 2x2 block patterns
  void _generateSimplePattern(Random random) {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        targetPattern[row][col] = random.nextInt(colorCount);
      }
    }
    
    // Ensure at least one 2x2 block of same color
    final color = random.nextInt(colorCount);
    final startRow = random.nextInt(gridSize - 1);
    final startCol = random.nextInt(gridSize - 1);
    
    for (int r = startRow; r < startRow + 2; r++) {
      for (int c = startCol; c < startCol + 2; c++) {
        targetPattern[r][c] = color;
      }
    }
  }
  
  /// Generate diagonal patterns
  void _generateDiagonalPattern(Random random) {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (row == col) {
          targetPattern[row][col] = 0; // Main diagonal
        } else if (row + col == gridSize - 1) {
          targetPattern[row][col] = 1; // Anti-diagonal
        } else {
          targetPattern[row][col] = random.nextInt(colorCount);
        }
      }
    }
  }
  
  /// Generate symmetric patterns
  void _generateSymmetricPattern(Random random) {
    final center = gridSize ~/ 2;
    
    for (int row = 0; row <= center; row++) {
      for (int col = 0; col <= center; col++) {
        final color = random.nextInt(colorCount);
        
        // Apply to all symmetric positions
        targetPattern[row][col] = color;
        targetPattern[row][gridSize - 1 - col] = color;
        targetPattern[gridSize - 1 - row][col] = color;
        targetPattern[gridSize - 1 - row][gridSize - 1 - col] = color;
      }
    }
  }
  
  /// Start the level timer and game logic
  void _startLevel() {
    isGameActive = true;
    isGamePaused = false;
    isLevelComplete = false;
    isGameOver = false;
    
    gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!isGamePaused && isGameActive) {
        remainingTime -= 0.1;
        _updateTimerDisplay();
        
        if (remainingTime <= 0) {
          _handleGameOver();
        }
      }
    });
  }
  
  /// Handle tap events for tile selection and swapping
  @override
  bool onTapDown(TapDownEvent event) {
    if (!isGameActive || isGamePaused) return false;
    
    try {
      final tileSize = min(
        (game.size.x - 40) / gridSize,
        (game.size.y - 200) / (gridSize * 2 + 1),
      );
      
      final gridStart = Vector2(
        (game.size.x - tileSize * gridSize) / 2,
        150,
      );
      
      final localPos = event.localPosition - gridStart;
      final col = (localPos.x / tileSize).floor();
      final row = (localPos.y / tileSize).floor();
      
      if (row >= 0 && row < gridSize && col >= 0 && col < gridSize) {
        final tappedTile = Vector2(row.toDouble(), col.toDouble());
        
        if (selectedTile == null) {
          // First tile selection
          selectedTile = tappedTile;
          _highlightTile(row, col, true);
        } else {
          // Second tile selection - attempt swap
          final selectedRow = selectedTile!.x.toInt();
          final selectedCol = selectedTile!.y.toInt();
          
          if (_areAdjacent(selectedRow, selectedCol, row, col)) {
            _swapTiles(selectedRow, selectedCol, row, col);
            _checkWinCondition();
          }
          
          _highlightTile(selectedRow, selectedCol, false);
          selectedTile = null;
        }
      }
    } catch (e) {
      print('Error handling tap: $e');
      selectedTile = null;
    }
    
    return true;
  }
  
  /// Check if two tiles are adjacent
  bool _areAdjacent(int row1, int col1, int row2, int col2) {
    final rowDiff = (row1 - row2).abs();
    final colDiff = (col1 - col2).abs();
    return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1);
  }
  
  /// Swap two tiles in the grid
  void _swapTiles(int row1, int col1, int row2, int col2) {
    final temp = gameGrid[row1][col1];
    gameGrid[row1][col1] = gameGrid[row2][col2];
    gameGrid[row2][col2] = temp;
    
    // Update visual components
    _updateTileColors();
  }
  
  /// Update tile visual colors based on current grid state
  void _updateTileColors() {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        tileComponents[row][col].paint.color = tileColors[gameGrid[row][col]];
      }
    }
  }
  
  /// Highlight or unhighlight a tile
  void _highlightTile(int row, int col, bool highlight) {
    if (highlight) {
      tileComponents[row][col].paint.color = tileColors[gameGrid[row][col]].withOpacity(0.7);
    } else {
      tileComponents[row][col].paint.color = tileColors[gameGrid[row][col]];
    }
  }
  
  /// Check if current grid matches target pattern
  void _checkWinCondition() {
    bool isMatch = true;
    
    for (int row = 0; row < gridSize && isMatch; row++) {
      for (int col = 0; col < gridSize && isMatch; col++) {
        if (gameGrid[row][col] != targetPattern[row][col]) {
          isMatch = false;
        }
      }
    }
    
    if (isMatch) {
      _handleLevelComplete();
    }
  }
  
  /// Handle successful level completion
  void _handleLevelComplete() {
    isGameActive = false;
    isLevelComplete = true;
    gameTimer?.cancel();
    
    // Calculate score based on remaining time
    final timeBonus = (remainingTime * 10).toInt();
    score += 100 + timeBonus;
    
    // Award stars based on performance
    int earnedStars = 1;
    if (remainingTime > timeLimit * 0.5) earnedStars = 2;
    if (remainingTime > timeLimit * 0.75) earnedStars = 3;
    
    stars += earnedStars;
    
    _updateScoreDisplay();
    
    // Trigger level complete event
    game.onGameEvent?.call('level_complete', {
      'level': currentLevel,
      'score': score,
      'stars': earnedStars,
      'time_remaining': remainingTime,
    });
  }
  
  /// Handle game over condition
  void _handleGameOver() {
    isGameActive = false;
    isGameOver = true;
    gameTimer?.cancel();
    
    // Trigger game over event
    game.onGameEvent?.call('level_fail', {
      'level': currentLevel,
      'reason': 'timer_expired',
    });
  }
  
  /// Update timer display