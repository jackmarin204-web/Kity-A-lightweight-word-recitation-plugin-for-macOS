# Lexicon notice

`Resources/Lexicon.json` is a filtered, transformed learning lexicon generated on 2026-08-31.

Sources:

- jieba `dict.txt`: frequency ranking; MIT License; https://github.com/fxsjy/jieba
- CC-CEDICT: English gloss candidates; CC BY-SA 4.0; https://cc-cedict.org/editor/editor.php?handler=Download

Transformations: only 2–6-character simplified-Chinese words are retained; entries are ranked by jieba frequency; a single short ASCII English gloss is selected; duplicates, long glosses, labels, names, and ambiguous formatting are discarded. The transformed lexicon is distributed under CC BY-SA 4.0 with the above attribution.
