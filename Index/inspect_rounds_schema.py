import os, json
from collections import Counter, defaultdict

ROUNDS_DIR = "rounds"  # <-- change if your output folder is different (e.g. output/rounds)

def is_date_like(s: str) -> bool:
    if not isinstance(s, str): return False
    # simple ISO-ish check
    return ("-" in s and "T" in s) or (len(s) >= 10 and s[4] == "-" and s[7] == "-")

def main():
    if not os.path.isdir(ROUNDS_DIR):
        raise SystemExit(f"Could not find folder: {ROUNDS_DIR}. Update ROUNDS_DIR in the script.")

    files = [f for f in os.listdir(ROUNDS_DIR) if f.endswith(".json")]
    if not files:
        raise SystemExit(f"No .json files found in {ROUNDS_DIR}")

    # sample a subset so it's fast
    files = files[:200]

    key_counts = Counter()
    sample_values = defaultdict(list)
    round_shapes = Counter()

    for fn in files:
        path = os.path.join(ROUNDS_DIR, fn)
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)

        # rounds file could be list OR object with "rounds"
        if isinstance(data, dict):
            rounds = data.get("rounds") or data.get("data") or data.get("items") or []
        else:
            rounds = data

        if not isinstance(rounds, list) or not rounds:
            continue

        for r in rounds[:25]:  # sample first 25 rounds per player file
            if not isinstance(r, dict):
                continue
            keys = tuple(sorted(r.keys()))
            round_shapes[keys] += 1

            for k, v in r.items():
                key_counts[k] += 1
                if len(sample_values[k]) < 5:
                    sample_values[k].append(v)

    print("\n=== TOP KEYS (most common) ===")
    for k, c in key_counts.most_common(40):
        print(f"{k:30}  {c}")

    print("\n=== SAMPLE VALUES (first few) ===")
    for k in list(key_counts.keys())[:30]:
        print(f"\n{k}:")
        for v in sample_values[k][:5]:
            print("  ", v)

    # heuristic guesses
    candidates = {"date": [], "score": [], "course": [], "tournament": []}
    for k in key_counts.keys():
        lk = k.lower()
        if "date" in lk or "time" in lk:
            candidates["date"].append(k)
        if "score" in lk or "strokes" in lk or lk in ("r1","r2","r3","r4"):
            candidates["score"].append(k)
        if "course" in lk or "club" in lk or "venue" in lk:
            candidates["course"].append(k)
        if "tournament" in lk or "event" in lk:
            candidates["tournament"].append(k)

    print("\n=== HEURISTIC FIELD CANDIDATES ===")
    for group, ks in candidates.items():
        print(f"{group}: {ks}")

    print("\n=== MOST COMMON ROUND SHAPES (key sets) ===")
    for shape, c in round_shapes.most_common(5):
        print(f"\nCount: {c}")
        print("Keys:", list(shape))

if __name__ == "__main__":
    main()
