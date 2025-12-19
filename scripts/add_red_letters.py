#!/usr/bin/env python3
"""
Script to add red letter markup [r]...[/r] to Jesus's words in Bible JSON files.

This uses a comprehensive list of red letter verse ranges based on traditional
red letter Bible editions.

Usage: python3 add_red_letters.py path/to/bible.json
"""

import json
import sys
import os

# Comprehensive list of red letter verses (Jesus speaking)
# Format: (book, chapter, verse_start, verse_end) - inclusive ranges
# When verse_end is None, it means just that single verse

RED_LETTER_VERSES = [
    # MATTHEW
    ("Matthew", 3, 15, 15),
    ("Matthew", 4, 4, 4),
    ("Matthew", 4, 7, 7),
    ("Matthew", 4, 10, 10),
    ("Matthew", 4, 17, 17),
    ("Matthew", 4, 19, 19),
    ("Matthew", 5, 3, 48),  # Sermon on the Mount
    ("Matthew", 6, 1, 34),  # Sermon on the Mount continued
    ("Matthew", 7, 1, 27),  # Sermon on the Mount continued
    ("Matthew", 8, 3, 3),
    ("Matthew", 8, 4, 4),
    ("Matthew", 8, 7, 7),
    ("Matthew", 8, 10, 13),
    ("Matthew", 8, 20, 20),
    ("Matthew", 8, 22, 22),
    ("Matthew", 8, 26, 26),
    ("Matthew", 8, 32, 32),
    ("Matthew", 9, 2, 2),
    ("Matthew", 9, 4, 6),
    ("Matthew", 9, 9, 9),
    ("Matthew", 9, 12, 13),
    ("Matthew", 9, 15, 15),
    ("Matthew", 9, 22, 22),
    ("Matthew", 9, 24, 24),
    ("Matthew", 9, 28, 30),
    ("Matthew", 9, 37, 38),
    ("Matthew", 10, 5, 42),  # Sending the Twelve
    ("Matthew", 11, 4, 30),
    ("Matthew", 12, 3, 8),
    ("Matthew", 12, 11, 13),
    ("Matthew", 12, 25, 37),
    ("Matthew", 12, 39, 45),
    ("Matthew", 12, 48, 50),
    ("Matthew", 13, 3, 52),  # Parables
    ("Matthew", 14, 16, 16),
    ("Matthew", 14, 18, 18),
    ("Matthew", 14, 27, 27),
    ("Matthew", 14, 29, 29),
    ("Matthew", 14, 31, 31),
    ("Matthew", 15, 3, 11),
    ("Matthew", 15, 13, 20),
    ("Matthew", 15, 24, 24),
    ("Matthew", 15, 26, 28),
    ("Matthew", 15, 32, 32),
    ("Matthew", 15, 34, 34),
    ("Matthew", 16, 2, 4),
    ("Matthew", 16, 6, 12),
    ("Matthew", 16, 13, 13),
    ("Matthew", 16, 15, 15),
    ("Matthew", 16, 17, 19),
    ("Matthew", 16, 23, 28),
    ("Matthew", 17, 7, 7),
    ("Matthew", 17, 9, 9),
    ("Matthew", 17, 11, 12),
    ("Matthew", 17, 17, 17),
    ("Matthew", 17, 20, 21),
    ("Matthew", 17, 22, 23),
    ("Matthew", 17, 25, 27),
    ("Matthew", 18, 2, 35),  # Teaching on humility
    ("Matthew", 19, 4, 6),
    ("Matthew", 19, 8, 12),
    ("Matthew", 19, 14, 14),
    ("Matthew", 19, 17, 21),
    ("Matthew", 19, 23, 26),
    ("Matthew", 19, 28, 30),
    ("Matthew", 20, 1, 16),  # Parable of workers
    ("Matthew", 20, 18, 19),
    ("Matthew", 20, 21, 23),
    ("Matthew", 20, 25, 28),
    ("Matthew", 20, 32, 32),
    ("Matthew", 21, 2, 3),
    ("Matthew", 21, 13, 13),
    ("Matthew", 21, 16, 16),
    ("Matthew", 21, 19, 22),
    ("Matthew", 21, 24, 27),
    ("Matthew", 21, 28, 44),
    ("Matthew", 22, 2, 14),
    ("Matthew", 22, 18, 21),
    ("Matthew", 22, 29, 32),
    ("Matthew", 22, 37, 40),
    ("Matthew", 22, 42, 45),
    ("Matthew", 23, 2, 39),  # Woes to Pharisees
    ("Matthew", 24, 2, 51),  # Olivet Discourse
    ("Matthew", 25, 1, 46),  # Parables
    ("Matthew", 26, 2, 2),
    ("Matthew", 26, 10, 13),
    ("Matthew", 26, 18, 18),
    ("Matthew", 26, 21, 21),
    ("Matthew", 26, 23, 25),
    ("Matthew", 26, 26, 29),
    ("Matthew", 26, 31, 32),
    ("Matthew", 26, 34, 34),
    ("Matthew", 26, 36, 36),
    ("Matthew", 26, 38, 46),
    ("Matthew", 26, 50, 50),
    ("Matthew", 26, 52, 56),
    ("Matthew", 26, 64, 64),
    ("Matthew", 27, 11, 11),
    ("Matthew", 27, 46, 46),
    ("Matthew", 28, 9, 10),
    ("Matthew", 28, 18, 20),  # Great Commission
    
    # MARK
    ("Mark", 1, 15, 15),
    ("Mark", 1, 17, 17),
    ("Mark", 1, 25, 25),
    ("Mark", 1, 38, 38),
    ("Mark", 1, 41, 41),
    ("Mark", 1, 44, 44),
    ("Mark", 2, 5, 5),
    ("Mark", 2, 8, 11),
    ("Mark", 2, 14, 14),
    ("Mark", 2, 17, 17),
    ("Mark", 2, 19, 22),
    ("Mark", 2, 25, 28),
    ("Mark", 3, 3, 5),
    ("Mark", 3, 23, 29),
    ("Mark", 3, 33, 35),
    ("Mark", 4, 3, 32),
    ("Mark", 4, 35, 35),
    ("Mark", 4, 39, 40),
    ("Mark", 5, 8, 9),
    ("Mark", 5, 19, 19),
    ("Mark", 5, 30, 30),
    ("Mark", 5, 34, 34),
    ("Mark", 5, 36, 36),
    ("Mark", 5, 39, 39),
    ("Mark", 5, 41, 41),
    ("Mark", 6, 4, 4),
    ("Mark", 6, 10, 11),
    ("Mark", 6, 31, 31),
    ("Mark", 6, 37, 38),
    ("Mark", 6, 50, 50),
    ("Mark", 7, 6, 23),
    ("Mark", 7, 27, 27),
    ("Mark", 7, 29, 29),
    ("Mark", 7, 34, 34),
    ("Mark", 8, 1, 3),
    ("Mark", 8, 5, 5),
    ("Mark", 8, 12, 12),
    ("Mark", 8, 15, 15),
    ("Mark", 8, 17, 21),
    ("Mark", 8, 27, 27),
    ("Mark", 8, 29, 29),
    ("Mark", 8, 33, 38),
    ("Mark", 9, 1, 1),
    ("Mark", 9, 12, 13),
    ("Mark", 9, 19, 19),
    ("Mark", 9, 21, 21),
    ("Mark", 9, 23, 23),
    ("Mark", 9, 25, 25),
    ("Mark", 9, 29, 29),
    ("Mark", 9, 31, 31),
    ("Mark", 9, 35, 37),
    ("Mark", 9, 39, 50),
    ("Mark", 10, 3, 9),
    ("Mark", 10, 11, 12),
    ("Mark", 10, 14, 15),
    ("Mark", 10, 18, 21),
    ("Mark", 10, 23, 27),
    ("Mark", 10, 29, 31),
    ("Mark", 10, 33, 34),
    ("Mark", 10, 36, 36),
    ("Mark", 10, 38, 40),
    ("Mark", 10, 42, 45),
    ("Mark", 10, 49, 49),
    ("Mark", 10, 51, 52),
    ("Mark", 11, 2, 6),
    ("Mark", 11, 14, 14),
    ("Mark", 11, 17, 17),
    ("Mark", 11, 22, 26),
    ("Mark", 11, 29, 33),
    ("Mark", 12, 1, 11),
    ("Mark", 12, 15, 17),
    ("Mark", 12, 24, 27),
    ("Mark", 12, 29, 31),
    ("Mark", 12, 34, 34),
    ("Mark", 12, 35, 37),
    ("Mark", 12, 38, 40),
    ("Mark", 12, 43, 44),
    ("Mark", 13, 2, 37),  # Olivet Discourse
    ("Mark", 14, 6, 9),
    ("Mark", 14, 13, 15),
    ("Mark", 14, 18, 18),
    ("Mark", 14, 20, 21),
    ("Mark", 14, 22, 25),
    ("Mark", 14, 27, 28),
    ("Mark", 14, 30, 30),
    ("Mark", 14, 32, 32),
    ("Mark", 14, 34, 34),
    ("Mark", 14, 36, 38),
    ("Mark", 14, 41, 42),
    ("Mark", 14, 48, 49),
    ("Mark", 14, 62, 62),
    ("Mark", 15, 2, 2),
    ("Mark", 15, 34, 34),
    ("Mark", 16, 15, 18),
    
    # LUKE
    ("Luke", 2, 49, 49),
    ("Luke", 4, 4, 4),
    ("Luke", 4, 8, 8),
    ("Luke", 4, 12, 12),
    ("Luke", 4, 18, 21),
    ("Luke", 4, 23, 27),
    ("Luke", 4, 35, 35),
    ("Luke", 4, 43, 44),
    ("Luke", 5, 4, 4),
    ("Luke", 5, 10, 10),
    ("Luke", 5, 13, 14),
    ("Luke", 5, 20, 20),
    ("Luke", 5, 22, 24),
    ("Luke", 5, 27, 27),
    ("Luke", 5, 31, 32),
    ("Luke", 5, 34, 39),
    ("Luke", 6, 3, 5),
    ("Luke", 6, 8, 10),
    ("Luke", 6, 20, 49),  # Sermon on the Plain
    ("Luke", 7, 9, 10),
    ("Luke", 7, 13, 15),
    ("Luke", 7, 22, 35),
    ("Luke", 7, 40, 50),
    ("Luke", 8, 5, 18),
    ("Luke", 8, 21, 22),
    ("Luke", 8, 25, 25),
    ("Luke", 8, 28, 28),
    ("Luke", 8, 30, 30),
    ("Luke", 8, 39, 39),
    ("Luke", 8, 45, 46),
    ("Luke", 8, 48, 48),
    ("Luke", 8, 50, 50),
    ("Luke", 8, 52, 52),
    ("Luke", 8, 54, 54),
    ("Luke", 9, 3, 5),
    ("Luke", 9, 13, 14),
    ("Luke", 9, 18, 18),
    ("Luke", 9, 20, 22),
    ("Luke", 9, 23, 27),
    ("Luke", 9, 35, 35),
    ("Luke", 9, 41, 41),
    ("Luke", 9, 44, 44),
    ("Luke", 9, 48, 48),
    ("Luke", 9, 50, 50),
    ("Luke", 9, 55, 56),
    ("Luke", 9, 58, 62),
    ("Luke", 10, 2, 24),
    ("Luke", 10, 26, 28),
    ("Luke", 10, 30, 37),
    ("Luke", 10, 41, 42),
    ("Luke", 11, 2, 13),  # Lord's Prayer
    ("Luke", 11, 17, 52),
    ("Luke", 12, 1, 59),  # Teachings
    ("Luke", 13, 2, 9),
    ("Luke", 13, 12, 12),
    ("Luke", 13, 15, 16),
    ("Luke", 13, 18, 21),
    ("Luke", 13, 23, 30),
    ("Luke", 13, 32, 35),
    ("Luke", 14, 3, 6),
    ("Luke", 14, 8, 24),
    ("Luke", 14, 26, 35),
    ("Luke", 15, 3, 32),  # Parables of lost things
    ("Luke", 16, 1, 13),
    ("Luke", 16, 15, 31),
    ("Luke", 17, 1, 10),
    ("Luke", 17, 14, 14),
    ("Luke", 17, 17, 37),
    ("Luke", 18, 2, 8),
    ("Luke", 18, 14, 14),
    ("Luke", 18, 16, 17),
    ("Luke", 18, 19, 22),
    ("Luke", 18, 24, 30),
    ("Luke", 18, 31, 34),
    ("Luke", 18, 41, 42),
    ("Luke", 19, 5, 5),
    ("Luke", 19, 9, 10),
    ("Luke", 19, 12, 27),
    ("Luke", 19, 30, 31),
    ("Luke", 19, 40, 40),
    ("Luke", 19, 42, 44),
    ("Luke", 19, 46, 46),
    ("Luke", 20, 3, 8),
    ("Luke", 20, 9, 18),
    ("Luke", 20, 23, 26),
    ("Luke", 20, 34, 38),
    ("Luke", 20, 41, 44),
    ("Luke", 20, 46, 47),
    ("Luke", 21, 3, 4),
    ("Luke", 21, 6, 36),  # Olivet Discourse
    ("Luke", 22, 10, 22),
    ("Luke", 22, 25, 38),
    ("Luke", 22, 40, 40),
    ("Luke", 22, 42, 42),
    ("Luke", 22, 46, 46),
    ("Luke", 22, 48, 48),
    ("Luke", 22, 51, 51),
    ("Luke", 22, 52, 53),
    ("Luke", 22, 61, 61),
    ("Luke", 22, 67, 70),
    ("Luke", 23, 3, 3),
    ("Luke", 23, 28, 31),
    ("Luke", 23, 34, 34),
    ("Luke", 23, 43, 43),
    ("Luke", 23, 46, 46),
    ("Luke", 24, 17, 17),
    ("Luke", 24, 19, 19),
    ("Luke", 24, 25, 27),
    ("Luke", 24, 36, 36),
    ("Luke", 24, 38, 49),
    
    # JOHN
    ("John", 1, 38, 39),
    ("John", 1, 42, 43),
    ("John", 1, 47, 47),
    ("John", 1, 50, 51),
    ("John", 2, 4, 4),
    ("John", 2, 7, 8),
    ("John", 2, 16, 16),
    ("John", 2, 19, 19),
    ("John", 3, 3, 21),  # Nicodemus
    ("John", 3, 5, 8),
    ("John", 3, 10, 21),
    ("John", 4, 7, 7),
    ("John", 4, 10, 10),
    ("John", 4, 13, 14),
    ("John", 4, 16, 18),
    ("John", 4, 21, 26),
    ("John", 4, 32, 38),
    ("John", 4, 48, 48),
    ("John", 4, 50, 50),
    ("John", 4, 53, 53),
    ("John", 5, 6, 6),
    ("John", 5, 8, 8),
    ("John", 5, 14, 14),
    ("John", 5, 17, 47),
    ("John", 6, 5, 5),
    ("John", 6, 10, 10),
    ("John", 6, 12, 12),
    ("John", 6, 20, 20),
    ("John", 6, 26, 58),  # Bread of Life
    ("John", 6, 61, 65),
    ("John", 6, 67, 67),
    ("John", 6, 70, 70),
    ("John", 7, 6, 8),
    ("John", 7, 16, 24),
    ("John", 7, 28, 29),
    ("John", 7, 33, 34),
    ("John", 7, 37, 38),
    ("John", 8, 7, 7),
    ("John", 8, 10, 11),
    ("John", 8, 12, 12),
    ("John", 8, 14, 19),
    ("John", 8, 21, 29),
    ("John", 8, 31, 38),
    ("John", 8, 39, 47),
    ("John", 8, 49, 51),
    ("John", 8, 54, 56),
    ("John", 8, 58, 58),
    ("John", 9, 3, 5),
    ("John", 9, 7, 7),
    ("John", 9, 35, 41),
    ("John", 10, 1, 18),  # Good Shepherd
    ("John", 10, 25, 30),
    ("John", 10, 32, 38),
    ("John", 11, 4, 4),
    ("John", 11, 7, 15),
    ("John", 11, 23, 26),
    ("John", 11, 34, 34),
    ("John", 11, 39, 40),
    ("John", 11, 41, 42),
    ("John", 11, 43, 44),
    ("John", 12, 7, 8),
    ("John", 12, 23, 28),
    ("John", 12, 30, 30),
    ("John", 12, 35, 36),
    ("John", 12, 44, 50),
    ("John", 13, 7, 20),  # Last Supper
    ("John", 13, 21, 21),
    ("John", 13, 26, 27),
    ("John", 13, 31, 38),
    ("John", 14, 1, 31),  # Farewell Discourse
    ("John", 15, 1, 27),  # True Vine
    ("John", 16, 1, 33),  # Farewell continued
    ("John", 17, 1, 26),  # High Priestly Prayer
    ("John", 18, 4, 4),
    ("John", 18, 5, 9),
    ("John", 18, 11, 11),
    ("John", 18, 20, 21),
    ("John", 18, 23, 23),
    ("John", 18, 34, 34),
    ("John", 18, 36, 37),
    ("John", 19, 11, 11),
    ("John", 19, 26, 27),
    ("John", 19, 28, 28),
    ("John", 19, 30, 30),
    ("John", 20, 15, 17),
    ("John", 20, 19, 19),
    ("John", 20, 21, 23),
    ("John", 20, 26, 27),
    ("John", 20, 29, 29),
    ("John", 21, 5, 6),
    ("John", 21, 10, 10),
    ("John", 21, 12, 12),
    ("John", 21, 15, 19),
    ("John", 21, 22, 23),
    
    # ACTS
    ("Acts", 1, 4, 5),
    ("Acts", 1, 7, 8),
    ("Acts", 9, 4, 6),
    ("Acts", 9, 10, 12),
    ("Acts", 9, 15, 16),
    ("Acts", 18, 9, 10),
    ("Acts", 22, 7, 8),
    ("Acts", 22, 10, 10),
    ("Acts", 22, 18, 21),
    ("Acts", 23, 11, 11),
    ("Acts", 26, 14, 18),
    
    # REVELATION
    ("Revelation", 1, 8, 8),
    ("Revelation", 1, 11, 11),
    ("Revelation", 1, 17, 20),
    ("Revelation", 2, 1, 29),  # Letters to churches
    ("Revelation", 3, 1, 22),  # Letters to churches
    ("Revelation", 16, 15, 15),
    ("Revelation", 21, 5, 8),
    ("Revelation", 22, 7, 7),
    ("Revelation", 22, 12, 13),
    ("Revelation", 22, 16, 16),
    ("Revelation", 22, 20, 20),
]


def add_red_letter_markup(bible_data):
    """Add [r]...[/r] markup to red letter verses."""
    books = bible_data.get("books", {})
    modified_count = 0
    
    for book_name, chapter_num, verse_start, verse_end in RED_LETTER_VERSES:
        if book_name not in books:
            continue
            
        chapters = books[book_name].get("chapters", {})
        chapter_key = str(chapter_num)
        
        if chapter_key not in chapters:
            continue
            
        verses = chapters[chapter_key].get("verses", {})
        
        for verse_num in range(verse_start, verse_end + 1):
            verse_key = str(verse_num)
            if verse_key in verses:
                text = verses[verse_key]
                # Skip if already has red letter markup
                if not text.startswith("[r]"):
                    verses[verse_key] = f"[r]{text}[/r]"
                    modified_count += 1
    
    return bible_data, modified_count


def process_bible_file(filepath):
    """Process a Bible JSON file and add red letter markup."""
    print(f"Processing: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8') as f:
        bible_data = json.load(f)
    
    bible_data, modified_count = add_red_letter_markup(bible_data)
    
    # Backup original
    backup_path = filepath + ".backup"
    if not os.path.exists(backup_path):
        os.rename(filepath, backup_path)
        print(f"  Created backup: {backup_path}")
    
    # Write updated file
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(bible_data, f, indent=2, ensure_ascii=False)
    
    print(f"  Added red letter markup to {modified_count} verses")
    return modified_count


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 add_red_letters.py path/to/bible.json")
        print("       python3 add_red_letters.py --all  (process all Bible files)")
        sys.exit(1)
    
    if sys.argv[1] == "--all":
        # Process all Bible JSON files in the BibleScroll directory
        bible_dir = os.path.join(os.path.dirname(__file__), "..", "BibleScroll")
        json_files = [f for f in os.listdir(bible_dir) if f.endswith('.json')]
        
        total = 0
        for json_file in json_files:
            filepath = os.path.join(bible_dir, json_file)
            total += process_bible_file(filepath)
        
        print(f"\nTotal: Added red letter markup to {total} verses across {len(json_files)} files")
    else:
        process_bible_file(sys.argv[1])




