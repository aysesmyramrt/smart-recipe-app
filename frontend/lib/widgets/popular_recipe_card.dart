import 'package:flutter/material.dart';
import 'package:smart_recipe_app/models/popular_recipe.dart';

// Tüm 144 tarif → asset fotoğraf eşleşmesi (ASCII dosya isimleri)
const _recipeAssetImages = {
  'Mercimek Çorbası':      'assets/images/Mercimek_Corbasi.jpg',
  'Pilav':                 'assets/images/Pilav.jpg',
  'Domates Çorbası':       'assets/images/Domates_Corbasi.jpg',
  'Patates Yemeği':        'assets/images/Patates_Yemegi.jpg',
  'Ezogelin Çorbası':      'assets/images/Ezogelin_Corbasi.jpg',
  'Tarhana Çorbası':       'assets/images/Tarhana_Corbasi.jpg',
  'Makarna':               'assets/images/Makarna.jpg',
  'Yumurtalı Patates':     'assets/images/Yumurtali_Patates.jpg',
  'Kuru Fasülye':          'assets/images/Kuru_Fasulye.jpg',
  'Tavuk Sote':            'assets/images/Tavuk_Sote.jpg',
  'İmam Bayıldı':          'assets/images/Imam_Bayildi.jpg',
  'Etli Güveç':            'assets/images/Etli_Guvec.jpg',
  'Karnıyarık':            'assets/images/Karniyarik.jpg',
  'Nohutlu Pilav':         'assets/images/Nohutlu_Pilav.jpg',
  'Tavuk Çorbası':         'assets/images/Tavuk_Corbasi.jpg',
  'Fırın Tavuk':           'assets/images/Firin_Tavuk.jpg',
  'Mantı':                 'assets/images/Manti.jpg',
  'İskender Kebap':        'assets/images/Iskender_Kebap.jpg',
  'Hünkar Beğendi':        'assets/images/Hunkar_Begendi.jpg',
  'Kuzu Tandır':           'assets/images/Kuzu_Tandir.jpg',
  'Dolma':                 'assets/images/Dolma.jpg',
  'Adana Kebap':           'assets/images/Adana_Kebap.jpg',
  'Testi Kebabı':          'assets/images/Testi_Kebabi.jpg',
  'Kuzu İncik':            'assets/images/Kuzu_Incik.jpg',
  'Menemen':               'assets/images/Menemen.jpg',
  'Sahanda Yumurta':       'assets/images/Sahanda_Yumurta.jpg',
  'Bal Kaymak':            'assets/images/Bal_Kaymak.jpg',
  'Haşlanmış Yumurta':     'assets/images/Haslanmis_Yumurta.jpg',
  'Domates Salatalık':     'assets/images/Domates_Salatalik.jpg',
  'Simit':                 'assets/images/Simit.jpg',
  'Çılbır':                'assets/images/Cilbir.jpg',
  'Yumurtalı Sucuk':       'assets/images/Yumurtali_Sucuk.jpg',
  'Peynirli Gözleme':      'assets/images/Peynirli_Gozleme.jpg',
  'Sigara Böreği':         'assets/images/Sigara_Boregi.jpg',
  'Kaygana':               'assets/images/Kaygana.jpg',
  'Patatesli Omlet':       'assets/images/Patatesli_Omlet.jpg',
  'Peynirli Pide':         'assets/images/Peynirli_Pide.jpg',
  'Ispanaklı Börek':       'assets/images/Ispanakli_Borek.jpg',
  'Patatesli Gözleme':     'assets/images/Patatesli_Gozleme.jpg',
  'Omlet':                 'assets/images/Omlet.jpg',
  'Su Böreği':             'assets/images/Su_Boregi.jpg',
  'Poğaça':                'assets/images/Pogaca.jpg',
  'Açma':                  'assets/images/Acma.jpg',
  'Tuzlu Kurabiye':        'assets/images/Tuzlu_Kurabiye.jpg',
  'Tepsi Böreği':          'assets/images/Tepsi_Boregi.jpg',
  'Katmer':                'assets/images/Katmer.jpg',
  'Pide':                  'assets/images/Pide.jpg',
  'Yufka Böreği':          'assets/images/Yufka_Boregi.jpg',
  'Sütlaç':                'assets/images/Sutlac.jpg',
  'Muhallebi':             'assets/images/Muhallebi.jpg',
  'Komposto':              'assets/images/Komposto.jpg',
  'Pelte':                 'assets/images/Pelte.jpg',
  'Dondurma':              'assets/images/Dondurma.jpg',
  'Helva':                 'assets/images/Helva.jpg',
  'Güllaç':                'assets/images/Gullac.jpg',
  'Tahin Pekmez':          'assets/images/Tahin_Pekmez.jpg',
  'Revani':                'assets/images/Revani.jpg',
  'Kazandibi':             'assets/images/Kazandibi.jpg',
  'Tulumba':               'assets/images/Tulumba.jpg',
  'Şekerpare':             'assets/images/Sekerpare.jpg',
  'Kadayıf':               'assets/images/Kadayif.jpg',
  'Lokma':                 'assets/images/Lokma.jpg',
  'Fırın Sütlaç':          'assets/images/Firin_Sutlac.jpg',
  'Trileçe':               'assets/images/Trilece.jpg',
  'Baklava':               'assets/images/Baklava.jpg',
  'Künefe':                'assets/images/Kunefe.jpg',
  'Aşure':                 'assets/images/Asure.jpg',
  'Lokum':                 'assets/images/Lokum.jpg',
  'Pasta':                 'assets/images/Pasta.jpg',
  'Profiterol':            'assets/images/Profiterol.jpg',
  'Cheesecake':            'assets/images/Cheesecake.jpg',
  'Bülbül Yuvası':         'assets/images/Bulbul_Yuvasi.jpg',
  'Haydari':               'assets/images/Haydari.jpg',
  'Cacık':                 'assets/images/Cacik.jpg',
  'Humus':                 'assets/images/Humus.jpg',
  'Patlıcan Ezmesi':       'assets/images/Patlican_Ezmesi.jpg',
  'Domates Salsa':         'assets/images/Domates_Salsa.jpg',
  'Zeytinyağlı Semizotu':  'assets/images/Zeytinyagli_Semizotu.jpg',
  'Çoban Salatası':        'assets/images/Coban_Salatasi.jpg',
  'Tarator':               'assets/images/Tarator.jpg',
  'Kısır':                 'assets/images/Kisir.jpg',
  'Mücver':                'assets/images/Mucver.jpg',
  'Arnavut Ciğeri':        'assets/images/Arnavut_Cigeri.jpg',
  'Falafel':               'assets/images/Falafel.jpg',
  'Patates Köftesi':       'assets/images/Patates_Koftesi.jpg',
  'Mercimek Köftesi':      'assets/images/Mercimek_Koftesi.jpg',
  'Kabak Çiçeği Dolması':  'assets/images/Kabak_Cicegi_Dolmasi.jpg',
  'İçli Köfte':            'assets/images/Icli_Kofte.jpg',
  'Lahmacun':              'assets/images/Lahmacun.jpg',
  'Midye Dolma':           'assets/images/Midye_Dolma.jpg',
  'Yaprak Sarma':          'assets/images/Yaprak_Sarma.jpg',
  'Börek':                 'assets/images/Borek.jpg',
  'Patlıcan Dolma':        'assets/images/Patlican_Dolma.jpg',
  'Karides Güveç':         'assets/images/Karides_Guvec.jpg',
  'Çiğ Köfte':             'assets/images/Cig_Kofte.jpg',
  'Ayran':                 'assets/images/Ayran.jpg',
  'Limonata':              'assets/images/Limonata.jpg',
  'Meyve Suyu':            'assets/images/Meyve_Suyu.jpg',
  'Ihlamur Çayı':          'assets/images/Ihlamur_Cayi.jpg',
  'Adaçayı':               'assets/images/Adacayi.jpg',
  'Nane Limon':            'assets/images/Nane_Limon.jpg',
  'Sıcak Çikolata':        'assets/images/Sicak_Cikolata.jpg',
  'Zencefil Çayı':         'assets/images/Zencefil_Cayi.jpg',
  'Sahlep':                'assets/images/Sahlep.jpg',
  'Boza':                  'assets/images/Boza.jpg',
  'Şalgam Suyu':           'assets/images/Salgam_Suyu.jpg',
  'Vişne Şerbeti':         'assets/images/Visne_Serbeti.jpg',
  'Tamarind Şerbeti':      'assets/images/Tamarind_Serbeti.jpg',
  'Smoothie':              'assets/images/Smoothie.jpg',
  'Gül Şerbeti':           'assets/images/Gul_Serbeti.jpg',
  'Portakallı İçecek':     'assets/images/Portakalli_Icecek.jpg',
  'Türk Kahvesi':          'assets/images/Turk_Kahvesi.jpg',
  'Osmanlı Şerbeti':       'assets/images/Osmanli_Serbeti.jpg',
  'Menengiç Kahvesi':      'assets/images/Menengic_Kahvesi.jpg',
  'Kefir':                 'assets/images/Kefir.jpg',
  'Kombucha':              'assets/images/Kombucha.jpg',
  'Sıkma Nar Suyu':        'assets/images/Sikma_Nar_Suyu.jpg',
  'Çay Likörü':            'assets/images/Cay_Likoru.jpg',
  'Badem Sütü':            'assets/images/Badem_Sutu.jpg',
  'Izgara Sebze':          'assets/images/Izgara_Sebze.jpg',
  'Yoğurtlu Salata':       'assets/images/Yogurtlu_Salata.jpg',
  'Mercimek Salatası':     'assets/images/Mercimek_Salatasi.jpg',
  'Domates Salatası':      'assets/images/Domates_Salatasi.jpg',
  'Haşlanmış Sebze':       'assets/images/Haslanmis_Sebze.jpg',
  'Taze Meyve Salatası':   'assets/images/Taze_Meyve_Salatasi.jpg',
  'Avokado Salatası':      'assets/images/Avokado_Salatasi.jpg',
  'Zeytinyağlı Fasülye':   'assets/images/Zeytinyagli_Fasulye.jpg',
  'Izgara Tavuk':          'assets/images/Izgara_Tavuk.jpg',
  'Sebzeli Çorba':         'assets/images/Sebzeli_Corba.jpg',
  'Quinoa Salatası':       'assets/images/Quinoa_Salatasi.jpg',
  'Nohutlu Ispanak':       'assets/images/Nohutlu_Ispanak.jpg',
  'Buharda Sebze':         'assets/images/Buharda_Sebze.jpg',
  'Ton Balıklı Salata':    'assets/images/Ton_Balikli_Salata.jpg',
  'Izgara Somon':          'assets/images/Izgara_Somon.jpg',
  'Zeytinyağlı Dolma':     'assets/images/Zeytinyagli_Dolma.jpg',
  'Fırın Levrek':          'assets/images/Firin_Levrek.jpg',
  'Sebzeli Güveç':         'assets/images/Sebzeli_Guvec.jpg',
  'Diyet Köfte':           'assets/images/Diyet_Kofte.jpg',
  'Tavuklu Brokoli':       'assets/images/Tavuklu_Brokoli.jpg',
  'Sebzeli Omlet':         'assets/images/Sebzeli_Omlet.jpg',
  'Bulgur Pilavı':         'assets/images/Bulgur_Pilavi.jpg',
  'Fırın Tavuk Göğsü':     'assets/images/Firin_Tavuk_Gogsu.jpg',
};

String recipeImageUrl(String title) {
  final path = _recipeAssetImages[title] ?? 'assets/images/anayemek.jpg';
  return 'asset:$path';
}

class RecipeThumbnail extends StatelessWidget {
  final String title;
  final Color color;
  const RecipeThumbnail({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    final url = recipeImageUrl(title);
    final fallback = Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.restaurant, color: color, size: 26),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url.startsWith('asset:')
          ? Image.asset(
              url.substring(6),
              width: 56, height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            )
          : Image.network(
              url.substring(8),
              width: 56, height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final PopularRecipe recipe;
  final Color color;
  final VoidCallback onTap;

  const RecipeCard({super.key, required this.recipe, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                RecipeThumbnail(title: recipe.title, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        recipe.description,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule_outlined, size: 13, color: Colors.grey.shade700),
                          const SizedBox(width: 3),
                          Text('${recipe.effectivePrepTime} dk',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 10),
                          Icon(Icons.local_fire_department_outlined, size: 13, color: Colors.grey.shade700),
                          const SizedBox(width: 3),
                          Text('${recipe.cookTime} dk',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 10),
                          Icon(Icons.kitchen_outlined, size: 13, color: Colors.grey.shade700),
                          const SizedBox(width: 3),
                          Text('${recipe.ingredientCount} malzeme',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DifficultySection extends StatelessWidget {
  final String title;
  final String emoji;
  final Color color;
  final List<PopularRecipe> recipes;
  final Future<void> Function(PopularRecipe) onTap;

  const DifficultySection({
    super.key,
    required this.title,
    required this.emoji,
    required this.color,
    required this.recipes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: color.withOpacity(0.3), thickness: 1.5)),
            ],
          ),
        ),
        ...recipes.map((r) => RecipeCard(recipe: r, color: color, onTap: () => onTap(r))),
      ],
    );
  }
}
