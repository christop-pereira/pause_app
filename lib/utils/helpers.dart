import 'package:intl/intl.dart';

class Helpers {
  static String formatDate(DateTime d) {
    return DateFormat('dd/MM/yyyy – HH:mm').format(d);
  }
}