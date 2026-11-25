class_name SocialTemplates
extends RefCounted
## Post templates for the in-game social network "Cıvıltı".
## Each entry: [turkish, english, sentiment(-1..1)]
## Placeholders: {line} {a} {b} {st} {mode} {city} {n} {poi} {year} {hood}

const FIRST_NAMES := ["Ayşe", "Mehmet", "Zeynep", "Emre", "Elif", "Can", "Deniz", "Burak", "Selin", "Mert",
	"Ece", "Kerem", "Defne", "Oğuz", "Cansu", "Barış", "İrem", "Tolga", "Melis", "Arda", "Nazlı", "Kaan",
	"Seda", "Umut", "Gizem", "Onur", "Buse", "Serkan", "Yağmur", "Hakan", "Ebru", "Efe", "Damla", "Cem",
	"Sevgi", "Halil", "Fatma", "Ali", "Hatice", "Murat", "Esra", "Volkan", "Pınar", "Doruk", "Ceren"]
const LAST_NAMES := ["Yılmaz", "Kaya", "Demir", "Şahin", "Çelik", "Yıldız", "Aydın", "Öztürk", "Arslan",
	"Doğan", "Kılıç", "Koç", "Kurt", "Özdemir", "Polat", "Aksoy", "Erdem", "Tekin", "Güneş", "Bulut", "Avcı"]
const HANDLE_SUFFIX := ["", "_", "34", "06", "35", "x", "_tr", "1907", "1903", "1905", "_dev", "_ist", "_kordon"]

const NEWS := [
	{"name": "Kent Haber", "handle": "kenthaber", "color": "e63946"},
	{"name": "Ulaşım Bülteni", "handle": "ulasimbulteni", "color": "1d72d8"},
	{"name": "Şehir Gündemi", "handle": "sehirgundemi", "color": "2a9d8f"},
]
const OFFICIAL := {"name": "Metro İşletmesi", "handle": "metro_resmi", "color": "ffb703"}

## Recurring characters. They post in their own voice when something they care about
## happens; tap their avatar in Cıvıltı to open their profile.
const CAST := {
	"nuri": {"name": "Nuri Aksoy", "handle": "vatman_nuri", "followers": 18400,
		"bio": ["Emekli vatman. 1978'den 2018'e Kabataş–Zeytinburnu. Ray sesini hâlâ duyarım.", "Retired tram driver, 1978 to 2018. I can still hear the rails."],
		"look": {"skin": 1, "hair": 0, "hair_col": 5, "beard": 1, "hat": "driver", "uniform": true, "shirt": "1d3566", "bg": "f3ebdd", "age": 2, "smile": true},
		"lines": {
			"line_open": [["yeni hatta bindim. 1978'de ilk tramvayımı sürdüğüm gün de böyle heyecanlanmıştım", "rode the new line. felt the same as the day i drove my first tram in 1978", 0.8]],
			"inc_breakdown": [["arıza olur evlat. ama bakım yapılmazsa daha çok olur, ben söylemiş olayım", "breakdowns happen, kid. skip maintenance and they happen more, mark my words", -0.4]],
			"vehicles_added": [["sefer sıklığı her şeydir. yolcu beklemeyi sevmez, kırk yıldır öyle", "frequency is everything. riders hate waiting, always have", 0.6]],
			"modernized": [["yeni trenler güzel olmuş. eskilerin kokusunu özleyeceğim ama", "the new trains are lovely. i'll miss the smell of the old ones though", 0.6]],
			"crowded": [["bu kalabalık benim zamanımda da vardı. çaresi belli: daha çok sefer", "we had crowds like this in my day too. the cure is simple: more trains", -0.4]],
			"ev_snow": [["kar yağınca gece üçte kalkıp makas temizlerdik. metro bu dertten kurtarıyor", "when it snowed we got up at 3am to clear the switches. the metro spares you that", 0.3]],
		}},
	"riza": {"name": "Rıza Kalkan", "handle": "rizaabi_taksi", "followers": 2300,
		"bio": ["30 yıllık taksici. Metroya karşıyım, ama bazen biniyorum. Kimseye söylemeyin.", "Cab driver for 30 years. Against the metro, but i ride it sometimes. Don't tell anyone."],
		"look": {"skin": 2, "hair": 1, "hair_col": 4, "beard": 1, "hat": "kasket", "shirt": "3d4b5c", "bg": "dfe8f1", "age": 1, "smile": false},
		"lines": {
			"line_open": [["metro açılmış, müşteri kalmadı. ben de bindim bari, fena değilmiş. kimseye söylemeyin", "the metro opened and my fares vanished. rode it myself. not bad. don't tell anyone", 0.2]],
			"fare_up": [["bilete zam gelmiş, millet taksiye döner dedim. dönmedi", "fares went up, i said people would come back to cabs. they didn't", -0.3]],
			"ev_bridge_traffic": [["köprüde iki saat. taksimetre çalışıyor, müşteri ağlıyor, ben ağlıyorum", "two hours on the bridge. meter running, passenger crying, me crying", -0.5]],
			"ev_derby": [["derbi günü stada taksi istemeyin. ben bile metroyla gidiyorum", "don't call a cab to the stadium on derby day. even i take the metro", 0.2]],
			"no_network": [["bu şehre metro yapılmaz, yapılsa da kimse binmez. 30 yıllık şoförüm, bilirim", "this city will never get a metro, and nobody would ride it anyway. 30 years behind the wheel, i know", -0.3]],
		}},
	"hatice": {"name": "Hatice Yurt", "handle": "haticeteyze56", "followers": 960,
		"bio": ["Emekli öğretmen, dört torun. Pazar günleri börek, salı günleri pazar.", "Retired teacher, four grandkids. Börek on Sundays, market on Tuesdays."],
		"look": {"skin": 0, "hair": 5, "scarf_col": "8e6bb0", "glasses": true, "shirt": "2f6b4f", "bg": "f0dfd2", "age": 2, "smile": true},
		"lines": {
			"crowded": [["pazara giderken kimse yer vermedi. gençler telefona bakıyor, ben poşetlere", "nobody gave me a seat on the way to the market. kids staring at phones, me at my shopping bags", -0.6]],
			"dlg_accessibility_1": [["istasyonlara asansör geliyormuş. dizlerim size dua ediyor", "lifts are coming to the stations. my knees are praying for you", 0.9]],
			"fare_up": [["emekli maaşıyla bilete zam. torunlara harçlık kalmadı", "a fare hike on a pension. nothing left for the grandkids' pocket money", -0.8]],
			"chatter_pos": [["metroyla torunlara gittim, kırk dakikada vardım. eskiden bütün günüm giderdi", "went to see the grandkids by metro, forty minutes. used to take my whole day", 0.8]],
			"line_extend": [["metro bizim mahalleye de gelmiş. komşular sevinçten börek yaptı", "the metro reached our street. the neighbours made börek to celebrate", 0.9]],
		}},
	"selin": {"name": "Selin Ekinci", "handle": "selin.okulda", "followers": 5100,
		"bio": ["Şehir planlama 3. sınıf. Kahve, harita, gecikmeli tren. Fikirlerim bana ait.", "Urban planning, third year. Coffee, maps, late trains. Opinions my own."],
		"look": {"skin": 4, "hair": 4, "hair_col": 1, "glasses": true, "shirt": "c47a1f", "bg": "ece2f0", "age": 0, "smile": true},
		"lines": {
			"poi_university": [["kampüse metro geldi. derse geç kalmak için yeni bahane bulmam lazım", "the metro reached campus. now i need a new excuse for being late", 0.8]],
			"ev_university": [["okullar açıldı, kampüs hattı yürüyen yurt gibi", "term started, the campus line is a dormitory on wheels", 0.1]],
			"fare_up": [["öğrenci bileti zamlanmış. fotokopi pahalı, metro pahalı. yürüyorum", "student fares went up. photocopies are expensive, the metro is expensive. i'm walking", -0.7]],
			"fare_down": [["bilet ucuzladı. bu ay bir simit fazla", "fares went down. one more simit this month", 0.8]],
			"long_wait": [["{line} {n} dakikada bir. dönem ödevimi bu bekleme süreleri üzerine yazıyorum", "{line} every {n} minutes. i'm writing my term paper about these waits", -0.5]],
			"hub_open": [["{station} aktarma merkezi olmuş. hocam derste örnek gösterdi, ben de gidip gördüm", "{station} became a real interchange. our lecturer used it as an example, i went to see it", 0.8]],
		}},
	"kemal": {"name": "Kemal Sargın", "handle": "kemalsargin_meclis", "followers": 31200,
		"bio": ["Belediye meclis üyesi (muhalefet). Ulaşım komisyonu. Rakamlar yalan söylemez.", "City councillor (opposition), transport committee. Numbers don't lie."],
		"look": {"skin": 0, "hair": 1, "hair_col": 5, "glasses": true, "shirt": "14233d", "bg": "dfe8f1", "age": 1, "smile": false},
		"lines": {
			"debt": [["Ulaşım işletmesi borç batağında. Meclise soru önergesi verdik.", "The transit operator is drowning in debt. We have filed a question in council.", -0.8]],
			"year_bad": [["Rakamlar ortada: işletme zarar ediyor. Hesabını soracağız.", "The numbers are clear: the operator is losing money. We will hold them to account.", -0.7]],
			"con_overrun": [["{line} yine gecikti, yine pahalandı. Planlama nerede?", "{line} is late again and over budget again. Where is the planning?", -0.7]],
			"re_fail": [["{event} tam bir rezalet. Ulaşım planı yoktu, vatandaş yolda kaldı.", "{event} was a disgrace. There was no transit plan and people were stranded.", -0.9]],
			"elec_poll": [["Anketler değişimin geldiğini gösteriyor. Sandıkta görüşürüz.", "The polls show change is coming. See you at the ballot box.", -0.4]],
			"line_open": [["{line} açıldı, güzel. Ama seçim öncesi açılış yapmak kolay, bakımı zor.", "{line} is open, fine. But opening lines before an election is easy; maintaining them isn't.", 0.0]],
		}},
}

const JOBS := [["muhasebeci", "accountant"], ["hemşire", "nurse"], ["öğrenci", "student"], ["esnaf", "shopkeeper"], ["yazılımcı", "developer"], ["emekli", "retired"], ["garson", "waiter"], ["öğretmen", "teacher"], ["mimar", "architect"], ["kurye", "courier"], ["berber", "barber"], ["avukat", "lawyer"]]
const QUIRKS := [["kedisi var", "has a cat"], ["sabah koşucusu", "morning runner"], ["çay bağımlısı", "tea addict"], ["vapur fotoğrafçısı", "ferry photographer"], ["derbi kaçırmaz", "never misses a derby"], ["bisiklet sever", "loves cycling"], ["kitap kurdu", "bookworm"], ["dolmuş nostaljisi", "misses the dolmuş"]]

const T := {
	# Voice guide: citizens write like real Turkish Twitter (lowercase, short, ironic, local);
	# news accounts use plain headline style; the operator writes like a corporate account.
	# Emoji are rare on purpose.
	"line_open": [
		["{line} açılmış. {a:dan} {b:a} 20 dakika. bunu da mı görecektik", "{line} is open. {a} to {b} in 20 minutes. never thought i'd see the day", 0.9],
		["ilk sefere bindim, vagon hâlâ yeni araba gibi kokuyor #{line}", "took the first train, the carriage still has that new car smell #{line}", 0.8],
		["{a:dan} {b:a} trafiğe girmeden gittim, annemi aradım anlattım", "got from {a} to {b} without traffic, called my mum to tell her", 0.9],
		["{st} durağı tam evin önüne çıkmış, kira artacak kesin", "{st} stop opened right outside my place. rent's going up, guaranteed", 0.4],
		["güzel de bizim mahalleye ne zaman? #{hood}", "nice, but when is it coming to us? #{hood}", -0.2],
		["açılışta çay dağıttılar. çay iyiydi, tren de fena değil", "they handed out tea at the opening. tea was good, train's not bad either", 0.7],
		["50 dakikalık yolum 20 dakika oldu. sabah 30 dakika fazla uyuyorum artık", "my 50 minute commute is 20 now. that's 30 more minutes of sleep", 1.0],
		["haritaya bir renk daha eklendi. {line} hayırlı olsun", "one more colour on the map. welcome {line}", 0.7],
	],
	"open_metro": [
		["metro gibisi yok. {a}–{b} arası kitabın iki bölümü kadar", "nothing beats the metro. {a}–{b} is two chapters of a book", 0.9],
		["{line} o kadar derinde ki yürüyen merdivende telefonun şarjı bitiyor", "{line} is so deep your phone dies on the escalator", 0.3],
	],
	"open_ferry": [
		["vapur, çay, simit. martıya simidin yarısını kaptırdım ama olsun #{line}", "ferry, tea, simit. lost half the simit to a gull but whatever #{line}", 1.0],
		["{a} iskelesinde gün batımı bedava, bilet ücretli", "the sunset at {a} pier is free, the ticket isn't", 0.8],
		["işe vapurla gidiyorum diye herkes kıskanıyor, haklılar", "everyone's jealous i commute by ferry. they're right to be", 0.9],
	],
	"open_funicular": [
		["yokuşu füniküler çıkıyor artık. dizlerim emekliye ayrıldı", "the funicular does the hill now. my knees have retired", 0.9],
		["füniküler 2 dakikada tepede. turistler fotoğraf çekmekten binmeye fırsat bulamıyor", "funicular gets you up in 2 minutes. tourists are too busy taking photos to board", 0.7],
	],
	"open_tram": [
		["tramvayın zil sesi şehre yakışmış", "the tram bell suits this city", 0.8],
		["{line} geldi, araba şeridi gitti. trafikte bekleyenler mutsuz", "{line} arrived, the car lane left. drivers are not amused", -0.3],
	],
	"open_metrobus": [
		["metrobüs hızlı ama sabah 8'de içinde ayakta uyuyan adamlar gördüm", "the busway is fast, but at 8am i saw people asleep standing up", 0.2],
		["{line} yolu ikiye böldü. ucuz çözüm ama işe yarıyor", "{line} split the road in two. cheap fix, but it works", 0.5],
	],
	"open_rail": [
		["banliyöyle {a:dan} merkeze 15 dakika. saatime bakıp güldüm", "commuter rail from {a} to the centre in 15 minutes. checked my watch and laughed", 0.9],
		["{line} trenleri o kadar dakik ki yetişemeyen ben oldum", "{line} trains are so punctual that i'm the one who's late now", 0.8],
	],
	"line_extend": [
		["{line} uzadı, {st} durağına da gidiyor artık", "{line} got longer, it goes to {st} now", 0.8],
		["uzatma açıldı, {st} tarafı bayram ediyor #{hood}", "the extension is open, {st} is celebrating #{hood}", 0.8],
		["{line} uzadı, trenler aynı. tahmin edin ne oldu", "{line} got longer, same number of trains. guess what happened", -0.1],
	],
	"crowded": [
		["{line} sabah sardalya konservesi. kapı kapanırken nefesimi tuttum", "{line} in the morning is a sardine can. held my breath while the doors closed", -0.9],
		["üç tren kaçırdım, {st:da} bekliyorum hâlâ @metro_resmi ek sefer diye bir şey var", "missed three trains, still at {st} @metro_resmi have you heard of extra trains", -0.8],
		["{line:da} oturacak yer bulmak piyangodan zor", "getting a seat on {line} is harder than winning the lottery", -0.7],
		["sabah {line:a} binmek kardiyo yerine geçiyor", "riding {line} in the morning counts as cardio", -0.7],
		["{line} kapasite sorununu çözecek misiniz yoksa alışalım mı @metro_resmi", "@metro_resmi are you fixing {line}'s capacity or should we just get used to it", -0.8],
	],
	"long_wait": [
		["{line} {n} dakikada bir geliyor. bu metro değil dolmuş", "{line} comes every {n} minutes. that's not a metro, that's a minibus", -0.7],
		["{st:da} {n} dakika bekledim, yürüsem varmıştım", "waited {n} minutes at {st}, would've been there on foot", -0.6],
		["sefer sıklığı lütfen. #{line}", "more frequent trains please. #{line}", -0.6],
	],
	"vehicles_added": [
		["{line:a} ek sefer koymuşlar, bugün oturarak gittim. tarihî gün", "they added trains to {line}, sat down today. historic day", 0.8],
		["şikâyet edince oluyormuş demek. {line} daha sık geliyor", "so complaining works. {line} runs more often now", 0.7],
	],
	"official_vehicles": [
		["{line} hattına yeni araçlar eklenmiş, sefer sıklığı artırılmıştır. İyi yolculuklar dileriz.", "New vehicles have been added to line {line} and service frequency increased. Have a pleasant journey.", 0.5],
	],
	"official_open": [
		["{line} ({mode}) hattı {a} – {b} arasında hizmete açılmıştır. Hayırlı olsun.", "Line {line} ({mode}) between {a} and {b} is now in service.", 0.5],
	],
	"line_removed": [
		["{line} kapatılmış. işe nasıl gideceğim şimdi, yüzerek mi", "they closed {line}. how am i supposed to get to work, swim?", -1.0],
		["{line} için harcanan paraya yazık. #{line}", "all that money spent on {line}, gone. #{line}", -0.8],
	],
	"poi_airport": [
		["havalimanına metroyla gittim, taksiye verdiğim parayla döner yedim", "took the metro to the airport, spent the taxi money on a döner instead #{poitag}", 0.9],
		["valizle {poi:a} raylı sistemle gitmek. medeniyet bu", "going to {poi} by rail with a suitcase. this is civilisation", 0.8],
	],
	"poi_university": [
		["{poi} öğrencisi olarak söylüyorum: 9 dersine artık yetişiyoruz. yetişmek istersek", "speaking as a {poi} student: we can make the 9am lecture now. if we want to", 0.9],
		["yurttan derse 10 dakika. bahanem kalmadı #{poitag}", "dorm to class in 10 minutes. i'm out of excuses #{poitag}", 0.8],
	],
	"goal": [
		["{city} raylı sistemi yeni bir eşiği geçti: {n}", "{city} rail network passes a new milestone: {n}", 0.6],
	],
	"year_good": [
		["{year} bilançosu: raylı sistem günde {n} yolcu taşıdı.", "{year} results: the rail network carried {n} riders a day.", 0.7],
		["Uzmanlar {city} ulaşım yatırımlarını başarılı buldu.", "Experts call {city}'s transit investments a success.", 0.6],
	],
	"year_bad": [
		["{year} bilançosu: ulaşım işletmesi zarar açıkladı, meclis açıklama istiyor.", "{year} results: the transit operator posts a loss, the council wants answers.", -0.6],
		["Ulaşım işletmesinin borcu büyüyor. Uzmanlar uyarıyor.", "The transit operator's debt keeps growing, experts warn.", -0.5],
	],
	"debt": [
		["Ulaşım işletmesi kredi limitini aştı. Maaş ödemelerinin gecikmesinden endişe ediliyor.", "The transit operator has exceeded its credit limit. Wage payments may be delayed.", -0.8],
	],
	"chatter_pos": [
		["{st} durağı tertemiz. kim temizliyorsa eline sağlık", "{st} station is spotless. whoever cleans it, thank you", 0.7],
		["arabayı sattım. bir yıl oldu, özlemedim", "sold the car. it's been a year, don't miss it", 0.9],
		["{line:da} kitap bitirdim. trafikte direksiyon başında bitiremezdim", "finished a book on {line}. couldn't do that stuck behind a wheel", 0.7],
		["{city} ulaşımına söylenip duruyorum ama itiraf edeyim, düzeliyor", "i complain about {city} transit a lot, but okay, it's getting better", 0.8],
		["{st:da} biri saz çalıyordu, iki tren kaçırdım dinlemek için", "someone was playing the saz at {st}, missed two trains listening", 0.6],
	],
	"chatter_neg": [
		["{hood:a} hâlâ raylı sistem yok. haritada var mıyız biz #{hood}", "still no rail in {hood}. are we even on the map #{hood}", -0.7],
		["aktarma için 10 dakika yürüdüm. bunu çizen hiç aktarma yapmamış", "walked 10 minutes to change lines. whoever designed this never transferred", -0.5],
		["{line:da} klima yine çalışmıyor. ağustosta sauna bedava", "the AC on {line} is broken again. free sauna in august", -0.5],
		["durağa 20 dakika yürü, sonra bekle. ben yine arabayla gideyim", "walk 20 minutes to the stop, then wait. i'll just drive", -0.6],
	],
	"no_network": [
		["{city:da} trafik çekilmez halde. raylı sistem diye bir şey duymuş muyduk", "traffic in {city} is unbearable. weren't we promised rail at some point", -0.6],
		["yeni ulaşım planlamacısı göreve başlamış. bakalım, umudumuz var", "a new transit planner just started. we'll see, we're hopeful", 0.2],
	],
	"archaeology": [
		["{line} kazısında tarihî buluntu çıktı, çalışmalar yavaşladı.", "Historic finds unearthed during {line} works; construction slowed.", 0.1],
		["metro kazısında bizans gemisi çıkmış. bu şehirde nereye kazsan tarih", "they found a byzantine ship digging the metro. dig anywhere in this city and it's history", 0.6],
		["arkeoloji güzel de {line} ne zaman bitecek, torunlarım mı binecek", "archaeology is lovely but when will {line} be done, will my grandkids ride it", -0.4],
	],
	"ev_bridge_traffic": [
		["köprü kilit. 2 saattir aynı yerdeyim, radyoda aynı şarkı üçüncü kez çalıyor", "bridge is gridlocked. same spot for 2 hours, same song on the radio for the third time", -0.4],
		["Köprü trafiği durma noktasında. Sürücülere raylı sistemi kullanmaları öneriliyor.", "Bridge traffic at a standstill. Drivers are advised to use rail.", -0.2],
	],
	"ev_derby": [
		["derbi günü. stada giden her yol kırmızı, metroda formalar", "derby day. every road to the stadium is red, the metro is full of shirts", 0.4],
		["maç çıkışı istasyon tıklım tıklım ama şarkı söyleyerek bekliyoruz en azından", "the station's packed after the match but at least we're singing while we wait", 0.3],
	],
	"ev_rain": [
		["yağmur başladı, yollar göl. metro hayat kurtarıyor", "it's pouring, roads are lakes. the metro is a lifesaver", 0.3],
		["şemsiyeyi evde unuttum, durağa kadar duş aldım", "forgot my umbrella, showered on the way to the stop", -0.2],
	],
	"ev_snow": [
		["kar yağdı, otobüs yolda kaldı, metro tıkır tıkır. bir kere de olsa haklı çıktık", "it snowed, buses got stuck, the metro ran fine. vindicated for once", 0.1],
		["ayaz bastırdı, durakta dondum. kulaklarım hâlâ yok", "it's freezing, i froze at the stop. still can't feel my ears", -0.4],
		["kızılay'da kartopu savaşı. sonra metroya inip ısındık", "snowball fight in kızılay. then we warmed up in the metro", 0.5],
	],
	"ev_concert": [
		["bu akşam konser var. dönüşte ek sefer olursa çok iyi olur, olmazsa yürürüz", "concert tonight. extra trains home would be great, otherwise we walk", 0.3],
	],
	"ev_imbat": [
		["imbat başladı. kordon'da vapur beklemek dünyanın en iyi işi", "the imbat breeze is here. waiting for the ferry on the kordon is the best job in the world", 0.8],
	],
	"ev_fair": [
		["Enternasyonal Fuar kapılarını açtı. Kültürpark'a raylı sistemle gelinmesi öneriliyor.", "The International Fair opens. Visitors are advised to reach Kültürpark by rail.", 0.7],
	],
	"ev_university": [
		["okullar açıldı. kampüs hattında yürümeye yer yok, nefes almaya da", "term started. no room to walk on the campus line, or breathe", 0.1],
	],
	"ev_summer": [
		["yaz geldi. sahil vapurları turist dolu, biz yerliler ayakta", "summer's here. coastal ferries full of tourists, us locals standing", 0.5],
	],
	"tech_official": [
		["{tech} sistemi tüm hatlarımızda kullanıma alınmıştır.", "{tech} is now in use across all our lines.", 0.6],
	],
	"tech_citizen": [
		["{tech} gelmiş, gerçekten fark ediyor", "{tech} is here and it actually makes a difference", 0.7],
		["{tech} güzel de bilete zam gelmesin yeter", "{tech} is nice, just don't raise the fare", 0.1],
	],
	"fare_up": [
		["bilete yine zam. maaş aynı, metro lüks oldu #zam", "another fare hike. same salary, the metro is a luxury now #farehike", -0.9],
		["bu fiyata arabayla gitmek mantıklı gelmeye başladı, bunu ben söylüyorum", "at this price driving starts to make sense, and i'm the one saying it", -0.7],
	],
	"fare_down": [
		["bilet ucuzladı. ilk kez bir zam haberi tersine döndü", "fares went down. first time a price story went the other way", 0.9],
		["ucuz bilet, daha çok yolcu. doğru karar", "cheaper fares, more riders. right call", 0.7],
	],
	"inc_breakdown": [
		["{line:da} arıza var, trenler yarım kapasite. sabah sabah", "breakdown on {line}, trains at half capacity. first thing in the morning", -0.7],
		["{line} yine arızalı, işe geç kaldım. bakım yapılıyor mu gerçekten @metro_resmi", "{line} broke down again, late for work. @metro_resmi is anyone doing maintenance", -0.8],
	],
	"inc_strike": [
		["{line} çalışanları grevde, seferler yapılmıyor.", "{line} staff are on strike; no service today.", -0.6],
		["çalışanlar haklı ama {line} olmadan şehir felç", "the workers have a point but without {line} the city's paralysed", -0.5],
	],
	"inc_flood": [
		["{line} tünelini su bastı, hat geçici olarak kapatıldı.", "{line} tunnel flooded; the line is temporarily closed.", -0.7],
	],
	"inc_fixed": [
		["{line} hattındaki arıza giderilmiş, seferler normale dönmüştür. Anlayışınız için teşekkür ederiz.", "The fault on line {line} has been fixed and service is back to normal. Thank you for your patience.", 0.5],
	],
	"quake_minor": [
		["Deprem hissedildi. Güçlendirilmiş tünellerde hasar tespit edilmedi, seferler sürüyor.", "An earthquake was felt. No damage found in the reinforced tunnels; service continues.", 0.6],
	],
	"quake_major": [
		["Deprem sonrası bazı metro hatları kontrol için kapatıldı. Hasar tespiti sürüyor.", "After the earthquake some metro lines were closed for inspection. Damage assessment is under way.", -0.6],
	],
	"mission_ok": [
		["Ulaşım işletmesi hedefini zamanında tutturdu.", "The transit operator hit its target on time.", 0.7],
	],
	"mission_fail": [
		["Ulaşım işletmesi verdiği hedefi tutturamadı. Meclis açıklama bekliyor.", "The transit operator missed its target. The council awaits an explanation.", -0.6],
	],
	"dlg_union_wage_1": [["ulaşım çalışanlarına zam gelmiş. sabah 5'te ilk treni kaldıranlar hak ediyor", "transit workers got a raise. the people running the 5am train deserve it", 0.6]],
	"dlg_union_wage_3": [["Sendika ile müzakereler sonuçsuz kaldı. Grev ihtimali gündemde.", "Talks with the union broke down. A strike is on the table.", -0.6]],
	"dlg_sponsor_station_1": [["{station} durağına marka adı vermişler. sırada ne var, vagonlara reklam şarkısı mı", "{station} now has a brand name. what's next, jingles in the carriages", -0.4]],
	"dlg_fare_cut_1": [["bilet indirimi gelmiş. cüzdan bu ay biraz nefes aldı", "fare cut. my wallet can breathe a little this month", 0.9]],
	"dlg_fare_cut_2": [["bilet indirimi talebi reddedilmiş. öğrenciyiz, emekliyiz, ne yapalım", "the fare cut was rejected. we're students and pensioners, what are we supposed to do", -0.6]],
	"dlg_accessibility_1": [["tüm istasyonlara asansör geliyor. annem tekerlekli sandalyeyle tek başına gezebilecek", "every station is getting lifts. my mum will be able to get around on her own in her wheelchair", 0.9]],
	"dlg_night_event_1": [["konser çıkışı gece seferi vardı. kim düşündüyse sağ olsun", "there were night trains after the concert. whoever thought of it, thank you", 0.8]],
	"dlg_night_event_2": [["konserden sonra eve taksiye servet verdim. gece seferi yok tabii", "paid a fortune for a taxi after the concert. no night trains, of course", -0.7]],
	"dlg_press_2": [["Gazete manşeti: 'Raylı sistemde kalabalık skandalı.'", "Headline: 'Crowding scandal on the rail network.'", -0.7]],
	"dlg_seismic_1": [["Tüneller depreme karşı güçlendiriliyor.", "Tunnels are being reinforced against earthquakes.", 0.8]],
	"flavor_istanbul": [
		["martılar yine vapurun peşinde. simit atan teyzeye selam", "the gulls are chasing the ferry again. respect to the auntie throwing simit", 0.7],
		["boğaz'ın altından 4 dakikada karşıya geçiyorum, hâlâ alışamadım", "crossing under the bosphorus in 4 minutes, still not used to it", 0.8],
		["kadıköy vapurunda çay 3 dakikada soğuyor, yolculuk 20 dakika. matematik tutmuyor", "tea on the kadıköy ferry goes cold in 3 minutes, the trip takes 20. the maths doesn't work", 0.5],
		["avrupa yakasında iş, anadolu yakasında ev. hayatım köprüde geçti", "job on the european side, home on the asian side. i've spent my life on bridges", -0.3],
	],
	"flavor_ankara": [
		["ankara ayazında metroya inmek hamama girmek gibi", "going down into the metro in ankara's frost is like walking into a hamam", 0.4],
		["'güvenpark'ta buluşalım' diyen kişi kaybolmayı göze almış demektir", "anyone who says 'meet at güvenpark' is ready to never be found", 0.5],
		["ankara'da deniz yok ama dikmen vadisi var, idare ediyoruz", "no sea in ankara but we have dikmen valley, we make do", 0.3],
	],
	"flavor_izmir": [
		["boyoz, gevrek, vapur. izmir sabahı bu kadar", "boyoz, gevrek, ferry. that's an izmir morning", 0.9],
		["kordon'da gün batımı, sonra metroyla eve. başka şehirde yaşayanlara üzülüyorum", "sunset on the kordon, then home by metro. i feel sorry for people in other cities", 0.9],
		["kuş cenneti'nde flamingolar gelmiş. pembe pembe", "the flamingos are back at the bird sanctuary. so pink", 0.8],
		["gevrek mi simit mi tartışmasına metroda da girdik, iki durak sürdü", "we got into the gevrek vs simit argument on the metro, lasted two stops", 0.4],
	],
	"flavor_eskisehir": [
		["porsuk'ta gondol, sonra tramvayla eve. eskişehir yaşanır şehir", "a gondola on the porsuk, then the tram home. eskişehir is a liveable city", 0.9],
		["öğrenci şehri: tramvay hep dolu, ama dolu olunca da güzel", "student city: the tram's always full, but in a nice way", 0.5],
		["odunpazarı'nın renkli evleri durağın yanında, turistler oradan ayrılmıyor", "odunpazarı's coloured houses are next to the stop, tourists never leave", 0.7],
	],
	"flavor_antalya": [
		["plaja raylıyla gittim, park yeri aramadım. yazın en iyi kararı", "went to the beach by rail, no parking hunt. best decision of the summer", 0.9],
		["yazın turist, kışın biz. aynı şehir iki farklı yer", "tourists in summer, us in winter. same city, two places", 0.4],
		["kaleiçi'nde gün batımı, sonra tramvayla lara. başka bir şey istemiyorum", "sunset in kaleiçi, then the tram to lara. i need nothing else", 0.8],
	],
	"flavor_bursa": [
		["teleferikle uludağ, inince iskender. bursa'da pazar böyle geçer", "gondola up uludağ, iskender when you're down. that's a sunday in bursa", 0.9],
		["osb vardiya çıkışı metro tıklım tıklım. ek sefer şart", "the metro is packed when the factory shift ends. we need more trains", -0.5],
		["yeşil bursa'da arabasız yaşanıyormuş, kimse söylememişti", "turns out you can live car-free in green bursa, nobody told me", 0.8],
	],
	"flavor_trabzon": [
		["boztepe'de çay, aşağıda şehir. manzara anlatılmaz #trabzon", "tea up on boztepe, the city below. can't describe the view #trabzon", 0.9],
		["sahil yolu tek, trafik bitmez. raylı sistem şart", "one coastal road, endless traffic. we need rail", -0.5],
		["hamsi mevsimi açıldı, herkes meydanda", "anchovy season's open, everyone's in the square", 0.7],
	],
	"con_start": [
		["{line} inşaatı başladı. Açılışın {n} ay sonra yapılması planlanıyor.", "Construction of {line} has begun. Opening is planned in {n} months.", 0.4],
		["mahalleye {line} geliyor ama önce toz geliyor. üç yıl toz", "{line} is coming to the neighbourhood, but first comes the dust. three years of dust", -0.2],
	],
	"con_overrun": [
		["{line} inşaatında maliyet aşımı: açılış {n} ay gecikecek.", "Cost overrun on {line}: opening delayed by {n} months.", -0.6],
	],
	"modernized": [
		["{line} yenilenmiş. trenler yeni, koltuklar yeni, kalabalık aynı", "{line} has been renewed. new trains, new seats, same crowds", 0.8],
	],
	"hub_open": [
		["{station} aktarma merkezi olmuş. aktarma 2 dakika, merdiven yok", "{station} is a proper interchange now. 2 minute transfers, no stairs", 0.8],
	],
	"rival": [
		["Yeni bir araç paylaşım uygulaması şehirde hizmete başladı.", "A new ride-hailing app has launched in the city.", -0.2],
	],
	"express": [
		["{line} ekspresi şehrin bir ucundan öbürüne yarım saatte götürüyor", "the {line} express gets you across the city in half an hour", 0.7],
		["ekspres benim durağımda durmuyor artık. ben de ekspres gibi geçiyorum yanından", "the express doesn't stop at my station anymore. so i express-walk past it", -0.6],
	],
	# ------------------------------------------------ real dated events
	"re_announce": [
		["{event} {n} ay sonra şehrimizde. Binlerce ziyaretçi bekleniyor, ulaşım planı merak konusu.", "{event} comes to the city in {n} months. Thousands of visitors are expected; all eyes on the transit plan.", 0.2],
		["{event} için geri sayım başladı: {n} ay.", "Countdown to {event} has begun: {n} months.", 0.1],
	],
	"re_reminder": [
		["{event} için {n} ay kaldı, etkinlik alanına hâlâ raylı bağlantı yok.", "{event} is {n} months away and the venue still has no rail link.", -0.6],
		["{event} kapıda ama alana nasıl gidilecek, kimse bilmiyor. {n} ay var", "{event} is almost here and nobody knows how to get to the venue. {n} months left", -0.5],
	],
	"re_ok": [
		["{event} için trenle geldim, kapının önünde indim. böyle organizasyon görmedim", "came to {event} by train, got off at the gate. never seen it run this smoothly", 0.95],
		["yabancı misafirler metroyu çok sevdi. iyi ki yapılmış", "the foreign guests loved the metro. glad it was built", 0.9],
	],
	"re_ok_news": [
		["{event} sorunsuz geçti: raylı sistem rekor yolcu taşıdı.", "{event} went off without a hitch: rail carried record crowds.", 0.8],
	],
	"re_fail": [
		["{event} yüzünden 3 saat trafikte kaldım. raylı sistem? yok", "stuck in traffic 3 hours because of {event}. rail? there is none", -0.95],
		["dünya bizi izliyor, biz otobüs kuyruğundayız", "the whole world is watching and we're in the bus queue", -0.9],
	],
	"re_fail_news": [
		["{event} ulaşım krizine dönüştü: etkinlik alanına raylı bağlantı yoktu.", "{event} turned into a transit crisis: there was no rail link to the venue.", -0.8],
	],
	"re_covid": [
		["Salgın nedeniyle toplu taşımada yolcu sayısı sert düştü. Maske ve mesafe kuralları yürürlükte.", "Ridership collapses as the pandemic hits. Masks and distancing are mandatory on transit.", -0.4],
	],
	"re_izm_quake": [
		["İzmir'de 6,6 büyüklüğünde deprem. Raylı sistem hatlarında hasar tespiti sürüyor.", "A magnitude 6.6 earthquake hits İzmir. Rail lines are being inspected for damage.", -0.5],
	],
	"re_ist_marathon": [
		["İstanbul Maratonu bugün: köprü araç trafiğine kapalı.", "Istanbul Marathon today: the bridge is closed to cars.", 0.3],
	],
	"re_ist_ecoc": [
		["İstanbul 2010 Avrupa Kültür Başkenti oldu. Yıl boyu sergi, konser ve festival programı açıklandı.", "Istanbul is the 2010 European Capital of Culture. A year of exhibitions, concerts and festivals is announced.", 0.7],
	],
	"re_ist_ucl": [
		["Avrupa kupası finali İstanbul'da. 70 bin taraftar Olimpiyat Stadı'na gidiyor.", "The European cup final is in Istanbul. 70,000 fans head to the Olympic Stadium.", 0.4],
	],
	"re_ank_centenary": [
		["Cumhuriyet'in 100. yılı. Kızılay'da kutlamalar, akşam havai fişek gösterisi var.", "The Republic turns 100. Celebrations in Kızılay, with fireworks tonight.", 0.8],
	],
	"re_ank_nato": [
		["NATO Zirvesi başladı. Söğütözü çevresinde geniş güvenlik önlemi, birçok yol kapalı.", "The NATO Summit opens. Tight security around Söğütözü; many roads closed.", 0.1],
	],
	"re_ant_cop31": [
		["COP31 İklim Zirvesi Antalya'da başladı. Delegeler toplu taşımaya yönlendiriliyor.", "The COP31 climate summit opens in Antalya. Delegates are directed to public transport.", 0.4],
	],
	"re_ant_g20": [
		["G20 Liderler Zirvesi Antalya'da. Yollar kapalı, şehir alarmda.", "The G20 Leaders' Summit is in Antalya. Roads closed, the city on alert.", 0.0],
	],
	"re_ant_expo": [
		["EXPO 2016 Antalya kapılarını açtı.", "EXPO 2016 Antalya opens its gates.", 0.6],
	],
	"re_trb_eyof": [
		["Avrupa Gençlik Olimpiyat Festivali Trabzon'da başladı.", "The European Youth Olympic Festival opens in Trabzon.", 0.6],
	],
	"re_esk_turkic": [
		["Eskişehir 2013 Türk Dünyası Kültür Başkenti. Odunpazarı'nda yıl boyu etkinlik var.", "Eskişehir is the 2013 Turkic World Capital of Culture, with events all year in Odunpazarı.", 0.6],
	],
	"re_bur_turkic": [
		["Bursa 2022 Türk Dünyası Kültür Başkenti oldu.", "Bursa is the 2022 Turkic World Capital of Culture.", 0.6],
	],
	# ------------------------------------------------ elections
	"elec_poll": [
		["ANKET: Seçime {m} ay kala ulaşım politikasına destek yüzde {n}.", "POLL: {m} months before the election, support for the transit policy stands at {n}%.", 0.0],
		["Son kamuoyu yoklaması: yüzde {n}. Seçime {m} ay var.", "Latest opinion poll: {n}%. {m} months to the election.", 0.0],
	],
	"elec_last": [
		["Seçime bir ay kaldı. Son ankette oy oranı yüzde {n}.", "One month to the election. Final poll: {n}%.", 0.0],
	],
	"elec_win": [
		["Seçim sonuçları: ulaşım politikası yüzde {n} oyla onay aldı.", "Election results: the transit agenda wins with {n}%.", 0.8],
	],
	"elec_win_cit": [
		["metroya oy verdik, metro kazandı", "we voted for the metro and the metro won", 0.9],
	],
	"elec_lose": [
		["Seçim sonuçları: seçmen ulaşım politikasını onaylamadı, oy oranı yüzde {n}'de kaldı.", "Election results: voters rejected the transit agenda, with just {n}%.", -0.9],
	],
	"elec_promise_lines": [
		["Seçime kadar iki yeni raylı sistem hattını hizmete açacağız.", "We will open two new rail lines before the election.", 0.4],
	],
	"elec_promise_riders": [
		["Seçime kadar toplu taşıma yolcu sayısını yüzde 30 artıracağız.", "We will grow public transport ridership by 30% before the election.", 0.4],
	],
	"elec_promise_sat": [
		["Seçime kadar yolcu memnuniyetini yüzde 70'in üzerine çıkaracağız.", "We will raise rider satisfaction above 70% before the election.", 0.4],
	],
}
