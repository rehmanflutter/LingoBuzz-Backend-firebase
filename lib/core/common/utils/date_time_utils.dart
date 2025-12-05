
class DateTimeUtils{

 static String formatDateToReadable(DateTime? date) {
    if (date == null) return '';
    // Format example: 4 Dec 2025
    return '${date.day} ${_monthAbbreviation(date.month)} ${date.year}';
  }

 static String _monthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

}