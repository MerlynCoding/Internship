from flask import Flask, request, jsonify
import joblib
import numpy as np

app = Flask(__name__)

model = joblib.load("efficiency_model.pkl")
encoder = joblib.load("label_encoder.pkl")

@app.route('/predict', methods=['POST'])
def predict():
    data = request.json
    try:
        features = np.array([[data['temperature'], data['humidity'], data['voltage'], data['current'], data['hour']]])
        prediction = model.predict(features)
        label = encoder.inverse_transform(prediction)
        return jsonify({"efficiency": label[0]})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
