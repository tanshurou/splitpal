// lib/pages/banking_details_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/payment_method.dart';
import '../services/payment_service.dart';

/// BankingDetailsPage now accepts an optional `serviceOverride` for testing.
///
/// If `serviceOverride` is non‐null, _both_ fetch and delete/add calls will
/// delegate to that object. Otherwise, it uses `PaymentService.instance`.
class BankingDetailsPage extends StatefulWidget {
  /// If non‐null, this PaymentService will be used instead of the real singleton.
  final PaymentService? serviceOverride;

  const BankingDetailsPage({Key? key, this.serviceOverride}) : super(key: key);

  @override
  State<BankingDetailsPage> createState() => _BankingDetailsPageState();
}

class _BankingDetailsPageState extends State<BankingDetailsPage> {
  /// Inside the state, always refer to `svc` instead of `PaymentService.instance`
  /// directly. That way, if `widget.serviceOverride` is supplied, it will get used.
  PaymentService get svc => widget.serviceOverride ?? PaymentService.instance;

  late Future<List<PaymentMethod>> _methodsFuture;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  void _loadMethods() {
    // Use the override if provided, otherwise the real singleton
    _methodsFuture = svc.fetchMethods();
  }

  Future<void> _deleteMethod(String id) async {
    await svc.deleteMethod(id);
    _loadMethods();
    setState(() {});
  }

  Future<void> _showAddDialog() async {
    String? name;
    String? number;

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Add Payment Method', style: GoogleFonts.poppins()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Name (e.g. Visa)',
                  ),
                  onChanged: (v) => name = v,
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'Card Number'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => number = v,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () {
                  final n = name?.trim() ?? '';
                  final num = number?.trim() ?? '';
                  if (n.isNotEmpty && num.isNotEmpty) {
                    svc.addMethod(n, num).then((_) {
                      _loadMethods();
                      setState(() {});
                      Navigator.pop(ctx);
                    });
                  }
                },
                child: Text('Add', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gradientStart = Color(0xFF7B5FFF);
    const gradientEnd = Color(0xFFFB56A5);
    const bgColor = Color(0xFFF8F8FB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Banking Details', style: GoogleFonts.poppins()),
        backgroundColor: gradientStart,
      ),
      body: FutureBuilder<List<PaymentMethod>>(
        future: _methodsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error loading payment methods',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            );
          }

          final methods = snap.data ?? [];
          if (methods.isEmpty) {
            return Center(
              child: Text(
                'No payment methods yet',
                style: GoogleFonts.poppins(),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: methods.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final m = methods[i];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(Icons.credit_card, color: gradientStart),
                  title: Text(
                    m.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(m.details, style: GoogleFonts.poppins()),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteMethod(m.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: gradientEnd,
        icon: const Icon(Icons.add),
        label: Text('Add Method', style: GoogleFonts.poppins()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
