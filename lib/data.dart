import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

class InputDataPage extends StatefulWidget {
  final bool isEdit;
  final int? index;
  const InputDataPage({super.key, this.isEdit = false, this.index});

  @override
  State<InputDataPage> createState() => _InputDataPageState();
}

class _InputDataPageState extends State<InputDataPage> {
  final namaCtrl = TextEditingController();
  final niCtrl = TextEditingController();
  final nisnCtrl = TextEditingController();
  final telpCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final tglCtrl = TextEditingController();
  final alamatCtrl = TextEditingController();

  String selectedKelas = "X - IPA 1";
  String selectedJK = "Laki-laki";
  String selectedAgama = "Islam";

  final List<String> daftarKelas = ["X - IPA 1", "X - IPA 2", "X - IPS 1", "XI - IPA 1", "XI - IPA 2", "XI - IPS 1", "XII - IPA 1", "XII - IPA 2", "XII - IPS 1"];
  final List<String> daftarAgama = ["Islam", "Protestan", "Katolik", "Hindu", "Buddha", "Konghucu"];

  File? _imageFile;
  String? errorText;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.index != null) {
      final s = dataSiswa[widget.index!];
      namaCtrl.text = s['nama'] ?? '';
      niCtrl.text = s['ni'] ?? '';
      nisnCtrl.text = s['nisn'] ?? '';
      telpCtrl.text = s['telp'] ?? '';
      emailCtrl.text = s['email'] ?? '';
      tglCtrl.text = s['tgl_lahir'] ?? '';
      alamatCtrl.text = s['alamat'] ?? '';
      if (daftarKelas.contains(s['kelas'])) selectedKelas = s['kelas']!;
      if (s['jk'] != null) selectedJK = s['jk']!;
      if (daftarAgama.contains(s['agama'])) selectedAgama = s['agama']!;
      if (s['foto'] != null && s['foto'] != '') _imageFile = File(s['foto']!);
    }
  }

  void _validasiDanSimpan() {
    setState(() => errorText = null);
    if (namaCtrl.text.isEmpty || niCtrl.text.isEmpty || nisnCtrl.text.isEmpty || tglCtrl.text.isEmpty) {
      setState(() => errorText = "Anda wajib mengisi data *");
      return;
    }
    if (telpCtrl.text.isEmpty || emailCtrl.text.isEmpty || alamatCtrl.text.isEmpty || _imageFile == null) {
      _showConfirmDialog();
    } else {
      _prosesSimpan();
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Data Belum Lengkap"),
        content: const Text("Anda yakin ingin melanjutkan data yang tidak lengkap?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("BATAL")),
          TextButton(onPressed: () { Navigator.pop(context); _prosesSimpan(); }, child: const Text("YA, LANJUTKAN")),
        ],
      ),
    );
  }

  void _prosesSimpan() async {
    final data = {
      "nama": namaCtrl.text, "ni": niCtrl.text, "nisn": nisnCtrl.text, "jk": selectedJK,
      "agama": selectedAgama, "telp": telpCtrl.text, "email": emailCtrl.text,
      "kelas": selectedKelas, "tgl_lahir": tglCtrl.text, "alamat": alamatCtrl.text,
      "foto": _imageFile?.path ?? ''
    };
    if (widget.isEdit) dataSiswa[widget.index!] = data; else dataSiswa.add(data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('siswa_prefs', jsonEncode(dataSiswa));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? "Edit Data Siswa" : "Tambah Data Siswa"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (errorText != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(errorText!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
            GestureDetector(
              onTap: _showPicker, 
              child: CircleAvatar(
                radius: 60, 
                backgroundColor: Colors.indigo.shade50,
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null, 
                child: _imageFile == null ? const Icon(Icons.camera_alt, size: 40, color: Colors.indigo) : null
              )
            ),
            const SizedBox(height: 20),
            _boxInput(namaCtrl, "Nama Lengkap*", Icons.person),
            const SizedBox(height: 15),
            DropdownButtonFormField(value: selectedJK, decoration: const InputDecoration(labelText: "Jenis Kelamin*", border: OutlineInputBorder(), prefixIcon: Icon(Icons.wc)), items: ["Laki-laki", "Perempuan"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => selectedJK = v!)),
            const SizedBox(height: 15),
            DropdownButtonFormField(value: selectedAgama, decoration: const InputDecoration(labelText: "Agama*", border: OutlineInputBorder(), prefixIcon: Icon(Icons.church)), items: daftarAgama.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => selectedAgama = v!)),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: _boxInput(niCtrl, "NIS*", Icons.badge, type: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _boxInput(nisnCtrl, "NISN*", Icons.fingerprint, type: TextInputType.number)),
            ]),
            const SizedBox(height: 15),
            TextField(controller: tglCtrl, readOnly: true, onTap: () async { DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1990), lastDate: DateTime.now()); if (p != null) setState(() => tglCtrl.text = DateFormat('dd MMMM yyyy').format(p)); }, decoration: const InputDecoration(labelText: "Tanggal Lahir*", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_month))),
            const SizedBox(height: 15),
            _boxInput(telpCtrl, "Nomor Telepon", Icons.phone, type: TextInputType.phone),
            const SizedBox(height: 15),
            _boxInput(emailCtrl, "Email / Gmail", Icons.email, type: TextInputType.emailAddress),
            const SizedBox(height: 15),
            DropdownButtonFormField(value: selectedKelas, decoration: const InputDecoration(labelText: "Kelas*", border: OutlineInputBorder(), prefixIcon: Icon(Icons.school)), items: daftarKelas.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => selectedKelas = v!)),
            const SizedBox(height: 15),
            _boxInput(alamatCtrl, "Alamat Lengkap", Icons.home, maxLines: 3),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white), onPressed: _validasiDanSimpan, child: const Text("SIMPAN DATA"))),
          ],
        ),
      ),
    );
  }

  Widget _boxInput(TextEditingController c, String l, IconData i, {int maxLines = 1, TextInputType type = TextInputType.text}) {
    return TextField(controller: c, maxLines: maxLines, keyboardType: type, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i), border: const OutlineInputBorder()));
  }

  void _showPicker() {
    showModalBottomSheet(context: context, builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.image), title: const Text("Galeri"), onTap: () { Navigator.pop(c); _pickImage(ImageSource.gallery); }),
        ListTile(leading: const Icon(Icons.camera_alt), title: const Text("Kamera"), onTap: () { Navigator.pop(c); _pickImage(ImageSource.camera); }),
        if (_imageFile != null)
          ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text("Hapus Foto", style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(c); setState(() => _imageFile = null); }),
      ]),
    ));
  }

  Future<void> _pickImage(ImageSource source) async { final p = await ImagePicker().pickImage(source: source); if (p != null) setState(() => _imageFile = File(p.path)); }
}