import 'package:flutter/material.dart';

DateTime dateTimeFromDatePicker(DateTime pickedDate, TimeOfDay pickedTime) {
  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}
