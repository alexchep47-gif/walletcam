import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() => runApp(const WalletcamApp());

enum Currency { xaf, usd, eur }

extension CurrencyLabel on Currency {
  String get code => name.toUpperCase();
  String get symbol => this == Currency.xaf ? 'FCFA' : code;
  int get decimals => this == Currency.xaf ? 0 : 2;
}

class Wallet {
  Wallet(this.currency, this.microBalance);
  final Currency currency;
  int microBalance;
}

class Rate {
  Rate({required this.from, required this.to, required this.rate, required this.effectiveAt});
  Currency from;
  Currency to;
  double rate;
  DateTime effectiveAt;
}

class TransactionRecord {
  TransactionRecord({required this.id, required this.date, required this.sender, required this.receiver, required this.sourceAmount, required this.sourceCurrency, required this.targetAmount, required this.targetCurrency, required this.rate, required this.fee, required this.tax, required this.commission, required this.status});
  final String id;
  final DateTime date;
  final String sender;
  final String receiver;
  final int sourceAmount;
  final Currency sourceCurrency;
  final double targetAmount;
  final Currency targetCurrency;
  final double rate;
  final int fee;
  final int tax;
  final int commission;
  final String status;
}

class WalletcamApp extends StatefulWidget {
  const WalletcamApp({super.key});
  @override State<WalletcamApp> createState() => _WalletcamAppState();
}

class _WalletcamAppState extends State<WalletcamApp> {
  int tab = 0;
  final Map<Currency, Wallet> wallets = {
    Currency.xaf: Wallet(Currency.xaf, 18500000000),
    Currency.usd: Wallet(Currency.usd, 42500000),
    Currency.eur: Wallet(Currency.eur, 12000000),
  };
  final List<Rate> rates = [
    Rate(from: Currency.xaf, to: Currency.usd, rate: 1 / 600, effectiveAt: DateTime(2026, 10, 1)),
    Rate(from: Currency.usd, to: Currency.xaf, rate: 600, effectiveAt: DateTime(2026, 10, 1)),
    Rate(from: Currency.xaf, to: Currency.eur, rate: 1 / 650, effectiveAt: DateTime(2026, 10, 1)),
    Rate(from: Currency.eur, to: Currency.xaf, rate: 650, effectiveAt: DateTime(2026, 10, 1)),
  ];
  final List<TransactionRecord> transactions = [];
  final money = NumberFormat('#,##0.00', 'fr_FR');

  String formatAmount(double amount, Currency currency) => currency == Currency.xaf ? NumberFormat('#,##0', 'fr_FR').format(amount) : money.format(amount);
  double amountOf(Wallet wallet) => wallet.microBalance / 1000000;

  void transfer({required Currency source, required Currency target, required int amount, required String receiver, required bool merchant}) {
    final fee = (amount * 25 ~/ 1000) + (source == Currency.xaf ? 100 : 1);
    final tax = fee * 1925 ~/ 10000;
    final debit = amount + fee + tax;
    final wallet = wallets[source]!;
    if (amount <= 0) { _message('Le montant doit être supérieur à zéro.'); return; }
    if (wallet.microBalance < debit * 1000000) { _message('Solde insuffisant : le débit inclut frais et taxe.'); return; }
    final rate = source == target ? 1.0 : rates.firstWhere((r) => r.from == source && r.to == target, orElse: () => Rate(from: source, to: target, rate: 1, effectiveAt: DateTime.now())).rate;
    final targetAmount = amount * rate;
    final commission = merchant ? (targetAmount * 0.01).round() : 0;
    wallet.microBalance -= debit * 1000000;
    transactions.insert(0, TransactionRecord(id: 'WC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}', date: DateTime.now(), sender: 'Alex Ndongo', receiver: receiver, sourceAmount: amount, sourceCurrency: source, targetAmount: targetAmount, targetCurrency: target, rate: rate, fee: fee, tax: tax, commission: commission, status: 'Réussie'));
    setState(() {});
    _message('Transfert confirmé : ${formatAmount(targetAmount, target)} ${target.code} crédités.');
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff125c55), brightness: Brightness.light), scaffoldBackgroundColor: const Color(0xfff5f7f6), useMaterial3: true, fontFamily: 'Arial'), home: Scaffold(body: SafeArea(child: IndexedStack(index: tab, children: [_dashboard(), _transferPage(), _history(), _ratesPage(), _reports()])), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Accueil'), NavigationDestination(icon: Icon(Icons.swap_horiz_rounded), label: 'Transférer'), NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Historique'), NavigationDestination(icon: Icon(Icons.currency_exchange_rounded), label: 'Taux'), NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Rapports')])));

  Widget _header(String eyebrow, String title) => Padding(padding: const EdgeInsets.fromLTRB(22, 20, 22, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(eyebrow.toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 11)), const SizedBox(height: 5), Text(title, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800, color: Color(0xff162725)))]));
  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(18)}) => Card(elevation: 0, margin: const EdgeInsets.only(bottom: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), child: Padding(padding: padding, child: child));

  Widget _dashboard() => ListView(padding: EdgeInsets.zero, children: [_header('Walletcam · Prototype éducatif', 'Bonjour, Alex.'), Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Valeur du portefeuille', style: TextStyle(color: Colors.white70)), Icon(Icons.account_balance_wallet_rounded, color: Colors.white.withOpacity(.9))]), const SizedBox(height: 12), const Text('20 847 500 FCFA', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w800, color: Colors.white)), const SizedBox(height: 8), const Text('Simulation · taux manuellement configurés', style: TextStyle(color: Colors.white70, fontSize: 12))]), padding: const EdgeInsets.all(22)),), Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Row(children: Currency.values.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: _balanceCard(c)))).toList())), Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Actions rapides', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 14), Row(children: [_quickAction(Icons.swap_horiz, 'Transférer', () => setState(() => tab = 1)), _quickAction(Icons.add_chart, 'Ajouter un taux', () => setState(() => tab = 3)), _quickAction(Icons.assessment_outlined, 'Rapports', () => setState(() => tab = 4))])]))), Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Dernières opérations', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), TextButton(onPressed: () => setState(() => tab = 2), child: const Text('Voir tout'))]), if (transactions.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Text('Aucune transaction. Lancez votre premier transfert.', style: TextStyle(color: Colors.black54))) else ...transactions.take(3).map(_transactionTile)])))];

  Widget _balanceCard(Currency c) => _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.code, style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)), const SizedBox(height: 8), Text(formatAmount(amountOf(wallets[c]!), c), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), Text(c.symbol, style: const TextStyle(color: Colors.black45, fontSize: 11))]), padding: const EdgeInsets.all(13));
  Widget _quickAction(IconData icon, String label, VoidCallback onTap) => Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Column(children: [CircleAvatar(backgroundColor: const Color(0xffe5f3ef), foregroundColor: const Color(0xff125c55), child: Icon(icon)), const SizedBox(height: 7), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))])));

  Widget _transferPage() { Currency source = Currency.xaf, target = Currency.usd; bool merchant = false; final amount = TextEditingController(); final receiver = TextEditingController(text: 'Marie Dupont'); return StatefulBuilder(builder: (context, local) => ListView(padding: EdgeInsets.zero, children: [_header('Opération sécurisée', 'Nouveau transfert'), Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Montant à envoyer', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), TextField(controller: amount, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: '10 000', suffixText: source.code, filled: true, fillColor: const Color(0xfff3f5f4), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)), onChanged: (_) => local(() {})), const SizedBox(height: 18), Row(children: [Expanded(child: _dropdown('Depuis', source, (v) => local(() => source = v!))), const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_rounded)), Expanded(child: _dropdown('Vers', target, (v) => local(() => target = v!)))]), const SizedBox(height: 18), TextField(controller: receiver, decoration: const InputDecoration(labelText: 'Destinataire ou marchand', prefixIcon: Icon(Icons.person_outline))), SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Paiement marchand'), subtitle: const Text('Appliquer une commission de 1%'), value: merchant, onChanged: (v) => local(() => merchant = v)), const SizedBox(height: 8), _estimate(amount.text, source, target, merchant), const SizedBox(height: 10), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () { final value = int.tryParse(amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0; transfer(source: source, target: target, amount: value, receiver: receiver.text, merchant: merchant); }, icon: const Icon(Icons.lock_outline), label: const Padding(padding: EdgeInsets.all(5), child: Text('Valider le transfert'))))])))])); }
  Widget _dropdown(String label, Currency value, ValueChanged<Currency?> onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)), DropdownButton<Currency>(value: value, isExpanded: true, underline: const SizedBox(), items: Currency.values.map((c) => DropdownMenuItem(value: c, child: Text(c.code))).toList(), onChanged: onChanged)]);
  Widget _estimate(String text, Currency s, Currency t, bool merchant) { final amount = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0; final double fee = amount * .025 + (s == Currency.xaf ? 100 : 1); final double tax = fee * .1925; final rate = s == t ? 1 : rates.firstWhere((r) => r.from == s && r.to == t, orElse: () => Rate(from: s, to: t, rate: 1, effectiveAt: DateTime.now())).rate; return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xffedf6f3), borderRadius: BorderRadius.circular(14)), child: Column(children: [ _line('Conversion estimée', '${formatAmount(amount * rate, t)} ${t.code}'), _line('Frais + taxe', '${formatAmount(fee + tax, s)} ${s.code}'), if (merchant) _line('Commission marchand', '${formatAmount(amount * rate * .01, t)} ${t.code}') ])); }
  Widget _line(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: const TextStyle(color: Colors.black54)), Text(b, style: const TextStyle(fontWeight: FontWeight.w800))]));

  Widget _history() => ListView(padding: EdgeInsets.zero, children: [_header('Journal auditable', 'Historique'), Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _card(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_stat('Total', '${transactions.length}'), _stat('Frais', '${transactions.fold<int>(0, (p, e) => p + e.fee)} FCFA'), _stat('Statut', 'Actif')]))), if (transactions.isEmpty) const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Les reçus de vos transferts apparaîtront ici.'))) else Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Column(children: transactions.map(_transactionTile).toList()))]);
  Widget _stat(String a, String b) => Column(children: [Text(a, style: const TextStyle(color: Colors.black45, fontSize: 11)), const SizedBox(height: 5), Text(b, style: const TextStyle(fontWeight: FontWeight.w800))]);
  Widget _transactionTile(TransactionRecord tx) => _card(child: Column(children: [Row(children: [CircleAvatar(backgroundColor: const Color(0xffe5f3ef), child: const Icon(Icons.arrow_upward_rounded, color: Color(0xff125c55))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tx.receiver, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${DateFormat('dd/MM/yyyy HH:mm').format(tx.date)} · ${tx.id}', style: const TextStyle(color: Colors.black45, fontSize: 11))])), Text('-${formatAmount(tx.sourceAmount.toDouble(), tx.sourceCurrency)} ${tx.sourceCurrency.code}', style: const TextStyle(fontWeight: FontWeight.w800))]), const Divider(height: 22), _line('Reçu', '${formatAmount(tx.targetAmount, tx.targetCurrency)} ${tx.targetCurrency.code}'), _line('Frais / taxe', '${tx.fee} / ${tx.tax} ${tx.sourceCurrency.code}'), _line('Taux utilisé', tx.rate.toStringAsFixed(tx.rate < 1 ? 6 : 2))]));

  Widget _ratesPage() => ListView(padding: EdgeInsets.zero, children: [_header('Paramètres administrateur', 'Taux de change'), Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Taux simulés', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 5), const Text('Chaque transfert conserve le taux appliqué.', style: TextStyle(color: Colors.black54)), const SizedBox(height: 12), ...rates.map((r) => ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: const Color(0xffe5f3ef), child: Text(r.to.code[0])), title: Text('1 ${r.from.code} = ${r.rate.toStringAsFixed(r.rate < 1 ? 6 : 2)} ${r.to.code}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('Effectif le ${DateFormat('dd/MM/yyyy').format(r.effectiveAt)}'), trailing: const Icon(Icons.edit_outlined))) ])),), Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: FilledButton.icon(onPressed: () => _message('Écran de gestion prêt pour une connexion administrateur.'), icon: const Icon(Icons.add), label: const Text('Ajouter un taux')))]);

  Widget _reports() { final fee = transactions.fold<int>(0, (p, e) => p + e.fee); final tax = transactions.fold<int>(0, (p, e) => p + e.tax); return ListView(padding: EdgeInsets.zero, children: [_header('Vue administrateur', 'Rapports'), Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Synthèse du mois', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 20), _reportRow('Transactions', '${transactions.length}', Icons.swap_horiz), _reportRow('Frais collectés', '$fee FCFA', Icons.payments_outlined), _reportRow('Taxes', '$tax FCFA', Icons.account_balance_outlined), _reportRow('Commissions marchand', '${transactions.fold<int>(0, (p, e) => p + e.commission)}', Icons.storefront_outlined)]))), Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Soldes par devise', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 12), ...Currency.values.map((c) => _line(c.code, '${formatAmount(amountOf(wallets[c]!), c)} ${c.symbol}'))])))]; }
  Widget _reportRow(String label, String value, IconData icon) => Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [Icon(icon, color: const Color(0xff125c55)), const SizedBox(width: 12), Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]));
}
