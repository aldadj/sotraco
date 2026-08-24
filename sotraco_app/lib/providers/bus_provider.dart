import 'package:flutter/foundation.dart';
import '../models/bus.dart';
import '../models/ligne.dart';
import '../services/api_service.dart';

class BusProvider extends ChangeNotifier {
  List<Ligne> lignes = [];
  List<Bus> buses = [];
  bool chargement = false;
  String? erreur;

  Future<void> chargerLignes() async {
    try {
      final data = await ApiService.get('/lignes');
      lignes = (data as List).map((e) => Ligne.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      erreur = e.toString();
      notifyListeners();
    }
  }

  Future<void> chargerBuses({int? ligneId, bool? enMarcheSeulement}) async {
    chargement = true;
    notifyListeners();
    try {
      final params = <String>[];
      if (ligneId != null) params.add('ligne_id=$ligneId');
      if (enMarcheSeulement == true) params.add('en_marche=1');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';

      final data = await ApiService.get('/buses$query');
      buses = (data as List).map((e) => Bus.fromJson(e)).toList();
      erreur = null;
    } catch (e) {
      erreur = e.toString();
    } finally {
      chargement = false;
      notifyListeners();
    }
  }

  void mettreAJourPosition(int busId, Map<String, dynamic> data) {
    final index = buses.indexWhere((b) => b.id == busId);
    if (index != -1) {
      buses[index].appliquerPosition(data);
      notifyListeners();
    }
  }
}
