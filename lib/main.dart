import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Key-Think',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1F1F1F),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _typeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Stopwatch _stopwatch = Stopwatch();
  bool _isTyping = false;
  bool _isComplete = false;
  int _correctChars = 0;
  int _wrongChars = 0;
  double _accuracy = 0;
  int _wpm = 0;
  String _currentText = '';
  int _currentPosition = 0;
  List<bool?> _charStatus = [];
  String _typedText = '';
  Duration _completionTime = Duration.zero;

  final Map<String, String> _concepts = {
    'Class':
        'A blueprint for creating objects It defines attributes and behaviors of objects',
    'Object':
        'An instance of a class It represents a real-world entity and has state and behavior',
    'Encapsulation':
        'The mechanism of hiding the internal details of an object and exposing only the necessary parts to the outside world',
    'Inheritance':
        'A feature of OOP where a class can inherit properties and methods from another class',
    'Polymorphism':
        'The ability of different classes to be treated as instances of the same class through inheritance It allows one interface to be used for a general class of actions',
    'Abstraction':
        'The process of hiding complex implementation details and showing only essential information to the user',
    'Method':
        'A function defined inside a class that operates on the data of that class',
    'Constructor': 'A special method used for initializing objects of a class',
    'Destructor':
        'A method called when an object is destroyed to clean up resources',
    'Interface':
        'A collection of abstract methods that defines a contract for classes to implement',
    'Overloading':
        'Defining multiple methods in the same class with the same name but different parameters',
    'Overriding':
        'Redefining a method in a subclass that is already defined in the parent class',
  };

  @override
  void initState() {
    super.initState();
    _loadNewConcept();
  }

  void _loadNewConcept() {
    final random = Random();
    final concepts = _concepts.entries.toList();
    final selectedConcept = concepts[random.nextInt(concepts.length)];
    setState(() {
      _currentText = '${selectedConcept.key}: ${selectedConcept.value}';
      _charStatus = List.filled(_currentText.length, null);
      _currentPosition = 0;
      _correctChars = 0;
      _wrongChars = 0;
      _accuracy = 0;
      _wpm = 0;
      _typedText = '';
      _isComplete = false;
      _completionTime = Duration.zero;
      _stopwatch.reset();
    });
    _typeController.clear();
  }

  void _startTyping() {
    if (!_isTyping) {
      setState(() {
        _isTyping = true;
      });
      _stopwatch.start();
    }
  }

  void _calculateStats() {
    final minutes = _stopwatch.elapsedMilliseconds / 60000;
    if (minutes > 0) {
      setState(() {
        _wpm = (_correctChars / 5 / minutes).round();
        final totalAttempts = _correctChars + _wrongChars;
        _accuracy =
            totalAttempts > 0 ? (_correctChars / totalAttempts * 100) : 0;
      });
    }
  }

  void _endSession() {
    _stopwatch.stop();
    setState(() {
      _isTyping = false;
      _isComplete = true;
      _completionTime = _stopwatch.elapsed;
      _calculateStats();
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        _handleBackspace();
      }
    }

    // Allow Tab key to work for navigating between text fields and buttons
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      FocusScope.of(context).nextFocus(); // Move to the next focusable element
      return;
    }
  }

  void _handleBackspace() {
    if (_currentPosition > 0) {
      setState(() {
        _currentPosition--;
        if (_charStatus[_currentPosition] == true) {
          _correctChars--;
        } else if (_charStatus[_currentPosition] == false) {
          _wrongChars--;
        }
        _charStatus[_currentPosition] = null;
        _typedText = _typedText.substring(0, _typedText.length - 1);
      });
      _calculateStats();
    }
  }

  void _handleTyping(String value) {
    if (!_isTyping) {
      _startTyping();
    }

    if (value.length > _typedText.length) {
      String newChar = value[value.length - 1];
      _processCharacter(newChar);
    } else if (value.length < _typedText.length) {
      _handleBackspace();
    }

    _typedText = value;
  }

  void _processCharacter(String char) {
    if (_currentPosition >= _currentText.length) return;

    setState(() {
      if (char == _currentText[_currentPosition]) {
        _charStatus[_currentPosition] = true;
        _correctChars++;
      } else {
        _charStatus[_currentPosition] = false;
        _wrongChars++;
      }
      _currentPosition++;
    });

    _calculateStats();

    if (_currentPosition >= _currentText.length) {
      _endSession();
    }
  }

  Widget _buildResultsSection() {
    if (!_isComplete) return const SizedBox.shrink();

    final minutes = _completionTime.inMinutes;
    final seconds = _completionTime.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'wpm',
                _wpm.toString(),
                Icons.speed,
                Colors.blue,
              ),
              _buildStatCard(
                'acc',
                '${_accuracy.toStringAsFixed(2)}%',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'time',
                '${minutes}:${seconds.toString().padLeft(2, '0')}',
                Icons.timer,
                Colors.orange,
              ),
              _buildStatCard(
                'characters',
                '$_correctChars/${_correctChars + _wrongChars}',
                Icons.keyboard,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Type and think next concept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff35333E),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                onPressed: _loadNewConcept,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _typeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Key-Think'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.stop_circle),
            label: const Text('End Session'),
            onPressed: () {
              _loadNewConcept();
              setState(() {
                _isTyping = false;
                _stopwatch.reset();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadNewConcept();
              setState(() {
                _isTyping = false;
                _stopwatch.reset();
              });
            },
          ),
        ],
      ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _handleKeyEvent,
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isComplete)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        StreamBuilder(
                          stream: Stream.periodic(
                              const Duration(milliseconds: 100)),
                          builder: (context, snapshot) {
                            final duration = _stopwatch.elapsed;
                            return Text(
                              'Time: ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 20),
                            );
                          },
                        ),
                        Text('WPM: $_wpm',
                            style: const TextStyle(fontSize: 20)),
                        Text(
                          'Accuracy: ${_accuracy.toStringAsFixed(2)}%',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: List.generate(
                          _currentText.length,
                          (index) => TextSpan(
                            text: _currentText[index],
                            style: TextStyle(
                              color: _charStatus[index] == null
                                  ? Colors.grey[400]
                                  : (_charStatus[index]!
                                      ? Colors.green
                                      : Colors.red),
                              fontSize: 24,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_isComplete) const SizedBox(height: 40),
                  if (!_isComplete)
                    TextField(
                      controller: _typeController,
                      onChanged: _handleTyping,
                      decoration: InputDecoration(
                        hintText: 'Start typing...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2D2D2D),
                      ),
                      style: const TextStyle(fontSize: 20),
                      autofocus: true,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                            onPressed: () {
                              _loadNewConcept();
                              setState(() {
                                _isTyping = false;
                                _stopwatch.reset();
                              });
                            },
                            icon: const Icon(Icons.refresh)),
                      ],
                    ),
                  ),
                  _buildResultsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
