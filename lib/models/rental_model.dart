import 'package:locality/models/item_model.dart';

class RentalRequest {
  final String id;
  final String itemId;
  final String lenderId;
  final String borrowerId;
  final RentalStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;

  RentalRequest({
    required this.id,
    required this.itemId,
    required this.lenderId,
    required this.borrowerId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'lenderId': lenderId,
      'borrowerId': borrowerId,
      'status': status.toString().split('.').last,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'totalPrice': totalPrice,
    };
  }

  factory RentalRequest.fromMap(Map<String, dynamic> map, String documentId) {
    return RentalRequest(
      id: documentId,
      itemId: map['itemId'] ?? '',
      lenderId: map['lenderId'] ?? '',
      borrowerId: map['borrowerId'] ?? '',
      status: RentalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => RentalStatus.pending,
      ),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate'] ?? 0),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
    );
  }
}
