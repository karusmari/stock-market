import time
from datetime import datetime
from random import uniform

from flask import Flask, jsonify, request
from flask_cors import CORS
import bcrypt
import json
from pathlib import Path
from threading import Lock

from utils import get_historical_data, load_data

app = Flask(__name__)
CORS(app)

start_time = time.time()

historical_data = load_data()

# Simple JSON-backed user store (username -> { password: hashed })
USERS_PATH = Path(__file__).parent / 'users.json'
_users_lock = Lock()

def _load_users():
    try:
        with _users_lock:
            return json.loads(USERS_PATH.read_text())
    except Exception:
        return {}

def _save_users(data):
    with _users_lock:
        USERS_PATH.write_text(json.dumps(data))

users = _load_users()


@app.route("/exchange_rate/<symbol>")
def get_stock_data(symbol):
    if symbol not in list(historical_data.keys()):
        response = jsonify({"error": "Invalid symbol"})
        response.status_code = 404
        return response
    current_time = time.time()
    last_value = historical_data[symbol].iloc[-1].Close
    step = (int(current_time * 10) - int(start_time * 10)) % len(
        historical_data[symbol]
    )
    return jsonify(
        {
            "currency": "USD",
            "rate": last_value * (1 + uniform(0.05, -0.05) + step * 0.0005),
            "datetime": datetime.fromtimestamp(current_time),
        }
    )


@app.route("/hist/<symbol>")
def get_hist_data(symbol):
    if symbol not in list(historical_data.keys()):
        response = jsonify({"error": "Invalid symbol"})
        response.status_code = 404
        return response

    df = historical_data[symbol]
    args = request.args
    start_date = args.get("start_date")
    end_date = args.get("end_date")
    if not start_date or not end_date:
        response = jsonify({"error": "start_date and end_date required"})
        response.status_code = 400
        return response

    try:
        filtered = get_historical_data(df, start_date, end_date, start_time)
        data = filtered[["datetime", "Close"]].to_dict(orient="list")

        values = [
            {"date": dt.date(), "close": close}
            for dt, close in zip(data["datetime"], data["Close"])
        ]
        response = jsonify(
            {
                "currency": "USD",
                "values": values,
            }
        )
        return response

    except Exception as e:
        response = jsonify({"error": str(e)})
        response.status_code = 400
        return response


@app.route("/stocks_list")
def list_symbols():
    return jsonify(list(historical_data.keys()))


@app.route('/register', methods=['POST'])
def register():
    data = request.get_json() or {}
    username = (data.get('username') or '').strip()
    password = data.get('password') or ''
    if not username or not password:
        return jsonify({'error': 'username and password required'}), 400

    if username in users:
        return jsonify({'error': 'user exists'}), 400

    # bcrypt requires bytes
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    users[username] = {'password': hashed.decode('utf-8')}
    _save_users(users)

    return jsonify({'ok': True, 'username': username}), 201


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    username = (data.get('username') or '').strip()
    password = data.get('password') or ''
    if not username or not password:
        return jsonify({'error': 'username and password required'}), 400

    if username not in users:
        return jsonify({'error': 'invalid credentials'}), 401

    stored = users[username]['password']
    try:
        ok = bcrypt.checkpw(password.encode('utf-8'), stored.encode('utf-8'))
    except Exception:
        ok = False

    if not ok:
        return jsonify({'error': 'invalid credentials'}), 401

    return jsonify({'ok': True, 'username': username}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
