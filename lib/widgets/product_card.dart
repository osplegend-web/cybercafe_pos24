import 'dart:io';
import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final String currencySymbol;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.currencySymbol = '₹',
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stockQty <= 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: outOfStock ? null : onTap,
        child: Opacity(
          opacity: outOfStock ? 0.5 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.3,
                child: _buildImage(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.money(product.sellingPrice, symbol: currencySymbol),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      outOfStock ? 'Out of stock' : 'Stock: ${_qty(product.stockQty)} ${product.unit}',
                      style: TextStyle(
                        fontSize: 11,
                        color: outOfStock
                            ? Colors.red
                            : (product.isLowStock ? Colors.orange.shade800 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _qty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(1);

  Widget _buildImage() {
    if (product.imagePath != null && File(product.imagePath!).existsSync()) {
      return Image.file(File(product.imagePath!), fit: BoxFit.cover, width: double.infinity);
    }
    return Container(
      color: Colors.grey.shade200,
      child: const Center(child: Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey)),
    );
  }
}
