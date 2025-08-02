import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VoiceFeatureForm extends StatefulWidget {
  const VoiceFeatureForm({super.key, required this.title});
  final String title;

  @override
  _VoiceFeatureFormState createState() => _VoiceFeatureFormState();
}

class _VoiceFeatureFormState extends State<VoiceFeatureForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool isLoading = false;

  final Map<String, List<double>> fieldRanges = {
    'MDVP:Fo(Hz)': [60, 300],
    'MDVP:Fhi(Hz)': [100, 600],
    'MDVP:Flo(Hz)': [50, 250],
    'MDVP:Jitter(%)': [0.0, 1.0],
    'MDVP:Jitter(Abs)': [0.0, 0.01],
    'MDVP:RAP': [0.0, 0.02],
    'MDVP:PPQ': [0.0, 0.02],
    'Jitter:DDP': [0.0, 0.05],
    'MDVP:Shimmer': [0.0, 0.2],
    'MDVP:Shimmer(dB)': [0.0, 3.0],
    'Shimmer:APQ3': [0.0, 0.1],
    'Shimmer:APQ5': [0.0, 0.2],
    'MDVP:APQ': [0.0, 0.3],
    'Shimmer:DDA': [0.0, 0.1],
    'NHR': [0.0, 0.5],
    'HNR': [0.0, 40.0],
    'RPDE': [0.0, 1.0],
    'DFA': [0.0, 1.0],
    'spread1': [-10.0, 0.0],
    'spread2': [0.0, 1.0],
    'D2': [1.0, 3.0],
    'PPE': [0.0, 1.0],
  };

  final List<String> fields = [
    'MDVP:Fo(Hz)', 'MDVP:Fhi(Hz)', 'MDVP:Flo(Hz)', 'MDVP:Jitter(%)',
    'MDVP:Jitter(Abs)', 'MDVP:RAP', 'MDVP:PPQ', 'Jitter:DDP',
    'MDVP:Shimmer', 'MDVP:Shimmer(dB)', 'Shimmer:APQ3', 'Shimmer:APQ5',
    'MDVP:APQ', 'Shimmer:DDA', 'NHR', 'HNR', 'RPDE', 'DFA',
    'spread1', 'spread2', 'D2', 'PPE'
  ];

  final Map<String, String> fieldDescriptions = {
    'MDVP:Fo(Hz)': 'Fundamental frequency of the voice. In Parkinson’s patients, this often decreases due to reduced vocal cord tension and monotonic speech.',
    'MDVP:Fhi(Hz)': 'Highest fundamental frequency. Elevated Fhi may suggest instability in voice control, a common symptom in Parkinson’s.',
    'MDVP:Flo(Hz)': 'Lowest fundamental frequency. Lower values can indicate stiffness in the vocal folds, associated with Parkinsonian hypophonia.',
    'MDVP:Jitter(%)': 'Measures frequency variation between cycles. High jitter reflects unstable voice pitch, common in Parkinson’s due to muscle control issues.',
    'MDVP:Jitter(Abs)': 'Absolute measure of jitter. Reinforces how much the pitch varies, helping detect vocal tremors in Parkinson’s.',
    'MDVP:RAP': 'Relative Average Perturbation. Indicates short-term variability in pitch, which tends to be higher in Parkinson’s patients.',
    'MDVP:PPQ': 'Pitch Period Perturbation Quotient. Captures average cycle-to-cycle variability in pitch, aiding in detecting micro-instabilities in voice.',
    'Jitter:DDP': 'Average absolute difference between consecutive RAP values. Detects fine-grained vocal fluctuations indicating motor degradation.',
    'MDVP:Shimmer': 'Amplitude variation across cycles. Increased shimmer points to breathy or weak voice, a typical Parkinson’s sign.',
    'MDVP:Shimmer(dB)': 'Logarithmic scale of amplitude variation. Helps in understanding voice harshness or instability.',
    'Shimmer:APQ3': 'Amplitude perturbation over 3 cycles. A local measure to detect short-term voice tremors.',
    'Shimmer:APQ5': 'Amplitude perturbation over 5 cycles. A broader shimmer metric for detecting prolonged amplitude instability.',
    'MDVP:APQ': 'Average perturbation across full recording. Useful for assessing chronic voice instability.',
    'Shimmer:DDA': 'Average absolute difference between consecutive APQ3 values. Helps capture persistent amplitude variations in Parkinsonian speech.',
    'NHR': 'Noise-to-Harmonics Ratio. High values suggest excessive breathiness or hoarseness in voice, typical in Parkinson’s.',
    'HNR': 'Harmonics-to-Noise Ratio. A low HNR implies increased noise, indicating impaired vocal fold vibration common in Parkinson’s.',
    'RPDE': 'Recurrence Period Density Entropy. Measures signal complexity. Higher values show irregular voice patterns due to impaired neuromuscular control.',
    'DFA': 'Detrended Fluctuation Analysis. Identifies long-range correlations in speech. Abnormal values reflect changes in vocal fold movement.',
    'spread1': '1st nonlinear measure of signal spread. Large negative values are linked to pathological voice patterns in Parkinson’s.',
    'spread2': '2nd nonlinear measure of signal spread. Helps capture fine details of voice modulation affected by the disease.',
    'D2': 'Correlation dimension. Reflects signal complexity. Lower values suggest reduced variability in speech patterns, often seen in Parkinson’s.',
    'PPE': 'Pitch Period Entropy. Measures randomness in pitch. High PPE indicates irregular pitch modulation associated with Parkinson’s.',
  };

  @override
  void initState() {
    super.initState();
    for (final field in fields) {
      controllers[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submitData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      final Map<String, dynamic> inputData = {};
      for (final field in fields) {
        final text = controllers[field]!.text;
        inputData[field] = double.tryParse(text) ?? text;
      }

      final body = {'input_data': inputData};
      final response = await http.post(
        Uri.parse('https://parkinsons-disease-detection-p022.onrender.com/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final result = jsonDecode(response.body);
      setState(() => isLoading = false);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Prediction Result',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Row(
            children: [
              Icon(
                result['prediction'] == 1 ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                color: result['prediction'] == 1 ? Colors.redAccent : Colors.green,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result['prediction'] == 1
                      ? 'Yes, you may have Parkinson\'s Disease. Please consult a specialist.'
                      : 'No, you don\'t have Parkinson\'s Disease. Stay healthy!',
                  style: TextStyle(
                    fontSize: 16,
                    color: result['prediction'] == 1 ? Colors.red[700] : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('Close'),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ...fields.map((field) => Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: Colors.black12,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              field,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline, color: Colors.blueGrey),
                            splashRadius: 20,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: Text(field),
                                  content: Text(fieldDescriptions[field] ?? 'No description available.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controllers[field],
                        decoration: InputDecoration(
                          labelText: 'Enter value',
                          helperText: 'Expected: ${fieldRanges[field]![0]} - ${fieldRanges[field]![1]}',
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: isLoading ? null : submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white),)
                    : const Text('Predict', style: TextStyle(fontSize: 16, color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}