import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'services/local_notification_service.dart';
import 'models/ardoise.dart';
import 'models/cash_movement.dart';
import 'theme/app_theme.dart';
import 'widgets/glass_card.dart';

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

class HomeScreen extends StatefulWidget {
  final LocalNotificationService notificationService;
  const HomeScreen({super.key, required this.notificationService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double cashBalance = 0;
  List<Ardoise> ardoises = [];
  List<CashMovement> movements = [];
  final money = NumberFormat('#,##0', 'fr_FR');
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    cashBalance = prefs.getDouble('cash_balance') ?? 0;
    final rawArdoises = prefs.getStringList('ardoises') ?? [];
    ardoises =
        rawArdoises.map((e) => Ardoise.fromJson(jsonDecode(e))).toList();
    final rawMovements = prefs.getStringList('cash_movements') ?? [];
    movements =
        rawMovements.map((e) => CashMovement.fromJson(jsonDecode(e))).toList();
    loading = false;
    setState(() {});
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('cash_balance', cashBalance);
    await prefs.setStringList(
      'ardoises',
      ardoises.map((a) => jsonEncode(a.toJson())).toList(),
    );
    await prefs.setStringList(
      'cash_movements',
      movements.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }

  double get totalDue => ardoises
      .where((a) => a.status == 'DUE')
      .fold(0.0, (sum, a) => sum + a.remainingAmount);

  Future<void> _onPaymentReceived(double amount, String clientName) async {
    cashBalance += amount;
    movements.insert(
      0,
      CashMovement(
        id: const Uuid().v4(),
        amount: amount,
        isIncome: true,
        label: 'Paiement ardoise — $clientName',
        createdAt: DateTime.now(),
      ),
    );
    await _saveData();
    setState(() {});
  }

  void _adjustCash(bool isIncome) {
    final amountCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Montant en FCFA',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Libellé (optionnel)',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: isIncome
                        ? const Color(0xFF00C9A7)
                        : const Color(0xFFFF6B6B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final amount = double.tryParse(
                          amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;
                    if (amount <= 0) return;

                    if (!isIncome && amount > cashBalance) {
                      final proceed = await showDialog<bool>(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          backgroundColor: const Color(0xFF0F1C3F),
                          title: const Text(
                            'Solde insuffisant',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            'Le décaissement (${money.format(amount)} FCFA) dépasse le solde (${money.format(cashBalance)} FCFA). Continuer ?',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: const Text('Annuler'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text('Continuer'),
                            ),
                          ],
                        ),
                      );
                      if (proceed != true) return;
                    }

                    final label = labelCtrl.text.trim().isEmpty
                        ? (isIncome ? 'Encaissement' : 'Décaissement')
                        : labelCtrl.text.trim();

                    setState(() {
                      cashBalance += isIncome ? amount : -amount;
                      movements.insert(
                        0,
                        CashMovement(
                          id: const Uuid().v4(),
                          amount: amount,
                          isIncome: isIncome,
                          label: label,
                          createdAt: DateTime.now(),
                        ),
                      );
                    });
                    await _saveData();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(isIncome ? 'Encaisser' : 'Décaisser'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1426),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
        ),
      );
    }

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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WALLET CAM',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
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
                ],
              ),
              const SizedBox(height: 28),
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solde de caisse',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'À recouvrer : ${money.format(totalDue)} FCFA · ${ardoises.where((a) => a.status == 'DUE').length} ardoise(s)',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                        onPaymentReceived: _onPaymentReceived,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C9A7), Color(0xFF00B4D8)],
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Trésorerie',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
              if (movements.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  'Derniers mouvements',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...movements.take(8).map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              m.isIncome
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: m.isIncome
                                  ? const Color(0xFF00C9A7)
                                  : const Color(0xFFFF6B6B),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMM · HH:mm', 'fr_FR')
                                        .format(m.createdAt),
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.45),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${m.isIncome ? '+' : '-'}${money.format(m.amount)} F',
                              style: TextStyle(
                                color: m.isIncome
                                    ? const Color(0xFF00C9A7)
                                    : const Color(0xFFFF6B6B),
                                fontWeight: FontWeight.w700,
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

  Widget _quickAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
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
}

class TreasuryScreen extends StatefulWidget {
  final List<Ardoise> ardoises;
  final LocalNotificationService notificationService;
  final Function(List<Ardoise>) onUpdate;
  final void Function(double amount, String clientName)? onPaymentReceived;

  const TreasuryScreen({
    super.key,
    required this.ardoises,
    required this.notificationService,
    required this.onUpdate,
    this.onPaymentReceived,
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

  Future<void> _markAsPaid(Ardoise a) async {
    final paidAmount = a.remainingAmount;
    if (paidAmount <= 0) return;

    await widget.notificationService
        .cancelReminder(a.id.hashCode.abs() % 100000);

    setState(() {
      final index = ardoises.indexWhere((e) => e.id == a.id);
      if (index != -1) {
        ardoises[index] = a.copyWith(status: 'PAID', remainingAmount: 0);
      }
    });

    widget.onPaymentReceived?.call(paidAmount, a.clientName);
    widget.onUpdate(ardoises);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ardoise payée — ${money.format(paidAmount)} FCFA ajoutés à la caisse',
          ),
          backgroundColor: const Color(0xFF00C9A7),
        ),
      );
    }
  }

  Future<void> _partialPay(Ardoise a) async {
    final ctrl = TextEditingController();
    final paid = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1C3F),
        title: const Text('Paiement partiel',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reste dû : ${money.format(a.remainingAmount)} FCFA',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Montant reçu',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(
                    ctrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
                  ) ??
                  0;
              Navigator.pop(ctx, v);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (paid == null || paid <= 0) return;
    final amount = paid > a.remainingAmount ? a.remainingAmount : paid;
    final newRemaining = a.remainingAmount - amount;
    final fullyPaid = newRemaining <= 0;

    if (fullyPaid) {
      await widget.notificationService
          .cancelReminder(a.id.hashCode.abs() % 100000);
    }

    setState(() {
      final index = ardoises.indexWhere((e) => e.id == a.id);
      if (index != -1) {
        ardoises[index] = a.copyWith(
          remainingAmount: fullyPaid ? 0 : newRemaining,
          status: fullyPaid ? 'PAID' : 'DUE',
        );
      }
    });

    widget.onPaymentReceived?.call(amount, a.clientName);
    widget.onUpdate(ardoises);
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
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: GlassCard(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nouvelle ardoise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDeco('Nom du client', Icons.person_outline),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDeco('Téléphone', Icons.phone_outlined),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      _fieldDeco('Montant FCFA', Icons.payments_outlined),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Échéance : ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing:
                      const Icon(Icons.calendar_today, color: Colors.white70),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
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
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9A7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final amount = double.tryParse(
                          amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
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

                    await widget.notificationService.scheduleArdoiseReminder(
                      notificationId: id.hashCode.abs() % 100000,
                      ardoiseId: id,
                      clientName: name,
                      amount: amount,
                      dueDate: dueDate,
                    );

                    setState(() => ardoises.insert(0, ardoise));
                    widget.onUpdate(ardoises);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text("Créer l'ardoise"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
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
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                    ),
                    const Text(
                      'Trésorerie',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    if (ardoises.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune ardoise',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      if (dues.isNotEmpty) ...[
                        Text(
                          'À recouvrer (${dues.length})',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
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
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
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
        label: const Text('Ardoise'),
      ),
    );
  }

  Widget _ardoiseTile(Ardoise a) {
    final isDue = a.status == 'DUE';
    final isLate = isDue && a.dueDate.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDue
                      ? const Color(0xFFFF6B6B).withValues(alpha: 0.2)
                      : const Color(0xFF00C9A7).withValues(alpha: 0.2),
                  child: Text(
                    a.clientName.isNotEmpty
                        ? a.clientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: isDue
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF00C9A7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.clientName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (a.clientPhone.isNotEmpty)
                        Text(
                          a.clientPhone,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${money.format(a.remainingAmount)} F',
                  style: TextStyle(
                    color: isDue
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF00C9A7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.event,
                    size: 13, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy', 'fr_FR').format(a.dueDate),
                  style: TextStyle(
                    color: isLate
                        ? const Color(0xFFFF6B6B)
                        : Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
                if (isLate) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'En retard',
                      style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
                    ),
                  ),
                ],
                const Spacer(),
                if (isDue) ...[
                  TextButton(
                    onPressed: () => _partialPay(a),
                    child: const Text('Partiel'),
                  ),
                  TextButton(
                    onPressed: () => _markAsPaid(a),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF00C9A7)),
                    child: const Text('Tout payer'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
