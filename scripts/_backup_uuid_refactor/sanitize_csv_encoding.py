#!/usr/bin/env python3
import sys
import csv

if len(sys.argv) != 2:
    print("Usage: sanitize_csv_encoding.py input.csv", file=sys.stderr)
    sys.exit(1)

input_path = sys.argv[1]
output_path = input_path.replace(".csv", "_clean.csv")

try:
    with open(input_path, "rb") as f:
        raw = f.read()

    # Попробуем UTF-16 и UTF-16LE
    try:
        decoded = raw.decode("utf-16")
    except UnicodeDecodeError:
        decoded = raw.decode("utf-16le")

    # Сохраним как UTF-8 чистый
    with open(output_path, "w", encoding="utf-8", newline='') as f_out:
        f_out.write(decoded)

    print(f"✅ Сохранён как UTF-8: {output_path}")
except Exception as e:
    print(f"❌ Ошибка: {e}", file=sys.stderr)
    sys.exit(1)
