# Tanıtım videosu üretimi

1. Ham çekim (oyunun içinden, 1080×1920, 30 fps):
   `xvfb-run godot --path . --rendering-driver opengl3 --resolution 1080x1920 --write-movie WORK/raw.avi --fixed-fps 30 tools/promo_capture.tscn -- --lang=tr > WORK/capture.log`
2. Seslendirme modeli (isteğe bağlı, çevrimdışı Piper):
   `pip install piper-tts` ve `WORK/../piper/tr_TR-dfki-medium.onnx(.json)` (huggingface: rhasspy/piper-voices)
3. Kurgu: `python3 tools/make_promo.py WORK --lang tr` (seslendirmesiz: `--no-vo`)

Sahne sırası, süreleri, geçişleri ve yazılar `tools/make_promo.py` içindeki `SCENES`, `TEXT`, `VO` tablolarından değiştirilebilir.
