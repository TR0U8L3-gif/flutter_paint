import 'package:flutter/material.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key,  this.onLeadingButtonPressed, this.onTrailingButtonPressed});
  
  final void Function()? onLeadingButtonPressed;
  final void Function()? onTrailingButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      width: double.maxFinite,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onLeadingButtonPressed,
              icon: const Icon(Icons.menu),
            ),
            const Text(
              'Flutter Paint',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            IconButton(
              onPressed: onTrailingButtonPressed,
              icon: const Icon(Icons.brightness_medium_sharp),
            ),
          ],
        ),
      ),
    );
  }
}