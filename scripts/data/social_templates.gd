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

const T := {
	"line_open": [
		["Nihayet! {line} hattı açıldı, {a} – {b} arası artık çok kolay 🎉 #{line}", "Finally! Line {line} is open, {a} – {b} is so easy now 🎉 #{line}", 0.9],
		["{line} ilk seferine bindim, tertemiz ve sessiz. Teşekkürler! #{city}Ulaşım", "Took the first {line} ride, clean and quiet. Thanks! #{city}Transit", 0.8],
		["{a:dan} {b:a} trafiğe takılmadan gitmek... rüya gibi. #{line}", "Getting from {a} to {b} without traffic... a dream. #{line}", 0.9],
		["Yeni {mode} hattı {line} hayırlı olsun! {st} durağı tam evimin önünde 😍", "Congrats on the new {mode} line {line}! {st} stop is right outside my home 😍", 0.85],
		["{line} açıldı ama bizim mahalleye ne zaman gelecek? #{hood}", "{line} opened, but when is it coming to our neighbourhood? #{hood}", -0.2],
		["Açılışta bedava çay dağıttılar, güzel jest ☕ #{line}", "They handed out free tea at the opening, nice touch ☕ #{line}", 0.7],
		["Haritaya yeni bir renk eklendi: {line}! Şehir değişiyor. #{city}", "A new colour on the map: {line}! The city is changing. #{city}", 0.7],
		["İşe gidiş 50 dakikadan 20 dakikaya indi. {line}, seni seviyorum ❤️", "My commute went from 50 to 20 minutes. {line}, I love you ❤️", 1.0],
	],
	"open_metro": [
		["Metro gibisi yok. {line} ile {a}–{b} arası dakikalar içinde 🚇", "Nothing beats the metro. {a}–{b} in minutes on {line} 🚇", 0.9],
		["{line} tüneli o kadar derinde ki yürüyen merdiven bitmek bilmedi 😅", "{line} is so deep the escalator never ends 😅", 0.3],
	],
	"open_ferry": [
		["Vapurda çay, simit ve martılar... {line} ile en güzel yolculuk ⛴️ #vapur", "Tea, simit and gulls on the ferry... the best commute with {line} ⛴️ #ferry", 1.0],
		["{a} iskelesinden gün batımı manzarası bedava 🌅 #{line}", "Free sunset view from {a} pier 🌅 #{line}", 0.9],
		["Martı simidimi kaptı ama yine de vapuru seviyorum 😂 #martı", "A gull stole my simit but I still love the ferry 😂 #gull", 0.6],
	],
	"open_funicular": [
		["{line} füniküleri sayesinde yokuşa veda! Dizlerim teşekkür ediyor 🙏", "Goodbye hill, thanks to {line} funicular! My knees thank you 🙏", 0.9],
		["Füniküler 2 dakikada tepeye çıkarıyor, turistler bayılacak", "The funicular climbs the hill in 2 minutes, tourists will love it", 0.7],
	],
	"open_tram": [
		["Tramvayın çan sesi şehre çok yakışmış 🔔 #{line}", "The tram bell really suits the city 🔔 #{line}", 0.8],
		["{line} tramvayı güzel ama araba şeridi daraldı, trafik arttı 😤", "{line} tram is nice but the car lane got narrower, more traffic 😤", -0.3],
	],
	"open_metrobus": [
		["Metrobüs hızlı ama kalabalığa hazır olun 😬 #{line}", "Metrobus is fast but brace for crowds 😬 #{line}", 0.2],
		["{line} metrobüsü yolu ikiye böldü, ucuz ama etkili çözüm", "The {line} busway split the road, cheap but effective", 0.5],
	],
	"open_rail": [
		["Banliyö treni {a:dan} merkeze 15 dakika! {line} harika 🚆", "Commuter rail from {a} to the centre in 15 minutes! {line} is great 🚆", 0.9],
		["{line} trenleri dakik, saatinizi ayarlayabilirsiniz ⏱️", "{line} trains are so punctual you can set your watch ⏱️", 0.8],
	],
	"line_extend": [
		["{line} uzadı, artık {st} durağına da gidiyor 🙌 #{line}", "{line} got longer, now reaching {st} 🙌 #{line}", 0.8],
		["Uzatma hattı açıldı, {st} sakinleri bayramda! #{hood}", "The extension opened, {st} residents are celebrating! #{hood}", 0.8],
		["{line} uzatması iyi ama trenler daha da doldu…", "The {line} extension is good but trains got even fuller…", -0.1],
	],
	"crowded": [
		["{line} sardalya konservesi gibi, nefes alamıyorum 🐟 #{line}", "{line} is like a sardine can, can't breathe 🐟 #{line}", -0.9],
		["Üç tren kaçırdım, {st:da} bekliyorum hâlâ. Ek sefer lütfen! @metro_resmi", "Missed three trains, still waiting at {st}. More trains please! @metro_resmi", -0.8],
		["{line:da} yer bulmak piyangodan zor #kalabalık", "Finding a seat on {line} is harder than winning the lottery #crowded", -0.7],
		["Sabah {line:a} binmek ekstrem spor gibi 😩", "Riding {line} in the morning is an extreme sport 😩", -0.7],
		["{line} kapasite sorununu ne zaman çözeceksiniz? @metro_resmi", "When will you fix {line}'s capacity problem? @metro_resmi", -0.8],
	],
	"long_wait": [
		["{line} sefer aralığı {n} dakika mı?! Bu ne biçim metro 🙄", "{line} runs every {n} minutes?! What kind of metro is this 🙄", -0.7],
		["{st} durağında {n} dakika bekledim, yürüsem daha hızlıydı", "Waited {n} minutes at {st}, walking would've been faster", -0.6],
		["Daha sık sefer istiyoruz! #{line} #seferArtsın", "We want more frequent service! #{line} #moreTrains", -0.6],
	],
	"vehicles_added": [
		["{line:a} ek sefer gelmiş, bugün oturarak gittim 🙏", "They added trains to {line}, got a seat today 🙏", 0.8],
		["Şikayetler işe yaradı, {line} artık daha sık geliyor 👏", "The complaints worked, {line} comes more often now 👏", 0.7],
	],
	"official_vehicles": [
		["{line} hattına yeni araçlar eklendi. Sefer sıklığı arttı. İyi yolculuklar!", "New vehicles added to line {line}. Service is more frequent now. Have a nice trip!", 0.5],
	],
	"official_open": [
		["{line} ({mode}) hattı {a} – {b} arasında hizmete açılmıştır. Hayırlı olsun! 🚦", "Line {line} ({mode}) between {a} and {b} is now in service. Enjoy! 🚦", 0.5],
	],
	"line_removed": [
		["{line} hattını kapattılar?! Şimdi nasıl işe gideceğim 😡", "They closed {line}?! How do I get to work now 😡", -1.0],
		["{line} kapandı, yatırım çöpe gitti. Yazık. #{line}", "{line} is closed, what a waste of investment. #{line}", -0.8],
	],
	"poi_airport": [
		["Havalimanına raylı sistemle gitmek çok rahat ✈️ #{poitag}", "Going to the airport by rail is so convenient ✈️ #{poitag}", 0.9],
		["Valizle {poi:a} metroyla gittim, taksiye para vermedim 💸", "Took the metro to {poi} with my suitcase, saved the taxi fare 💸", 0.8],
	],
	"poi_university": [
		["{poi} öğrencileri olarak teşekkürler, sabah derslerine yetişebiliyoruz 🎓", "As {poi} students, thanks — we can make morning classes now 🎓", 0.9],
		["Kampüse raylı sistem! Yurttan derse 10 dakika #{poitag}", "Rail to campus! Dorm to class in 10 minutes #{poitag}", 0.8],
	],
	"goal": [
		["SON DAKİKA: {city} raylı sistemi yeni bir hedefe ulaştı: {n}", "BREAKING: {city} rail network reached a new milestone: {n}", 0.6],
	],
	"year_good": [
		["{year} raporu: Günlük {n} yolcu! Raylı sistem rekor kırdı 📈", "{year} report: {n} daily riders! Rail sets a record 📈", 0.7],
		["Uzmanlar {city} ulaşım yatırımlarını örnek gösteriyor #{year}", "Experts praise {city}'s transit investments #{year}", 0.6],
	],
	"year_bad": [
		["{year} raporu: Raylı sistem zararda, muhalefet hesap soruyor", "{year} report: the rail operator lost money, critics demand answers", -0.6],
		["Ulaşım işletmesinin borcu büyüyor mu? Uzmanlar uyarıyor #{year}", "Is the transit operator's debt growing? Experts warn #{year}", -0.5],
	],
	"debt": [
		["Ulaşım işletmesi kredi limitini aştı, maaşlar gecikebilir 😟", "The transit operator went over its credit limit, wages may be delayed 😟", -0.8],
	],
	"chatter_pos": [
		["{st} durağı çok temiz ve aydınlık, emeği geçenlere teşekkürler ✨", "{st} station is so clean and bright, thanks to everyone involved ✨", 0.7],
		["Arabayı sattım, artık her yere {line} ile gidiyorum 🚇", "Sold my car, I go everywhere by {line} now 🚇", 0.9],
		["{line:da} kitabımı bitirdim, trafikte bunu yapamazdım 📚", "Finished my book on {line}, couldn't do that in traffic 📚", 0.7],
		["{city} ulaşımı her yıl daha iyi oluyor, gurur duyuyorum", "{city} transit gets better every year, proud of it", 0.8],
		["{st:da} sokak müzisyeni çalıyordu, yolculuk keyif oldu 🎸", "A busker was playing at {st}, made the trip a joy 🎸", 0.6],
	],
	"chatter_neg": [
		["{hood:a} hâlâ raylı sistem yok, bizi unuttunuz mu? #{hood}", "Still no rail in {hood}, did you forget us? #{hood}", -0.7],
		["Aktarma yapmak için 10 dakika yürüdüm, planlama berbat", "Walked 10 minutes to transfer, terrible planning", -0.5],
		["{line:da} klima çalışmıyor, sauna gibi 🥵", "The AC on {line} isn't working, it's a sauna 🥵", -0.5],
		["Durağa yürümek 20 dakika, sonra metro… ben yine arabayla gideyim", "20 minute walk to the stop, then the metro… I'll just drive", -0.6],
	],
	"no_network": [
		["{city:da} trafik çekilmez halde. Raylı sistem nerede? #{city}", "Traffic in {city} is unbearable. Where's the rail network? #{city}", -0.6],
		["Yeni ulaşım planlamacısı göreve başladı, umarız metro gelir 🤞", "The new transit planner took office, hope we get a metro 🤞", 0.2],
	],
	"archaeology": [
		["SON DAKİKA: {line} kazısında tarihi buluntular çıktı! Çalışmalar yavaşladı 🏺", "BREAKING: Historic finds unearthed during {line} works! Construction slowed 🏺", 0.1],
		["Metro kazısında Bizans dönemi batık gemiler bulundu. Tarih yeniden yazılıyor ⚓", "Byzantine shipwrecks found during the metro dig. History rewritten ⚓", 0.6],
		["Arkeoloji iyi hoş da {line} ne zaman bitecek? 😤", "Archaeology is nice but when will {line} be done? 😤", -0.4],
	],
	"ev_bridge_traffic": [
		["Köprü trafiği kilitlendi! Raylı sisteme yönelin 🚗🚗🚗 #köprü", "Bridge traffic is gridlocked! Take the rail instead 🚗🚗🚗 #bridge", -0.2],
		["Köprüde 2 saattir bekliyorum, keşke trene binseydim", "Stuck on the bridge for 2 hours, wish I'd taken the train", -0.4],
	],
	"ev_derby": [
		["Derbi günü! Taraftarlar stada raylı sistemle akın ediyor ⚽ #derbi", "Derby day! Fans flood to the stadium by rail ⚽ #derby", 0.4],
	],
	"ev_rain": [
		["Yağmur başladı, yollar göl oldu. Metro hayat kurtarıyor ☔", "It's pouring, roads are lakes. The metro is a lifesaver ☔", 0.3],
		["Şemsiyesiz yakalandım, durağa kadar sırılsıklam oldum 🌧️", "Caught without an umbrella, soaked by the time I reached the stop 🌧️", -0.2],
	],
	"ev_snow": [
		["Ankara'da kar! Tramvay ve otobüsler yavaşladı, metro tıkır tıkır ❄️ #kar", "Snow in Ankara! Trams and buses slowed down, the metro runs fine ❄️ #snow", 0.1],
		["Ayaz bastırdı, durakta donduk 🥶 #Ankara", "Freezing cold, we froze at the stop 🥶 #Ankara", -0.4],
		["Kızılay'da kartopu savaşı ⛄ İyi ki metro var", "Snowball fight in Kızılay ⛄ Glad the metro exists", 0.5],
	],
	"ev_concert": [
		["Bu akşam büyük konser var, dönüşte ek sefer olsa süper olur 🎶", "Big concert tonight, extra trains on the way back would be great 🎶", 0.3],
	],
	"ev_imbat": [
		["İmbat esmeye başladı, Kordon'da vapur beklemek bir keyif 🌬️ #İzmir", "The imbat breeze is blowing, waiting for the ferry on the Kordon is a pleasure 🌬️ #Izmir", 0.8],
	],
	"ev_fair": [
		["İzmir Enternasyonal Fuarı başladı! Kültürpark'a raylı sistemle gelin 🎡 #fuar", "Izmir International Fair is on! Come to Kültürpark by rail 🎡 #fair", 0.7],
	],
	"ev_university": [
		["Okullar açıldı, kampüs hatları dolup taşıyor 🎒 #üniversite", "Term started, campus lines are packed 🎒 #university", 0.1],
	],
	"ev_summer": [
		["Yaz geldi, sahil vapurları turist dolu ☀️ #İzmir", "Summer is here, coastal ferries are full of tourists ☀️ #Izmir", 0.6],
	],
	"tech_official": [
		["Ar-Ge projemiz tamamlandı: {tech}. Yolculuklarınız artık daha iyi! 🚀", "Our R&D project is complete: {tech}. Your trips just got better! 🚀", 0.6],
	],
	"tech_citizen": [
		["{tech} gelmiş, gerçekten fark ediliyor 👌 #teknoloji", "{tech} is here and you can really feel the difference 👌 #tech", 0.7],
		["Bu şehrin ulaşımı Avrupa'yı aratmıyor artık. {tech} 👏", "Our city's transit rivals Europe now. {tech} 👏", 0.8],
		["{tech} güzel de bilet fiyatı artmasın yeter 😅", "{tech} is nice, just don't raise the fare 😅", 0.1],
	],
	"fare_up": [
		["Bilete yine zam! Maaşlar aynı, ulaşım pahalı 😡 #zam", "Another fare hike! Wages stay the same, transit gets pricier 😡 #farehike", -0.9],
		["Bu fiyatla arabayla gitmek daha mantıklı hale geldi", "At this price driving is starting to make more sense", -0.7],
	],
	"fare_down": [
		["Bilet fiyatı düştü! Teşekkürler 🙏 #ucuzulaşım", "Fares went down! Thank you 🙏 #cheaptransit", 0.9],
		["Ucuz bilet = daha çok yolcu. Doğru karar 👍", "Cheaper fares = more riders. Right call 👍", 0.7],
	],
	"inc_breakdown": [
		["{line:da} arıza var, trenler yarım kapasite 😤 #arıza", "Breakdown on {line}, trains at half capacity 😤 #breakdown", -0.7],
		["{line} yine arızalı, işe geç kaldım. Bakım nerede? @metro_resmi", "{line} broke down again, late for work. Where's the maintenance? @metro_resmi", -0.8],
	],
	"inc_strike": [
		["Grev nedeniyle {line} seferleri yapılmıyor ✊ #grev", "{line} is not running due to a strike ✊ #strike", -0.6],
		["Çalışanlar haklı ama {line} olmadan şehir felç 😩", "The workers have a point, but the city is paralysed without {line} 😩", -0.5],
	],
	"inc_flood": [
		["{line} tünelini su bastı! Hat geçici olarak kapalı 🌊", "{line} tunnel flooded! The line is temporarily closed 🌊", -0.7],
	],
	"inc_fixed": [
		["{line} hattındaki arıza giderildi, seferler normale döndü. Anlayışınız için teşekkürler.", "The fault on line {line} has been fixed, service is back to normal. Thanks for your patience.", 0.5],
	],
	"quake_minor": [
		["Deprem hissedildi; güçlendirilmiş tüneller hasarsız atlattı. Ulaşım normal 👏", "An earthquake was felt; reinforced tunnels came through unharmed. Transit is running 👏", 0.6],
	],
	"quake_major": [
		["Deprem sonrası bazı metro hatları kontrol için kapatıldı. Hasar tespiti sürüyor ⚠️", "After the earthquake some metro lines were closed for inspection. Damage assessment ongoing ⚠️", -0.6],
	],
	"mission_ok": [
		["Belediye ulaşım işletmesinin hedefi zamanında tutturduğunu açıkladı 🎯", "The city announced the transit operator hit its target on time 🎯", 0.7],
	],
	"mission_fail": [
		["Ulaşım işletmesi verdiği sözü tutamadı, meclis hesap soruyor", "The transit operator missed its promised target; the council demands answers", -0.6],
	],
	"dlg_union_wage_1": [["Ulaşım çalışanlarına zam geldi, hak ettiler 👏", "Transit workers got a raise, well deserved 👏", 0.6]],
	"dlg_union_wage_3": [["Sendika ile müzakereler çöktü, grev kapıda mı?", "Talks with the union collapsed, is a strike coming?", -0.6]],
	"dlg_sponsor_station_1": [["{station} durağına marka adı verilmiş… her şey satılık mı? 🙄", "{station} now carries a brand name… is everything for sale? 🙄", -0.4]],
	"dlg_fare_cut_1": [["Bilet indirimi geldi! Cebimize nefes aldıran karar 💸", "Fare cut! A decision that lets our wallets breathe 💸", 0.9]],
	"dlg_fare_cut_2": [["Bilet indirimi talebi reddedildi, vatandaş zor durumda", "The fare cut request was rejected, citizens are struggling", -0.6]],
	"dlg_accessibility_1": [["Tüm istasyonlara asansör geliyor ♿ Engelsiz şehir!", "Elevators are coming to every station ♿ An accessible city!", 0.9]],
	"dlg_night_event_1": [["Konser çıkışı gece seferleri vardı, harika organizasyon 🎶", "There were night trains after the concert, great organisation 🎶", 0.8]],
	"dlg_night_event_2": [["Konserden sonra eve taksiyle 400 lira verdim, gece seferi yok 😡", "Paid a fortune for a taxi after the concert, no night trains 😡", -0.7]],
	"dlg_press_2": [["Gazete manşeti: 'Raylı sistemde kalabalık skandalı' 📰", "Headline: 'Crowding scandal on the rail network' 📰", -0.7]],
	"dlg_seismic_1": [["Tüneller depreme karşı güçlendiriliyor, içimiz rahat 🏗️", "Tunnels are being reinforced against earthquakes, peace of mind 🏗️", 0.8]],
	"flavor_eskisehir": [
		["Porsuk kıyısında gondol, sonra tramvayla eve. Eskişehir çok yaşanılır 🚋", "A gondola on the Porsuk, then home by tram. Eskişehir is so liveable 🚋", 0.9],
		["Öğrenci şehri = her yer tramvay dolu, ama seviyoruz 🎓 #Eskişehir", "Student city = trams always full, but we love it 🎓 #Eskisehir", 0.5],
		["Odunpazarı'nın renkli evleri durağın hemen yanında, turistler bayılıyor", "Odunpazarı's colourful houses are right by the stop, tourists love it", 0.7],
	],
	"flavor_antalya": [
		["Plaja raylı sistemle gitmek, otopark derdi yok 🏖️ #Antalya", "Taking rail to the beach, no parking stress 🏖️ #Antalya", 0.9],
		["Yazın turist, kışın biz… şehir iki farklı şehir gibi ☀️", "Tourists in summer, locals in winter… two different cities ☀️", 0.4],
		["Kaleiçi'nde gün batımı, sonra tramvayla Lara'ya 🌅", "Sunset in Kaleiçi, then the tram to Lara 🌅", 0.8],
	],
	"flavor_bursa": [
		["Teleferikle Uludağ'a çıkmak, sonra İskender 😋 #Bursa", "Gondola up Uludağ, then İskender kebab 😋 #Bursa", 0.9],
		["OSB vardiya çıkışı metro tıklım tıklım, ek sefer şart", "Metro is packed when the factory shift ends, we need more trains", -0.5],
		["Yeşil Bursa'da arabasız yaşam mümkünmüş 🌳", "Car-free life is possible in green Bursa 🌳", 0.8],
	],
	"flavor_trabzon": [
		["Boztepe'ye çıkıp çay içmek… manzara efsane ☕ #Trabzon", "Tea up on Boztepe… the view is legendary ☕ #Trabzon", 0.9],
		["Sahil yolu tek, trafik bitmiyor. Raylı sistem şart! #Trabzon", "One coastal road, endless traffic. We need rail! #Trabzon", -0.5],
		["Hamsi mevsimi geldi, Meydan'a herkes akın ediyor 🐟", "Anchovy season is here, everyone heads to Meydan 🐟", 0.7],
	],
	"con_start": [
		["{line} inşaatı başladı! {n} ay sonra açılış bekleniyor 🏗️", "Construction of {line} has started! Opening expected in {n} months 🏗️", 0.4],
		["Mahallemize {line} geliyor ama şantiye tozu çekilmez 😷", "{line} is coming to our neighbourhood but the construction dust is awful 😷", -0.2],
	],
	"con_overrun": [
		["{line} inşaatında maliyet aşımı! Açılış {n} ay gecikecek 💸", "Cost overrun on {line}! Opening delayed by {n} months 💸", -0.6],
	],
	"modernized": [
		["{line} yenilendi: yeni trenler, temiz vagonlar ✨", "{line} has been renewed: new trains, clean carriages ✨", 0.8],
	],
	"hub_open": [
		["{station} artık dev bir aktarma merkezi. Aktarma 2 dakika! 🔁", "{station} is now a major interchange. Transfers in 2 minutes! 🔁", 0.8],
	],
	"rival": [
		["Yeni bir paylaşımlı araç uygulaması çıktı, herkes onu deniyor 📱", "A new ride-hailing app launched, everyone is trying it 📱", -0.2],
	],
	"express": [
		["{line} ekspres seferleri harika, şehrin bir ucundan öbürüne yarım saat ⚡", "{line} express is great, end to end in half an hour ⚡", 0.7],
		["Ekspres benim durağımda durmuyor artık 😠 #{line}", "The express doesn't stop at my station anymore 😠 #{line}", -0.6],
	],
	"flavor_istanbul": [
		["Martılar yine vapurun peşinde, simit atanlara selam 🐦 #İstanbul", "The gulls are chasing the ferry again, hi to everyone tossing simit 🐦 #Istanbul", 0.7],
		["Boğaz'ın altından 4 dakikada karşıya geçmek… mühendislik harikası", "Crossing under the Bosphorus in 4 minutes… an engineering marvel", 0.8],
		["Kız Kulesi manzarasıyla sabah kahvesi ☕ #İstanbul", "Morning coffee with a Maiden's Tower view ☕ #Istanbul", 0.7],
	],
	"flavor_ankara": [
		["Ankara'nın ayazında metroya inmek sauna gibi geliyor 😅", "Going down to the metro in Ankara's frost feels like a sauna 😅", 0.4],
		["Kızılay'da buluşma klasiği: 'Güvenpark'ta görüşürüz' #Ankara", "Classic meet-up spot: 'see you at Güvenpark' #Ankara", 0.5],
	],
	"flavor_izmir": [
		["Boyoz + gevrek + vapur = mükemmel İzmir sabahı 🥐 #İzmir", "Boyoz + gevrek + ferry = perfect Izmir morning 🥐 #Izmir", 0.9],
		["Kordon'da gün batımı, sonra metroyla eve. İzmir böyle güzel 🌇", "Sunset on the Kordon, then home by metro. That's Izmir 🌇", 0.9],
		["Kuş Cenneti'nde flamingolar geldi! Pembe pembe 🦩 #İzmir", "The flamingos are back at the bird sanctuary! So pink 🦩 #Izmir", 0.8],
	],
	# ------------------------------------------------ real dated events
	"re_announce": [
		["SON DAKİKA: {event} şehrimizde! {n} ay sonra binlerce ziyaretçi bekleniyor. Ulaşım hazır mı? 🚨", "BREAKING: {event} is coming to our city! Thousands expected in {n} months. Is transit ready? 🚨", 0.2],
		["{event} için geri sayım başladı: {n} ay. Gözler ulaşım planında 👀 #{city}", "Countdown to {event}: {n} months. All eyes on the transit plan 👀 #{city}", 0.1],
	],
	"re_reminder": [
		["{event} kapıda ({n} ay) ama etkinlik alanına hâlâ raylı sistem yok! 😬", "{event} is {n} months away and there's still no rail to the venue! 😬", -0.6],
		["Uzmanlar uyarıyor: {event} öncesi ulaşım hazırlığı yetersiz. Kalan süre {n} ay.", "Experts warn: transit is not ready for {event}. {n} months left.", -0.5],
	],
	"re_ok": [
		["{event} için trenle geldim, kapıda indim. Böyle organizasyon görmedim 👏", "Came to {event} by train, got off at the gate. Never seen it this smooth 👏", 0.95],
		["Yabancı misafirler metroya bayıldı. {event} şehrin vitrini oldu 🌍", "Foreign guests loved the metro. {event} made our city shine 🌍", 0.9],
	],
	"re_ok_news": [
		["{event} kusursuz geçti: raylı sistem rekor yolcu taşıdı.", "{event} went flawlessly: rail carried record crowds.", 0.8],
	],
	"re_fail": [
		["{event} yüzünden 3 saat trafikte kaldık. Raylı sistem nerede?! 😡", "Stuck in traffic for 3 hours because of {event}. Where is the rail?! 😡", -0.95],
		["Dünya bizi izliyor, biz kuyrukta bekliyoruz. {event} ulaşım fiyaskosu 🤦", "The world is watching and we're stuck in queues. {event} transit fiasco 🤦", -0.9],
	],
	"re_fail_news": [
		["{event} ulaşım krizine döndü: etkinlik alanına raylı bağlantı yoktu.", "{event} turned into a transit crisis: no rail link to the venue.", -0.8],
	],
	"re_covid": [
		["Salgın nedeniyle şehir sessiz: toplu taşımada yolcu sayısı çakıldı. Maske ve mesafe kuralları yürürlükte 😷", "The pandemic has silenced the city: transit ridership collapsed. Masks and distancing in force 😷", -0.4],
	],
	"re_izm_quake": [
		["İzmir'de 6.6 büyüklüğünde deprem! Raylı sistemde hasar tespit çalışmaları sürüyor 🙏 #İzmir", "A magnitude 6.6 earthquake hit Izmir! Rail lines are being inspected 🙏 #Izmir", -0.5],
	],
	"re_ist_marathon": [
		["İstanbul Maratonu bugün: köprü araç trafiğine kapalı, kıtalar arası koşu başladı 🏃", "Istanbul Marathon today: the bridge is closed to cars, the intercontinental run is on 🏃", 0.3],
	],
	"re_ist_ecoc": [
		["İstanbul 2010 Avrupa Kültür Başkenti! Müzeler, konserler, festivaller 🎭", "Istanbul is the 2010 European Capital of Culture! Museums, concerts, festivals 🎭", 0.7],
	],
	"re_ist_ucl": [
		["Avrupa kupası finali İstanbul'da! 70 bin taraftar Olimpiyat Stadı'na akıyor ⚽", "The European cup final is in Istanbul! 70,000 fans heading to the Olympic Stadium ⚽", 0.4],
	],
	"re_ank_centenary": [
		["Cumhuriyetimiz 100 yaşında! 🇹🇷 Kızılay'da büyük kutlama, havai fişekler 🎆", "Our Republic turns 100! 🇹🇷 Huge celebration in Kızılay, fireworks 🎆", 0.8],
	],
	"re_ank_nato": [
		["NATO Zirvesi başladı: liderler Ankara'da, Söğütözü çevresinde geniş güvenlik önlemi 🚧", "NATO Summit opens: leaders in Ankara, tight security around Söğütözü 🚧", 0.1],
	],
	"re_ant_cop31": [
		["COP31 İklim Zirvesi Antalya'da! Delegeler toplu taşımaya yönlendiriliyor 🌱", "COP31 climate summit in Antalya! Delegates directed to public transit 🌱", 0.4],
	],
	"re_ant_g20": [
		["G20 Liderler Zirvesi Antalya'da: yollar kapalı, şehir alarmda 🚨", "G20 Leaders' Summit in Antalya: roads closed, city on alert 🚨", 0.0],
	],
	"re_ant_expo": [
		["EXPO 2016 Antalya kapılarını açtı! Çiçekler ve çocuklar teması 🌷", "EXPO 2016 Antalya opens! Theme: flowers and children 🌷", 0.6],
	],
	"re_trb_eyof": [
		["Avrupa Gençlik Olimpiyat Festivali Trabzon'da başladı! 🏅", "The European Youth Olympic Festival kicks off in Trabzon! 🏅", 0.6],
	],
	"re_esk_turkic": [
		["Eskişehir 2013 Türk Dünyası Kültür Başkenti! Odunpazarı rengârenk 🎨", "Eskişehir is the 2013 Turkic World Capital of Culture! Odunpazarı is full of colour 🎨", 0.6],
	],
	"re_bur_turkic": [
		["Bursa 2022 Türk Dünyası Kültür Başkenti! 🎨 #Bursa", "Bursa is the 2022 Turkic World Capital of Culture! 🎨 #Bursa", 0.6],
	],
	# ------------------------------------------------ elections
	"elec_poll": [
		["ANKET: Seçime {m} ay kala ulaşım politikanıza destek %{n} 🗳️", "POLL: {m} months before the election, support for your transit policy is {n}% 🗳️", 0.0],
		["Son kamuoyu yoklaması: %{n}. Seçime {m} ay var. #Seçim", "Latest opinion poll: {n}%. {m} months to the election. #Election", 0.0],
	],
	"elec_last": [
		["Seçime son 1 ay! Son ankette oy oranı %{n} 🗳️", "One month to the election! Final poll: {n}% 🗳️", 0.0],
	],
	"elec_win": [
		["SEÇİM SONUÇLARI: Ulaşım vaatleri kazandı, oy oranı %{n} 🎉", "ELECTION RESULTS: The transit agenda wins with {n}% 🎉", 0.8],
	],
	"elec_win_cit": [
		["Metroya oy verdik, metro kazandı! 🚇🗳️", "We voted for the metro, and the metro won! 🚇🗳️", 0.9],
	],
	"elec_lose": [
		["SEÇİM SONUÇLARI: Seçmen ulaşımdan memnun değildi, oy oranı %{n} kaldı.", "ELECTION RESULTS: Voters weren't happy with transit, only {n}%.", -0.9],
	],
	"elec_promise_lines": [
		["Söz veriyoruz: seçimlere kadar 2 yeni raylı hat hizmete girecek!", "Our promise: 2 new lines will open before the election!", 0.4],
	],
	"elec_promise_riders": [
		["Söz veriyoruz: toplu taşıma yolcu sayısını %30 artıracağız!", "Our promise: we'll grow ridership by 30%!", 0.4],
	],
	"elec_promise_sat": [
		["Söz veriyoruz: yolcu memnuniyeti %70'in üzerine çıkacak!", "Our promise: rider satisfaction above 70%!", 0.4],
	],
}
