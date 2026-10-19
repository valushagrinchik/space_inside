import 'package:flutter/material.dart';

IconData resolveIcon(String name) {
  const map = <String, IconData>{
    'plus_one': Icons.plus_one,
    'note': Icons.note,
    'calculate': Icons.calculate,
    'sync_alt': Icons.sync_alt,
    'home': Icons.home,
    'settings': Icons.settings,
    'timer': Icons.timer,
    'shopping_cart': Icons.shopping_cart,
    'translate': Icons.translate,
    'flash_on': Icons.flash_on,
    'self_improvement': Icons.self_improvement,
    'work': Icons.work,
    'favorite': Icons.favorite,
    'person': Icons.person,
    'notifications': Icons.notifications,
    'handshake': Icons.handshake,
    'explore': Icons.explore,
    'psychology': Icons.psychology,
    'spa': Icons.spa,
    'menu_book': Icons.menu_book,
    'format_quote': Icons.format_quote,
    'edit_note': Icons.edit_note,
    'mood': Icons.mood,
  };
  return map[name] ?? Icons.build;
}
