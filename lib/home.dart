import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'main.dart';
import 'data.dart';

List<Map<String, String>> dataSiswa = [];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryColor = Colors.indigo;
  String filterGender = "Semua";
  
  String searchQuery = "";
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('siswa_prefs');
    if (savedData != null) {
      setState(() {
        List<dynamic> decoded = jsonDecode(savedData);
        dataSiswa = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('siswa_prefs', jsonEncode(dataSiswa));
  }

  List<Map<String, String>> get filteredList {
    return dataSiswa.where((s) {
      bool matchGender = filterGender == "Semua" || s['jk'] == filterGender;
      bool matchSearch = s['nama']!.toLowerCase().contains(searchQuery.toLowerCase());
      return matchGender && matchSearch;
    }).toList();
  }

  void _shareStudent(Map<String, String> s) {
    final String text = 
      " DATA SISWA E-SEKOLAH SMA \n"
      "--------------------------\n"
      "Nama    : ${s['nama']}\n"
      "NIS     : ${s['ni']}\n"
      "NISN    : ${s['nisn']}\n"
      "JK      : ${s['jk']}\n"
      "Agama   : ${s['agama']}\n"
      "Kelas   : ${s['kelas']}\n"
      "Tgl Lahir: ${s['tgl_lahir']}\n"
      "Telp    : ${s['telp']}\n"
      "Email   : ${s['email']}\n"
      "Alamat  : ${s['alamat']}\n"
      "--------------------------";
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: isSearching 
          ? TextField(
              controller: searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Cari nama siswa...",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            )
          : const Text("E-Sekolah SMA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  isSearching = false;
                  searchQuery = "";
                  searchController.clear();
                } else {
                  isSearching = true;
                }
              });
            },
          ),
          IconButton(
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false),
            icon: const Icon(Icons.logout, color: Colors.white),
          )
        ],
      ),
      body: Column(
        children: [
          _buildHeaderStats(),
          _buildFilterBar(),
          Expanded(child: filteredList.isEmpty ? _buildEmptyState() : _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const InputDataPage()));
          _saveData();
          setState(() {});
        },
        backgroundColor: primaryColor,
        label: const Text("Tambah Siswa", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: primaryColor, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Total", dataSiswa.length.toString()),
          _statItem("Laki-laki", dataSiswa.where((s) => s['jk'] == "Laki-laki").length.toString()),
          _statItem("Perempuan", dataSiswa.where((s) => s['jk'] == "Perempuan").length.toString()),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
    ]);
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ["Semua", "Laki-laki", "Perempuan"].map((g) {
          bool isSelected = filterGender == g;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(g),
              selected: isSelected,
              onSelected: (val) => setState(() => filterGender = g),
              selectedColor: primaryColor,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final s = filteredList[index];
        int originalIndex = dataSiswa.indexOf(s);
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            onTap: () => _showDetail(context, originalIndex),
            leading: CircleAvatar(
              backgroundImage: s['foto'] != '' ? FileImage(File(s['foto']!)) : null,
              child: s['foto'] == '' ? const Icon(Icons.person) : null,
            ),
            title: Text(s['nama']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${s['kelas']} • NIS: ${s['ni']}"),
            trailing: Wrap(
              children: [
                IconButton(icon: const Icon(Icons.share, color: Colors.blue), onPressed: () => _shareStudent(s)),
                IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => InputDataPage(isEdit: true, index: originalIndex)));
                  _saveData();
                  setState(() {});
                }),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(originalIndex)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Data?"),
        content: Text("Yakin ingin menghapus ${dataSiswa[index]['nama']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("BATAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => dataSiswa.removeAt(index));
              _saveData();
              Navigator.pop(context);
            },
            child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, int index) {
    final s = dataSiswa[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              CircleAvatar(radius: 50, backgroundImage: s['foto'] != '' ? FileImage(File(s['foto']!)) : null, child: s['foto'] == '' ? const Icon(Icons.person, size: 40) : null),
              const SizedBox(height: 15),
              Text(s['nama']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Divider(),
              _infoRow(Icons.wc, "Jenis Kelamin", s['jk'] ?? "-"),
              _infoRow(Icons.badge, "NIS / NISN", "${s['ni']} / ${s['nisn']}"),
              _infoRow(Icons.church, "Agama", s['agama'] ?? "-"),
              _infoRow(Icons.school, "Kelas", s['kelas'] ?? "-"),
              _infoRow(Icons.calendar_month, "Tanggal Lahir", s['tgl_lahir'] ?? "-"),
              _infoRow(Icons.phone, "Telepon", s['telp'] ?? "-"),
              _infoRow(Icons.email, "Email", s['email'] ?? "-"),
              _infoRow(Icons.location_on, "Alamat", s['alamat'] ?? "-"),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _shareStudent(s), 
                  icon: const Icon(Icons.share), 
                  label: const Text("SHARE DATA"),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text("Data tidak ditemukan", style: TextStyle(color: Colors.grey)));
}