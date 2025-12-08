import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/screens/credits_screen.dart';
import 'package:rate_my_bowl/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  bool _femaleOn = false;
  bool _maleOn = false;
  bool _unisexOn = false;
  double _minRating = 3.0;
  bool _minRatingEnabled = false;

  void _toggleFemale() {
    setState(() => _femaleOn = !_femaleOn);
    _savePrefs();
  }

  void _toggleMale() {
    setState(() => _maleOn = !_maleOn);
    _savePrefs();
  }

  void _toggleUnisex() {
    setState(() => _unisexOn = !_unisexOn);
    _savePrefs();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('filter_female', _femaleOn);
    await prefs.setBool('filter_male', _maleOn);
    await prefs.setBool('filter_unisex', _unisexOn);
    await prefs.setDouble('filter_min_rating', _minRating);
    await prefs.setBool('filter_min_rating_enabled', _minRatingEnabled);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _femaleOn = prefs.getBool('filter_female') ?? false;
      _maleOn = prefs.getBool('filter_male') ?? false;
      _unisexOn = prefs.getBool('filter_unisex') ?? false;
      _minRating = prefs.getDouble('filter_min_rating') ?? 3.0;
      _minRatingEnabled = prefs.getBool('filter_min_rating_enabled') ?? false;
    });
  }

  void _handleLogout() {
    // Try to pop back to login; if you have an AuthService, call signOut there instead.
    context.read<AuthService>().logout();
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Options',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.lightBlueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filters',
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Female toggle
                ElevatedButton.icon(
                  onPressed: _toggleFemale,
                  icon: Icon(
                    Icons.female,
                    color: _femaleOn ? Colors.white : Colors.black54,
                  ),
                  label: Text(
                    'Female',
                    style: GoogleFonts.quicksand(
                      color: _femaleOn ? Colors.white : Colors.black54,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _femaleOn
                        ? Colors.pinkAccent
                        : Colors.white,
                    elevation: _femaleOn ? 4 : 0,
                  ),
                ),
                // Unisex toggle
                ElevatedButton.icon(
                  onPressed: _toggleUnisex,
                  icon: Icon(
                    Icons.transgender,
                    color: _unisexOn ? Colors.white : Colors.black54,
                  ),
                  label: Text(
                    'Unisex',
                    style: GoogleFonts.quicksand(
                      color: _unisexOn ? Colors.white : Colors.black54,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _unisexOn ? Colors.green : Colors.white,
                    elevation: _unisexOn ? 4 : 0,
                  ),
                ),
                // Male toggle
                ElevatedButton.icon(
                  onPressed: _toggleMale,
                  icon: Icon(
                    Icons.male,
                    color: _maleOn ? Colors.white : Colors.black54,
                  ),
                  label: Text(
                    'Male',
                    style: GoogleFonts.quicksand(
                      color: _maleOn ? Colors.white : Colors.black54,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _maleOn ? Colors.blueAccent : Colors.white,
                    elevation: _maleOn ? 4 : 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _minRatingEnabled
                      ? 'Minimum Rating: ${_minRating.toStringAsFixed(1)}'
                      : 'Minimum Rating (off)',
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _minRatingEnabled ? Colors.white : Colors.white54,
                  ),
                ),
                Switch(
                  value: _minRatingEnabled,
                  onChanged: (value) {
                    setState(() => _minRatingEnabled = value);
                    _savePrefs();
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.blueAccent,
                  inactiveTrackColor: Colors.grey.shade400,
                ),
              ],
            ),
            Slider(
              value: _minRating,
              min: 1.0,
              max: 5.0,
              divisions: 4,
              label: _minRating.toStringAsFixed(1),
              onChanged: _minRatingEnabled
                  ? (v) {
                      setState(() => _minRating = v);
                      _savePrefs();
                    }
                  : null,
            ),
            if (_minRatingEnabled)
              Text(
                "Note: This will hide restrooms without reviews.",
                style: GoogleFonts.quicksand(fontSize: 12, color: Colors.white),
              ),
            const SizedBox(height: 8),
            const Spacer(),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreditsScreen()),
                  );
                },
                child: Text(
                  "Credits",
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(
                'Log out',
                style: GoogleFonts.quicksand(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                padding: const EdgeInsets.symmetric(vertical: 14.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
