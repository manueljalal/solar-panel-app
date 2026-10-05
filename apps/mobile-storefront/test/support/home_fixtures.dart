// Sample content for widget tests only. Production code never uses this —
// the app reads live data from Firestore (see HomeRepository).
import 'package:solary_marketplace/features/home/domain/home_company.dart';
import 'package:solary_marketplace/features/home/domain/home_product.dart';

const homeCompanies = [
  HomeCompany(
    name: 'SunBridge Energy',
    city: 'Erbil',
    rating: 4.9,
    logoUrl: 'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=400&q=80',
  ),
  HomeCompany(
    name: 'Helios Power Co.',
    city: 'Sulaymaniyah',
    rating: 4.8,
    logoUrl: 'https://images.unsplash.com/photo-1497440001374-f26997328c1b?w=400&q=80',
  ),
  HomeCompany(
    name: 'GreenTech Iraq',
    city: 'Basra',
    rating: 4.7,
    logoUrl: 'https://images.unsplash.com/photo-1466611653911-95081537e5b7?w=400&q=80',
  ),
];

const homeProducts = [
  HomeProduct(
    imageUrl: 'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=400&q=80',
    spec: '450W',
    brand: 'JinkoSolar',
    title: 'Tiger Neo Mono Panel',
    vendor: 'SunBridge Energy',
    price: '\$189',
    rating: 4.9,
    sold: 312,
    warranty: '25-year power output',
    description:
        'High-efficiency N-type monocrystalline panel with a low temperature '
        'coefficient, built for rooftop residential arrays. Ships with '
        'mounting hardware compatible with most rail systems.',
  ),
  HomeProduct(
    imageUrl: 'https://images.unsplash.com/photo-1624397640148-949b1732bb0a?w=400&q=80',
    spec: '5kWh',
    brand: 'Huawei',
    title: 'LUNA2000 Battery Unit',
    vendor: 'Helios Power Co.',
    price: '\$1,240',
    rating: 4.8,
    sold: 87,
    warranty: '10-year manufacturer',
    description:
        'Modular lithium home battery designed to pair with a residential '
        'inverter for backup power and time-of-use savings. Wall-mounted, '
        'stackable up to 3 units for extra capacity.',
  ),
  HomeProduct(
    imageUrl: 'https://images.unsplash.com/photo-1592833159155-c62df1b65634?w=400&q=80',
    spec: '6kW',
    brand: 'Growatt',
    title: 'Hybrid Grid Inverter',
    vendor: 'GreenTech Iraq',
    price: '\$860',
    rating: 4.7,
    sold: 54,
    warranty: '5-year manufacturer',
    description:
        'Hybrid inverter supporting both grid-tied and battery-backed '
        'operation, with built-in Wi-Fi monitoring and support for two MPPT '
        'trackers.',
  ),
  HomeProduct(
    imageUrl: 'https://images.unsplash.com/photo-1613665813446-82a78c468a1d?w=400&q=80',
    spec: '400W',
    brand: 'Canadian Solar',
    title: 'HiKu6 Mono Panel',
    vendor: 'SunBridge Energy',
    price: '\$164',
    rating: 4.6,
    sold: 203,
    warranty: '25-year power output',
    description:
        'Balanced-cost mono panel for larger residential and light-commercial '
        'arrays, with a reinforced frame rated for higher wind and snow loads.',
  ),
];
