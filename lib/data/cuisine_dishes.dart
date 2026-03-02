// lib/data/cuisine_dishes.dart
// База РЕАЛЬНЫХ блюд по кухням — AI выбирает только из этого списка

class CuisineDish {
  final String title;      // локальное название
  final String nameEn;


  const CuisineDish({
    required this.title,
    required this.nameEn,
  });
}

class CuisineData {
  final String nameEn;
  final String nameRu;
  final String flag;
  final List<CuisineDish> dishes;

  const CuisineData({
    required this.nameEn,
    required this.nameRu,
    required this.flag,
    required this.dishes,
  });
}

// ════════════════════════════════════════════════════════════
// БАЗА РЕАЛЬНЫХ БЛЮД
// ════════════════════════════════════════════════════════════

const List<CuisineData> allCuisines = [

  // ── УЗБЕКИСТАН ──────────────────────────────────────────
  CuisineData(
    nameEn: 'Uzbek', nameRu: 'Узбекистан', flag: '🇺🇿',
    dishes: [
      CuisineDish(title: 'Плов',              nameEn: 'Uzbek Plov'),
      CuisineDish(title: 'Лагман',            nameEn: 'Lagman'),
      CuisineDish(title: 'Шурпа',             nameEn: 'Shurpa soup'),
      CuisineDish(title: 'Манты',             nameEn: 'Manti dumplings'),
      CuisineDish(title: 'Самса',             nameEn: 'Samsa'),
      CuisineDish(title: 'Дамлама',           nameEn: 'Dimlama'),
      CuisineDish(title: 'Бешбармак',         nameEn: 'Beshbarmak'),
      CuisineDish(title: 'Нарын',             nameEn: 'Naryn noodles'),
      CuisineDish(title: 'Мастава',           nameEn: 'Mastava rice soup'),
      CuisineDish(title: 'Жареная картошка с мясом', nameEn: 'Uzbek fried potatoes meat'),
      CuisineDish(title: 'Кабоб',             nameEn: 'Kebab shashlik'),
    ],
  ),

  // ── ТАДЖИКИСТАН ─────────────────────────────────────────
  CuisineData(
    nameEn: 'Tajik', nameRu: 'Таджикистан', flag: '🇹🇯',
    dishes: [
      CuisineDish(title: 'Кутаб',              nameEn: 'Tajik Qutab flatbread'),
      CuisineDish(title: 'Оши Плов',           nameEn: 'Osh Palov Tajik'),
      CuisineDish(title: 'Курутоб',            nameEn: 'Qurutob'),
      CuisineDish(title: 'Самбуса',            nameEn: 'Tajik Sambusa'),
      CuisineDish(title: 'Шурбо',              nameEn: 'Tajik Shurbo soup'),
      CuisineDish(title: 'Манту',              nameEn: 'Tajik Mantu'),
      CuisineDish(title: 'Лагмон',             nameEn: 'Tajik Lagmon noodles'),
      CuisineDish(title: 'Фатир',              nameEn: 'Fatir bread'),
    ],
  ),

  // ── РОССИЯ ──────────────────────────────────────────────
  CuisineData(
    nameEn: 'Russian', nameRu: 'Россия', flag: '🇷🇺',
    dishes: [
      CuisineDish(title: 'Борщ',              nameEn: 'Russian Borscht'),
      CuisineDish(title: 'Пельмени',          nameEn: 'Pelmeni'),
      CuisineDish(title: 'Блины',             nameEn: 'Russian Blini'),
      CuisineDish(title: 'Щи',               nameEn: 'Shchi cabbage soup'),
      CuisineDish(title: 'Бефстроганов',      nameEn: 'Beef Stroganoff'),
      CuisineDish(title: 'Оливье',            nameEn: 'Olivier salad'),
      CuisineDish(title: 'Вареники',          nameEn: 'Vareniki'),
      CuisineDish(title: 'Солянка',           nameEn: 'Solyanka soup'),
      CuisineDish(title: 'Котлеты',          nameEn: 'Russian Kotlety'),
      CuisineDish(title: 'Окрошка',           nameEn: 'Okroshka'),
    ],
  ),

  // ── ИТАЛИЯ ──────────────────────────────────────────────
  CuisineData(
    nameEn: 'Italian', nameRu: 'Италия', flag: '🇮🇹',
    dishes: [
      CuisineDish(title: 'Спагетти Карбонара', nameEn: 'Spaghetti Carbonara'),
      CuisineDish(title: 'Ризотто',           nameEn: 'Risotto'),
      CuisineDish(title: 'Лазанья',           nameEn: 'Lasagna'),
      CuisineDish(title: 'Тирамису',          nameEn: 'Tiramisu'),
      CuisineDish(title: 'Пицца Маргарита',   nameEn: 'Pizza Margherita'),
      CuisineDish(title: 'Оссобуко',          nameEn: 'Osso Buco'),
      CuisineDish(title: 'Паста Болоньезе',   nameEn: 'Pasta Bolognese'),
      CuisineDish(title: 'Минестроне',        nameEn: 'Minestrone soup'),
      CuisineDish(title: 'Равиоли',           nameEn: 'Ravioli'),
      CuisineDish(title: 'Кальцоне',          nameEn: 'Calzone'),
    ],
  ),

  // ── ТУРЦИЯ ──────────────────────────────────────────────
  CuisineData(
    nameEn: 'Turkish', nameRu: 'Турция', flag: '🇹🇷',
    dishes: [
      CuisineDish(title: 'Кебаб Адана',       nameEn: 'Adana Kebab'),
      CuisineDish(title: 'Донер Кебаб',       nameEn: 'Doner Kebab'),
      CuisineDish(title: 'Манты',             nameEn: 'Turkish Manti'),
      CuisineDish(title: 'Баклава',           nameEn: 'Baklava'),
      CuisineDish(title: 'Мерджимек Чорбасы', nameEn: 'Mercimek Çorbası'),
      CuisineDish(title: 'Имам Баялды',       nameEn: 'Imam Bayildi'),
      CuisineDish(title: 'Кёфте',             nameEn: 'Kofte meatballs'),
      CuisineDish(title: 'Пиде',              nameEn: 'Turkish Pide bread'),
      CuisineDish(title: 'Чечевичный суп',    nameEn: 'Turkish lentil soup'),
      CuisineDish(title: 'Лахмаджун',         nameEn: 'Lahmacun'),
    ],
  ),

  // ── ЯПОНИЯ ──────────────────────────────────────────────
  CuisineData(
    nameEn: 'Japanese', nameRu: 'Япония', flag: '🇯🇵',
    dishes: [
      CuisineDish(title: 'Рамен',             nameEn: 'Ramen'),
      CuisineDish(title: 'Суши',              nameEn: 'Sushi'),
      CuisineDish(title: 'Темпура',           nameEn: 'Tempura'),
      CuisineDish(title: 'Тонкацу',           nameEn: 'Tonkatsu'),
      CuisineDish(title: 'Онигири',           nameEn: 'Onigiri'),
      CuisineDish(title: 'Якитори',           nameEn: 'Yakitori'),
      CuisineDish(title: 'Удон',              nameEn: 'Udon noodles'),
      CuisineDish(title: 'Мисо суп',          nameEn: 'Miso soup'),
      CuisineDish(title: 'Гёза',              nameEn: 'Gyoza dumplings'),
      CuisineDish(title: 'Окономияки',        nameEn: 'Okonomiyaki'),
    ],
  ),

  // ── КИТАЙ ───────────────────────────────────────────────
  CuisineData(
    nameEn: 'Chinese', nameRu: 'Китай', flag: '🇨🇳',
    dishes: [
      CuisineDish(title: 'Жареный рис',       nameEn: 'Chinese Fried Rice'),
      CuisineDish(title: 'Дим Сам',           nameEn: 'Dim Sum'),
      CuisineDish(title: 'Кунг Пао курица',   nameEn: 'Kung Pao Chicken'),
      CuisineDish(title: 'Утка по-пекински',  nameEn: 'Peking Duck'),
      CuisineDish(title: 'Пельмени Цзяоцзы', nameEn: 'Jiaozi dumplings'),
      CuisineDish(title: 'Маpo Тофу',         nameEn: 'Mapo Tofu'),
      CuisineDish(title: 'Чау Мейн',          nameEn: 'Chow Mein'),
      CuisineDish(title: 'Суп Хот Пот',       nameEn: 'Hot Pot'),
      CuisineDish(title: 'Жареная свинина',   nameEn: 'Char Siu pork'),
      CuisineDish(title: 'Баозы',             nameEn: 'Baozi steamed buns'),
    ],
  ),

  // ── ИНДИЯ ───────────────────────────────────────────────
  CuisineData(
    nameEn: 'Indian', nameRu: 'Индия', flag: '🇮🇳',
    dishes: [
      CuisineDish(title: 'Баттер Чикен',      nameEn: 'Butter Chicken'),
      CuisineDish(title: 'Бирьяни',           nameEn: 'Biryani'),
      CuisineDish(title: 'Палак Панир',       nameEn: 'Palak Paneer'),
      CuisineDish(title: 'Самоса',            nameEn: 'Samosa'),
      CuisineDish(title: 'Дал',               nameEn: 'Dal lentil curry'),
      CuisineDish(title: 'Наан',              nameEn: 'Naan bread'),
      CuisineDish(title: 'Тикка Масала',      nameEn: 'Chicken Tikka Masala'),
      CuisineDish(title: 'Алоо Гоби',        nameEn: 'Aloo Gobi'),
      CuisineDish(title: 'Роган Джош',        nameEn: 'Rogan Josh'),
      CuisineDish(title: 'Чана Масала',       nameEn: 'Chana Masala'),
    ],
  ),

  // ── ТАИЛАНД ─────────────────────────────────────────────
  CuisineData(
    nameEn: 'Thai', nameRu: 'Таиланд', flag: '🇹🇭',
    dishes: [
      CuisineDish(title: 'Пад Тай',           nameEn: 'Pad Thai'),
      CuisineDish(title: 'Том Ям',            nameEn: 'Tom Yum soup'),
      CuisineDish(title: 'Зелёное карри',     nameEn: 'Thai Green Curry'),
      CuisineDish(title: 'Красное карри',     nameEn: 'Thai Red Curry'),
      CuisineDish(title: 'Жареный рис',       nameEn: 'Thai Fried Rice'),
      CuisineDish(title: 'Сом Там',           nameEn: 'Som Tam papaya salad'),
      CuisineDish(title: 'Масаман карри',     nameEn: 'Massaman Curry'),
      CuisineDish(title: 'Ларб',              nameEn: 'Larb minced meat'),
      CuisineDish(title: 'Пад Кра Пао',      nameEn: 'Pad Kra Pao'),
      CuisineDish(title: 'Том Ка Гай',       nameEn: 'Tom Kha Gai'),
    ],
  ),

  // ── ВЬЕТНАМ ─────────────────────────────────────────────
  CuisineData(
    nameEn: 'Vietnamese', nameRu: 'Вьетнам', flag: '🇻🇳',
    dishes: [
      CuisineDish(title: 'Фо Бо',             nameEn: 'Pho Bo beef soup'),
      CuisineDish(title: 'Бань Ми',           nameEn: 'Banh Mi sandwich'),
      CuisineDish(title: 'Го Куон',           nameEn: 'Goi Cuon spring rolls'),
      CuisineDish(title: 'Бун Бо Хюэ',       nameEn: 'Bun Bo Hue'),
      CuisineDish(title: 'Ком Там',           nameEn: 'Com Tam broken rice'),
      CuisineDish(title: 'Бань Ксео',         nameEn: 'Banh Xeo sizzling cake'),
      CuisineDish(title: 'Ча Га',             nameEn: 'Cha Ca fish'),
      CuisineDish(title: 'Бун Чa',            nameEn: 'Bun Cha'),
      CuisineDish(title: 'Мì Кванг',         nameEn: 'Mi Quang noodles'),
      CuisineDish(title: 'Хуэ Нем Луй',      nameEn: 'Nem Lui lemongrass'),
    ],
  ),

  // ── ФРАНЦИЯ ─────────────────────────────────────────────
  CuisineData(
    nameEn: 'French', nameRu: 'Франция', flag: '🇫🇷',
    dishes: [
      CuisineDish(title: 'Луковый суп',       nameEn: 'French Onion Soup'),
      CuisineDish(title: 'Рататуй',           nameEn: 'Ratatouille'),
      CuisineDish(title: 'Кок-о-Вин',        nameEn: 'Coq au Vin'),
      CuisineDish(title: 'Буф Бургиньон',    nameEn: 'Boeuf Bourguignon'),
      CuisineDish(title: 'Киш Лорен',        nameEn: 'Quiche Lorraine'),
      CuisineDish(title: 'Крем Брюле',       nameEn: 'Creme Brulee'),
      CuisineDish(title: 'Круассан',          nameEn: 'Croissant'),
      CuisineDish(title: 'Профитроли',        nameEn: 'Profiteroles'),
      CuisineDish(title: 'Нисуаз',           nameEn: 'Salad Nicoise'),
      CuisineDish(title: 'Утиное конфи',     nameEn: 'Duck Confit'),
    ],
  ),

  // ── МЕКСИКА ─────────────────────────────────────────────
  CuisineData(
    nameEn: 'Mexican', nameRu: 'Мексика', flag: '🇲🇽',
    dishes: [
      CuisineDish(title: 'Тако',              nameEn: 'Tacos'),
      CuisineDish(title: 'Гуакамоле',         nameEn: 'Guacamole'),
      CuisineDish(title: 'Энчиладас',         nameEn: 'Enchiladas'),
      CuisineDish(title: 'Чили кон карне',    nameEn: 'Chili con Carne'),
      CuisineDish(title: 'Позоле',            nameEn: 'Pozole soup'),
      CuisineDish(title: 'Моле',              nameEn: 'Mole sauce chicken'),
      CuisineDish(title: 'Тамалес',           nameEn: 'Tamales'),
      CuisineDish(title: 'Буррито',           nameEn: 'Burrito'),
      CuisineDish(title: 'Кесадилья',         nameEn: 'Quesadilla'),
      CuisineDish(title: 'Сальса',            nameEn: 'Salsa with chips'),
    ],
  ),

  // ── КОРЕЯ ───────────────────────────────────────────────
  CuisineData(
    nameEn: 'Korean', nameRu: 'Корея', flag: '🇰🇷',
    dishes: [
      CuisineDish(title: 'Кимчи Чиге',       nameEn: 'Kimchi Jjigae stew'),
      CuisineDish(title: 'Пибимпап',          nameEn: 'Bibimbap'),
      CuisineDish(title: 'Bulgogi',           nameEn: 'Bulgogi beef'),
      CuisineDish(title: 'Токпокки',          nameEn: 'Tteokbokki'),
      CuisineDish(title: 'Самгёпсаль',        nameEn: 'Samgyeopsal pork belly'),
      CuisineDish(title: 'Пулькоги суп',     nameEn: 'Korean BBQ'),
      CuisineDish(title: 'Доенджан Чиге',    nameEn: 'Doenjang Jjigae'),
      CuisineDish(title: 'Кимпап',            nameEn: 'Kimbap'),
      CuisineDish(title: 'Хэмуль Пажон',    nameEn: 'Haemul Pajeon'),
      CuisineDish(title: 'Суюк',             nameEn: 'Bossam pork'),
    ],
  ),

  // ── ГРУЗИЯ ──────────────────────────────────────────────
  CuisineData(
    nameEn: 'Georgian', nameRu: 'Грузия', flag: '🇬🇪',
    dishes: [
      CuisineDish(title: 'Хачапури',          nameEn: 'Khachapuri'),
      CuisineDish(title: 'Хинкали',           nameEn: 'Khinkali dumplings'),
      CuisineDish(title: 'Чахохбили',         nameEn: 'Chakhokhbili'),
      CuisineDish(title: 'Лобиани',           nameEn: 'Lobiani bean bread'),
      CuisineDish(title: 'Пхали',             nameEn: 'Pkhali walnut appetizer'),
      CuisineDish(title: 'Аджапсандали',      nameEn: 'Ajapsandali stew'),
      CuisineDish(title: 'Мцвади',            nameEn: 'Mtsvadi shashlik'),
      CuisineDish(title: 'Харчо',             nameEn: 'Kharcho soup'),
      CuisineDish(title: 'Сациви',            nameEn: 'Satsivi walnut chicken'),
      CuisineDish(title: 'Лобио',             nameEn: 'Lobio beans'),
    ],
  ),

  // ── КАЗАХСТАН ───────────────────────────────────────────
  CuisineData(
    nameEn: 'Kazakh', nameRu: 'Казахстан', flag: '🇰🇿',
    dishes: [
      CuisineDish(title: 'Бешбармак',         nameEn: 'Beshbarmak'),
      CuisineDish(title: 'Плов',              nameEn: 'Kazakh Plov'),
      CuisineDish(title: 'Манты',             nameEn: 'Kazakh Manti'),
      CuisineDish(title: 'Сорпа',             nameEn: 'Sorpa meat broth'),
      CuisineDish(title: 'Казы',              nameEn: 'Kazy horse sausage'),
      CuisineDish(title: 'Баурсак',           nameEn: 'Baursak fried bread'),
      CuisineDish(title: 'Куырдак',           nameEn: 'Kuurdak fried offal'),
      CuisineDish(title: 'Самса',             nameEn: 'Kazakh Samsa'),
    ],
  ),

  // ── ГРЕЦИЯ ──────────────────────────────────────────────
  CuisineData(
    nameEn: 'Greek', nameRu: 'Греция', flag: '🇬🇷',
    dishes: [
      CuisineDish(title: 'Мусака',            nameEn: 'Moussaka'),
      CuisineDish(title: 'Сувлаки',           nameEn: 'Souvlaki'),
      CuisineDish(title: 'Спанакопита',       nameEn: 'Spanakopita'),
      CuisineDish(title: 'Греческий салат',   nameEn: 'Greek Salad'),
      CuisineDish(title: 'Тцацики',           nameEn: 'Tzatziki'),
      CuisineDish(title: 'Долмадес',          nameEn: 'Dolmades'),
      CuisineDish(title: 'Гирос',             nameEn: 'Gyros'),
      CuisineDish(title: 'Пастицио',          nameEn: 'Pastitsio'),
      CuisineDish(title: 'Клефтико',          nameEn: 'Kleftiko lamb'),
      CuisineDish(title: 'Баклава',           nameEn: 'Greek Baklava'),
    ],
  ),

  // ── ИСПАНИЯ ─────────────────────────────────────────────
  CuisineData(
    nameEn: 'Spanish', nameRu: 'Испания', flag: '🇪🇸',
    dishes: [
      CuisineDish(title: 'Паэлья',            nameEn: 'Paella'),
      CuisineDish(title: 'Тортилья',          nameEn: 'Spanish Tortilla'),
      CuisineDish(title: 'Гаспачо',           nameEn: 'Gazpacho'),
      CuisineDish(title: 'Патас Бравас',      nameEn: 'Patatas Bravas'),
      CuisineDish(title: 'Чурро',             nameEn: 'Churros'),
      CuisineDish(title: 'Кокидо Мадриленьо',nameEn: 'Cocido Madrileño'),
      CuisineDish(title: 'Фабада Астуриана',  nameEn: 'Fabada Asturiana'),
      CuisineDish(title: 'Крема Каталана',    nameEn: 'Crema Catalana'),
    ],
  ),

  // ── АРМЕНИЯ ─────────────────────────────────────────────
  CuisineData(
    nameEn: 'Armenian', nameRu: 'Армения', flag: '🇦🇲',
    dishes: [
      CuisineDish(title: 'Долма',             nameEn: 'Armenian Dolma'),
      CuisineDish(title: 'Хаш',              nameEn: 'Khash beef feet soup'),
      CuisineDish(title: 'Кюфта',            nameEn: 'Kufta meatballs'),
      CuisineDish(title: 'Ламаджо',           nameEn: 'Lahmajoun Armenian'),
      CuisineDish(title: 'Хоровац',           nameEn: 'Khorovats BBQ'),
      CuisineDish(title: 'Жингялов хац',     nameEn: 'Zhingyalov hats'),
      CuisineDish(title: 'Бозбаш',            nameEn: 'Bozbash soup'),
      CuisineDish(title: 'Ануш абур',        nameEn: 'Anoushabour pudding'),
    ],
  ),

  // ── АЗЕРБАЙДЖАН ─────────────────────────────────────────
  CuisineData(
    nameEn: 'Azerbaijani', nameRu: 'Азербайджан', flag: '🇦🇿',
    dishes: [
      CuisineDish(title: 'Плов',              nameEn: 'Azerbaijani Plov'),
      CuisineDish(title: 'Довга',             nameEn: 'Dovga yogurt soup'),
      CuisineDish(title: 'Долма',             nameEn: 'Azerbaijani Dolma'),
      CuisineDish(title: 'Кутабы',            nameEn: 'Qutab flatbread'),
      CuisineDish(title: 'Пити',              nameEn: 'Piti lamb soup'),
      CuisineDish(title: 'Люля-кебаб',        nameEn: 'Lula Kebab'),
      CuisineDish(title: 'Бозбаш',            nameEn: 'Azerbaijani Bozbash'),
      CuisineDish(title: 'Пахлава',           nameEn: 'Azerbaijani Pakhlava'),
    ],
  ),

  // ── США ─────────────────────────────────────────────────
  CuisineData(
    nameEn: 'American', nameRu: 'США', flag: '🇺🇸',
    dishes: [
      CuisineDish(title: 'Бургер',            nameEn: 'American Hamburger'),
      CuisineDish(title: 'Барбекю рёбра',     nameEn: 'BBQ Ribs'),
      CuisineDish(title: 'Клам Чаудер',      nameEn: 'Clam Chowder'),
      CuisineDish(title: 'Мак энд Чиз',      nameEn: 'Mac and Cheese'),
      CuisineDish(title: 'Кукурузный хлеб',  nameEn: 'Cornbread'),
      CuisineDish(title: 'Чизбургер',        nameEn: 'Cheeseburger'),
      CuisineDish(title: 'Гамбо',            nameEn: 'Gumbo'),
      CuisineDish(title: 'Жареная курица',   nameEn: 'Southern Fried Chicken'),
      CuisineDish(title: 'Чили',             nameEn: 'American Chili'),
      CuisineDish(title: 'Яблочный пирог',   nameEn: 'Apple Pie'),
    ],
  ),
];

// Удобный метод поиска кухни по nameEn
CuisineData? getCuisineByName(String nameEn) {
  try {
    return allCuisines.firstWhere((c) => c.nameEn == nameEn);
  } catch (_) {
    return null;
  }
}
