from flask import Flask, request, jsonify
import joblib
import numpy as np

app = Flask(__name__)

# Load the model and label encoder
model = joblib.load("efficiency_model_v2.pkl")
encoder = joblib.load("label_encoder_v2.pkl")

# 🟢 Optional root route for browser testing
@app.route("/", methods=["GET"])
def home():
    return "✅ AI API is running. Use POST /predict to get efficiency prediction."

# 🔵 Prediction route for POST request
@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.json
        features = np.array([[data['temperature'], data['humidity'], data['voltage'], data['current'], data['hour']]])
        prediction = model.predict(features)
        label = encoder.inverse_transform(prediction)
        return jsonify({"efficiency": label[0]})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# ✅ Only used if you run it locally with python api.py
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
