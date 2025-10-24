class Wallet {
  final String id;
  final String name;
  final double balance;
  final String? icon;
  final String? color;

  Wallet({
    required this.id,
    required this.name,
    required this.balance,
    this.icon,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'icon': icon,
      'color': color,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      icon: map['icon'],
      color: map['color'],
    );
  }

  Wallet copyWith({
    String? id,
    String? name,
    double? balance,
    String? icon,
    String? color,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
