import 'package:flutter/material.dart';
import '../models/item_model.dart';

class ItemDescriptionPage extends StatelessWidget {
  final Item item;
  const ItemDescriptionPage({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A3C6B),
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrls.isNotEmpty)
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: item.imageUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, idx) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      item.imageUrls[idx],
                      width: 260,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              item.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A3C6B)),
            ),
            const SizedBox(height: 12),
            if (item.description != null && item.description!.isNotEmpty)
              Text(
                item.description!,
                style: const TextStyle(fontSize: 16, color: Color(0xFF232B38)),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (item.pricePerDay != null)
                  Text('₹${item.pricePerDay!.toStringAsFixed(0)} /day', style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.w600)),
                if (item.pricePerHour != null)
                  Text('  ₹${item.pricePerHour!.toStringAsFixed(0)} /hour', style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 20),
            if (item.category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.category!,
                  style: const TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.w500),
                ),
              ),
            // Add more item details here as needed
          ],
        ),
      ),
    );
  }
}
