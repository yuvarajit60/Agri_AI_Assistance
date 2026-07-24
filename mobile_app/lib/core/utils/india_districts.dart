/// Real, curated district lists — deliberately started with just one
/// state rather than guessing at all ~750 districts across India in one
/// pass (same "narrow slice first, widen later" reasoning as the rest of
/// this project — see docs/architecture/ROADMAP.md). A state not present
/// here falls back to free-text district entry in the UI instead of a
/// fabricated/incomplete dropdown.
///
/// Tamil Nadu: 38 districts, current as of the most recent reorganizations
/// (Chengalpattu, Kallakurichi, Ranipet, Tenkasi, Tirupathur split off in
/// 2019-2020; Mayiladuthurai split from Nagapattinam in 2021).
const List<String> _tamilNaduDistricts = [
  'Ariyalur',
  'Chengalpattu',
  'Chennai',
  'Coimbatore',
  'Cuddalore',
  'Dharmapuri',
  'Dindigul',
  'Erode',
  'Kallakurichi',
  'Kanchipuram',
  'Kanyakumari',
  'Karur',
  'Krishnagiri',
  'Madurai',
  'Mayiladuthurai',
  'Nagapattinam',
  'Namakkal',
  'Nilgiris',
  'Perambalur',
  'Pudukkottai',
  'Ramanathapuram',
  'Ranipet',
  'Salem',
  'Sivaganga',
  'Tenkasi',
  'Thanjavur',
  'Theni',
  'Thoothukudi',
  'Tiruchirappalli',
  'Tirunelveli',
  'Tirupathur',
  'Tiruppur',
  'Tiruvallur',
  'Tiruvannamalai',
  'Tiruvarur',
  'Vellore',
  'Viluppuram',
  'Virudhunagar',
];

/// Keyed by the exact state names in kIndianStates (india_states.dart).
const Map<String, List<String>> kDistrictsByState = {
  'Tamil Nadu': _tamilNaduDistricts,
};
