import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Result extends StatefulWidget {
  final String place;

  const Result({super.key, required this.place});

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  late Future<Map<String, dynamic>> _weatherData;

  @override
  void initState() {
    super.initState();
    _weatherData = getDataFromAPI();
  }

  Future<Map<String, dynamic>> getDataFromAPI() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://api.openweathermap.org/data/2.5/weather?q=${widget.place}&appid=d76ea7244c0c2e07f2abe5f516049ac1&units=metric",
        ),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception("${errorData['message']} (${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Koneksi gagal: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hasil Perkiraan Cuaca",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: FutureBuilder(
          future: _weatherData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Terjadi kesalahan:",
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _weatherData = getDataFromAPI();
                      }),
                      child: const Text("Coba Lagi"),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasData) {
              final data = snapshot.data!;

              // Jika kota tidak ditemukan
              if (data['cod'] == '404') {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 50,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Lokasi '${widget.place}' tidak ditemukan",
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Coba cek penulisan atau gunakan nama kota lain",
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Kembali"),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      data['name'] ?? "Nama tidak tersedia",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gunakan icon cuaca dari OpenWeather
                    Image.network(
                      "https://openweathermap.org/img/wn/${data["weather"][0]["icon"]}@4x.png",
                      width: 150,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.wb_sunny,
                          size: 100,
                          color: Colors.amber,
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    Text(
                      "${data["main"]["temp"]?.toStringAsFixed(1) ?? 'N/A'}°C",
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Terasa seperti: ${data["main"]["feels_like"]?.toStringAsFixed(1) ?? 'N/A'}°C",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),

                    const SizedBox(height: 30),
                    _buildWeatherInfoCard(
                      "Kondisi",
                      data["weather"][0]["description"],
                    ),
                    _buildWeatherInfoCard(
                      "Kelembaban",
                      "${data["main"]["humidity"]}%",
                    ),
                    _buildWeatherInfoCard(
                      "Kecepatan Angin",
                      "${data["wind"]["speed"]?.toStringAsFixed(1) ?? 'N/A'} m/s",
                    ),
                    _buildWeatherInfoCard(
                      "Tekanan",
                      "${data["main"]["pressure"]} hPa",
                    ),

                    const SizedBox(height: 30),
                    // Tampilkan bendera dengan fallback
                    if (data['sys']?['country'] != null)
                      Image.network(
                        'https://flagcdn.com/w160/${data['sys']['country'].toString().toLowerCase()}.png',
                        width: 80,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.flag,
                            size: 60,
                            color: Colors.blue,
                          );
                        },
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            }

            return const Center(child: Text("Tidak ada data tersedia"));
          },
        ),
      ),
    );
  }

  Widget _buildWeatherInfoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(value, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
