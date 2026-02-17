import 'package:flutter/material.dart';
import '../utils/constants.dart';

class BallWidget extends StatelessWidget {
  final int ballNumber;
  final bool isPocketed;
  final bool isTarget;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BallWidget({
    super.key,
    required this.ballNumber,
    this.isPocketed = false,
    this.isTarget = false,
    this.size = 40,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(AppConstants.ballColors[ballNumber] ?? 0xFFFFFFFF);
    final isStriped = AppConstants.isStriped(ballNumber);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isPocketed ? 0.25 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isStriped
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      color,
                      color,
                      Colors.white,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  )
                : RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    radius: 0.8,
                    colors: [
                      Color.lerp(color, Colors.white, 0.3)!,
                      color,
                      Color.lerp(color, Colors.black, 0.3)!,
                    ],
                  ),
            border: isTarget
                ? Border.all(color: Colors.amber, width: 3)
                : null,
            boxShadow: [
              if (!isPocketed)
                BoxShadow(
                  color: isTarget
                      ? Colors.amber.withValues(alpha: 0.5)
                      : Colors.black38,
                  blurRadius: isTarget ? 10 : 4,
                  offset: const Offset(1, 2),
                ),
            ],
          ),
          child: Center(
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(
                child: Text(
                  '$ballNumber',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CueBallWidget extends StatelessWidget {
  final double size;

  const CueBallWidget({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [Colors.white, Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
    );
  }
}
