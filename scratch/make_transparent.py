import os
from PIL import Image

input_path = r"C:\Users\devan\.gemini\antigravity\brain\68e2007a-0593-41fd-903b-ab9d17d679f8\krishi_mitra_icon_1778364713405.png"
output_path = r"e:\Dev\krishi-mitra\make-a-ton\assets\icon.png"

os.makedirs(os.path.dirname(output_path), exist_ok=True)

img = Image.open(input_path).convert("RGBA")
datas = img.getdata()

new_data = []
for item in datas:
    # change all white (also shades of white)
    # to transparent
    if item[0] > 240 and item[1] > 240 and item[2] > 240:
        new_data.append((255, 255, 255, 0))
    else:
        new_data.append(item)

img.putdata(new_data)
# Resize to 1024x1024 which is standard for app icons
img = img.resize((1024, 1024), Image.Resampling.LANCZOS)
img.save(output_path, "PNG")
print(f"Saved transparent icon to {output_path}")
