#!/usr/bin/env python3
"""
SeeSaw Companion — Step 12 Statistical Comparison Analysis
Generates publication-quality charts comparing all four story generation modes.

Usage (from repo root):
    python scripts/analysis_step12.py

Output: data/step12/charts/*.png  (300 dpi, suitable for dissertation figures)

Requirements:
    pip install pandas matplotlib scipy numpy
"""

import os
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from scipy import stats

# ─── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_DIR   = os.path.join(REPO_ROOT, "data")
STEP12_DIR = os.path.join(DATA_DIR, "step12")
CHARTS_DIR = os.path.join(STEP12_DIR, "charts")
os.makedirs(CHARTS_DIR, exist_ok=True)

# ─── Style ────────────────────────────────────────────────────────────────────
COLORS = {
    "cloud":        "#4C9BE8",   # blue
    "onDevice":     "#56C687",   # green
    "gemma4OnDevice": "#F4A261", # orange
    "hybrid":       "#9B72CF",   # purple
}
MODE_LABELS = {
    "cloud":          "Cloud\n(Gemini 2.0)",
    "onDevice":       "Apple FM\n(3B on-device)",
    "gemma4OnDevice": "Gemma 3 1B\n(on-device)",
    "hybrid":         "Hybrid\n(Gemma+Cloud)",
}
MODES = ["cloud", "onDevice", "gemma4OnDevice", "hybrid"]
DPI = 300
FIGSIZE_WIDE = (12, 6)
FIGSIZE_SQUARE = (8, 8)

plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "font.size": 11,
    "axes.titlesize": 13,
    "axes.labelsize": 11,
    "figure.dpi": DPI,
})

# ─── Load data ────────────────────────────────────────────────────────────────
def load_story_metrics():
    frames = []
    for mode, fname in [
        ("cloud",          "story_metrics_cloud.csv"),
        ("onDevice",       "story_metrics_ondevice.csv"),
        ("gemma4OnDevice", "story_metrics_gemma4.csv"),
        ("hybrid",         "story_metrics_hybrid.csv"),
    ]:
        path = os.path.join(STEP12_DIR, fname)
        if not os.path.exists(path):
            print(f"  WARNING: {fname} not found — skipping {mode}")
            continue
        df = pd.read_csv(path)
        # Normalise column name variants
        df.columns = df.columns.str.strip()
        df["_mode"] = mode
        frames.append(df)
    return pd.concat(frames, ignore_index=True) if frames else pd.DataFrame()


def load_privacy_metrics():
    frames = {}
    for mode, fname in [
        ("cloud",          "step5/privacy_pipeline_cloud.csv"),
        ("onDevice",       "step6/privacy_pipeline_ondevice.csv"),
        ("gemma4OnDevice", "step7/privacy_pipeline_gemma4.csv"),
        ("hybrid",         "step8/privacy_pipeline_hybrid.csv"),
    ]:
        path = os.path.join(DATA_DIR, fname)
        if not os.path.exists(path):
            print(f"  WARNING: {fname} not found — skipping privacy metrics for {mode}")
            continue
        frames[mode] = pd.read_csv(path)
    return frames


# ─── Chart helpers ────────────────────────────────────────────────────────────
def savefig(fig, name):
    path = os.path.join(CHARTS_DIR, name)
    fig.savefig(path, dpi=DPI, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved {name}")


def add_significance_bar(ax, x1, x2, y, p_value):
    """Draw a significance bracket between two bars."""
    stars = "***" if p_value < 0.001 else ("**" if p_value < 0.01 else ("*" if p_value < 0.05 else "ns"))
    ax.plot([x1, x1, x2, x2], [y, y + 0.03 * y, y + 0.03 * y, y], lw=1.0, c="black")
    ax.text((x1 + x2) / 2, y + 0.04 * y, stars, ha="center", va="bottom", fontsize=9)


# ─── Figure 12.1 — Generation latency boxplot ─────────────────────────────────
def fig_latency_boxplot(df):
    col = "totalGenerationMs"
    if col not in df.columns:
        print(f"  SKIP fig_latency_boxplot: column '{col}' not found")
        return

    fig, axes = plt.subplots(1, 2, figsize=FIGSIZE_WIDE)

    # Left: total generation latency
    data_total = [df[df["_mode"] == m][col].dropna().values / 1000 for m in MODES]
    bp = axes[0].boxplot(
        data_total, labels=[MODE_LABELS[m] for m in MODES],
        patch_artist=True, medianprops=dict(color="black", linewidth=2),
        whiskerprops=dict(linestyle="--"),
    )
    for patch, mode in zip(bp["boxes"], MODES):
        patch.set_facecolor(COLORS[mode])
        patch.set_alpha(0.8)
    axes[0].set_title("Total Story Beat Generation Time")
    axes[0].set_ylabel("Time (seconds)")
    axes[0].set_xlabel("Generation Mode")
    axes[0].grid(axis="y", alpha=0.3)

    # Right: TTFT / first-token latency
    ttft_col = "timeToFirstTokenMs"
    if ttft_col in df.columns:
        data_ttft = [df[(df["_mode"] == m) & (df[ttft_col] > 0)][ttft_col].dropna().values / 1000 for m in MODES]
        bp2 = axes[1].boxplot(
            data_ttft, labels=[MODE_LABELS[m] for m in MODES],
            patch_artist=True, medianprops=dict(color="black", linewidth=2),
            whiskerprops=dict(linestyle="--"),
        )
        for patch, mode in zip(bp2["boxes"], MODES):
            patch.set_facecolor(COLORS[mode])
            patch.set_alpha(0.8)
        axes[1].set_title("Time to First Token (TTFT)")
        axes[1].set_ylabel("Time (seconds)")
        axes[1].set_xlabel("Generation Mode")
        axes[1].grid(axis="y", alpha=0.3)
    else:
        axes[1].text(0.5, 0.5, "TTFT data not available", ha="center", va="center")

    fig.suptitle("Story Generation Latency by Mode", fontsize=14, fontweight="bold")
    plt.tight_layout()
    savefig(fig, "fig12_1_latency_boxplot.png")


# ─── Figure 12.2 — Mean latency bar chart with error bars ─────────────────────
def fig_latency_bar(df):
    col = "totalGenerationMs"
    if col not in df.columns:
        print(f"  SKIP fig_latency_bar: column '{col}' not found")
        return

    means, stds, counts = [], [], []
    for m in MODES:
        vals = df[df["_mode"] == m][col].dropna() / 1000
        means.append(vals.mean())
        stds.append(vals.std())
        counts.append(len(vals))

    fig, ax = plt.subplots(figsize=(9, 5))
    x = np.arange(len(MODES))
    bars = ax.bar(x, means, yerr=stds, capsize=6, width=0.5,
                  color=[COLORS[m] for m in MODES], alpha=0.85, edgecolor="white")
    ax.set_xticks(x)
    ax.set_xticklabels([MODE_LABELS[m] for m in MODES])
    ax.set_ylabel("Mean Total Generation Time (s)")
    ax.set_title("Mean Story Beat Generation Latency ± SD", fontsize=13, fontweight="bold")
    ax.grid(axis="y", alpha=0.3)

    for bar, mean, std, n in zip(bars, means, stds, counts):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + std + 0.3,
                f"{mean:.1f}s\n(n={n})", ha="center", va="bottom", fontsize=9)

    plt.tight_layout()
    savefig(fig, "fig12_2_latency_bar.png")


# ─── Figure 12.3 — Memory footprint bar chart ─────────────────────────────────
def fig_memory_bar():
    # Empirical values from Instruments Memory profiling (session summaries)
    memory_mb = {
        "cloud":          65.4,
        "onDevice":       66.1,
        "gemma4OnDevice": 2960.0,
        "hybrid":         2960.0,
    }
    labels = [MODE_LABELS[m] for m in MODES]
    values = [memory_mb[m] for m in MODES]

    fig, ax = plt.subplots(figsize=(9, 5))
    bars = ax.bar(labels, values, color=[COLORS[m] for m in MODES], alpha=0.85, edgecolor="white", width=0.5)
    ax.set_ylabel("Peak RSS Memory (MB)")
    ax.set_title("Peak Memory Footprint by Generation Mode", fontsize=13, fontweight="bold")
    ax.set_yscale("log")
    ax.grid(axis="y", alpha=0.3, which="both")

    for bar, val in zip(bars, values):
        label = f"{val:.0f} MB" if val < 1000 else f"{val/1024:.2f} GB"
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() * 1.05,
                label, ha="center", va="bottom", fontsize=10, fontweight="bold")

    ax.annotate("GGUF model\nloads into RAM\n(Q4_K_M, 2.96 GB)",
                xy=(2, 2960), xytext=(1.5, 1000),
                arrowprops=dict(arrowstyle="->", color="gray"),
                fontsize=9, color="gray")

    plt.tight_layout()
    savefig(fig, "fig12_3_memory_bar.png")


# ─── Figure 12.4 — Privacy pipeline latency comparison ────────────────────────
def fig_pipeline_latency(privacy_frames):
    if not privacy_frames:
        print("  SKIP fig_pipeline_latency: no privacy metrics loaded")
        return

    stages = ["faceDetectMs", "faceBlurMs", "yoloMs", "sceneClassifyMs", "sttMs", "piiScrubMs"]
    stage_labels = ["Face\nDetect", "Face\nBlur", "YOLO\nDetect", "Scene\nClassify", "STT", "PII\nScrub"]

    fig, ax = plt.subplots(figsize=(12, 6))
    x = np.arange(len(stages))
    width = 0.2

    for i, mode in enumerate(MODES):
        if mode not in privacy_frames:
            continue
        df = privacy_frames[mode]
        means = [df[s].dropna().mean() if s in df.columns else 0 for s in stages]
        stds  = [df[s].dropna().std()  if s in df.columns else 0 for s in stages]
        ax.bar(x + i * width, means, width, label=MODE_LABELS[mode].replace("\n", " "),
               color=COLORS[mode], alpha=0.85, yerr=stds, capsize=3, edgecolor="white")

    ax.set_xticks(x + width * 1.5)
    ax.set_xticklabels(stage_labels)
    ax.set_ylabel("Stage Latency (ms)")
    ax.set_title("Privacy Pipeline Stage Latencies by Mode", fontsize=13, fontweight="bold")
    ax.legend(loc="upper right")
    ax.grid(axis="y", alpha=0.3)

    plt.tight_layout()
    savefig(fig, "fig12_4_pipeline_stages.png")


# ─── Figure 12.5 — Network footprint ─────────────────────────────────────────
def fig_network_footprint():
    # From Proxyman captures (Steps 5 & 8). Cloud mode sends ScenePayload JSON.
    # onDevice and Gemma send zero cloud bytes. Hybrid: 15 requests (all /generate fallbacks).
    data = {
        "cloud": {
            "requests": 25,
            "req_bytes_mean": 692,     # mean request body bytes
            "resp_bytes_mean": 423,    # mean response body bytes
        },
        "onDevice": {
            "requests": 0,
            "req_bytes_mean": 0,
            "resp_bytes_mean": 0,
        },
        "gemma4OnDevice": {
            "requests": 0,
            "req_bytes_mean": 0,
            "resp_bytes_mean": 0,
        },
        "hybrid": {
            "requests": 15,            # all fell back to /story/generate (enhance 404)
            "req_bytes_mean": 715,
            "resp_bytes_mean": 426,
        },
    }

    fig, axes = plt.subplots(1, 2, figsize=FIGSIZE_WIDE)

    # Left: number of cloud requests per session (5 sessions each)
    req_counts = [data[m]["requests"] / 5 for m in MODES]
    bars = axes[0].bar([MODE_LABELS[m] for m in MODES], req_counts,
                       color=[COLORS[m] for m in MODES], alpha=0.85, edgecolor="white", width=0.5)
    axes[0].set_ylabel("Cloud Requests per Session")
    axes[0].set_title("Cloud Requests per Story Session")
    axes[0].grid(axis="y", alpha=0.3)
    for bar, v in zip(bars, req_counts):
        if v > 0:
            axes[0].text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.05,
                         f"{v:.1f}", ha="center", fontsize=10, fontweight="bold")
        else:
            axes[0].text(bar.get_x() + bar.get_width() / 2, 0.05,
                         "0", ha="center", fontsize=10, color="gray")

    # Right: mean request + response bytes per beat
    req_b = [data[m]["req_bytes_mean"] for m in MODES]
    resp_b = [data[m]["resp_bytes_mean"] for m in MODES]
    x = np.arange(len(MODES))
    w = 0.35
    axes[1].bar(x - w/2, req_b, w, label="Request body", color="#6BAED6", alpha=0.85)
    axes[1].bar(x + w/2, resp_b, w, label="Response body", color="#FD8D3C", alpha=0.85)
    axes[1].set_xticks(x)
    axes[1].set_xticklabels([MODE_LABELS[m] for m in MODES])
    axes[1].set_ylabel("Bytes")
    axes[1].set_title("Mean Request / Response Size (cloud requests only)")
    axes[1].legend()
    axes[1].grid(axis="y", alpha=0.3)

    fig.suptitle("Network Footprint by Generation Mode", fontsize=14, fontweight="bold")
    plt.tight_layout()
    savefig(fig, "fig12_5_network_footprint.png")


# ─── Figure 12.6 — VAD layer distribution ─────────────────────────────────────
def fig_vad_layers():
    # From Step 9 VAD analysis (58 total turns across all modes)
    vad_data = {
        "L1 only (keyword)":          2,    # 3%
        "L2 success (semantic)":      27,   # 47%
        "L2 skipped (Gemma mode)":    29,   # 50% — Gemma/hybrid always skip L2
        # L3 hard cap fires in all 58 turns (i.e. recording always stops at cap)
    }

    fig, axes = plt.subplots(1, 2, figsize=FIGSIZE_WIDE)

    # Pie: VAD path distribution
    labels = list(vad_data.keys())
    sizes  = list(vad_data.values())
    pie_colors = ["#AEC6CF", "#56C687", "#F4A261"]
    wedges, texts, autotexts = axes[0].pie(
        sizes, labels=labels, autopct="%1.0f%%",
        colors=pie_colors, startangle=90, pctdistance=0.75,
        textprops={"fontsize": 10},
    )
    axes[0].set_title("VAD Layer Path Distribution\n(58 total turns, all modes)")

    # Bar: per-mode VAD breakdown
    mode_vad = {
        "cloud":          {"L1": 1, "L2 semantic": 16, "L2 skipped": 0,  "L3": 8},
        "onDevice":       {"L1": 1, "L2 semantic": 11, "L2 skipped": 0,  "L3": 6},
        "gemma4OnDevice": {"L1": 0, "L2 semantic": 0,  "L2 skipped": 19, "L3": 5},
        "hybrid":         {"L1": 0, "L2 semantic": 0,  "L2 skipped": 10, "L3": 3},
    }
    categories = ["L1", "L2 semantic", "L2 skipped", "L3"]
    cat_colors  = ["#AEC6CF", "#56C687", "#F4A261", "#CC0000"]
    x = np.arange(len(MODES))
    w = 0.18
    for j, (cat, col) in enumerate(zip(categories, cat_colors)):
        vals = [mode_vad[m][cat] for m in MODES]
        axes[1].bar(x + j * w, vals, w, label=cat, color=col, alpha=0.85, edgecolor="white")

    axes[1].set_xticks(x + w * 1.5)
    axes[1].set_xticklabels([MODE_LABELS[m].replace("\n", " ") for m in MODES], fontsize=9)
    axes[1].set_ylabel("Turn count")
    axes[1].set_title("VAD Layer Activations per Mode")
    axes[1].legend(fontsize=9)
    axes[1].grid(axis="y", alpha=0.3)

    fig.suptitle("Voice Activity Detection (VAD) Layer Analysis", fontsize=14, fontweight="bold")
    plt.tight_layout()
    savefig(fig, "fig12_6_vad_layers.png")


# ─── Figure 12.7 — Story output statistics ────────────────────────────────────
def fig_story_output(df):
    if "storyTextLength" not in df.columns:
        print("  SKIP fig_story_output: 'storyTextLength' column not found")
        return

    fig, axes = plt.subplots(1, 2, figsize=FIGSIZE_WIDE)

    # Left: story text length distribution
    data_len = [df[df["_mode"] == m]["storyTextLength"].dropna().values for m in MODES]
    bp = axes[0].boxplot(
        data_len, labels=[MODE_LABELS[m] for m in MODES],
        patch_artist=True, medianprops=dict(color="black", linewidth=2),
    )
    for patch, mode in zip(bp["boxes"], MODES):
        patch.set_facecolor(COLORS[mode])
        patch.set_alpha(0.8)
    axes[0].set_title("Story Beat Text Length")
    axes[0].set_ylabel("Characters per beat")
    axes[0].grid(axis="y", alpha=0.3)

    # Right: turn count (beats per session)
    if "turnCount" in df.columns:
        # Aggregate by session (first beat of each session)
        session_beats = df.groupby(["_mode", "timestamp"])["turnCount"].max().reset_index()
        data_turns = [session_beats[session_beats["_mode"] == m]["turnCount"].dropna().values for m in MODES]
        bp2 = axes[1].boxplot(
            data_turns, labels=[MODE_LABELS[m] for m in MODES],
            patch_artist=True, medianprops=dict(color="black", linewidth=2),
        )
        for patch, mode in zip(bp2["boxes"], MODES):
            patch.set_facecolor(COLORS[mode])
            patch.set_alpha(0.8)
        axes[1].set_title("Turns per Story Session")
        axes[1].set_ylabel("Turn count")
        axes[1].grid(axis="y", alpha=0.3)
    else:
        axes[1].text(0.5, 0.5, "Turn count data not available", ha="center", va="center")

    fig.suptitle("Story Output Characteristics by Mode", fontsize=14, fontweight="bold")
    plt.tight_layout()
    savefig(fig, "fig12_7_story_output.png")


# ─── Figure 12.8 — Kruskal-Wallis significance table ─────────────────────────
def fig_statistical_tests(df):
    col = "totalGenerationMs"
    if col not in df.columns:
        print(f"  SKIP fig_statistical_tests: '{col}' not found")
        return

    groups = {m: df[df["_mode"] == m][col].dropna().values for m in MODES}

    # Kruskal-Wallis overall
    stat, p_kw = stats.kruskal(*[g for g in groups.values() if len(g) > 0])

    # Pairwise Mann-Whitney U
    pairs = []
    mode_list = [m for m in MODES if len(groups[m]) > 0]
    for i in range(len(mode_list)):
        for j in range(i + 1, len(mode_list)):
            m1, m2 = mode_list[i], mode_list[j]
            u_stat, p_val = stats.mannwhitneyu(groups[m1], groups[m2], alternative="two-sided")
            # Bonferroni correction for 6 pairs
            p_corrected = min(p_val * 6, 1.0)
            pairs.append({
                "Mode A": MODE_LABELS[m1].replace("\n", " "),
                "Mode B": MODE_LABELS[m2].replace("\n", " "),
                "U statistic": f"{u_stat:.1f}",
                "p (uncorrected)": f"{p_val:.4f}",
                "p (Bonferroni)": f"{p_corrected:.4f}",
                "Significant": "Yes" if p_corrected < 0.05 else "No",
            })

    fig, ax = plt.subplots(figsize=(12, 4))
    ax.axis("off")
    title = (
        f"Kruskal-Wallis H-test: H = {stat:.2f}, p = {p_kw:.4f} "
        f"({'significant' if p_kw < 0.05 else 'not significant'} at α=0.05)\n"
        "Pairwise Mann-Whitney U (Bonferroni-corrected for 6 comparisons):"
    )
    ax.set_title(title, fontsize=11, loc="left", pad=10)

    table_data = [[r["Mode A"], r["Mode B"], r["U statistic"],
                   r["p (uncorrected)"], r["p (Bonferroni)"], r["Significant"]] for r in pairs]
    col_labels = ["Mode A", "Mode B", "U", "p", "p (corrected)", "Sig."]
    tbl = ax.table(cellText=table_data, colLabels=col_labels,
                   cellLoc="center", loc="center", bbox=[0, 0, 1, 0.85])
    tbl.auto_set_font_size(False)
    tbl.set_fontsize(10)

    # Highlight significant rows
    for row_idx, row in enumerate(pairs, start=1):
        color = "#d4edda" if row["Significant"] == "Yes" else "#f8d7da"
        for col_idx in range(len(col_labels)):
            tbl[row_idx, col_idx].set_facecolor(color)

    plt.tight_layout()
    savefig(fig, "fig12_8_statistical_tests.png")

    # Also print to console
    print(f"\n  Kruskal-Wallis: H={stat:.2f}, p={p_kw:.4f}")
    for r in pairs:
        print(f"    {r['Mode A']} vs {r['Mode B']}: U={r['U statistic']}, p={r['p (Bonferroni)']} ({r['Significant']})")


# ─── Figure 12.9 — Round-trip latency breakdown ───────────────────────────────
def fig_roundtrip():
    # End-to-end round-trip estimates per mode (from Step 11 analysis)
    # Components: pipeline + generation + TTS + VAD listen
    roundtrip = {
        "cloud": {
            "Privacy pipeline": 0.6,
            "Generation (cloud RTT)": 4.2,
            "TTS playback (est.)": 15.0,
            "VAD listen window": 8.0,
        },
        "onDevice": {
            "Privacy pipeline": 0.6,
            "Generation (Apple FM)": 7.1,
            "TTS playback (est.)": 5.9,
            "VAD listen window": 8.0,
        },
        "gemma4OnDevice": {
            "Privacy pipeline": 0.6,
            "Generation (Gemma)": 14.6,
            "TTS playback (est.)": 6.7,
            "VAD listen window": 8.0,
        },
        "hybrid": {
            "Privacy pipeline": 0.6,
            "Generation (beat 0 Gemma)": 19.6,   # weighted avg across sessions
            "Generation (beats 1+ cloud)": 4.2,
            "TTS playback (est.)": 5.2,
            "VAD listen window": 8.0,
        },
    }

    fig, ax = plt.subplots(figsize=(11, 6))
    x = np.arange(len(MODES))
    bottoms = np.zeros(len(MODES))
    component_colors = ["#2166AC", "#4DAC26", "#D01C8B", "#F1A340"]

    all_components = set()
    for v in roundtrip.values():
        all_components.update(v.keys())
    all_components = sorted(all_components)

    for comp, color in zip(all_components, component_colors * 3):
        vals = [roundtrip[m].get(comp, 0) for m in MODES]
        ax.bar(x, vals, bottom=bottoms, label=comp, color=color, alpha=0.8, edgecolor="white")
        for xi, (v, b) in enumerate(zip(vals, bottoms)):
            if v > 0.5:
                ax.text(xi, b + v / 2, f"{v:.1f}s", ha="center", va="center",
                        fontsize=8, color="white", fontweight="bold")
        bottoms += vals

    ax.set_xticks(x)
    ax.set_xticklabels([MODE_LABELS[m] for m in MODES])
    ax.set_ylabel("Time (seconds)")
    ax.set_title("Estimated Round-Trip Latency per Story Beat", fontsize=13, fontweight="bold")
    ax.legend(loc="upper left", fontsize=9)
    ax.grid(axis="y", alpha=0.3)

    plt.tight_layout()
    savefig(fig, "fig12_9_roundtrip_latency.png")


# ─── Main ─────────────────────────────────────────────────────────────────────
def main():
    print("SeeSaw Step 12 — Statistical Analysis")
    print(f"Data dir : {DATA_DIR}")
    print(f"Chart dir: {CHARTS_DIR}")
    print()

    print("Loading story metrics…")
    df = load_story_metrics()
    if df.empty:
        print("  ERROR: no story metric CSVs found — ensure data/*.csv files are present")
        sys.exit(1)
    print(f"  Loaded {len(df)} rows across {df['_mode'].nunique()} modes")

    print("\nLoading privacy pipeline metrics…")
    privacy_frames = load_privacy_metrics()
    print(f"  Loaded {len(privacy_frames)} mode(s)")

    print("\nGenerating charts…")
    fig_latency_boxplot(df)
    fig_latency_bar(df)
    fig_memory_bar()
    fig_pipeline_latency(privacy_frames)
    fig_network_footprint()
    fig_vad_layers()
    fig_story_output(df)
    fig_statistical_tests(df)
    fig_roundtrip()

    print(f"\nDone — {len(os.listdir(CHARTS_DIR))} chart(s) in {CHARTS_DIR}/")


if __name__ == "__main__":
    main()
