import re, sys, glob, os

CURSED = r'\b(delve|tapestry|testament|pivotal|underscore|foster|crucial|intricate|realm|nuanced|multifaceted|robust|seamless|leverage|beacon|vibrant|showcase|harness|elevate|embark|unlock|unleash|profound|myriad|plethora|paramount|cornerstone|ever-evolving|game-changer|deep dive|treasure trove|boasts|stands as)\b'
FILLER = r"(it'?s important to note|it is worth noting|it'?s worth noting|needless to say|rest assured|that being said|when it comes to|in order to|a wide range of|a variety of|plays a (?:crucial|key|vital|significant|pivotal) role)"
ANTITH = r"(not just\b|isn't about\b|is not about\b|not merely\b|more than just\b|, not [a-z]+ but\b)"
UNCON  = r"\b(is not|are not|was not|were not|does not|do not|did not|cannot|can not|will not|would not|has not|have not|had not|it is|that is|there is|what is|you are|they are|you will|you have|I am|we are)\b"
TAILS  = r"(, ensuring |, highlighting |, reflecting |, solidifying |, underscoring |, showcasing )"

def strip_code(t, ext):
    if ext in ('.Rmd', '.md'):
        t = re.sub(r'```.*?```', '', t, flags=re.S)
        t = re.sub(r'`[^`\n]*`', '', t)
        t = re.sub(r'<!--.*?-->', '', t, flags=re.S)
        t = re.sub(r'^\s*\|.*\|\s*$', '', t, flags=re.M)   # tables
        t = re.sub(r'https?://\S+', '', t)
        t = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', t)
    elif ext == '.R':
        keep = [l[3:] if l.startswith("#' ") else '' for l in t.split('\n')
                if l.startswith("#'") and not l.startswith("#' @")]
        t = '\n'.join(keep)
        t = re.sub(r'\\(code|link|pkg|emph|strong)\{[^{}]*\}', '', t)
    return t

def check(path):
    ext = os.path.splitext(path)[1]
    raw = open(path, encoding='utf-8', errors='replace').read()
    t = strip_code(raw, ext)
    hits = {}
    for name, pat in [('em/en dash', r'[—–]'), ('cursed', CURSED), ('filler', FILLER),
                      ('antithesis', ANTITH), ('uncontracted', UNCON), ('sig-tail', TAILS)]:
        m = re.findall(pat, t, flags=re.I)
        if m: hits[name] = len(m)
    return hits

files = sorted(set(
    glob.glob('*.md') + glob.glob('vignettes/*.Rmd') + glob.glob('vignettes/articles/*.Rmd') +
    glob.glob('R/*.R') + glob.glob('data-raw/*.R')))
total = {}
for f in files:
    h = check(f)
    if h:
        print(f"{f:44s} " + "  ".join(f"{k}:{v}" for k, v in h.items()))
        for k, v in h.items(): total[k] = total.get(k, 0) + v
print("\nTOTAL " + "  ".join(f"{k}:{v}" for k, v in sorted(total.items())))
