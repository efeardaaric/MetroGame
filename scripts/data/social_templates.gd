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
const OFFICIAL := {"name": "Ray Ağı İşletme", "handle": "rayagi_resmi", "color": "ffb703"}

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
		["Üç tren kaçırdım, {st:da} bekliyorum hâlâ. Ek sefer lütfen! @rayagi_resmi", "Missed three trains, still waiting at {st}. More trains please! @rayagi_resmi", -0.8],
		["{line:da} yer bulmak piyangodan zor #kalabalık", "Finding a seat on {line} is harder than winning the lottery #crowded", -0.7],
		["Sabah {line:a} binmek ekstrem spor gibi 😩", "Riding {line} in the morning is an extreme sport 😩", -0.7],
		["{line} kapasite sorununu ne zaman çözeceksiniz? @rayagi_resmi", "When will you fix {line}'s capacity problem? @rayagi_resmi", -0.8],
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
}
