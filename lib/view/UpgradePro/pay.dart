const String GooglePayDefault = '''
{
    "provider": "google_pay",
    "data": {
        "environment": "TEST",
        "apiVersion": 2,
        "apiVersionMinor": 0,
        "allowedPaymentMethods": [
            {
                "type": "CARD",
                "parameters": {
                    "allowedAuthMethods": [
                        "PAN_ONLY",
                        "CRYPTOGRAM_3DS"
                    ],
                    "allowedCardNetworks": [
                        "VISA",
                        "MASTERCARD"
                    ]
                },
                "tokenizationSpecification": {
                    "type": "PAYMENT_GATEWAY",
                    "parameters": {
                        "gateway": "stripe",
                        "stripe:publishableKey": "your-publishable-key",
                        "stripe:version": "2023-10-16"
                    }
                }
            }
        ]
    }
}
''';
