String formatAmount(num amount) {
  return amount % 1 == 0
      ? amount.toInt().toString()
      : amount.toStringAsFixed(2);
}
