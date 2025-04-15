from quart import Quart, request, jsonify
from pyrogram import Client
import asyncio
import time
import logging

# я хуесос
logging.getLogger("pyrogram").setLevel(logging.ERROR)
logging.getLogger("pyrogram.session").setLevel(logging.ERROR)

API_ID = 
API_HASH = ""
SESSION_NAME = "ya_gandon"

app = Quart(__name__)
tg = Client(SESSION_NAME, API_ID, API_HASH, no_updates=True)

message_cache = {}

@app.before_serving
async def startup():
    await tg.start()
    print("Telegram client started")

@app.after_serving
async def shutdown():
    await tg.stop()
    print("Telegram client stopped")

@app.route('/find_chat/<string:username>', methods=['GET'])
async def find_chat(username):
    try:
        chat = await tg.get_chat(username)
        chat_name = ""
        
        if chat.type == "private":
            chat_name = chat.first_name or ""
            if chat.last_name:
                chat_name += " " + chat.last_name
        else:
            chat_name = chat.title or ""
            
        if not chat_name:
            chat_name = username
            
        return jsonify({
            "id": chat.id,
            "name": chat_name
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 404

@app.route('/messages/<int:chat_id>', methods=['GET'])
async def get_messages(chat_id):
    last_id = int(request.args.get('last_id', 0))
    
    try:
        # Всегда получаем только 5 последних сообщений
        messages_list = []
        
        # Если это первый запрос, просто берем 5 последних сообщений
        if last_id == 0:
            async for message in tg.get_chat_history(chat_id, limit=5):
                if message.text:
                    sender_name = "Unknown"
                    if message.from_user:
                        sender_name = message.from_user.first_name
                        if message.from_user.last_name:
                            sender_name += " " + message.from_user.last_name
                    
                    messages_list.append({
                        "id": message.id,
                        "sender": sender_name,
                        "text": message.text
                    })
            
            # гандон
            messages_list.reverse()
        else:
            # не
            async for message in tg.get_chat_history(chat_id, limit=10):
                if message.id > last_id and message.text:
                    sender_name = "Unknown"
                    if message.from_user:
                        sender_name = message.from_user.first_name
                        if message.from_user.last_name:
                            sender_name += " " + message.from_user.last_name
                    
                    messages_list.append({
                        "id": message.id,
                        "sender": sender_name,
                        "text": message.text
                    })
            
            # не
            messages_list.reverse()
        
        # аваыв
        message_cache[chat_id] = messages_list
        
        return jsonify(messages_list)
    except Exception as e:
        # сын шалавы
        if chat_id in message_cache:
            return jsonify(message_cache[chat_id])
        return jsonify({"error": str(e)}), 500

@app.route('/send', methods=['POST'])
async def send_message():
    data = await request.get_json()
    chat_id = data.get('chat_id')
    text = data.get('text')
    
    if not chat_id or not text:
        return jsonify({"error": "Missing chat_id or text"}), 400
    
    try:
        sent = await tg.send_message(chat_id, text)
        return jsonify({"success": True, "message_id": sent.id})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000)
