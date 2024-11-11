import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(SnakeGame());
}

class SnakeGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GamePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GamePage extends StatefulWidget {
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final int rows = 20; // Number of rows
  final int columns = 20; // Number of columns
  final int totalCells = 400; // Total cells

  List<int> snake = [];
  int food = 0;
  String direction = 'down';
  Timer? gameLoop;
  int score = 0;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    setState(() {
      // Initialize snake position and direction
      snake = [45, 65, 85];
      direction = 'down';
      score = 0;
      generateFood(); // Generate the first food position

      // Start game loop
      gameLoop?.cancel();
      gameLoop = Timer.periodic(Duration(milliseconds: 150), (Timer timer) {
        if (!isPaused) {
          updateSnake();
        }
      });
    });
  }

  void generateFood() {
    // Generate a food position not occupied by the snake
    while (snake.contains(food)) {
      food = Random().nextInt(totalCells);
    }
  }

  void updateSnake() {
    setState(() {
      int newHead;
      switch (direction) {
        case 'up':
          newHead = (snake.first - columns) % totalCells;
          if (newHead < 0) newHead += totalCells;
          break;
        case 'down':
          newHead = (snake.first + columns) % totalCells;
          break;
        case 'left':
          newHead = snake.first % columns == 0 ? snake.first + columns - 1 : snake.first - 1;
          break;
        case 'right':
          newHead = snake.first % columns == columns - 1 ? snake.first - columns + 1 : snake.first + 1;
          break;
        default:
          newHead = snake.first;
      }

      // Check for self-collision
      if (snake.contains(newHead) || newHead < 0 || newHead >= totalCells) {
        gameLoop?.cancel();
        startGame(); // Restart game on collision or boundary
        return;
      }

      // Update snake position
      snake.insert(0, newHead);

      // Check if the snake eats the food
      if (snake.first == food) {
        score++;
        generateFood(); // Generate new food after eating
      } else {
        snake.removeLast();
      }
    });
  }

  void updateDirection(String newDirection) {
    if ((direction == 'up' && newDirection != 'down') ||
        (direction == 'down' && newDirection != 'up') ||
        (direction == 'left' && newDirection != 'right') ||
        (direction == 'right' && newDirection != 'left')) {
      direction = newDirection;
    }
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size to calculate grid size dynamically
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate the cell size
    double cellSize = min(screenWidth, screenHeight) / rows;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Game grid
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  itemCount: totalCells,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: 1.0, // Square cells
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    if (snake.contains(index)) {
                      return Container(
                        margin: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    } else if (index == food) {
                      return Container(
                        margin: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      );
                    } else {
                      return Container(
                        margin: EdgeInsets.all(1),
                        color: Colors.grey[900],
                      );
                    }
                  },
                );
              },
            ),
          ),
          // Score display
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              "Score: $score",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          // Pause button in the top-right corner
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
                size: 30,
              ),
              onPressed: togglePause,
            ),
          ),
          // Joystick for direction control
          Positioned(
            bottom: 40,
            right: 20,
            child: Joystick(
              onDirectionChanged: updateDirection,
            ),
          ),
        ],
      ),
    );
  }
}

class Joystick extends StatefulWidget {
  final Function(String) onDirectionChanged;

  Joystick({required this.onDirectionChanged});

  @override
  _JoystickState createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset joystickPosition = Offset(0, 0);
  Offset origin = Offset(0, 0);
  double maxDistance = 40;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          origin = details.localPosition;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          final offset = details.localPosition - origin;

          if (offset.distance <= maxDistance) {
            joystickPosition = offset;
          } else {
            joystickPosition = Offset(
              maxDistance * offset.dx / offset.distance,
              maxDistance * offset.dy / offset.distance,
            );
          }

          if (joystickPosition.dy < -10) {
            widget.onDirectionChanged('up');
          } else if (joystickPosition.dy > 10) {
            widget.onDirectionChanged('down');
          } else if (joystickPosition.dx < -10) {
            widget.onDirectionChanged('left');
          } else if (joystickPosition.dx > 10) {
            widget.onDirectionChanged('right');
          }
        });
      },
      onPanEnd: (details) {
        setState(() {
          joystickPosition = Offset(0, 0);
        });
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueGrey.withOpacity(0.5),
        ),
        child: Center(
          child: Transform.translate(
            offset: joystickPosition,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
