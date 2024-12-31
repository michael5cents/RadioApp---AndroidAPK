import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/radio_station.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const RadioApp());
  debugPrint('App started in debug mode');
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Popz Place Radio Player',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.pink,
          surface: const Color(0xFF1a1a1a),
          background: const Color(0xFF2d2d2d),
        ),
        useMaterial3: true,
      ),
      home: const RadioHomePage(),
    );
  }
}

class RadioHomePage extends StatefulWidget {
  const RadioHomePage({super.key});

  @override
  State<RadioHomePage> createState() => _RadioHomePageState();
}

class _RadioHomePageState extends State<RadioHomePage> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  bool isLoading = false;
  bool isMetadataVisible = false;
  String nowPlaying = 'Ready to Play';
  String currentTitle = 'Title: ';
  String currentArtist = 'Artist: ';
  String serverTitle = '';
  String currentSong = '';
  final TextEditingController _searchController = TextEditingController();
  List<RadioStation> searchResults = [];
  List<RadioStation> favorites = [];
  final String _favoritesKey = 'favorites';
  int? _selectedSearchIndex;
  bool _isLargeScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkScreenSize();
    _initRadioPlayer().then((_) {
      _startMetadataPolling();
      _loadFavorites();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _checkScreenSize();
  }

  void _checkScreenSize() {
    if (!mounted) return;
    
    final window = WidgetsBinding.instance.window;
    final size = window.physicalSize / window.devicePixelRatio;
    setState(() {
      _isLargeScreen = size.width > 800; // Threshold for unfolded state
    });
  }

  Future<void> _initRadioPlayer() async {
    try {
      _audioPlayer = AudioPlayer()
        ..setReleaseMode(ReleaseMode.loop)
        ..setVolume(1.0);
      
      _audioPlayer.onPlayerStateChanged.listen((state) {
        debugPrint('Player state changed: $state');
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey);
    
    final defaultStation = RadioStation(
      name: 'Popz Place Radio',
      url: 'http://s8.myradiostream.com/15672/listen.mp3',
      genre: 'Pop',
      supportsMetadata: true
    );

    if (favoritesJson != null) {
      setState(() {
        favorites = favoritesJson
            .map((json) => RadioStation.fromJson(jsonDecode(json)))
            .toList();
        
        if (!favorites.any((station) => station.url == defaultStation.url)) {
          favorites.insert(0, defaultStation);
          _saveFavorites();
        }
      });
    } else {
      setState(() {
        favorites = [defaultStation];
      });
      _saveFavorites();
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = favorites.map((station) => jsonEncode(station.toJson())).toList();
    await prefs.setStringList(_favoritesKey, favoritesJson);
  }

  Future<void> _searchStations(String genre) async {
    if (genre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a genre to search'),
          duration: Duration(seconds: 2),
        )
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
        'https://de1.api.radio-browser.info/json/stations/bytagexact/$genre'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          searchResults = data
              .take(20)
              .map((station) => RadioStation(
                    name: station['name'],
                    url: station['url_resolved'],
                    genre: station['tags'],
                  ))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search error: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        )
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchMetadata() async {
    try {
      if (nowPlaying == 'Popz Place Radio' && isPlaying) {
        final response = await http.get(
          Uri.parse('http://s8.myradiostream.com/15672/stats?json=1'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final songInfo = (data['songtitle'] as String? ?? '').split(' - ');
          setState(() {
            if (songInfo.length > 1) {
              currentTitle = 'Title: ${songInfo[0].trim()}';
              currentArtist = 'Artist: ${songInfo[1].trim()}';
            } else {
              currentTitle = 'Title: ${songInfo[0].trim()}';
              currentArtist = 'Artist: Unknown';
            }
            currentSong = '$currentTitle\n$currentArtist';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching metadata: $e');
    }
  }

  void _startMetadataPolling() {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (isPlaying) {
        if (nowPlaying == 'Popz Place Radio') {
          await _fetchMetadata();
        } else {
          setState(() {
            currentSong = 'Now Playing: $nowPlaying';
          });
        }
      }
    });
  }

  Future<void> _playStation(RadioStation station) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(station.url));
      setState(() {
        nowPlaying = station.name;
        isPlaying = true;
        currentSong = 'Now Playing: ${station.name}';
      });
    } catch (e) {
      setState(() {
        nowPlaying = 'Error: Unable to play station';
        isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playback error: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Popz Place Radio Player'),
      ),
      body: _isLargeScreen
          ? Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 10, 20),
                    child: _buildPlayerControls(),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 20, 20, 20),
                    child: _buildSearchAndFavorites(),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPlayerControls(),
                  const SizedBox(height: 20),
                  _buildSearchAndFavorites(),
                  const SizedBox(height: 20),
                  _buildExitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF363636),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Now Playing:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            nowPlaying,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            currentSong,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  if (isPlaying) {
                    await _audioPlayer.pause();
                    setState(() {
                      isPlaying = false;
                    });
                  } else {
                    await _audioPlayer.resume();
                    setState(() {
                      isPlaying = true;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  isPlaying ? 'Pause' : 'Play',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Slider(
            value: _audioPlayer.volume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: _audioPlayer.volume.toStringAsFixed(1),
            onChanged: (double value) {
              setState(() {
                _audioPlayer.setVolume(value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFavorites() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF363636),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🎵 Find Radio Stations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter genre (e.g., jazz, rock, classical)',
              filled: true,
              fillColor: const Color(0xFF4d4d4d),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
            ),
            onSubmitted: (value) async {
              await _searchStations(value);
            },
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () async {
              await _searchStations(_searchController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              '🔍 Search Radio Stations',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '🎵 Search Results:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: BoxConstraints(
              maxHeight: _isLargeScreen ? 400 : 250,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4d4d4d),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final station = searchResults[index];
                return ListTile(
                  title: Text(
                    station.toString(),
                    style: TextStyle(
                      color: _selectedSearchIndex == index 
                        ? Colors.green 
                        : Colors.white,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedSearchIndex = index;
                    });
                    _playStation(station);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_selectedSearchIndex != null) {
                final station = searchResults[_selectedSearchIndex!];
                if (!favorites.contains(station)) {
                  setState(() {
                    favorites.add(station);
                    _saveFavorites();
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              '❤ Save to Favorites',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '❤ My Favorite Stations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: BoxConstraints(
              maxHeight: _isLargeScreen ? 400 : 250,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4d4d4d),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final station = favorites[index];
                return ListTile(
                  title: Text(
                    station.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => _playStation(station),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExitButton() {
    return ElevatedButton(
      onPressed: () async {
        await _audioPlayer.pause();
        if (kIsWeb) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit'),
              content: const Text('Thank you for using Popz Place Radio!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF666666),
        padding: const EdgeInsets.symmetric(
          horizontal: 25,
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: const Text(
        'Exit Radio Player',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
