import 'package:flutter/material.dart';
import '../models/commission_model.dart';
import '../services/commission_service.dart';

class CommissionController extends ChangeNotifier {
  final CommissionService _commissionService;

  CommissionController(this._commissionService);

  List<CommissionModel> _commissions = [];
  List<CommissionModel> get commissions => _commissions;

  Future<void> fetchCommissions(String userId) async {
    try {
      _commissions = await _commissionService.getCommissionsByUser(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching commissions: $e');
    }
  }

  Future<void> createCommission(CommissionModel commission) async {
    try {
      await _commissionService.createCommission(commission);
      _commissions.add(commission);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating commission: $e');
    }
  }

  Future<void> updateCommission(
      String commissionId, Map<String, dynamic> updates) async {
    try {
      await _commissionService.updateCommission(commissionId, updates);
      final index = _commissions.indexWhere((c) => c.id == commissionId);
      if (index != -1) {
        _commissions[index] = _commissions[index].copyWith(updates);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating commission: $e');
    }
  }

  Future<void> deleteCommission(String commissionId) async {
    try {
      await _commissionService.deleteCommission(commissionId);
      _commissions.removeWhere((c) => c.id == commissionId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting commission: $e');
    }
  }
}
