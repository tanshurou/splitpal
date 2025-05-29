import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/currency_service.dart';

class CurrencySettingsPage extends StatefulWidget {
  const CurrencySettingsPage({Key? key}) : super(key: key);
  @override
  State<CurrencySettingsPage> createState() => _CurrencySettingsPageState();
}

class _CurrencySettingsPageState extends State<CurrencySettingsPage> {
  final svc = CurrencyService.instance;
  late String _selected;

  @override
  void initState() {
    super.initState();
    // start with whatever's in memory
    _selected = svc.current;
    // then load from Firestore and refresh
    svc.loadCurrency().then((_) {
      setState(() {
        _selected = svc.current;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Currency', style: GoogleFonts.poppins()),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ...CurrencyService.supported.map((code) {
            return RadioListTile<String>(
              value: code,
              groupValue: _selected,
              title: Text(code, style: GoogleFonts.poppins(fontSize: 18)),
              onChanged: (val) {
                if (val == null) return;
                setState(() => _selected = val);
                svc.updateCurrency(val);
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
