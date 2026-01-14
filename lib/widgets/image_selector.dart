import 'package:flutter/cupertino.dart';

class ImageSelector extends StatelessWidget{
  ImageSelector({
    super.key,
    required this.onTapCallback,
    required this.pickedImagePath,
  });

  final VoidCallback onTapCallback;
  final pickedImagePath;

  //TODO: refactor this
  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}