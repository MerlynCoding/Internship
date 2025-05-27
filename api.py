from flask import Flask, request, jsonify
import joblib
import numpy as np

app = Flask(__name__)

# Load model and label encoder
model = joblib.load("efficiency_model_v2.pkl")
encoder = joblib.load("label_encoder_v2.pkl")

@app.route("/", methods=["GET"])
def home():
    return "✅ AI API is running. POST to /predict with temperature, humidity, voltage, current, charging_encoded, day, hour."

@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.json

        # Ensure all 7 required features are present
        required_fields = ["temperature", "humidity", "voltage", "current", "charging_encoded", "day", "hour"]
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing field: {field}"}), 400

        # Create input array for model
        features = np.array([[
            data["temperature"],
            data["humidity"],
            data["voltage"],
            data["current"],
            data["charging_encoded"],
            data["day"],
            data["hour"]
        ]])

        # Predict efficiency
        prediction = model.predict(features)
        label = encoder.inverse_transform(prediction)

        return jsonify({"efficiency": label[0]})
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
