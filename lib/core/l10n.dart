import 'package:flutter/foundation.dart';

/// Simple localization without codegen.
/// Usage: S.t('key') for strings, S.fmt('key', {'name': value}) for placeholders.
class S {
  static const defaultLanguage = 'en';
  static const supportedLanguages = ['en', 'ru'];

  static final ValueNotifier<String> language = ValueNotifier(defaultLanguage);

  static String t(String key) =>
      _strings[language.value]?[key] ?? _strings[defaultLanguage]?[key] ?? key;

  static String fmt(String key, Map<String, String> args) {
    var text = t(key);
    args.forEach((name, value) {
      text = text.replaceAll('{$name}', value);
    });
    return text;
  }

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'app_title': 'Space Inside',
      'tagline': 'your space to notice, grow and remember',
      'banner_text': 'A little space\nfor what matters',
      'settings': 'Settings',
      'language': 'Language',
      'notion_sync_settings': 'Sync settings',
      'tools_visibility': 'Sections',
      'notion_env_hint': 'Token and database ID are loaded from .env',
      'autosync_on_save': 'Auto-sync on save',
      'save_settings': 'Save settings',
      'sync_now': 'Sync now',
      'settings_saved': 'Settings saved',
      'synced_count': 'Synced entries: {count}',
      'sync_error': 'Sync error: {error}',
      'error': 'Error: {error}',
      'unfold_empty':
          'No saved data.\nTap sync to load data from Notion.',
      'no_reflections': 'No reflections',
      'no_data': 'No data',
      'next': 'Next',
      'back': 'Back',
      'save': 'Save',
      'answer_hint': 'Type your answer...',
      'new_entry': 'New entry',
      'empty_entries': 'No entries yet. Tap + to add.',
      'gratitude': 'Gratitude',
      'self_trust': 'Self-trust',
      'quotes': 'Quotes',
      'notes': 'Notes',
      'quote_prompt': 'Write down a quote',
      'note_prompt': 'Write down a note',
      'add_book': 'Add book',
      'book_title': 'Book title',
      'book_author': 'Author (optional)',
      'add': 'Add',
      'cancel': 'Cancel',
      'quote_text': 'Quote',
      'add_quote': 'New quote',
      'quotes_count': '{count} quotes',
      'mood': 'Mood',
      'new_mood': 'How do you feel?',
      'mood_description': 'Description',
      'mood_anchor': 'Anchor',
      'mood_icon': 'Emotion',
      'mood_emotions':
          'Joy,Calm,Gratitude,Love,Inspiration,Surprise,Interest,Hope,'
          'Sadness,Disappointment,Disgust,Irritation,Anxiety,Fear,Anger,'
          'Hurt,Guilt,Shame,Confusion,Loneliness,Fatigue',
      'emotions_positive':
          'Joy,Calm,Gratitude,Love,Inspiration,Surprise,Interest,Hope',
      'emotions_negative':
          'Sadness,Disappointment,Disgust,Irritation,Anxiety,Fear,Anger,'
          'Hurt,Guilt,Shame,Confusion,Loneliness,Fatigue',
      'mood_state': 'State',
      'mood_states':
          'Warmth,Quiet,Calm,Tension,Energy,Clarity,Fog,Emptiness,'
          'Fullness,Lightness,Heaviness',
      'mood_reflection': 'Reflection — thoughts, themes to explore later',
      'reflections': 'Reflections',
      'add_photo': 'Add photo',
      'change_photo': 'Change photo',
      'remove_photo': 'Remove photo',
      'edit': 'Edit',
      'tags_hint': 'Tags (comma separated)',
      'no_books': 'No books yet. Tap + to add.',
      'no_quotes': 'No quotes yet. Tap + to add.',
      'stt_not_available': 'Speech recognition is not available',
      // Gratitude practice
      'gratitude_moment':
          '✨ Gratitude is a way to notice the good that is already in your life.\n\n'
          '🖊 Recall one moment today that you feel grateful for. What happened?',
      'gratitude_source':
          '🫂 Who or what are you grateful to in this situation? Is it a person, an action, a circumstance, or yourself?',
      'gratitude_reason':
          '💡 What exactly in this moment sparked your gratitude? Why was it important to you?',
      'gratitude_impact':
          '🌱 How did this moment affect your day or your state? What changed in you?',
      'gratitude_feelings':
          '🤍 If you described your feeling right now — what is it? (warmth, calm, joy, relief, etc.)',
      'field_moment': 'Moment',
      'field_source': 'Source',
      'field_reason': 'Reason',
      'field_impact': 'Impact',
      'field_feelings': 'Feeling',
      // Self-trust practice
      'st_situation': '🖊 Briefly describe the situation.',
      'st_self_signal':
          '🫂 What inside you suggested this decision? What thoughts, feelings, or body sensations did you notice?',
      'st_chosen_action': '✨ What did you choose to do?',
      'st_alternative':
          '🌿 How would you usually act in a similar situation, or what did others expect of you?',
      'st_feelings_after': '🌱 What did you feel afterwards?',
      'st_insight': '💭 What did this situation show you about yourself?',
      'st_difficulty':
          '⚡️ How hard was it to act this way instead of differently? Rate from 0 to 10.',
      'st_difficulty_label': 'Drag the slider or tap a number',
      'field_situation': 'Situation',
      'field_self_signal': 'Inner signal',
      'field_chosen_action': 'Chosen action',
      'field_alternative': 'Alternative',
      'field_feelings_after': 'Feelings after',
      'field_insight': 'Insight',
      'field_difficulty': 'Difficulty',
    },
    'ru': {
      'app_title': 'Space Inside',
      'tagline': 'твоё пространство — замечать, расти и помнить',
      'banner_text': 'Немного пространства\nдля важного',
      'settings': 'Настройки',
      'language': 'Язык',
      'notion_sync_settings': 'Настройки синхронизации',
      'tools_visibility': 'Разделы',
      'notion_env_hint': 'Токен и ID базы данных загружаются из .env',
      'autosync_on_save': 'Автосинхронизация при сохранении',
      'save_settings': 'Сохранить настройки',
      'sync_now': 'Синхронизировать сейчас',
      'settings_saved': 'Настройки сохранены',
      'synced_count': 'Синхронизировано записей: {count}',
      'sync_error': 'Ошибка синхронизации: {error}',
      'error': 'Ошибка: {error}',
      'unfold_empty':
          'Нет сохранённых данных.\nНажмите синхронизацию, чтобы загрузить данные из Notion.',
      'no_reflections': 'Нет рефлексий',
      'no_data': 'Нет данных',
      'next': 'Далее',
      'back': 'Назад',
      'save': 'Сохранить',
      'answer_hint': 'Введите ответ...',
      'new_entry': 'Новая запись',
      'empty_entries': 'Пока нет записей. Нажми +, чтобы добавить.',
      'gratitude': 'Благодарность',
      'self_trust': 'Доверие к себе',
      'quotes': 'Цитаты',
      'notes': 'Конспекты',
      'quote_prompt': 'Запиши цитату',
      'note_prompt': 'Запиши конспект',
      'add_book': 'Добавить книгу',
      'book_title': 'Название книги',
      'book_author': 'Автор (необязательно)',
      'add': 'Добавить',
      'cancel': 'Отмена',
      'quote_text': 'Цитата',
      'add_quote': 'Новая цитата',
      'quotes_count': 'Цитат: {count}',
      'mood': 'Настроение',
      'new_mood': 'Как ты себя чувствуешь?',
      'mood_description': 'Описание',
      'mood_anchor': 'Якорь',
      'mood_icon': 'Эмоция',
      'mood_emotions':
          'Радость,Спокойствие,Благодарность,Любовь,Вдохновение,'
          'Удивление,Интерес,Надежда,Грусть,Разочарование,Отвращение,'
          'Раздражение,Тревога,Страх,Гнев,Обида,Вина,Стыд,Растерянность,'
          'Одиночество,Усталость',
      'emotions_positive':
          'Радость,Спокойствие,Благодарность,Любовь,Вдохновение,'
          'Удивление,Интерес,Надежда',
      'emotions_negative':
          'Грусть,Разочарование,Отвращение,Раздражение,Тревога,Страх,'
          'Гнев,Обида,Вина,Стыд,Растерянность,Одиночество,Усталость',
      'mood_state': 'Состояние',
      'mood_states':
          'Тепло,Тишина,Спокойствие,Напряжение,Энергия,Ясность,Туман,'
          'Пустота,Наполненность,Лёгкость,Тяжесть',
      'mood_reflection': 'Рефлексия — мысли, темы, что развернуть потом',
      'reflections': 'Рефлексии',
      'add_photo': 'Добавить фото',
      'change_photo': 'Заменить фото',
      'remove_photo': 'Убрать фото',
      'edit': 'Редактировать',
      'tags_hint': 'Теги (через запятую)',
      'no_books': 'Пока нет книг. Нажми +, чтобы добавить.',
      'no_quotes': 'Пока нет цитат. Нажми +, чтобы добавить.',
      'stt_not_available': 'Распознавание речи недоступно',
      // Gratitude practice
      'gratitude_moment':
          '✨ Благодарность — это способ заметить хорошее, которое уже есть в твоей жизни.\n\n'
          '🖊 Вспомни один момент за сегодня, за который ты чувствуешь благодарность. Что произошло?',
      'gratitude_source':
          '🫂 Кому или чему ты благодарен(на) в этой ситуации? Это человек, действие, обстоятельство или ты сам(а)?',
      'gratitude_reason':
          '💡 Что именно в этом моменте вызвало твою благодарность? Почему это было важно для тебя?',
      'gratitude_impact':
          '🌱 Как этот момент повлиял на твой день или состояние? Что в тебе изменилось?',
      'gratitude_feelings':
          '🤍 Если описать твоё чувство сейчас — какое оно? (тепло, спокойствие, радость, облегчение и т.д.)',
      'field_moment': 'Момент',
      'field_source': 'Источник',
      'field_reason': 'Причина',
      'field_impact': 'Влияние',
      'field_feelings': 'Чувство',
      // Self-trust practice
      'st_situation': '🖊 Коротко опиши ситуацию.',
      'st_self_signal':
          '🫂 Что внутри подсказало тебе это решение? Какие мысли, чувства или телесные ощущения ты заметил(а)?',
      'st_chosen_action': '✨ Что ты выбрал(а) сделать?',
      'st_alternative':
          '🌿 А как ты обычно поступил(а) бы в похожей ситуации или чего от тебя ожидали другие?',
      'st_feelings_after': '🌱 Что ты почувствовал(а) после?',
      'st_insight': '💭 Что эта ситуация показала тебе о себе?',
      'st_difficulty':
          '⚡️ Насколько было сложно поступить так, а не по-другому? Оцени от 0 до 10.',
      'st_difficulty_label': 'Проведи ползунок или нажми нужное число',
      'field_situation': 'Ситуация',
      'field_self_signal': 'Внутренний сигнал',
      'field_chosen_action': 'Выбранное действие',
      'field_alternative': 'Альтернатива',
      'field_feelings_after': 'Чувства после',
      'field_insight': 'Инсайт',
      'field_difficulty': 'Сложность',
    },
  };
}
