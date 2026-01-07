import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// Main game class for the tile-swapping puzzle game
class Batch20260107105243Puzzle01Game extends FlameGame
    with HasTapDetector, HasCollisionDetection {
  
  /// Current game state
  GameState _gameState = GameState.playing;
  
  /// Current level (1-10)
  int _currentLevel = 1;
  
  /// Player's current score
  int _score = 0;
  
  /// Stars earned in current level
  int _starsEarned = 0;
  
  /// Total stars collected
  int _totalStars = 0;
  
  /// Level timer component
  late TimerComponent _levelTimer;
  
  /// Grid component for tile management
  late GridComponent _gameGrid;
  
  /// Target pattern component
  late PatternComponent _targetPattern;
  
  /// Game mascot character
  late MascotComponent _mascot;
  
  /// Background component
  late BackgroundComponent _background;
  
  /// Analytics service hook
  Function(String event, Map<String, dynamic> parameters)? onAnalyticsEvent;
  
  /// Ad service hook
  Function(String adType, Function onComplete, Function onFailed)? onShowAd;
  
  /// Storage service hook
  Function(String key, dynamic value)? onSaveData;
  Function(String key)? onLoadData;
  
  /// Level configuration data
  late Map<int, LevelConfig> _levelConfigs;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    _initializeLevelConfigs();
    await _loadComponents();
    _setupLevel(_currentLevel);
    
    // Track game start
    _trackEvent('game_start', {
      'level': _currentLevel,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Initialize level configuration data
  void _initializeLevelConfigs() {
    _levelConfigs = {
      1: LevelConfig(gridSize: 3, colorCount: 3, timeLimit: 60, complexity: 1),
      2: LevelConfig(gridSize: 3, colorCount: 3, timeLimit: 55, complexity: 2),
      3: LevelConfig(gridSize: 3, colorCount: 4, timeLimit: 50, complexity: 2),
      4: LevelConfig(gridSize: 4, colorCount: 4, timeLimit: 48, complexity: 3),
      5: LevelConfig(gridSize: 4, colorCount: 4, timeLimit: 45, complexity: 3),
      6: LevelConfig(gridSize: 4, colorCount: 5, timeLimit: 42, complexity: 4),
      7: LevelConfig(gridSize: 5, colorCount: 5, timeLimit: 38, complexity: 4),
      8: LevelConfig(gridSize: 5, colorCount: 5, timeLimit: 35, complexity: 5),
      9: LevelConfig(gridSize: 5, colorCount: 6, timeLimit: 32, complexity: 5),
      10: LevelConfig(gridSize: 5, colorCount: 6, timeLimit: 30, complexity: 6),
    };
  }

  /// Load all game components
  Future<void> _loadComponents() async {
    // Background
    _background = BackgroundComponent();
    add(_background);
    
    // Game grid
    _gameGrid = GridComponent(
      gridSize: _levelConfigs[_currentLevel]!.gridSize,
      colorCount: _levelConfigs[_currentLevel]!.colorCount,
      onTileSwap: _handleTileSwap,
      onPatternMatch: _handlePatternMatch,
    );
    add(_gameGrid);
    
    // Target pattern
    _targetPattern = PatternComponent();
    add(_targetPattern);
    
    // Mascot
    _mascot = MascotComponent();
    add(_mascot);
    
    // Level timer
    _levelTimer = TimerComponent(
      period: _levelConfigs[_currentLevel]!.timeLimit.toDouble(),
      repeat: false,
      onTick: _handleTimerExpired,
    );
    add(_levelTimer);
  }

  /// Setup level with specific configuration
  void _setupLevel(int level) {
    final config = _levelConfigs[level]!;
    
    _gameState = GameState.playing;
    _starsEarned = 0;
    
    // Configure grid
    _gameGrid.setupLevel(config);
    
    // Generate target pattern
    _targetPattern.generatePattern(config);
    
    // Reset timer
    _levelTimer.timer.stop();
    _levelTimer.timer.limit = config.timeLimit.toDouble();
    _levelTimer.timer.start();
    
    // Update mascot state
    _mascot.setState(MascotState.ready);
    
    // Track level start
    _trackEvent('level_start', {
      'level': level,
      'grid_size': config.gridSize,
      'time_limit': config.timeLimit,
    });
  }

  /// Handle tile swap interaction
  void _handleTileSwap(TileComponent tile1, TileComponent tile2) {
    if (_gameState != GameState.playing) return;
    
    // Perform swap animation
    _gameGrid.swapTiles(tile1, tile2);
    
    // Check for pattern match
    if (_gameGrid.checkPatternMatch(_targetPattern.pattern)) {
      _handlePatternMatch();
    }
    
    // Check for no valid moves
    if (!_gameGrid.hasValidMoves()) {
      _handleNoValidMoves();
    }
  }

  /// Handle successful pattern match
  void _handlePatternMatch() {
    _gameState = GameState.levelComplete;
    _levelTimer.timer.stop();
    
    // Calculate score and stars
    final timeBonus = (_levelTimer.timer.limit - _levelTimer.timer.current).round();
    final levelScore = 1000 + (timeBonus * 10);
    _score += levelScore;
    
    // Determine stars earned (1-3 based on time remaining)
    final timePercent = timeBonus / _levelTimer.timer.limit;
    if (timePercent > 0.7) {
      _starsEarned = 3;
    } else if (timePercent > 0.4) {
      _starsEarned = 2;
    } else {
      _starsEarned = 1;
    }
    
    _totalStars += _starsEarned;
    
    // Update mascot
    _mascot.setState(MascotState.celebrating);
    
    // Save progress
    _saveGameData();
    
    // Track completion
    _trackEvent('level_complete', {
      'level': _currentLevel,
      'score': levelScore,
      'stars': _starsEarned,
      'time_remaining': timeBonus,
    });
    
    // Show level complete overlay
    overlays.add('LevelCompleteOverlay');
  }

  /// Handle timer expiration
  void _handleTimerExpired() {
    if (_gameState != GameState.playing) return;
    
    _gameState = GameState.gameOver;
    _mascot.setState(MascotState.disappointed);
    
    _trackEvent('level_fail', {
      'level': _currentLevel,
      'reason': 'timer_expired',
    });
    
    overlays.add('GameOverOverlay');
  }

  /// Handle no valid moves remaining
  void _handleNoValidMoves() {
    _gameState = GameState.gameOver;
    _levelTimer.timer.stop();
    _mascot.setState(MascotState.disappointed);
    
    _trackEvent('level_fail', {
      'level': _currentLevel,
      'reason': 'no_valid_moves',
    });
    
    overlays.add('GameOverOverlay');
  }

  /// Restart current level
  void restartLevel() {
    overlays.remove('GameOverOverlay');
    _setupLevel(_currentLevel);
  }

  /// Advance to next level
  void nextLevel() {
    overlays.remove('LevelCompleteOverlay');
    
    if (_currentLevel < 10) {
      _currentLevel++;
      
      // Check if level is locked
      if (_currentLevel > 3 && !_isLevelUnlocked(_currentLevel)) {
        _showUnlockPrompt();
        return;
      }
      
      _setupLevel(_currentLevel);
    } else {
      // Game completed
      overlays.add('GameCompleteOverlay');
    }
  }

  /// Check if level is unlocked
  bool _isLevelUnlocked(int level) {
    final unlockedLevels = onLoadData?.call('unlocked_levels') as List<int>? ?? [1, 2, 3];
    return unlockedLevels.contains(level);
  }

  /// Show unlock prompt for locked level
  void _showUnlockPrompt() {
    _trackEvent('unlock_prompt_shown', {
      'level': _currentLevel,
    });
    
    overlays.add('UnlockPromptOverlay');
  }

  /// Unlock level with rewarded ad
  void unlockLevelWithAd() {
    _trackEvent('rewarded_ad_started', {
      'level': _currentLevel,
      'purpose': 'unlock_level',
    });
    
    onShowAd?.call('rewarded', () {
      // Ad completed successfully
      _trackEvent('rewarded_ad_completed', {
        'level': _currentLevel,
      });
      
      final unlockedLevels = onLoadData?.call('unlocked_levels') as List<int>? ?? [1, 2, 3];
      unlockedLevels.add(_currentLevel);
      onSaveData?.call('unlocked_levels', unlockedLevels);
      
      _trackEvent('level_unlocked', {
        'level': _currentLevel,
      });
      
      overlays.remove('UnlockPromptOverlay');
      _setupLevel(_currentLevel);
    }, () {
      // Ad failed
      _trackEvent('rewarded_ad_failed', {
        'level': _currentLevel,
      });
      
      _currentLevel--;
    });
  }

  /// Use stars for hint
  void useHint() {
    if (_totalStars >= 1 && _gameState == GameState.playing) {
      _totalStars--;
      _gameGrid.showHint(_targetPattern.pattern);
      _saveGameData();
    }
  }

  /// Use stars for extra time
  void useExtraTime() {
    if (_totalStars >= 2 && _gameState == GameState.playing) {
      _totalStars -= 2;
      _levelTimer.timer.limit += 15;
      _saveGameData();
    }
  }

  /// Skip level with stars
  void skipLevel() {
    if (_totalStars >= 3) {
      _totalStars -= 3;
      _saveGameData();
      nextLevel();
    }
  }

  /// Pause the game
  void pauseGame() {
    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
      _levelTimer.timer.stop();
      overlays.add('PauseOverlay');
    }
  }

  /// Resume the game
  void resumeGame() {
    if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
      _levelTimer.timer.start();
      overlays.remove('PauseOverlay');
    }
  }

  /// Save game data
  void _saveGameData() {
    onSaveData?.call('total_stars', _totalStars);
    onSaveData?.call('current_level', _currentLevel);
    onSaveData?.call('total_score', _score);
  }

  /// Track analytics event
  void _trackEvent(String event, Map<String, dynamic> parameters) {
    onAnalyticsEvent?.call(event, parameters);
  }

  @override
  bool onTapDown(TapDownInfo info) {
    if (_gameState == GameState.playing) {
      _gameGrid.handleTap(info.eventPosition.global);
    }
    return true;
  }

  // Getters for UI
  GameState get gameState => _gameState;
  int get currentLevel => _currentLevel;
  int get score => _score;
  int get starsEarned => _starsEarned;
  int get totalStars => _totalStars;
  double get timeRemaining => _levelTimer.timer.limit - _levelTimer.timer.current;
}

/// Game state enumeration
enum GameState {
  playing,
  paused,
  gameOver,
  levelComplete,
}

/// Mascot state enumeration
enum MascotState {
  ready,
  thinking,
  celebrating,
  disappointed,
}

/// Level configuration data class
class LevelConfig {
  final int gridSize;
  final int colorCount;
  final int timeLimit;
  final int complexity;

  LevelConfig({
    required this.gridSize,
    required this.colorCount,
    required this.timeLimit,
    required this.complexity,
  });
}

/// Grid component for managing tiles
class GridComponent extends Component {
  final int gridSize;
  final int colorCount;
  final Function(TileComponent, TileComponent) onTileSwap;
  final Function() onPatternMatch;
  
  late List<List<TileComponent>> tiles;
  TileComponent? selectedTile;

  GridComponent({
    required this.gridSize,
    required this.colorCount,
    required this.onTileSwap,
    required this.onPatternMatch,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializeGrid();
  }

  void _initializeGrid() {
    tiles = List.generate(gridSize, (row) =>
        List.generate(gridSize, (col) =>
            TileComponent(row: row, col: col, colorIndex: Random().nextInt(colorCount))));
    
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        add(tiles[row][col]);
      }
    }
  }

  void setupLevel(LevelConfig config) {
    // Reconfigure grid for new level
    removeAll(children.whereType<TileComponent>());
    _initializeGrid();
  }

  void handleTap(Vector2 position) {
    final tappedTile = _getTileAtPosition(position);
    if (tappedTile == null) return;

    if (selectedTile == null) {
      selectedTile = tappedTile;
      tappedTile.setSelected(true);
    } else if (selectedTile == tappedTile) {
      selectedTile!.setSelected(false);
      selectedTile = null;
    } else if (_areAdjacent(selectedTile!, tappedTile)) {
      onTileSwap(selectedTile!, tappedTile);
      selectedTile!.setSelected(false);
      selectedTile = null;
    } else {
      selectedTile!.setSelected(false);
      selectedTile = tappedTile;
      tappedTile.setSelected(true);
    }
  }

  TileComponent? _getTileAtPosition(Vector2 position) {
    for (final tile in children.whereType<TileComponent>()) {
      if (tile.containsPoint(position)) {
        return tile;
      }
    }
    return null;
  }

  bool _areAdjacent(TileComponent tile1, TileComponent tile2) {
    final rowDiff = (tile1.row - tile2.row).abs();
    final colDiff = (tile1.col