// Funzione di utilità per formattare le date
String formatDate(DateTime date) {
  // Converte in ora locale per sicurezza
  final localDate = date.toLocal();
  final now = DateTime.now();
  final difference = now.difference(localDate);

  // Gestione per "oggi"
  if (difference.inDays == 0) {
    if (difference.inHours < 1) {
      if (difference.inMinutes < 2) {
        return 'Just now';
      }
      return '${difference.inMinutes}m ago';
    }
    return '${difference.inHours}h ago';
  }
  // Gestione per "ieri"
  else if (difference.inDays == 1) {
    return 'Yesterday';
  }
  // Gestione per la settimana scorsa
  else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  }
  // Formato standard per date più vecchie
  else {
    return '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year}';
  }
}
