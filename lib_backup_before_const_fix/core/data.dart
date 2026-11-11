import 'package:flutter/material.dart';
import 'icons.dart';

class Station {
  final String name, brand, distance, eta, rating, image;
  final double km;
  const Station({
    required this.name,
    required this.brand,
    required this.distance,
    required this.eta,
    required this.rating,
    required this.image,
    required this.km,
  });
}

const kStations = [
  Station(name: 'Stabex Kira Road', brand: 'STABEX', distance: '1.8 km', eta: '15–20 min', rating: '4.9', image: 'assets/images/station-hero.jpg', km: 1.8),
  Station(name: 'Shell Lugogo', brand: 'SHELL', distance: '3.2 km', eta: '20–28 min', rating: '4.8', image: 'assets/images/station-card.jpg', km: 3.2),
  Station(name: 'Rubis Bukoto', brand: 'RUBIS', distance: '4.1 km', eta: '22–30 min', rating: '4.8', image: 'assets/images/pump.jpg', km: 4.1),
];

class Partner {
  final String name, tone;
  const Partner(this.name, this.tone);
}

const kPartners = [
  Partner('Stabex', 'stabex'),
  Partner('Rubis', 'rubis'),
  Partner('Shell', 'shell'),
  Partner('City Oil', 'city'),
  Partner('TotalEnergies', 'total'),
];

Color? toneColor(String tone) {
  switch (tone) {
    case 'stabex':
      return const Color(0xFFEE2C2C);
    case 'rubis':
      return const Color(0xFF125FBB);
    case 'shell':
      return const Color(0xFFE7B916);
    case 'city':
      return const Color(0xFF16874C);
  }
  return null; // 'total' uses a gradient
}

const kTotalGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFE32135), Color(0xFF275AB6)],
);

class Slide {
  final String eyebrow, title, body, image;
  const Slide(this.eyebrow, this.title, this.body, this.image);
}

const kSlides = [
  Slide('ON-DEMAND DELIVERY', 'Fuel that meets you where you are.', 'Skip the station. Choose your fuel, pin your location, and we’ll handle the rest.', 'assets/images/station-hero.jpg'),
  Slide('LIVE PRICE COMPARISON', 'Better prices. Smarter refuels.', 'Compare verified stations nearby and always know exactly what you’ll pay.', 'assets/images/station-card.jpg'),
  Slide('SAFE & TRACKED', 'Every delivery, visible in real time.', 'From secure payment to arrival, follow your certified delivery partner every step.', 'assets/images/pump.jpg'),
];

class Vehicle {
  final String id, name, plate, fuel, color, tank, visual;
  const Vehicle({
    required this.id,
    required this.name,
    required this.plate,
    required this.fuel,
    this.color = '',
    this.tank = '',
    required this.visual,
  });
  String get selectCaption => [plate, fuel, if (color.isNotEmpty) color].join(' · ');
  String get listCaption => [plate, fuel, if (tank.isNotEmpty) '$tank tank'].join(' · ');
}

class Place {
  final String label, address;
  const Place(this.label, this.address);
}

class PayMethod {
  final String id, title, caption, badge;
  final IconName? icon;
  final Color? badgeBg, badgeFg;
  const PayMethod({
    required this.id,
    required this.title,
    required this.caption,
    this.badge = '',
    this.icon,
    this.badgeBg,
    this.badgeFg,
  });
}

class WalletTx {
  final String title, subtitle;
  final int amount;
  const WalletTx(this.title, this.subtitle, this.amount);
}

class Notice {
  final IconName icon;
  final String title, body, time;
  bool fresh;
  Notice(this.icon, this.title, this.body, this.time, this.fresh);
}

class HistoryOrder {
  final String date, station, product, price;
  const HistoryOrder(this.date, this.station, this.product, this.price);
}

const kHistory = [
  HistoryOrder('18 Jun 2025', 'Shell Lugogo', 'Diesel · 28L', 'UGX 153,500'),
  HistoryOrder('29 May 2025', 'Stabex Kira Road', 'Premium · 35L', 'UGX 191,800'),
  HistoryOrder('04 May 2025', 'TotalEnergies Ntinda', 'Petrol · 22L', 'UGX 124,400'),
];
