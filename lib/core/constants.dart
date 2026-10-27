import 'package:flutter/material.dart';
import '../../models/models.dart';

const kAppName = 'SkillBridge';
const kTagline = 'Show it. Prove it. Grow it.';
const kAppVersion = '1.0.0';

/// Quiz score needed (as a fraction) to earn a quiz badge.
const kBadgeThreshold = 0.8;

const kTrades = <TradeCategory>[
  TradeCategory('plumbing', 'Plumbing', Icons.plumbing,
      ['Leak repair', 'Pipe fitting', 'Bathroom installation', 'Blocked drains']),
  TradeCategory('electrical', 'Electrical work', Icons.electrical_services,
      ['House wiring', 'Lighting installation', 'Fault finding', 'Socket repair']),
  TradeCategory('welding', 'Welding', Icons.hardware,
      ['Gates and burglar bars', 'Window frames', 'Steel structures', 'Metal repairs']),
  TradeCategory('carpentry', 'Carpentry', Icons.handyman,
      ['Wardrobes', 'Kitchen cabinets', 'Doors and frames', 'Roof trusses']),
  TradeCategory('tailoring', 'Tailoring', Icons.content_cut,
      ['School uniforms', 'Dress making', 'Alterations', 'Chitenge outfits']),
  TradeCategory('hair_beauty', 'Hair and beauty', Icons.spa,
      ['Braiding', 'Barbering', 'Makeup', 'Nail care']),
  TradeCategory('painting', 'Painting', Icons.format_paint,
      ['Interior painting', 'Exterior painting', 'Wall preparation', 'Ceiling finishing']),
  TradeCategory('masonry', 'Masonry and construction', Icons.foundation,
      ['Bricklaying', 'Plastering', 'Paving', 'Boundary walls']),
  TradeCategory('mechanics', 'Motor vehicle mechanics', Icons.car_repair,
      ['General servicing', 'Brake repair', 'Engine diagnostics', 'Suspension']),
  TradeCategory('appliance', 'Appliance repair', Icons.kitchen,
      ['Fridge repair', 'Washing machine repair', 'Cooker repair', 'Air conditioner servicing']),
  TradeCategory('cleaning', 'Cleaning', Icons.cleaning_services,
      ['Home cleaning', 'Office cleaning', 'Post-construction clean up', 'Carpet cleaning']),
  TradeCategory('gardening', 'Gardening and landscaping', Icons.yard,
      ['Lawn care', 'Garden design', 'Tree trimming', 'Irrigation set up']),
];

TradeCategory tradeById(String id) =>
    kTrades.firstWhere((t) => t.id == id, orElse: () => kTrades.first);

/// Zambian provinces and a selection of towns in each.
const kProvinceTowns = <String, List<String>>{
  'Central': ['Kabwe', 'Kapiri Mposhi', 'Mkushi'],
  'Copperbelt': ['Kitwe', 'Ndola', 'Chingola', 'Mufulira'],
  'Eastern': ['Chipata', 'Petauke'],
  'Luapula': ['Mansa', 'Kawambwa'],
  'Lusaka': ['Lusaka', 'Chilanga', 'Kafue'],
  'Muchinga': ['Chinsali', 'Mpika'],
  'Northern': ['Kasama', 'Mbala'],
  'North-Western': ['Solwezi', 'Mwinilunga'],
  'Southern': ['Livingstone', 'Choma', 'Mazabuka'],
  'Western': ['Mongu', 'Senanga'],
};

List<String> get kAllTowns {
  final l = kProvinceTowns.values.expand((e) => e).toList()..sort();
  return l;
}

String provinceOfTown(String town) {
  for (final e in kProvinceTowns.entries) {
    if (e.value.contains(town)) return e.key;
  }
  return 'Lusaka';
}

const kWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const kSkillLevels = ['Beginner', 'Intermediate', 'Advanced'];
const kContactMethods = ['In-app message', 'Phone call', 'WhatsApp'];
const kReviewTags = [
  'On time',
  'Professional',
  'Fair price',
  'Quality work',
  'Good communication',
  'Tidy worksite',
];

const kBadges = <SkillBadge>[
  SkillBadge('plumbing_basics', 'Plumbing Basics',
      'Score at least 80% on the Plumbing Basics quiz.', BadgeKind.quiz, Icons.plumbing),
  SkillBadge('electrical_safety', 'Electrical Safety',
      'Score at least 80% on the Electrical Safety quiz.', BadgeKind.quiz, Icons.electrical_services),
  SkillBadge('welding_safety', 'Welding Safety',
      'Score at least 80% on the Welding Safety quiz.', BadgeKind.quiz, Icons.hardware),
  SkillBadge('carpentry_foundations', 'Carpentry Foundations',
      'Score at least 80% on the Carpentry Measurements quiz.', BadgeKind.quiz, Icons.handyman),
  SkillBadge('construction_safety', 'Construction Safety',
      'Score at least 80% on the Construction Safety quiz.', BadgeKind.quiz, Icons.foundation),
  SkillBadge('consistent_reviews', 'Consistent Client Reviews',
      'Have at least 3 saved client reviews with an average of 4.5 stars or more.',
      BadgeKind.reviews, Icons.star_rounded),
  SkillBadge('experienced_worker', 'Experienced Worker',
      'Declare 5 or more years of experience on your profile.', BadgeKind.profile, Icons.work_history),
  SkillBadge('portfolio_complete', 'Portfolio Complete',
      'Add at least 3 portfolio projects to your profile.', BadgeKind.profile, Icons.photo_library),
];

SkillBadge badgeById(String id) =>
    kBadges.firstWhere((b) => b.id == id, orElse: () => kBadges.first);
