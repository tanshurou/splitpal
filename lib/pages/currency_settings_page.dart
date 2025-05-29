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
    // 1) initialize with the default or previously loaded value
    _selected = svc.current;

    // 2) pull the last‐saved choice from Firestore
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
        title: Text('Choose Currency', style: GoogleFonts.inter()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: _selected,
              items:
                  svc.supported.map((code) {
                    return DropdownMenuItem(
                      value: code,
                      child: Text(
                        '${_symbolFor(code)}  $code',
                        style: GoogleFonts.inter(fontSize: 16),
                      ),
                    );
                  }).toList(),
              onChanged: (newCode) async {
                if (newCode == null) return;
                // update locally + Firestore
                await svc.updateCurrency(newCode);
                setState(() {
                  _selected = newCode;
                });
              },
            ),

            const SizedBox(height: 24),
            Text(
              'Preview: ${_symbolFor(_selected)} 1234.56',
              style: GoogleFonts.inter(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  String _symbolFor(String code) {
    switch (code) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'AUD':
        return 'A\$';
      case 'RM':
        return 'RM';
      default:
        return code;
    }
  }
}
