import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';

import 'services/local_notification_service.dart';
import 'models/ardoise.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final notificationService = LocalNotificationService();
  await notificationService.init();

  runApp(WalletcamApp(notificationService: notificationService));
}

class WalletcamApp extends StatelessWidget {
  final LocalNotificationService notificationService;

  const WalletcamApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walletcam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkGlass,
      home: HomeScreen(notificationService: notificationService),
    );
  }
}

// ─────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final LocalNotificationService notificationService;
  const HomeScreen({super.key, required this.notificationService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double cashBalance = 0;
  List<Ardoise> ardoises = [];
  final money = NumberFormat('#,##0', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    cashBalance = prefs.getDouble('cash_balance') ?? 485000;
    final raw = prefs.getStringList('ardoises') ?? [];
    ardoises = raw.map((e) => Ardoise.fromJson(jsonDecode(e))).toList();
    setState(() {});
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('cash_balance', cashBalance);
    await prefs.setStringList(
      'ardoises',
      ardoises.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  double get totalDue => ardoises
      .where((a) => a.status == 'DUE')
      .fold(0.0, (sum, a) => sum + a.remainingAmount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1426),
              Color(0xFF0F1C3F),
              Color(0xFF0A1628),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WALLET CAM',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Bonjour 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.notifications_none_rounded,
                        color: Colors.white70, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Balance Card
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solde de caisse',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${money.format(cashBalance)} FCFA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _miniStat('À recouvrer', totalDue, const Color(0xFFFF6B6B)),
                        const SizedBox(width: 16),
                        _miniStat('Ardoises', ardoises.where((a) => a.status == 'DUE').length.toDouble(), const Color(0xFF4ECDC4)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // CTA Trésorerie
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TreasuryScreen(
                        ardoises: ardoises,
                        notificationService: widget.notificationService,
                        onUpdate: (updated) async {
                          ardoises = updated;
                          await _saveData();
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C9A7), Color(0xFF00B4D8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C9A7).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 26),
                      SizedBox(width: 12),
                      Text(
                        'Trésorerie',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Quick actions
              Text(
                'Actions rapides',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _quickAction(
                      Icons.add_circle_outline_rounded,
                      'Encaisser',
                      const Color(0xFF00C9A7),
                      () => _adjustCash(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickAction(
                      Icons.remove_circle_outline_rounded,
                      'Décaisser',
                      const Color(0xFFFF6B6B),
                      () => _adjustCash(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Recent ardoises preview
              if (ardoises.where((a) => a.status == 'DUE').isNotEmpty) ...[
                Text(
                  'Ardoises en cours',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...ardoises
                    .where((a) => a.status == 'DUE')
                    .take(3)
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      const Color(0xFF00C9A7).withOpacity(0.2),
                                  child: Text(
                                    a.clientName.isNotEmpty
                                        ? a.clientName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Color(0xFF00C9A7),
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.clientName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        'Échéance : ${DateFormat('dd MMM yyyy', 'fr_FR').format(a.dueDate)}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${money.format(a.remainingAmount)} F',
                                  style: const TextStyle(
                                    color: Color(0xFFFF6B6B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value == value.roundToDouble()
                  ? value.toInt().toString()
                  : money.format(value),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _adjustCash(bool isIncome) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: GlassCard(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isIncome ? 'Encaisser' : 'Décaisser',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Montant en FCFA',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixText: 'FCFA',
                  suffixStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isIncome ? const Color(0xFF00C9A7) : const Color(0xFFFF6B6B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final amount = double.tryParse(
                            controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                        0;
                    if (amount <= 0) return;
                    setState(() {
                      cashBalance += isIncome ? amount : -amount;
                    });
                    await _saveData();
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: Text(
                    isIncome ? 'Encaisser' : 'Décaisser',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TREASURY SCREEN
// ─────────────────────────────────────────────
class TreasuryScreen extends StatefulWidget {
  final List<Ardoise> ardoises;
  final LocalNotificationService notificationService;
  final Function(List<Ardoise>) onUpdate;

  const TreasuryScreen({
    super.key,
    required this.ardoises,
    required this.notificationService,
    required this.onUpdate,
  });

  @override
  State<TreasuryScreen> createState() => _TreasuryScreenState();
}

class _TreasuryScreenState extends State<TreasuryScreen> {
  late List<Ardoise> ardoises;
  final money = NumberFormat('#,##0', 'fr_FR');

  @override
  void initState() {
    super.initState();
    ardoises = List.from(widget.ardoises);
  }

  @override
  Widget build(BuildContext context) {
    final dues = ardoises.where((a) => a.status == 'DUE').toList();
    final paid = ardoises.where((a) => a.status == 'PAID').toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1426), Color(0xFF0F1C3F), Color(0xFF0A1628)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70),
                    ),
                    const Expanded(
                      child: Text(
                        'Trésorerie',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GlassCard(
                      padding: const EdgeInsets.all(10),
                      child: GestureDetector(
                        onTap: _addArdoise,
                        child: const Icon(Icons.add_rounded,
                            color: Color(0xFF00C9A7), size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  children: [
                    if (dues.isEmpty && paid.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 64,
                                color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune ardoise',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Appuyez sur + pour ajouter un crédit client',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      if (dues.isNotEmpty) ...[
                        Text(
                          'À recouvrer (${dues.length})',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...dues.map(_ardoiseTile),
                        const SizedBox(height: 24),
                      ],
                      if (paid.isNotEmpty) ...[
                        Text(
                          'Payées (${paid.length})',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...paid.map(_ardoiseTile),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addArdoise,
        backgroundColor: const Color(0xFF00C9A7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle ardoise',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _ardoiseTile(Ardoise a) {
    final isDue = a.status == 'DUE';
    final isOverdue = isDue && a.dueDate.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isDue
                      ? const Color(0xFFFF6B6B).withOpacity(0.2)
                      : const Color(0xFF00C9A7).withOpacity(0.2),
                  child: Text(
                    a.clientName.isNotEmpty
                        ? a.clientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: isDue
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF00C9A7),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.clientName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (a.clientPhone.isNotEmpty)
                        Text(
                          a.clientPhone,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${money.format(a.remainingAmount)} F',
                      style: TextStyle(
                        color: isDue
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF00C9A7),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (isOverdue)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'En retard',
                          style: TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 13, color: Colors.white.withOpacity(0.4)),
                const SizedBox(width: 6),
                Text(
                  'Échéance : ${DateFormat('dd MMM yyyy', 'fr_FR').format(a.dueDate)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (isDue)
                  TextButton(
                    onPressed: () => _markAsPaid(a),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00C9A7),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Marquer payé',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addArdoise() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: GlassCard(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouvelle ardoise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _field(nameCtrl, 'Nom du client', Icons.person_outline),
                const SizedBox(height: 12),
                _field(phoneCtrl, 'Téléphone (optionnel)', Icons.phone_outlined,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                _field(amountCtrl, 'Montant (FCFA)', Icons.payments_outlined,
                    keyboard: TextInputType.number),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF00C9A7),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setModal(() => dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: Colors.white54),
                        const SizedBox(width: 12),
                        Text(
                          'Échéance : ${DateFormat('dd MMM yyyy', 'fr_FR').format(dueDate)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9A7),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final amount = double.tryParse(amountCtrl.text
                              .replaceAll(RegExp(r'[^0-9]'), '')) ??
                          0;
                      if (name.isEmpty || amount <= 0) return;

                      final id = const Uuid().v4();
                      final ardoise = Ardoise(
                        id: id,
                        clientName: name,
                        clientPhone: phoneCtrl.text.trim(),
                        totalAmount: amount,
                        remainingAmount: amount,
                        dueDate: dueDate,
                        status: 'DUE',
                      );

                      // Schedule local notification
                      await widget.notificationService.scheduleArdoiseReminder(
                        notificationId: id.hashCode.abs() % 100000,
                        ardoiseId: id,
                        clientName: name,
                        amount: amount,
                        dueDate: dueDate,
                      );

                      setState(() => ardoises.insert(0, ardoise));
                      widget.onUpdate(ardoises);
                      if (mounted) Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Créer l\'ardoise',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _markAsPaid(Ardoise a) async {
    await widget.notificationService
        .cancelReminder(a.id.hashCode.abs() % 100000);
    setState(() {
      final index = ardoises.indexWhere((e) => e.id == a.id);
      if (index != -1) {
        ardoises[index] = a.copyWith(status: 'PAID', remainingAmount: 0);
      }
    });
    widget.onUpdate(ardoises);
  }
}

// ─────────────────────────────────────────────
// GLASS CARD WIDGET
// ─────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
