from flask import Flask, request, jsonify
import razorpay
import hashlib
import hmac
import os

from flask_cors import CORS  # Import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Razorpay API credentials
RAZORPAY_KEY_ID = os.getenv('RAZORPAY_KEY_ID', 'rzp_test_GkajTwSfONYREd')
RAZORPAY_KEY_SECRET = os.getenv('RAZORPAY_KEY_SECRET', 'san2oOaZ6L2KHd0h4q2p4Zfi')

# Initialize Razorpay client
client = razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))

@app.route('/create_order', methods=['POST'])
def create_order():
    try:
        data = request.json
        amount = data['amount']  # Amount in INR (multiplied by 100 for paise)
        currency = 'INR'
        
        # Create Razorpay order
        order = client.order.create({
            'amount': amount * 100,  # Razorpay accepts amount in paise
            'currency': currency,
            'payment_capture': '1'
        })

        return jsonify({
            'order_id': order['id'],
            'amount': order['amount'],
            'currency': order['currency'],
            'status': order['status']
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/verify_payment', methods=['POST'])
def verify_payment():
    try:
        data = request.json
        order_id = data['order_id']
        payment_id = data['payment_id']
        signature = data['signature']

        # Verify payment signature
        body = order_id + "|" + payment_id
        expected_signature = hmac.new(
            RAZORPAY_KEY_SECRET.encode('utf-8'),
            body.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

        if expected_signature == signature:
            return jsonify({'status': 'success'}), 200
        else:
            return jsonify({'status': 'failure', 'reason': 'Invalid signature'}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 400

if __name__ == '__main__':
    app.run(debug=True)
