import telebot
import requests
from datetime import datetime

# ==========================================
# НАСТРОЙКИ
# ==========================================
BOT_TOKEN = "8153689622:AAEA_xcthWDCheuwOJurQZerwVLVUzReQwY"
GROUP_CHAT_ID = None  # Заполнится автоматически при первом сообщении в группе

bot = telebot.TeleBot(BOT_TOKEN)

# Хранилище отзывов (в памяти, пока бот работает)
user_sessions = {}  # user_id -> {"step": ..., "rating": ..., "text": ...}

# ==========================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ==========================================

def send_to_group(message_text):
    """Отправить сообщение в группу AiChefReviews"""
    if GROUP_CHAT_ID:
        try:
            bot.send_message(GROUP_CHAT_ID, message_text, parse_mode="HTML")
        except Exception as e:
            print(f"Ошибка отправки в группу: {e}")
    else:
        print("⚠️  GROUP_CHAT_ID не задан. Напишите что-нибудь в группе AiChefReviews.")

def stars(rating):
    return "⭐" * int(rating)

# ==========================================
# ОБРАБОТЧИКИ
# ==========================================

@bot.message_handler(commands=["start"])
def handle_start(message):
    # Если сообщение из группы — запомнить ID
    if message.chat.type in ["group", "supergroup"]:
        global GROUP_CHAT_ID
        GROUP_CHAT_ID = message.chat.id
        print(f"✅ Группа найдена! ID: {GROUP_CHAT_ID}")
        return

    # Личный чат — начать сбор отзыва
    user_sessions[message.from_user.id] = {"step": "rating"}
    keyboard = telebot.types.ReplyKeyboardMarkup(resize_keyboard=True, one_time_keyboard=True)
    keyboard.row("⭐ 1", "⭐⭐ 2", "⭐⭐⭐ 3")
    keyboard.row("⭐⭐⭐⭐ 4", "⭐⭐⭐⭐⭐ 5")
    bot.send_message(
        message.chat.id,
        "👋 Добро пожаловать в <b>Ai Chef</b>!\n\nПожалуйста, оцените ваш опыт:",
        reply_markup=keyboard,
        parse_mode="HTML"
    )

@bot.message_handler(func=lambda m: m.chat.type in ["group", "supergroup"])
def handle_group_message(message):
    """Запомнить ID группы при любом сообщении в ней"""
    global GROUP_CHAT_ID
    if GROUP_CHAT_ID != message.chat.id:
        GROUP_CHAT_ID = message.chat.id
        print(f"✅ Группа найдена! ID: {GROUP_CHAT_ID}")

@bot.message_handler(func=lambda m: m.chat.type == "private")
def handle_private_message(message):
    user_id = message.from_user.id
    session = user_sessions.get(user_id, {})
    step = session.get("step")

    # Шаг 1: Получить оценку
    if step == "rating":
        text = message.text.strip()
        # Извлечь цифру из текста (например "⭐⭐ 2" -> 2)
        rating = None
        for char in text:
            if char.isdigit():
                rating = int(char)
                break

        if rating and 1 <= rating <= 5:
            user_sessions[user_id]["rating"] = rating
            user_sessions[user_id]["step"] = "review_text"
            bot.send_message(
                message.chat.id,
                f"Вы выбрали: {stars(rating)} ({rating}/5)\n\n✍️ Теперь напишите ваш отзыв:",
                reply_markup=telebot.types.ReplyKeyboardRemove()
            )
        else:
            bot.send_message(message.chat.id, "Пожалуйста, выберите оценку от 1 до 5 ⬆️")

    # Шаг 2: Получить текст отзыва
    elif step == "review_text":
        review_text = message.text.strip()
        rating = session.get("rating", 0)
        username = message.from_user.username or message.from_user.first_name
        now = datetime.now().strftime("%d.%m.%Y %H:%M")

        # Сформировать сообщение для группы
        group_message = (
            f"📝 <b>Новый отзыв!</b>\n"
            f"━━━━━━━━━━━━━━━\n"
            f"👤 Пользователь: @{username}\n"
            f"⭐ Оценка: {stars(rating)} ({rating}/5)\n"
            f"💬 Отзыв: {review_text}\n"
            f"🕐 Время: {now}\n"
            f"━━━━━━━━━━━━━━━"
        )

        # Отправить в группу
        send_to_group(group_message)

        # Подтвердить пользователю
        bot.send_message(
            message.chat.id,
            "✅ Спасибо за ваш отзыв! Мы ценим ваше мнение 🙏",
            reply_markup=telebot.types.ReplyKeyboardRemove()
        )

        # Очистить сессию
        user_sessions.pop(user_id, None)

    else:
        # Если нет активной сессии — предложить начать
        user_sessions[user_id] = {"step": "rating"}
        keyboard = telebot.types.ReplyKeyboardMarkup(resize_keyboard=True, one_time_keyboard=True)
        keyboard.row("⭐ 1", "⭐⭐ 2", "⭐⭐⭐ 3")
        keyboard.row("⭐⭐⭐⭐ 4", "⭐⭐⭐⭐⭐ 5")
        bot.send_message(
            message.chat.id,
            "Оцените ваш опыт:",
            reply_markup=keyboard
        )

# ==========================================
# ЗАПУСК
# ==========================================
if __name__ == "__main__":
    print("🤖 Бот AiChef запущен...")
    print("📌 Напишите /start в группе AiChefReviews чтобы зарегистрировать группу")
    print("📌 Затем пользователи пишут боту в личку — отзывы появятся в группе")
    print("⏹  Для остановки нажмите Ctrl+C\n")
    bot.infinity_polling()
